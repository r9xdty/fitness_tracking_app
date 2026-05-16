%% ============================================================
%  FITNESS TRACKER — FULL DEMO SUITE
%  Run sections sequentially (Ctrl+Enter on each section)
%  or run all with F5
%  ============================================================

%% DEMO 0 — SETUP (run once at start)
clear; clc; close all;

set(0, 'DefaultFigureColor', 'w');
set(0, 'DefaultAxesFontSize', 11);
set(0, 'DefaultAxesFontName', 'Segoe UI');
set(0, 'DefaultLineLineWidth', 1.3);
set(0, 'DefaultAxesGridAlpha', 0.3);
set(0, 'DefaultAxesBox', 'on');

COLOR_P1 = [0.20 0.50 0.85];
COLOR_P2 = [0.85 0.33 0.10];
COLOR_P3 = [0.18 0.55 0.34];
colors = [COLOR_P1; COLOR_P2; COLOR_P3];
names  = {'Person_01','Person_02','Person_03'};

fprintf('Setup complete. Ready for demos.\n');


%% DEMO 1 — USER PROFILES
P = core.buildAllPersonas();

personaTable = table( ...
    [P.p01.name; P.p02.name; P.p03.name], ...
    [P.p01.age; P.p02.age; P.p03.age], ...
    [P.p01.height_cm; P.p02.height_cm; P.p03.height_cm], ...
    [P.p01.weight_kg; P.p02.weight_kg; P.p03.weight_kg], ...
    [P.p01.bmi; P.p02.bmi; P.p03.bmi], ...
    [round(P.p01.bmr); round(P.p02.bmr); round(P.p03.bmr)], ...
    [P.p01.stride_m; P.p02.stride_m; P.p03.stride_m], ...
    'VariableNames', {'Name','Age','Height_cm','Weight_kg','BMI','BMR','Stride_m'});
disp('=== USER PROFILES ==='); disp(personaTable);

figure('Position',[100 100 1200 400],'Name','User Profiles');
tl = tiledlayout(1, 3, 'TileSpacing','compact','Padding','compact');
title(tl, 'Three User Profiles', 'FontSize', 14, 'FontWeight','bold');

nexttile;
b = bar([P.p01.bmi, P.p02.bmi, P.p03.bmi],'FaceColor','flat'); b.CData = colors;
yline(18.5,'--k','Underweight','LabelHorizontalAlignment','left');
yline(25,'--k','Overweight','LabelHorizontalAlignment','left');
xticklabels(names); ylabel('BMI'); title('Body Mass Index'); grid on; ylim([15 30]);

nexttile;
b = bar([P.p01.bmr, P.p02.bmr, P.p03.bmr],'FaceColor','flat'); b.CData = colors;
xticklabels(names); ylabel('kcal/day'); title('Basal Metabolic Rate'); grid on

nexttile;
b = bar([P.p01.stride_m, P.p02.stride_m, P.p03.stride_m]*100,'FaceColor','flat'); b.CData = colors;
xticklabels(names); ylabel('cm'); title('Estimated Stride Length'); grid on


%% DEMO 2 — RAW SIGNAL COMPARISON
R_sit  = core.processSession("data/sitting_01.mat",  "01", 'verbose', false);
R_walk = core.processSession("data/walking_01.mat",  "01", 'verbose', false);
R_run  = core.processSession("data/running_01.mat",  "01", 'verbose', false);

figure('Position',[100 100 1200 600],'Name','Raw Signal Comparison');
tl = tiledlayout(3, 1, 'TileSpacing','compact','Padding','compact');
title(tl,'Raw Acceleration Magnitude — Activity Signatures','FontSize',14,'FontWeight','bold');

nexttile;
plot(R_sit.session.accel.t, R_sit.session.accel.mag,'Color',[0.5 0.5 0.5]);
yline(9.81,'--k','g = 9.81','LabelHorizontalAlignment','left');
ylabel('|a| (m/s^2)'); title('Sitting'); grid on; ylim([0 25]);

nexttile;
plot(R_walk.session.accel.t, R_walk.session.accel.mag,'Color',COLOR_P1);
yline(9.81,'--k','g = 9.81','LabelHorizontalAlignment','left');
ylabel('|a| (m/s^2)'); title('Walking'); grid on; ylim([0 25]);

