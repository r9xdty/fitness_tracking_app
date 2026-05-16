function P = Persona(name, height_cm, weight_kg, age, sex, personaID)
%PERSONA  Bir kullanıcının fitness ve sağlık profili için struct
%
%   P = core.Persona("Ayşe", 165, 60, 28, "F", "01")
%
%   Türetilmiş alanlar otomatik hesaplanır:
%     P.height_m, P.bmi, P.bmr, P.stride_m, P.id
%
%   stride_m:  Standart antropometrik tahmin (Boy oranı yöntemi)
%   bmr     :  Mifflin-St Jeor denklemi (kcal/gün, dinlenme metabolizma hızı)
%   bmi     :  weight / height_m^2

arguments
    name      (1,1) string
    height_cm (1,1) double {mustBePositive}
    weight_kg (1,1) double {mustBePositive}
    age       (1,1) double {mustBePositive, mustBeInteger}
    sex       (1,1) string {mustBeMember(sex, ["M","F"])}
    personaID (1,1) string
end

P = struct();
P.id        = personaID;       % "01", "02", "03"
P.name      = name;
P.height_cm = height_cm;
P.height_m  = height_cm / 100;
P.weight_kg = weight_kg;
P.age       = age;
P.sex       = sex;

% BMI
P.bmi = weight_kg / P.height_m^2;

% BMR — Mifflin-St Jeor
base = 10*weight_kg + 6.25*height_cm - 5*age;
if sex == "M"
    P.bmr = base + 5;
else
    P.bmr = base - 161;
end

% Stride length (m) — antropometrik tahmin
if sex == "M"
    P.stride_m = 0.413 * P.height_m;
else
    P.stride_m = 0.415 * P.height_m;
end

% BMI kategorisi (sağlık bağlamı için)
if P.bmi < 18.5,        P.bmi_category = "Underweight";
elseif P.bmi < 25,      P.bmi_category = "Normal";
elseif P.bmi < 30,      P.bmi_category = "Overweight";
else,                    P.bmi_category = "Obese";
end
end