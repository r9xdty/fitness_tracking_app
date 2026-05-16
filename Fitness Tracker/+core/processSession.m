function R = processSession(matFilePath, personaID, opts)
%PROCESSSESSION  Tek bir kayıt dosyasını uçtan uca işle
%
%   R = core.processSession("data/walking_01.mat", "01")
%
%   matFilePath : .mat dosyası yolu
%   personaID   : "01", "02" veya "03"
%   opts.verbose : true (default) → konsola özet yaz
%
%   Çıktı R struct alanları:
%     .session   : util.loadSession çıktısı (raw data)
%     .persona   : core.Persona objesi
%     .activity  : dosya adından çıkarılmış (string)
%     .duration  : saniye
%     .nSteps    : IMU peak-detect adım sayısı
%     .cadence   : steps per minute
%     .kcal      : yakılan kalori
%     .met       : kullanılan MET değeri
%     .peakInfo  : countSteps debug bilgisi (plot için)

arguments
    matFilePath  (1,1) string
    personaID    (1,1) string
    opts.verbose (1,1) logical = true
end

% 1) Personayı yükle
P = core.buildAllPersonas();
personaField = "p" + personaID;
if ~isfield(P, personaField)
    error('Geçersiz persona ID: %s (01/02/03 olmalı)', personaID);
end
persona = P.(personaField);

% 2) Aktiviteyi dosya adından çıkar
[~, fname, ~] = fileparts(matFilePath);
activity = extractActivityFromName(fname);

% 3) Oturumu yükle
S = util.loadSession(matFilePath, activity);

if ~isfield(S, 'accel')
    error('Oturumda Acceleration yok: %s', matFilePath);
end

% 4) Gravity'yi çıkar
accelXYZ = [S.accel.x, S.accel.y, S.accel.z];
accelDyn = util.removeGravity(accelXYZ, S.accel.fs);

% 5) Adım say
duration = S.accel.t(end) - S.accel.t(1);
[nSteps, peakInfo] = metrics.countSteps(persona, accelDyn, S.accel.t);

% 6) Cadence
cadence_spm = metrics.computeCadence(nSteps, duration);

% 7) Kalori
[kcal, met] = metrics.computeCalories(persona, activity, duration);

% Çıktıyı topla
R = struct();
R.session   = S;
R.persona   = persona;
R.activity  = activity;
R.duration  = duration;
R.nSteps    = nSteps;
R.cadence   = cadence_spm;
R.kcal      = kcal;
R.met       = met;
R.peakInfo  = peakInfo;
R.accelDyn  = accelDyn;        % ileride başka analizler için

if opts.verbose
    printSummary(R);
end
end

% ---- Yardımcılar ----

function activity = extractActivityFromName(fname)
% "walking_01" → "walking", "stairsup_02" → "stairsup"
parts = split(string(fname), "_");
activity = parts(1);
end

function printSummary(R)
fprintf('\n┌─ Session Summary ────────────────────────────────────┐\n');
fprintf('│ Persona  : %-10s  (BMI %.1f, BMR %d kcal/d)\n', ...
    R.persona.name, R.persona.bmi, round(R.persona.bmr));
fprintf('│ Activity : %-10s  Duration: %.1f s\n', R.activity, R.duration);
fprintf('│ Steps    : %4d           Cadence: %.0f spm\n', R.nSteps, R.cadence);
fprintf('│ MET      : %.1f            Calories: %.1f kcal\n', R.met, R.kcal);
fprintf('│                          (%.2f%% of daily BMR)\n', ...
    100 * R.kcal / R.persona.bmr);
fprintf('└──────────────────────────────────────────────────────┘\n');
end