nexttile;
plot(R_run.session.accel.t, R_run.session.accel.mag,'Color',COLOR_P2);
yline(9.81,'--k','g = 9.81','LabelHorizontalAlignment','left');
ylabel('|a| (m/s^2)'); xlabel('Time (s)'); title('Running'); grid on; ylim([0 25]);


%% DEMO 3 — STEP DETECTION (sitting vs walking)
R_sit  = core.processSession("data/sitting_01.mat","01",'verbose',false);
R_walk = core.processSession("data/walking_01.mat","01",'verbose',false);

figure('Position',[100 100 1300 700],'Name','Step Detection Algorithm');
tl = tiledlayout(2,1,'TileSpacing','compact','Padding','compact');
title(tl,'Step Detection — Activity Gate + Cadence Consistency','FontSize',14,'FontWeight','bold');

% Sitting
nexttile;
P_sit = R_sit.peakInfo; t_sit = R_sit.session.accel.t;
plot(t_sit, P_sit.signal,'Color',[0.7 0.7 0.7],'LineWidth',0.8); hold on
ylims = ylim;
fill([t_sit; flipud(t_sit)], ...
     [P_sit.activeMask*ylims(2); flipud(P_sit.activeMask*ylims(1))], ...
     [0.2 0.7 0.3],'FaceAlpha',0.15,'EdgeColor','none');
plot(t_sit, P_sit.signalGated,'Color',COLOR_P1,'LineWidth',1);
if ~isempty(P_sit.locs)
    plot(t_sit(P_sit.locs), P_sit.pks,'rv','MarkerFaceColor','r','MarkerSize',7);
end
grid on; ylabel('Filtered |a| (m/s^2)');
title(sprintf('Sitting (with hand movement) — %d steps detected ✓', R_sit.nSteps));
legend('Bandpass','Active gate','Gated','Peaks','Location','northeast');

% Walking
nexttile;
P_walk = R_walk.peakInfo; t_walk = R_walk.session.accel.t;
plot(t_walk, P_walk.signal,'Color',[0.7 0.7 0.7],'LineWidth',0.8); hold on
ylims = ylim;
fill([t_walk; flipud(t_walk)], ...
     [P_walk.activeMask*ylims(2); flipud(P_walk.activeMask*ylims(1))], ...
     [0.2 0.7 0.3],'FaceAlpha',0.15,'EdgeColor','none');
plot(t_walk, P_walk.signalGated,'Color',COLOR_P1,'LineWidth',1);
plot(t_walk(P_walk.locs), P_walk.pks,'rv','MarkerFaceColor','r','MarkerSize',7);
grid on; ylabel('Filtered |a| (m/s^2)'); xlabel('Time (s)');
title(sprintf('Walking — %d steps detected (cadence: %.0f spm)', R_walk.nSteps, R_walk.cadence));
legend('Bandpass','Active gate','Gated','Peaks','Location','northeast');


%% DEMO 4 — PER-SESSION METRICS (all 15 sessions)
activities = ["sitting","walking","running","stairsup","stairsdown"];
personas   = ["01","02","03"];

allRows = {};
for p = personas
    for a = activities
        f = sprintf("data/%s_%s.mat", a, p);
        if isfile(f)
            R = core.processSession(f, p, 'verbose', false);
            allRows{end+1} = {string(R.persona.name), string(R.activity), ...
                              R.duration, R.nSteps, R.cadence, R.kcal, R.met}; %#ok<SAGROW>
        end
    end
end

T_sessions = cell2table(vertcat(allRows{:}), ...
    'VariableNames', {'Person','Activity','Duration_s','Steps','Cadence_spm','Calories','MET'});
disp('=== ALL SESSIONS METRICS ==='); disp(T_sessions);

kcalMatrix = zeros(3, 5);
stepMatrix = zeros(3, 5);
for i = 1:3
    for j = 1:5
        row = T_sessions(T_sessions.Person == "Kişi_" + personas(i) & T_sessions.Activity == activities(j), :);
        if height(row) > 0
            kcalMatrix(i, j) = row.Calories;
            stepMatrix(i, j) = row.Steps;
        end
    end
end

figure('Position',[100 100 1100 500],'Name','Calories per Session');
tl = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

