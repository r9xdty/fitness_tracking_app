function [nSteps, peakInfo] = countSteps(persona, accelDyn, t, opts)
%COUNTSTEPS  Robust IMU peak-detection ile adım sayısı
%
%   Üç katmanlı koruma:
%     1. Aktivite kapısı: düşük enerjili pencerelerde peak aramaz
%     2. Prominence eşiği: amplitude yerine peak belirginliği
%     3. Cadence tutarlılığı: ritmik olmayan peak'leri eler
%
%   [nSteps, peakInfo] = metrics.countSteps(persona, accelDyn, t)
%
%   accelDyn : Nx3 gravity-removed ivme (util.removeGravity çıktısı)
%   t        : N×1 zaman vektörü (saniye)
%   opts     : (opsiyonel) struct
%      .minProminence    - peak prominence eşiği (m/s^2). Default 1.8
%      .minCadence       - minimum adım frekansı (Hz). Default 1.0
%      .maxCadence       - maksimum adım frekansı (Hz). Default 4.0
%      .activityRMSGate  - aktivite kapısı RMS eşiği (m/s^2). Default 0.6
%      .gateWindowSec    - aktivite kapısı pencere uzunluğu (s). Default 2.0
%      .maxCadenceCV     - max coefficient of variation. Default 0.35
%      .minBoutLength    - bir "bout"u kabul etmek için min peak. Default 3

    arguments
        persona  struct
        accelDyn (:,3) double
        t        (:,1) double
        opts.minProminence   (1,1) double = 1.8
        opts.minCadence      (1,1) double = 1.0
        opts.maxCadence      (1,1) double = 4.0
        opts.activityRMSGate (1,1) double = 0.6
        opts.gateWindowSec   (1,1) double = 2.0
        opts.maxCadenceCV    (1,1) double = 0.35
        opts.minBoutLength   (1,1) double = 3
    end
    
    fs = 1 / median(diff(t));
    
    % --- 1) 1D sinyali türet: dinamik magnitüd ---
    sig = sqrt(sum(accelDyn.^2, 2));
    sig = sig - mean(sig);
    
    % --- 2) Bandpass: walking/running cadence aralığı ---
    %  fs=10 Hz için Nyquist=5 Hz, [1, 4]/5 = [0.2, 0.8] güvenli
    nyq = fs / 2;
    if opts.maxCadence >= nyq
        opts.maxCadence = nyq * 0.95;
    end
    [b, a] = butter(2, [opts.minCadence opts.maxCadence] / nyq, 'bandpass');
    sigFilt = filtfilt(b, a, sig);
    
    % --- 3) AKTIVITE KAPISI: düşük enerjili pencereleri maskele ---
    winN = round(opts.gateWindowSec * fs);
    halfWin = floor(winN / 2);
    activeMask = false(size(sigFilt));
    
    for i = 1:numel(sigFilt)
        a1 = max(1, i - halfWin);
        a2 = min(numel(sigFilt), i + halfWin);
        rms_local = rms(sigFilt(a1:a2));
        if rms_local >= opts.activityRMSGate
            activeMask(i) = true;
        end
    end
    
    % Aktif olmayan bölgeleri sıfırla
    sigGated = sigFilt;
    sigGated(~activeMask) = 0;
    
    % --- 4) Peak detection (prominence tabanlı) ---
    minDistSamples = max(1, round(fs / opts.maxCadence));
    [pks, locs] = findpeaks(sigGated, ...
        'MinPeakProminence', opts.minProminence, ...
        'MinPeakDistance',   minDistSamples);
    
    % --- 5) CADENCE TUTARLILIK FİLTRESİ ---
    %  Peak'leri "bout"lara grupla. Bir bout = ardışık tutarlı ritmik peak'ler.
    %  CV (std/mean of intervals) düşükse bout valid, yüksekse sallama.
    
    if numel(locs) >= opts.minBoutLength
        validLocs = filterByConsistency(locs, t, opts);
        locs = validLocs;
        pks  = sigGated(locs);
    elseif numel(locs) < opts.minBoutLength
        % Yetersiz peak — büyük ihtimalle gerçek yürüme değil
        locs = [];
        pks  = [];
    end
    
    nSteps = numel(locs);
    
    duration = t(end) - t(1);
    cadence_Hz = nSteps / duration;
    
    peakInfo.locs        = locs;
    peakInfo.pks         = pks;
    peakInfo.signal      = sigFilt;
    peakInfo.signalGated = sigGated;
    peakInfo.activeMask  = activeMask;
    peakInfo.cadence_Hz  = cadence_Hz;
    peakInfo.cadence_spm = cadence_Hz * 60;
end


% ============== Yardımcı: Cadence Tutarlılık Filtresi ==============

function keepLocs = filterByConsistency(locs, t, opts)
% Peak'leri "bout"lara böl, CV düşük olan bout'ları tut.
% Bir bout = 3+ peak, inter-peak interval CV < maxCadenceCV

    intervals = diff(t(locs));
    keepLocs = [];
    
    % Sliding window approach: her peak için yerel CV hesapla
    halfBout = floor(opts.minBoutLength / 2);
    
    for i = 1:numel(locs)
        % Bu peak'in etrafındaki minBoutLength penceresinde CV bak
        a1 = max(1, i - halfBout);
        a2 = min(numel(locs), i + halfBout);
        
        if (a2 - a1) < opts.minBoutLength - 1
            continue;  % yeterince komşu yok
        end
        
        localIntervals = diff(t(locs(a1:a2)));
        if numel(localIntervals) < 2, continue; end
        
        cv = std(localIntervals) / mean(localIntervals);
        
        if cv < opts.maxCadenceCV
            keepLocs(end+1) = locs(i); %#ok<AGROW>
        end
    end
    
    keepLocs = keepLocs(:);
end