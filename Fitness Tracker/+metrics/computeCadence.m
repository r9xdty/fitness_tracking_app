function cadence_spm = computeCadence(nSteps, duration_s)
%COMPUTECADENCE  Adım/dakika (steps per minute)
arguments
    nSteps      (1,1) double {mustBeNonnegative}
    duration_s  (1,1) double {mustBePositive}
end
cadence_spm = nSteps / (duration_s / 60);
end