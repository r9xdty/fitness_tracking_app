function verifySession(S)
%VERIFYSESSION  Yüklenmiş oturum struct'ını kontrol et ve özet bas/çiz
%
%   Örnek kullanım:
%       S = util.loadSession("data/walking_01.mat", "walking");
%       util.verifySession(S);

fprintf('\n=== Session: %s ===\n', S.name);
if S.label ~= "", fprintf('Label : %s\n', S.label); end

sensors = {'accel','gyro','orient','gps'};
labels  = {'Acceleration','Angular Velocity','Orientation','GPS'};

fprintf('\n%-18s %10s %10s %10s\n', 'Sensor','Samples','Duration','EffFs(Hz)');
fprintf('%s\n', repmat('-',1,52));

for i = 1:numel(sensors)
    if isfield(S, sensors{i})
        d = S.(sensors{i});
        n = numel(d.t);
        dur = d.t(end) - d.t(1);
        fprintf('%-18s %10d %10.2f %10.2f\n', labels{i}, n, dur, d.fs);
    else
        fprintf('%-18s %10s %10s %10s\n', labels{i}, '--', '--', '--');
    end
end

% GPS sağlık kontrolü
if isfield(S, 'gps')
    validFix = ~isnan(S.gps.lat) & S.gps.hacc < 50;
    fprintf('\nGPS valid fixes: %d / %d  (hacc < 50 m)\n', ...
        sum(validFix), numel(S.gps.lat));
    if sum(validFix) > 0
        distM = computeQuickDistance(S.gps.lat(validFix), S.gps.lon(validFix));
        fprintf('GPS toplam mesafe: %.1f m\n', distM);
    end
end

% Hızlı görsel
figure('Name', sprintf('Verify: %s', S.name), 'Color', 'w', ...
    'Position', [100 100 1100 600]);
tiledlayout(2, 2, 'TileSpacing','compact', 'Padding','compact');

% İvme bileşenleri
nexttile;
if isfield(S, 'accel')
    plot(S.accel.t, S.accel.x, S.accel.t, S.accel.y, S.accel.t, S.accel.z);
    grid on; xlabel('t (s)'); ylabel('a (m/s^2)');
    legend('a_x','a_y','a_z','Location','best');
    title('Acceleration components');
end

% Magnitüd
nexttile;
if isfield(S, 'accel')
    plot(S.accel.t, S.accel.mag, 'LineWidth', 1, 'Color', [0.85 0.33 0.10]);
    yline(9.81, '--g', 'g');
    grid on; xlabel('t (s)'); ylabel('|a| (m/s^2)');
    title('Acceleration magnitude');
end

% Gyro
nexttile;
if isfield(S, 'gyro')
    plot(S.gyro.t, S.gyro.x, S.gyro.t, S.gyro.y, S.gyro.t, S.gyro.z);
    grid on; xlabel('t (s)'); ylabel('\omega (rad/s)');
    legend('\omega_x','\omega_y','\omega_z','Location','best');
    title('Angular velocity');
else
    text(0.5, 0.5, 'Gyro yok', 'HorizontalAlignment','center', 'Units','normalized');
    axis off
end

% GPS yolu
nexttile;
if isfield(S, 'gps') && any(~isnan(S.gps.lat))
    valid = ~isnan(S.gps.lat);
    geoplot(S.gps.lat(valid), S.gps.lon(valid), 'LineWidth', 1.5);
    geobasemap streets;
    title('GPS path');
else
    text(0.5, 0.5, 'GPS fix yok (içeride misin?)', ...
        'HorizontalAlignment','center', 'Units','normalized', 'FontSize', 12);
    axis off
end
end

% ---- Yardımcı: haversine yaklaşımı ----
function d = computeQuickDistance(lat, lon)
R = 6371000;  % dünya yarıçapı, metre
lat = deg2rad(lat); lon = deg2rad(lon);
dlat = diff(lat); dlon = diff(lon);
a = sin(dlat/2).^2 + cos(lat(1:end-1)).*cos(lat(2:end)).*sin(dlon/2).^2;
c = 2 * atan2(sqrt(a), sqrt(1-a));
d = sum(R * c);
end