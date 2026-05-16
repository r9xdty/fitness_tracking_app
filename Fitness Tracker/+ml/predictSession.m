function [labels, probs, counts] = predictSession(model, R)
%PREDICTSESSION  Eğitilmiş modeli tek oturuma uygula
%
%   [labels, probs, counts] = ml.predictSession(model, R)
%
%   model : ml.trainAndEvaluate çıktısı
%   R     : core.processSession çıktısı
%
%   labels : N×1 string — her pencere için tahmin
%   probs  : N×K matrix — sınıf olasılıkları (varsa)
%   counts : table — her sınıftan kaç pencere

F = ml.extractWindowFeatures(R);
X = removevars(F, {'t_center', 'activity', 'persona_id'});

[labels, scores] = predict(model.classifier, X);
labels = string(labels);

if exist('scores','var') && ~isempty(scores)
    probs = scores;
else
    probs = [];
end

% Count summary
[u, ~, ic] = unique(labels);
n = accumarray(ic, 1);
counts = table(u, n, 100*n/sum(n), ...
    'VariableNames', {'Activity','Windows','Percent'});
counts = sortrows(counts, 'Windows', 'descend');
end