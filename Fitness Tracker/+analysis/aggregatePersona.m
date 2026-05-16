function results = aggregatePersona(personaID, dataDir, activities)
%AGGREGATEPERSONA  Bir personanın tüm aktivite oturumlarını işle
%
%   results = analysis.aggregatePersona("01")
%   results = analysis.aggregatePersona("01", "data/")
%
%   results : cell array of core.processSession çıktıları

arguments
    personaID  (1,1) string
    dataDir    (1,1) string = "data/"
    activities (1,:) string = ["sitting","walking","running","stairsup","stairsdown"]
end

results = {};
for a = activities
    matPath = fullfile(dataDir, sprintf('%s_%s.mat', a, personaID));
    if isfile(matPath)
        try
            R = core.processSession(matPath, personaID, 'verbose', false);
            results{end+1} = R; %#ok<AGROW>
        catch ME
            fprintf('Atlandı %s: %s\n', matPath, ME.message);
        end
    end
end
fprintf('Persona %s: %d oturum işlendi\n', personaID, numel(results));
end