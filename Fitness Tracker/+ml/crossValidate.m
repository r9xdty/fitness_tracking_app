% +ml/crossValidate.m
function cvAcc = crossValidate(T, modelType, k)
%CROSSVALIDATE  k-fold cross-validation accuracy
%
%   cvAcc = ml.crossValidate(T, "ensemble", 5)
arguments
    T table
    modelType (1,1) string = "ensemble"
    k (1,1) double = 5
end

y = T.activity;
X = removevars(T, {'t_center','activity','persona_id'});

cv = cvpartition(y, 'KFold', k);
accs = zeros(k, 1);

for i = 1:k
    trainIdx = training(cv, i);
    testIdx  = test(cv, i);

    mdl = trainOneLocal(X(trainIdx,:), y(trainIdx), modelType);
    pred = predict(mdl, X(testIdx,:));
    accs(i) = mean(pred == y(testIdx));
end

cvAcc = mean(accs);
fprintf('%d-fold CV (%s): mean acc = %.3f ± %.3f\n', k, modelType, ...
    cvAcc, std(accs));
end

function mdl = trainOneLocal(X, y, modelType)
% trainAndEvaluate'taki trainOne ile aynı — kopya
classes = categories(y);
classCounts = countcats(y);
classWeights = sum(classCounts) ./ (numel(classes) * classCounts);
sampleWeights = zeros(size(y));
for c = 1:numel(classes)
    sampleWeights(y == classes{c}) = classWeights(c);
end

switch lower(modelType)
    case "ensemble"
        t = templateTree('MaxNumSplits', 30, 'MinLeafSize', 5);
        mdl = fitcensemble(X, y, 'Method', 'Bag', ...
            'NumLearningCycles', 100, 'Learners', t, ...
            'Weights', sampleWeights);
    case "knn"
        mdl = fitcknn(X, y, 'NumNeighbors', 7, 'Standardize', true);
    otherwise
        error('Bilinmeyen: %s', modelType);
end
end