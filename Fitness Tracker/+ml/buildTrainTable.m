function T = buildTrainTable(dataDir, opts)
%BUILDTRAINTABLE  Tüm .mat dosyalarını işle, ML için tek labeled table üret
%
%   T = ml.buildTrainTable()                        — default "data/" klasörü
%   T = ml.buildTrainTable("data/")
%   T = ml.buildTrainTable("data/", opts)
%
%   opts.activities : hangi aktiviteler dahil edilsin (default all)
%   opts.personas   : hangi personalar dahil edilsin (default all)
%   opts.verbose    : true/false
%
%   T : table — her satır bir pencere, kolonlar feature'lar + activity + persona_id

arguments
    dataDir (1,1) string = "data/"
    opts.activities (1,:) string = ["sitting","walking","running","stairsup","stairsdown"]
    opts.personas   (1,:) string = ["01","02","03"]
    opts.verbose    (1,1) logical = true
end

if ~isfolder(dataDir)
    error('Klasör bulunamadı: %s', dataDir);
end

allFeats = {};
fileCount = 0;

if opts.verbose
    fprintf('\n=== Building training table ===\n');
    fprintf('%-25s %-12s %-8s %s\n', 'File', 'Activity', 'Persona', 'Windows');
    fprintf('%s\n', repmat('-', 1, 60));
end

for a = opts.activities
    for p = opts.personas
        matName = sprintf('%s_%s.mat', a, p);
        matPath = fullfile(dataDir, matName);

        if ~isfile(matPath)
            if opts.verbose
                fprintf('%-25s %-12s %-8s %s\n', matName, a, p, '(YOK)');
            end
            continue;
        end

        try
            R = core.processSession(matPath, p, 'verbose', false);
            F = ml.extractWindowFeatures(R);

            if height(F) > 0
                allFeats{end+1} = F; %#ok<AGROW>
                fileCount = fileCount + 1;

                if opts.verbose
                    fprintf('%-25s %-12s %-8s %d\n', matName, a, p, height(F));
                end
            end
        catch ME
            if opts.verbose
                fprintf('%-25s %-12s %-8s HATA: %s\n', matName, a, p, ME.message);
            end
        end
    end
end

if isempty(allFeats)
    error('Hiç veri yüklenemedi. dataDir/dosya adlarını kontrol et.');
end

T = vertcat(allFeats{:});

% Activity'yi categorical yap — ML algoritmaları daha iyi handle eder
T.activity = categorical(T.activity);
T.persona_id = categorical(T.persona_id);

if opts.verbose
    fprintf('\n--- Özet ---\n');
    fprintf('Toplam dosya     : %d\n', fileCount);
    fprintf('Toplam pencere   : %d\n', height(T));
    fprintf('Özellik sayısı   : %d\n', width(T) - 3);  % activity, persona_id, t_center hariç
    fprintf('\nAktivite dağılımı:\n');
    disp(countcats(T.activity));
    fprintf('\nPersona dağılımı:\n');
    disp(countcats(T.persona_id));
end
end