nexttile;
b = bar(kcalMatrix','grouped');
for k = 1:3, b(k).FaceColor = colors(k,:); end
xticklabels(activities); ylabel('Calories (kcal)');
title('Calories Burned per Activity'); grid on
legend(names,'Location','northwest');

nexttile;
b = bar(stepMatrix','grouped');
for k = 1:3, b(k).FaceColor = colors(k,:); end
xticklabels(activities); ylabel('Steps');
title('Step Count per Activity'); grid on
legend(names,'Location','northwest');


%% DEMO 5 — ML TRAINING (random split)
fprintf('\n=== BUILDING TRAINING TABLE ===\n');
T = ml.buildTrainTable("data/");

fprintf('\n=== CLEANING DATA ===\n');
T = ml.cleanData(T);

fprintf('\n=== TRAINING MODELS ===\n');
model = ml.trainAndEvaluate(T);

fig = gcf; fig.Position = [100 100 800 700]; fig.Name = 'ML — Activity Classification';


%% DEMO 6 — ROBUSTNESS (3 persona holdouts)
fprintf('\n=== HOLDOUT PERSON_01 ===\n');
modelHO_01 = ml.trainAndEvaluate(T, 'holdoutPersona', "01");
fig = gcf; fig.Name = 'Robustness — Holdout Person_01';

fprintf('\n=== HOLDOUT PERSON_02 ===\n');
modelHO_02 = ml.trainAndEvaluate(T, 'holdoutPersona', "02");
fig = gcf; fig.Name = 'Robustness — Holdout Person_02';

fprintf('\n=== HOLDOUT PERSON_03 ===\n');
modelHO_03 = ml.trainAndEvaluate(T, 'holdoutPersona', "03");
fig = gcf; fig.Name = 'Robustness — Holdout Person_03';

figure('Position',[100 100 800 500],'Name','Cross-Person Generalization');
accs = [model.testAcc, modelHO_01.testAcc, modelHO_02.testAcc, modelHO_03.testAcc] * 100;
b = bar(accs,'FaceColor','flat');
b.CData = [0.3 0.3 0.3; colors];
xticklabels({'Random Split','Holdout Person_01','Holdout Person_02','Holdout Person_03'});
ylabel('Test Accuracy (%)'); ylim([0 100]); grid on
title('Generalization Capability: Random vs Cross-Person Tests','FontWeight','bold');
for i = 1:numel(accs)
    text(i, accs(i)+2, sprintf('%.1f%%', accs(i)), ...
         'HorizontalAlignment','center','FontWeight','bold');
end


%% DEMO 7 — FEATURE IMPORTANCE
imp = predictorImportance(model.classifier);
[impSorted, idx] = sort(imp,'descend');
featNames = model.featureNames(idx);
nTop = min(15, numel(impSorted));

figure('Position',[100 100 900 500],'Name','Feature Importance');
barh(impSorted(nTop:-1:1),'FaceColor',COLOR_P1);
yticks(1:nTop); yticklabels(featNames(nTop:-1:1));
xlabel('Importance Score');
title('Top 15 Most Predictive Features','FontWeight','bold');
grid on


%% DEMO 8 — HEALTH INSIGHTS (3 narratives)
P = core.buildAllPersonas();
r01 = analysis.aggregatePersona("01");
r02 = analysis.aggregatePersona("02");
r03 = analysis.aggregatePersona("03");

I01 = analysis.healthInsights(P.p01, r01);
I02 = analysis.healthInsights(P.p02, r02);
I03 = analysis.healthInsights(P.p03, r03);

fprintf('\n=========================================\n');
fprintf(' HEALTH INSIGHTS — PERSON_01\n');
fprintf('=========================================\n');
for s = I01.narrative, fprintf('%s\n', s); end

fprintf('\n=========================================\n');
fprintf(' HEALTH INSIGHTS — PERSON_02\n');
fprintf('=========================================\n');
for s = I02.narrative, fprintf('%s\n', s); end

fprintf('\n=========================================\n');
fprintf(' HEALTH INSIGHTS — PERSON_03\n');
fprintf('=========================================\n');
for s = I03.narrative, fprintf('%s\n', s); end


%% DEMO 9 — CROSS-USER COMPARISON
analysis.compareAll({I01, I02, I03});
fig = gcf; fig.Name = 'Cross-User Comparison';


%% DEMO 10 — CALORIE BREAKDOWN (PIE CHARTS)
figure('Position',[100 100 1200 450],'Name','Calorie Breakdown by Activity');
tl = tiledlayout(1,3,'TileSpacing','compact','Padding','compact');
title(tl,'Where Each User Burned Their Calories','FontSize',14,'FontWeight','bold');

ins = {I01, I02, I03};
for idx = 1:3
    nexttile;
    I = ins{idx};
    
    actKeys = keys(I.totals.activityCalories);
    vals = zeros(numel(actKeys), 1);
    for k = 1:numel(actKeys)
        vals(k) = I.totals.activityCalories(actKeys{k});
    end
    
    labels = strings(numel(actKeys), 1);
    for k = 1:numel(actKeys)
        labels(k) = sprintf("%s (%.1f kcal)", actKeys{k}, vals(k));
    end
    
    pie(vals, labels);
    title(sprintf('%s — Total: %.1f kcal', I.persona.name, I.totals.calories));
end


%% DEMO 11 — FINAL DASHBOARD (3x4 summary)
close(findobj('Name','Fitness Tracker — Final Dashboard'));

figure('Position',[50 50 1500 900],'Name','Fitness Tracker — Final Dashboard');
tl = tiledlayout(3, 4, 'TileSpacing','compact','Padding','compact');
title(tl,'Fitness Tracker — Summary Across 3 Users, 5 Activities, 15 Sessions', ...
      'FontSize', 15, 'FontWeight','bold');

% Row 1: 4 profile bars
nexttile;
b = bar(cellfun(@(I) I.persona.bmi, ins),'FaceColor','flat'); b.CData = colors;
yline(18.5,'--'); yline(25,'--');
xticklabels(names); title('BMI'); grid on

nexttile;
b = bar(cellfun(@(I) I.persona.bmr, ins),'FaceColor','flat'); b.CData = colors;
xticklabels(names); ylabel('kcal/day'); title('BMR'); grid on

nexttile;
b = bar(cellfun(@(I) I.totals.steps, ins),'FaceColor','flat'); b.CData = colors;
xticklabels(names); title('Total Steps'); grid on

nexttile;
b = bar(cellfun(@(I) I.totals.calories, ins),'FaceColor','flat'); b.CData = colors;
xticklabels(names); ylabel('kcal'); title('Total Calories'); grid on

% Row 2: activity comparison + 2 small
nexttile([1 2]);
acts = {'sitting','walking','running','stairsup','stairsdown'};
kcalM = zeros(3, 5);
for i = 1:3
    I = ins{i};
    for j = 1:5
        if isKey(I.totals.activityCalories, acts{j})
            kcalM(i,j) = I.totals.activityCalories(acts{j});
        end
    end
end
b = bar(kcalM','grouped');
for k = 1:3, b(k).FaceColor = colors(k,:); end
xticklabels(acts); ylabel('kcal'); title('Calories by Activity'); grid on
legend(names,'Location','northwest');

nexttile;
b = bar(cellfun(@(I) I.health.avg_intensity_MET, ins),'FaceColor','flat'); b.CData = colors;
xticklabels(names); ylabel('METs'); title('Avg Intensity'); grid on

nexttile;
b = bar(cellfun(@(I) I.health.calories_pct_bmr, ins),'FaceColor','flat'); b.CData = colors;
xticklabels(names); ylabel('% of BMR'); title('Exercise / BMR'); grid on

% Row 3: ML accuracy + Calorie equivalents
nexttile([1 2]);
mlAccs = [model.testAcc, modelHO_01.testAcc, modelHO_02.testAcc, modelHO_03.testAcc] * 100;
b = bar(mlAccs,'FaceColor','flat');
b.CData = [0.3 0.3 0.3; colors];
xticklabels({'Random Split','Holdout P_01','Holdout P_02','Holdout P_03'});
ylabel('Accuracy (%)'); ylim([0 100]); title('ML Classification Performance'); grid on
for i = 1:numel(mlAccs)
    text(i, mlAccs(i)+2, sprintf('%.1f%%', mlAccs(i)), ...
         'HorizontalAlignment','center','FontWeight','bold','FontSize',10);
end

nexttile([1 2]);
burgerM = cellfun(@(I) I.fun.burgers,   ins);
bananaM = cellfun(@(I) I.fun.bananas,   ins);
choclM  = cellfun(@(I) I.fun.chocolate, ins);
M = [burgerM; bananaM; choclM]';
b = bar(M,'grouped');
xticklabels(names); ylabel('Equivalent');
title('Calorie Equivalents (Food)'); grid on
legend({'Burgers','Bananas','Chocolate bars'},'Location','northwest');

fprintf('\n*** ALL DEMOS COMPLETE ***\n');