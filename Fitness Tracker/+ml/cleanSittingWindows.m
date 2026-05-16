function T = cleanData(T, opts)
%CLEANDATA  Kötü pencereleri at: sallanan sitting + sessiz walking
%
%   T = ml.cleanData(T)
%   T = ml.cleanData(T, opts)

    arguments
        T table
        opts.maxStdSitting (1,1) double = 1.2  % sitting için max std (m/s^2)
        opts.minStdWalking (1,1) double = 0.8  % walking için min std
        opts.minMagWalking (1,1) double = 0.5  % walking için min rms magnitude
        opts.verbose       (1,1) logical = true
    end
    
    n0 = height(T);
    
    % 1) Sallanan sitting penceleri at
    sitMask = T.activity == "sitting";
    sitBad  = sitMask & T.mag_std > opts.maxStdSitting;
    
    % 2) Sessiz walking penceleri at (yürümeyi durduğun anlar)
    walkMask = T.activity == "walking";
    walkBad  = walkMask & (T.mag_std < opts.minStdWalking | ...
                          T.mag_rms < opts.minMagWalking);
    
    % 3) NaN/Inf içeren satırlar
    Xnum = T{:, 1:end-3};  % son 3 kolon: t_center, activity, persona_id
    badRow = any(isnan(Xnum) | isinf(Xnum), 2);
    
    toRemove = sitBad | walkBad | badRow;
    T(toRemove, :) = [];
    
    if opts.verbose
        fprintf('\n=== Data Cleaning ===\n');
        fprintf('Sitting (gürültülü) atılan : %d / %d\n', sum(sitBad), sum(sitMask));
        fprintf('Walking (sessiz) atılan    : %d / %d\n', sum(walkBad), sum(walkMask));
        fprintf('NaN/Inf satır atılan       : %d\n', sum(badRow));
        fprintf('Toplam: %d → %d (%d satır atıldı, %%%.1f)\n', ...
                n0, height(T), n0 - height(T), 100*(n0 - height(T))/n0);
    end
end