% +util/inspectMat.m
function inspectMat(matFilePath)
%INSPECTMAT  MATLAB Mobile sensor .mat dosyasının içeriğini göster

arguments
    matFilePath (1,1) string
end

if ~isfile(matFilePath)
    error('Dosya bulunamadı: %s', matFilePath);
end

fprintf('\n=== %s ===\n', matFilePath);
raw = load(matFilePath);
fields = fieldnames(raw);

for i = 1:numel(fields)
    f = fields{i};
    val = raw.(f);
    fprintf('\n[%s]  class=%s\n', f, class(val));
    if istimetable(val) || istable(val)
        vars = val.Properties.VariableNames;
        fprintf('   Variable names : %s\n', strjoin(vars, ', '));
        fprintf('   Size           : %d rows x %d cols\n', height(val), width(val));
        try
            fprintf('   First row:\n');
            disp(val(1, :));
        catch
        end
    end
end
end