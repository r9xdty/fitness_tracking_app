function model = trainAndEvaluate(T, opts)
%TRAINANDEVALUATE  ML modeli eğit, değerlendir, döndür
%
%   model = ml.trainAndEvaluate(T)
%   model = ml.trainAndEvaluate(T, opts)
%
%   T    : ml.buildTrainTable çıktısı
%   opts.testRatio    : test set oranı (default 0.2)
%   opts.holdoutPersona : "01"/"02"/"03"/"none" - 
%                        bir personayı tamamen test'e ayır (default "none")
%   opts.modelType    : "tree" | "knn" | "svm" | "ensemble" | "auto"
%                       "auto" = hepsini dene, en iyiyi döndür
%
%   model : trained model + meta info struct

    arguments
        T table
        opts.testRatio       (1,1) double = 0.2
        opts.holdoutPersona  (1,1) string = "none"
        opts.modelType       (1,1) string = "auto"
        opts.verbose         (1,1) logical = true
    end
    
    % --- Feature ve label ayır ---
    yLabel = T.activity;
    
    % t_center, activity, persona_id'yi feature'lardan çıkar
    X = removevars(T, {'t_center', 'activity', 'persona_id'});
    
    % --- Train/test split ---
    rng(42);  % reproducibility
    
    if opts.holdoutPersona ~= "none"
        % Bir personayı tamamen test'e koy
        testIdx = T.persona_id == opts.holdoutPersona;
        trainIdx = ~testIdx;
        
        if opts.verbose
            fprintf('\n=== Train/Test Split: Persona-Holdout ===\n');
            fprintf('Test persona: %s\n', opts.holdoutPersona);
            fprintf('Train size  : %d, Test size: %d\n', sum(trainIdx), sum(testIdx));
        end
    else
        % Random split, sınıf-stratified
        cv = cvpartition(yLabel, 'HoldOut', opts.testRatio);
        trainIdx = training(cv);
        testIdx  = test(cv);
        
        if opts.verbose
            fprintf('\n=== Train/Test Split: Random Stratified ===\n');
            fprintf('Train size: %d, Test size: %d\n', sum(trainIdx), sum(testIdx));
        end
    end
    
    Xtrain = X(trainIdx, :);
    ytrain = yLabel(trainIdx);
    Xtest  = X(testIdx, :);
    ytest  = yLabel(testIdx);
    
    % --- Model adayları ---
    if opts.modelType == "auto"
    modelTypes = ["knn", "ensemble", "boosted", "subspace_knn"];
else
    modelTypes = opts.modelType;
end
    
    results = struct();
    bestAcc = 0;
    bestModel = [];
    bestName = "";
    
    if opts.verbose
        fprintf('\n=== Training Models ===\n');
        fprintf('%-12s %-12s %-12s\n', 'Model', 'TrainAcc', 'TestAcc');
        fprintf('%s\n', repmat('-', 1, 40));
    end
    
    for mt = modelTypes
        try
            mdl = trainOne(Xtrain, ytrain, mt);
            trainPred = predict(mdl, Xtrain);
            testPred  = predict(mdl, Xtest);
            
            trainAcc = mean(trainPred == ytrain);
            testAcc  = mean(testPred  == ytest);
            
            results.(char(mt)).model    = mdl;
            results.(char(mt)).trainAcc = trainAcc;
            results.(char(mt)).testAcc  = testAcc;
            
            if opts.verbose
                fprintf('%-12s %-12.3f %-12.3f\n', mt, trainAcc, testAcc);
            end
            
            if testAcc > bestAcc
                bestAcc = testAcc;
                bestModel = mdl;
                bestName = mt;
            end
        catch ME
            if opts.verbose
                fprintf('%-12s HATA: %s\n', mt, ME.message);
            end
        end
    end
    
    % --- En iyi modelle detaylı değerlendirme ---
    finalPred = predict(bestModel, Xtest);
    
    if opts.verbose
        fprintf('\n=== Best Model: %s (test acc: %.3f) ===\n', bestName, bestAcc);
        
        % Confusion matrix
        fig = figure('Color','w','Name','Confusion Matrix','Position',[100 100 700 600]);
        cm = confusionchart(fig, ytest, finalPred);
        cm.Title = sprintf('Best Model: %s — Test Accuracy: %.1f%%', bestName, bestAcc*100);
        cm.RowSummary = 'row-normalized';
        cm.ColumnSummary = 'column-normalized';
        drawnow;
        
        % Per-class accuracy
        classes = categories(ytest);
        fprintf('\nPer-class accuracy:\n');
        for c = 1:numel(classes)
            mask = ytest == classes{c};
            if sum(mask) > 0
                acc = mean(finalPred(mask) == ytest(mask));
                fprintf('  %-12s : %.3f  (n=%d)\n', classes{c}, acc, sum(mask));
            end
        end
    end
    
    % --- Çıktıyı paketle ---
    model = struct();
    model.classifier  = bestModel;
    model.modelType   = bestName;
    model.testAcc     = bestAcc;
    model.trainAcc    = results.(char(bestName)).trainAcc;
    model.allResults  = results;
    model.featureNames = X.Properties.VariableNames;
    model.classes     = categories(yLabel);
    model.predict     = @(featTable) predict(bestModel, featTable);
    model.trainedAt   = datetime('now');
end


% trainAndEvaluate.m'in ALT KISMINDAKİ trainOne fonksiyonunu komple değiştir:
function mdl = trainOne(X, y, modelType)
    classes = categories(y);
    classCounts = countcats(y);
    classWeights = sum(classCounts) ./ (numel(classes) * classCounts);
    sampleWeights = zeros(size(y));
    for c = 1:numel(classes)
        sampleWeights(y == classes{c}) = classWeights(c);
    end
    
    switch lower(modelType)
        case "tree"
            mdl = fitctree(X, y, 'MaxNumSplits', 50, ...
                'MinLeafSize', 8, 'Weights', sampleWeights);
            
        case "knn"
            mdl = fitcknn(X, y, 'NumNeighbors', 5, ...
                'Standardize', true, 'Distance', 'cityblock', ...
                'DistanceWeight', 'inverse');
            
        case "svm"
            t = templateSVM('KernelFunction','linear', ...
                'Standardize', true, 'BoxConstraint', 1);
            mdl = fitcecoc(X, y, 'Learners', t, 'Coding', 'onevsone');
            
        case "ensemble"
            t = templateTree('MaxNumSplits', 30, 'MinLeafSize', 5);
            mdl = fitcensemble(X, y, 'Method', 'Bag', ...
                'NumLearningCycles', 150, 'Learners', t, ...
                'Weights', sampleWeights);
            
        case "boosted"
            % Gradient boosted trees — genellikle Bagging'i geçer
            t = templateTree('MaxNumSplits', 20, 'MinLeafSize', 5);
            mdl = fitcensemble(X, y, ...
                'Method', 'AdaBoostM2', ...
                'NumLearningCycles', 200, ...
                'LearnRate', 0.1, ...
                'Learners', t, ...
                'Weights', sampleWeights);
            
        case "subspace_knn"
            % Random subspace KNN — feature noise'a robust
            t = templateKNN('NumNeighbors', 5, 'Standardize', true);
            mdl = fitcensemble(X, y, ...
                'Method', 'Subspace', ...
                'NumLearningCycles', 30, ...
                'Learners', t, ...
                'NPredToSample', max(2, round(width(X)/3)), ...
                'Weights', sampleWeights);
            
        otherwise
            error('Bilinmeyen model: %s', modelType);
    end
end