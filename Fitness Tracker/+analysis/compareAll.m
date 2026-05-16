function compareAll(insights)
%COMPAREALL  Üç personanın sağlık öngörülerini görsel karşılaştır
%
%   insights : 1x3 cell array of analysis.healthInsights outputs

arguments
    insights cell
end

n = numel(insights);
names    = cellfun(@(I) I.persona.name, insights, 'UniformOutput', false);
bmis     = cellfun(@(I) I.persona.bmi, insights);
bmrs     = cellfun(@(I) I.persona.bmr, insights);
steps    = cellfun(@(I) I.totals.steps, insights);
calories = cellfun(@(I) I.totals.calories, insights);
intens   = cellfun(@(I) I.health.avg_intensity_MET, insights);
moderate = cellfun(@(I) I.health.moderate_minutes, insights);
pctBMR   = cellfun(@(I) I.health.calories_pct_bmr, insights);

figure('Color','w','Position',[80 80 1300 800],'Name','Persona Comparison');
tiledlayout(2, 3, 'TileSpacing','compact','Padding','compact');

colors = [0.20 0.50 0.85; 0.85 0.33 0.10; 0.18 0.55 0.34];

% 1) BMI
nexttile;
b = bar(bmis, 'FaceColor','flat'); b.CData = colors;
yline(18.5, '--', 'Underweight'); yline(25, '--', 'Overweight');
xticklabels(names); ylabel('BMI'); title('Body Mass Index');
grid on

% 2) Total Steps
nexttile;
b = bar(steps, 'FaceColor','flat'); b.CData = colors;
xticklabels(names); ylabel('Steps'); title('Total Steps Recorded');
grid on

% 3) Total Calories
nexttile;
b = bar(calories, 'FaceColor','flat'); b.CData = colors;
xticklabels(names); ylabel('kcal'); title('Total Calories Burned');
grid on

% 4) % of Daily BMR
nexttile;
b = bar(pctBMR, 'FaceColor','flat'); b.CData = colors;
xticklabels(names); ylabel('% of daily BMR');
title('Exercise Energy / Resting Metabolic Rate');
grid on

% 5) Moderate-to-Vigorous Activity Minutes
nexttile;
b = bar(moderate, 'FaceColor','flat'); b.CData = colors;
yline(21.4, '--', 'WHO Daily Target');
xticklabels(names); ylabel('Minutes'); title('Moderate Activity Time');
grid on

% 6) Average MET
nexttile;
b = bar(intens, 'FaceColor','flat'); b.CData = colors;
xticklabels(names); ylabel('METs'); title('Avg Exercise Intensity');
grid on
end