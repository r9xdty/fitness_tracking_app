function P = buildAllPersonas()
%BUILDALLPERSONAS  Üç personayı sabit değerlerle inşa et
%
%   P = core.buildAllPersonas()
%
%   Geri dönüş:
%     P.p01, P.p02, P.p03  - core.Persona struct'ları
%     P.list                - tüm personalar tek bir struct array'de

P = struct();
P.p01 = core.Persona("Kişi_01", 183, 82, 23, "M", "01");
P.p02 = core.Persona("Kişi_02", 170, 68, 27, "M", "02");
P.p03 = core.Persona("Kişi_03", 180, 60, 20, "M", "03");

% Toplu erişim için array - iterate etmek kolay
P.list = [P.p01, P.p02, P.p03];
end