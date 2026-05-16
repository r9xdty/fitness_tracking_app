function [kcal, met] = computeCalories(persona, activity, duration_s)
%COMPUTECALORIES  METs tabanlı kalori yakımı
%
%   [kcal, met] = metrics.computeCalories(persona, activity, duration_s)
%
%   persona    : core.Persona struct (weight_kg kullanılır)
%   activity   : "sitting" | "walking" | "running" | "stairsup" | "stairsdown"
%   duration_s : aktivite süresi (saniye)
%
%   Formül: kcal = MET × weight_kg × hours
%   MET değerleri ACSM 2011 Compendium'dan alındı.

arguments
    persona     struct
    activity    (1,1) string
    duration_s  (1,1) double {mustBeNonnegative}
end

% MET lookup tablosu (ACSM 2011)
metTable = dictionary( ...
    "sitting",     1.3, ...    % quiet sitting
    "walking",     4.3, ...    % 5.6 km/h, normal pace
    "running",     8.3, ...    % 8 km/h, jogging
    "stairsup",    8.0, ...    % climbing stairs, moderate
    "stairsdown",  3.5);       % descending stairs

if ~isKey(metTable, activity)
    warning('computeCalories:unknownActivity', ...
        'Bilinmeyen aktivite: %s. MET=1 varsayılıyor.', activity);
    met = 1.0;
else
    met = metTable(activity);
end

hours = duration_s / 3600;
kcal = met * persona.weight_kg * hours;
end