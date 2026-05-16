function I = healthInsights(persona, sessionResults)
%HEALTHINSIGHTS  Bir personanın oturumlarından sağlık öngörüleri üret

    arguments
        persona        struct
        sessionResults cell
    end
    
    I = struct();
    I.persona = persona;
    
    % --- Toplam aktivite metrikleri ---
    totalSteps    = 0;
    totalCalories = 0;
    totalDuration = 0;
    totalDistance = 0;
    
    % Dictionary yerine containers.Map kullan (boş init sorun yok)
    activityTime     = containers.Map('KeyType','char','ValueType','double');
    activityCalories = containers.Map('KeyType','char','ValueType','double');
    cadenceByActivity = containers.Map('KeyType','char','ValueType','double');
    
    for k = 1:numel(sessionResults)
        R = sessionResults{k};
        
        totalSteps    = totalSteps    + R.nSteps;
        totalCalories = totalCalories + R.kcal;
        totalDuration = totalDuration + R.duration;
        
        a = char(R.activity);  % char olmalı, string değil
        
        if isKey(activityTime, a)
            activityTime(a) = activityTime(a) + R.duration;
            activityCalories(a) = activityCalories(a) + R.kcal;
        else
            activityTime(a) = R.duration;
            activityCalories(a) = R.kcal;
        end
        
        if R.nSteps > 5 && ismember(a, {'walking','running','stairsup','stairsdown'})
            cadenceByActivity(a) = R.cadence;
        end
        
        % GPS mesafesi (varsa)
        if isfield(R.session, 'gps') && isfield(R.session.gps, 'lat')
            validLat = ~isnan(R.session.gps.lat);
            if sum(validLat) > 2
                d = haversineDistance(R.session.gps.lat(validLat), ...
                                      R.session.gps.lon(validLat));
                totalDistance = totalDistance + d;
            end
        end
    end
    
    I.totals.steps        = totalSteps;
    I.totals.calories     = totalCalories;
    I.totals.duration_s   = totalDuration;
    I.totals.duration_min = totalDuration / 60;
    I.totals.distance_m   = totalDistance;
    I.totals.activityTime = activityTime;
    I.totals.activityCalories = activityCalories;
    I.totals.cadenceByActivity = cadenceByActivity;
    
    % --- Türetilmiş sağlık göstergeleri ---
    I.health.bmi              = persona.bmi;
    I.health.bmi_category     = persona.bmi_category;
    I.health.bmr              = persona.bmr;
    I.health.calories_pct_bmr = 100 * totalCalories / persona.bmr;
    
    % WHO önerisi: günlük ~21 dk orta yoğunlukta aktivite
    daily_target_min = 150 / 7;
    moderate_min = 0;
    if isKey(activityTime, 'walking'),  moderate_min = moderate_min + activityTime('walking')/60; end
    if isKey(activityTime, 'stairsup'), moderate_min = moderate_min + activityTime('stairsup')/60; end
    if isKey(activityTime, 'running'),  moderate_min = moderate_min + activityTime('running')/60; end
    I.health.moderate_minutes = moderate_min;
    I.health.who_target_pct   = 100 * moderate_min / daily_target_min;
    
    sedentary_min = 0;
    if isKey(activityTime, 'sitting'), sedentary_min = activityTime('sitting')/60; end
    I.health.sedentary_minutes = sedentary_min;
    
    I.health.step_goal_pct = 100 * totalSteps / 10000;
    
    % --- Yoğunluk skoru (METs-weighted average) ---
    intensity = 0;
    actKeys = keys(activityTime);
    for ki = 1:numel(actKeys)
        a_str = actKeys{ki};
        if isKey(activityCalories, a_str) && activityTime(a_str) > 0
            met = activityCalories(a_str) / (persona.weight_kg * activityTime(a_str)/3600);
            intensity = intensity + met * activityTime(a_str);
        end
    end
    if totalDuration > 0
        I.health.avg_intensity_MET = intensity / totalDuration;
    else
        I.health.avg_intensity_MET = 0;
    end
    
    % --- Eğlenceli karşılaştırmalar ---
    I.fun.burgers   = totalCalories / 540;
    I.fun.bananas   = totalCalories / 89;
    I.fun.chocolate = totalCalories / 230;
    I.fun.whoppers  = totalCalories / 765;  % rapor için
    
    % --- Narrative ---
    I.narrative = buildNarrative(persona, I);
end


function d = haversineDistance(lat, lon)
    R = 6371000;
    lat = deg2rad(lat); lon = deg2rad(lon);
    dlat = diff(lat); dlon = diff(lon);
    a = sin(dlat/2).^2 + cos(lat(1:end-1)).*cos(lat(2:end)).*sin(dlon/2).^2;
    c = 2 * atan2(sqrt(a), sqrt(1-a));
    d = sum(R * c);
end

function txt = buildNarrative(P, I)
    txt = strings(0);
    txt(end+1) = sprintf("%s (age %d, BMI %.1f - %s):", ...
                         P.name, P.age, P.bmi, P.bmi_category);
    txt(end+1) = sprintf("  Total session: %.1f minutes, %d steps, %.1f kcal burned.", ...
                         I.totals.duration_min, I.totals.steps, I.totals.calories);
    
    if I.totals.distance_m > 0
        txt(end+1) = sprintf("  Distance covered: %.0f m via GPS tracking.", ...
                             I.totals.distance_m);
    end
    
    txt(end+1) = sprintf("  Energy expenditure: %.1f%% of daily resting metabolic rate (%d kcal/day).", ...
                         I.health.calories_pct_bmr, round(P.bmr));
    txt(end+1) = sprintf("  Moderate-to-vigorous activity: %.1f minutes (%.0f%% of daily WHO target).", ...
                         I.health.moderate_minutes, I.health.who_target_pct);
    txt(end+1) = sprintf("  Average exercise intensity: %.1f METs.", ...
                         I.health.avg_intensity_MET);
    txt(end+1) = sprintf("  Equivalent to: %.2f burger, %.1f bananas, %.2f chocolate bars, %.2f Whoppers.", ...
                         I.fun.burgers, I.fun.bananas, I.fun.chocolate, I.fun.whoppers);
    
    if I.health.bmi < 18.5
        txt(end+1) = "  Note: BMI in underweight range. Consider strength training + caloric surplus.";
    elseif I.health.bmi >= 25
        txt(end+1) = "  Note: BMI in overweight range. Current cardio activity is beneficial.";
    else
        txt(end+1) = "  Note: BMI in healthy range. Maintain current activity level.";
    end
    
    if I.health.who_target_pct < 50
        txt(end+1) = "  Recommendation: Increase moderate activity time to meet WHO guidelines.";
    elseif I.health.who_target_pct > 100
        txt(end+1) = "  Achievement: Exceeded daily WHO activity target.";
    end
end