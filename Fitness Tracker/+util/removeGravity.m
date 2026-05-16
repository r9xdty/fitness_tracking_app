function aDyn = removeGravity(accelXYZ, fs)
%REMOVEGRAVITY  Ham ivmeden gravity bileşenini çıkar
%
%   aDyn = util.removeGravity(accelXYZ, fs)
%
%   accelXYZ : Nx3 matrix [ax ay az] (m/s^2, gravity dahil)
%   fs       : örnekleme oranı (Hz)
%
%   aDyn     : Nx3 dinamik ivme bileşeni (gravity çıkarılmış)
%
%   Yöntem: Low-pass filter ile gravity'yi tahmin et (kesim ~0.25 Hz),
%   sonra ham sinyalden çıkar. Telefon yönelimi yavaş değişse bile
%   doğru gravity tahmin eder.

arguments
    accelXYZ (:,3) double
    fs       (1,1) double {mustBePositive}
end

% Kesim frekansı: yer çekimi yavaş değişir, hareket hızlı.
% 0.25 Hz altındaki bileşeni gravity, üstündekini hareket sayarız.
fc = 0.25;

% Butterworth low-pass, 2. derece
[b, a] = butter(2, fc / (fs/2), 'low');

% Her eksen için ayrı filtrele (zero-phase, sıfır geçikme)
gravity = zeros(size(accelXYZ));
for k = 1:3
    gravity(:,k) = filtfilt(b, a, accelXYZ(:,k));
end

aDyn = accelXYZ - gravity;
end