# 🏃 Personal Fitness Tracker
### Activity Recognition & Personalized Health Insights via Machine Learning

> **MathWorks Hackathon 2026** — Team: Erkan Polat · Samet Erhan Sarı · Mustafa Altuntaş

---

## Overview

A smartphone-based fitness tracker built entirely on raw MATLAB Mobile sensor data — no smartwatch, no heart rate strap. The system collects motion data from a phone in your pocket, classifies what you're doing, and translates it into personalized health metrics tailored to your body.

**The core question:** Can a phone in your pocket understand what you're doing — and how hard?

---

## Results at a Glance

| Metric | Value |
|--------|-------|
| Labeled sessions | 15 (3 users × 5 activities) |
| Engineered features | 23 (time + frequency domain) |
| Best model accuracy | **78.5%** (Boosted Ensemble) |
| Fitness metrics per user | 5 (steps · kcal · METs · WHO · BMR%) |

---

## Activities Recognized

`sitting` · `walking` · `running` · `stairsup` · `stairsdown`

Each activity has a distinct acceleration fingerprint visible in the raw signal:
- **Sitting** — near g = 9.81 m/s², low variance
- **Walking** — regular ~2 Hz oscillation
- **Running** — high amplitude, ~3 Hz peaks

---

## Pipeline

```
MATLAB Mobile  →  fitness_logger.m  →  fitness_process.m  →  ML Classifier
  (sensor data)      (recording)         (processing)          (prediction)
```

### 1. Data Collection — `fitness_logger.m`
Records 4 sensors simultaneously via MATLAB Mobile:
- Accelerometer (3-axis, ~10–50 Hz)
- Gyroscope (angular velocity)
- Orientation (Azimuth, Pitch, Roll)
- GPS (position + Haversine-derived speed)

```matlab
fitness_logger('walking', 60)   % label, duration in seconds
fitness_logger('running', 60)
```

Saves a structured `.mat` file compatible with both Format A (logger output) and Format B (MATLAB Mobile Log mode).

### 2. Signal Processing — `fitness_process.m`
Automatically detects the file format and applies:

- **Sensor synchronization** — resamples all signals to a common time axis via `interp1`
- **Butterworth low-pass filter** — 4th order, fc = 10 Hz, zero-phase via `filtfilt`
- **Haversine GPS speed** — bypasses the broken `poslog()` speed field; computes velocity from coordinates with outlier clipping and Gaussian smoothing
- **Step detection** — 3-layer filter: bandpass (1–4 Hz cadence band) → activity gate (energy threshold) → rhythm check (CV < 0.35 between peaks)

```matlab
S = fitness_process('run_03.mat')
% Works with both MATLAB Mobile timetable format and fitness_logger format
```

### 3. Feature Extraction
23 features extracted from 2-second sliding windows (1-second hop):

| Domain | Features |
|--------|----------|
| Time | Per-axis mean, std, RMS, peak-to-peak (ax, ay, az) |
| Magnitude | amag mean, amag std |
| Frequency | Dominant frequency, bandpower in 3 bands (0.1–1 Hz, 1–3 Hz, 3–8 Hz) |
| Gyro | Angular velocity magnitude mean & std |

Output: `S.feat` — a windows × 23 matrix ready for any MATLAB classifier.

### 4. Machine Learning
4 models trained and compared using `ClassificationLearner`:

| Model | Test Accuracy |
|-------|--------------|
| KNN | — |
| Bagged Ensemble | — |
| **Boosted Ensemble** | **78.5%** ✓ |
| Subspace KNN | — |

Inverse-frequency class weights applied to compensate for walking-dominant training data.

---

## Personalized Health Metrics

The system computes per-user metrics using anthropometric data (weight, age, height):

```
kcal = MET × weight_kg × duration_hr        (ACSM 2011 Compendium)
BMR  = 88.36 + (13.4 × kg) + (4.8 × cm) − (5.7 × age)   (Mifflin-St Jeor)
```

**Example — same walking session, three users:**

| User | Weight | Steps | Calories | Notes |
|------|--------|-------|----------|-------|
| Person_01 | 82 kg · 23 yr | 397 | **54 kcal** | Highest output — body weight matters |
| Person_02 | 68 kg · 27 yr | 385 | 47.9 kcal | Longest GPS distance (712 m) |
| Person_03 | 60 kg · 20 yr | 508 | 40.9 kcal | Most steps — highest cadence efficiency |

---

## Generalization

| Test setup | Accuracy |
|------------|----------|
| Random 80/20 split | 78.5% |
| Holdout Person_01 | 48.2% |
| Holdout Person_02 | 40.1% |
| Holdout Person_03 | 55.2% |

The cross-person drop is expected and informative — with ~470 windows per person, the model learns both universal activity patterns and person-specific gait signatures. Production path: larger per-user training sets → transfer learning → on-device personalization.

---

## Requirements

- MATLAB R2021b or newer
- MATLAB Mobile (iOS / Android)
- Signal Processing Toolbox (`butter`, `filtfilt`, `bandpower`, `findpeaks`)
- Statistics and Machine Learning Toolbox (`fitcensemble`, `ClassificationLearner`)

---

## File Structure

```
fitness_tracking_app/
├── Fitness Tracker/
│   ├── fitness_logger.m       # Data recording (replaces third.m)
│   ├── fitness_process.m      # Signal processing + feature extraction
│   └── timeElapsed.m          # Datetime utility
├── Fitness_Tracker_Presentation.pdf
└── README.md
```

---

## Quick Start

```matlab
% 1. Record a session (phone must be connected via MATLAB Mobile)
fitness_logger('walking', 60)

% 2. Process the saved file
S = fitness_process('session_walking_20260516_120000.mat')

% 3. Inspect results
S.steps        % step count
S.gps.speed    % Haversine-derived speed (m/s)
S.feat         % 23-feature matrix — feed directly to your classifier
```

---

## License

MIT © 2026 r9xdty
