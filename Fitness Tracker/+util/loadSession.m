function S = loadSession(matFilePath, sessionLabel)
%LOADSESSION  MATLAB Mobile Log .mat → standart struct (dayanıklı sürüm)

    arguments
        matFilePath (1,1) string
        sessionLabel string = ""
    end
    
    if ~isfile(matFilePath)
        error('Dosya bulunamadı: %s', matFilePath);
    end
    
    raw = load(matFilePath);
    
    [~, name, ~] = fileparts(matFilePath);
    S = struct();
    S.name  = string(name);
    S.label = sessionLabel;
    S.path  = string(matFilePath);
    
    % ---- Acceleration ----
    if isfield(raw, 'Acceleration') && ~isempty(raw.Acceleration)
        TT = raw.Acceleration;
        t  = util.timeElapsed(TT.Timestamp);
        S.accel.t   = t(:);
        S.accel.x   = getCol(TT, ["X","x"]);
        S.accel.y   = getCol(TT, ["Y","y"]);
        S.accel.z   = getCol(TT, ["Z","z"]);
        S.accel.mag = sqrt(S.accel.x.^2 + S.accel.y.^2 + S.accel.z.^2);
        S.accel.fs  = effectiveFs(t);
    end
    
    % ---- Angular Velocity ----
    if isfield(raw, 'AngularVelocity') && ~isempty(raw.AngularVelocity)
        TT = raw.AngularVelocity;
        t  = util.timeElapsed(TT.Timestamp);
        S.gyro.t  = t(:);
        S.gyro.x  = getCol(TT, ["X","x"]);
        S.gyro.y  = getCol(TT, ["Y","y"]);
        S.gyro.z  = getCol(TT, ["Z","z"]);
        S.gyro.fs = effectiveFs(t);
    end
    
    % ---- Orientation ----
    if isfield(raw, 'Orientation') && ~isempty(raw.Orientation)
        TT = raw.Orientation;
        t  = util.timeElapsed(TT.Timestamp);
        S.orient.t       = t(:);
        S.orient.azimuth = getCol(TT, ["Azimuth","azimuth","Yaw","yaw","X","x"]);
        S.orient.pitch   = getCol(TT, ["Pitch","pitch","Y","y"]);
        S.orient.roll    = getCol(TT, ["Roll","roll","Z","z"]);
        S.orient.fs      = effectiveFs(t);
    end
    
    % ---- Position (GPS) ----
    if isfield(raw, 'Position') && ~isempty(raw.Position)
        TT = raw.Position;
        t  = util.timeElapsed(TT.Timestamp);
        S.gps.t      = t(:);
        S.gps.lat    = getCol(TT, ["latitude","Latitude","lat"]);
        S.gps.lon    = getCol(TT, ["longitude","Longitude","lon"]);
        S.gps.alt    = getCol(TT, ["altitude","Altitude","alt"]);
        S.gps.speed  = getCol(TT, ["speed","Speed"]);
        S.gps.course = getCol(TT, ["course","Course","heading","Heading"]);
        S.gps.hacc   = getCol(TT, ["hacc","Hacc","HorizontalAccuracy","horizontalAccuracy"]);
        S.gps.fs     = effectiveFs(t);
    end
end

% ---- Yardımcılar ----
function col = getCol(TT, candidates)
% Olası kolon adları arasından ilkini case-insensitive bulup vektör döndür
    vars = string(TT.Properties.VariableNames);
    for i = 1:numel(candidates)
        idx = find(strcmpi(vars, candidates(i)), 1);
        if ~isempty(idx)
            col = TT.(vars(idx));
            col = col(:);
            return;
        end
    end
    warning('loadSession:missingColumn', ...
            'Kolon bulunamadı (aday: %s). Mevcut kolonlar: %s', ...
            strjoin(candidates, ', '), strjoin(vars, ', '));
    col = nan(height(TT), 1);
end

function fs = effectiveFs(t)
    if numel(t) < 2
        fs = NaN; return;
    end
    fs = 1 / median(diff(t));
end