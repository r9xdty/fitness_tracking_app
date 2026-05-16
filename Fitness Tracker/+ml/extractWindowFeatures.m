function F = extractWindowFeatures(R, opts)
%EXTRACTWINDOWFEATURES  Persona-invariant özellikler (v2)
%
%   Değişiklikler v1'e göre:
%     - Per-axis mean kaldırıldı (telefon yönelim artefaktı yaratıyordu)
%     - Cross-axis korelasyonlar koruundu
%     - Magnitude tabanlı feature'lar genişletildi (yöne bağımsız)

    arguments
        R       struct
        opts.winSec (1,1) double = 2.0
        opts.hopSec (1,1) double = 1.0
    end
    
    t       = R.session.accel.t;
    accDyn  = R.accelDyn;
    fs      = R.session.accel.fs;
    amag    = sqrt(sum(accDyn.^2, 2));
    
    if isfield(R.session, 'gyro')
        gyro = [R.session.gyro.x, R.session.gyro.y, R.session.gyro.z];
        gyro = interp1(R.session.gyro.t, gyro, t, 'linear', 'extrap');
        gmag = sqrt(sum(gyro.^2, 2));
    else
        gyro = zeros(numel(t), 3);
        gmag = zeros(numel(t), 1);
    end
    
    winN = round(opts.winSec * fs);
    hopN = round(opts.hopSec * fs);
    
    if numel(t) < winN
        F = table();
        return;
    end
    
    starts = 1:hopN:(numel(t) - winN + 1);
    nWin = numel(starts);
    features = zeros(nWin, 23);
    
    centers  = zeros(nWin, 1);
    
    for k = 1:nWin
        idx = starts(k):(starts(k) + winN - 1);
        wa  = accDyn(idx, :);
        wm  = amag(idx);
        wg  = gyro(idx, :);
        wgm = gmag(idx);
        
        % --- Per-axis std/rms (6) — yön bilgisi taşır ama mean'siz ---
        features(k, 1)  = std(wa(:,1));
        features(k, 2)  = std(wa(:,2));
        features(k, 3)  = std(wa(:,3));
        features(k, 4)  = rms(wa(:,1));
        features(k, 5)  = rms(wa(:,2));
        features(k, 6)  = rms(wa(:,3));
        
        % --- Magnitude feature'ları (6) — yön bağımsız, persona-invariant ---
        features(k, 7)  = mean(wm);
        features(k, 8)  = std(wm);
        features(k, 9)  = rms(wm);
        features(k, 10) = max(wm) - min(wm);
        features(k, 11) = median(wm);
        features(k, 12) = iqr(wm);
        
        % --- Frekans domain (5) ---
        features(k, 13) = dominantFreq(wm, fs);
        features(k, 14) = safeBandpower(wm, fs, [0.3 1.0]);   % sitting/yavaş
        features(k, 15) = safeBandpower(wm, fs, [1.0 2.5]);   % walking
        features(k, 16) = safeBandpower(wm, fs, [2.5 min(5.0, fs/2 - 0.1)]); % running
        features(k, 17) = specEntropy(wm, fs);                 % sinyal düzeni
        
        % --- SMA + korelasyon (3) ---
        features(k, 18) = sum(abs(wa(:,1)) + abs(wa(:,2)) + abs(wa(:,3))) / winN;
        features(k, 19) = corrSafe(wa(:,1), wa(:,2));
        features(k, 20) = corrSafe(wa(:,1), wa(:,3));
        
        % --- Gyro magnitude (2) — yön bağımsız ---
        features(k, 21) = mean(wgm);
        features(k, 22) = std(wgm);
        features(k, 23) = autocorrPeak(wm, fs);
        
        centers(k) = t(starts(k) + floor(winN/2));
    end
    
    F = array2table(features, 'VariableNames', { ...
        'ax_std','ay_std','az_std', ...
        'ax_rms','ay_rms','az_rms', ...
        'mag_mean','mag_std','mag_rms','mag_p2p','mag_median','mag_iqr', ...
        'dom_freq','bp_low','bp_walk','bp_run','spec_entropy', ...
        'sma','corr_xy','corr_xz', ...
        'gyro_mag_mean','gyro_mag_std','autocorr_peak'});
    
    F.t_center   = centers;
    F.activity   = repmat(string(R.activity), nWin, 1);
    F.persona_id = repmat(string(R.persona.id), nWin, 1);
end


function fd = dominantFreq(sig, fs)
    sig = sig - mean(sig);
    N = numel(sig);
    Y = abs(fft(sig));
    Y = Y(1:floor(N/2)+1);
    f = (0:floor(N/2)) * fs / N;
    Y(1) = 0;
    [~, idx] = max(Y);
    fd = f(idx);
end

function se = specEntropy(sig, fs)
    % Spektral entropi — ritmik sinyalde düşük, gürültülüde yüksek
    sig = sig - mean(sig);
    N = numel(sig);
    Y = abs(fft(sig)).^2;
    Y = Y(2:floor(N/2)+1);
    if sum(Y) < eps
        se = 0; return;
    end
    p = Y / sum(Y);
    p = p(p > 0);
    se = -sum(p .* log2(p));
end

function bp = safeBandpower(sig, fs, band)
    try, bp = bandpower(sig, fs, band);
    catch, bp = 0; end
    if isnan(bp) || isinf(bp), bp = 0; end
end

function c = corrSafe(x, y)
    if std(x) < eps || std(y) < eps, c = 0;
    else, c = corr(x, y); end
    if isnan(c), c = 0; end
end

function ap = autocorrPeak(sig, fs)
% İlk anlamlı autocorrelation peak'inin değeri (0 lag dışında)
sig = sig - mean(sig);
if std(sig) < eps, ap = 0; return; end

maxLag = min(numel(sig)-1, round(fs * 1.5));  % 1.5 sn max
[c, lags] = xcorr(sig, maxLag, 'normalized');
c = c(lags >= round(fs * 0.2));  % 0.2 sn lag sonrası

if isempty(c), ap = 0; return; end

[pks, ~] = findpeaks(c);
if isempty(pks)
    ap = max(c);
else
    ap = max(pks);
end
if isnan(ap), ap = 0; end
end