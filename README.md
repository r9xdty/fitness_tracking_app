# \\\ Personal Fitness Tracker //
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
| Total windows after cleaning | 1,301 (from 1,419 — 8.3% noise removed) |
| Engineered features | 23 (time + frequency domain) |
| Best model accuracy | **78.5%** (Boosted Ensemble) |
| Fitness metrics per user | 5 (steps · kcal · METs · WHO% · BMR%) |

---

## User Profiles

| User | Age | Height | Weight | BMI | BMR | Stride |
|------|-----|--------|--------|-----|-----|--------|
| Kişi_01 | 23 | 183 cm | 82 kg | 24.5 | 1854 kcal/day | 75.6 cm |
| Kişi_02 | 27 | 170 cm | 68 kg | 23.5 | 1613 kcal/day | 70.2 cm |
| Kişi_03 | 20 | 180 cm | 60 kg | 18.5 | 1630 kcal/day | 74.3 cm |

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
S = fitness_process('running_03.mat')
% Works with both MATLAB Mobile timetable format and fitness_logger format
```

### 3. Feature Extraction
23 features extracted from 2-second sliding windows (1-second hop), yielding 1,419 windows across 15 sessions:

| Domain | Features |
|--------|----------|
| Time | Per-axis mean, std, RMS, peak-to-peak (ax, ay, az) |
| Magnitude | amag mean, amag std |
| Frequency | Dominant frequency, bandpower in 3 bands (0.1–1 Hz, 1–3 Hz, 3–8 Hz) |
| Gyro | Angular velocity magnitude mean & std |

**Data cleaning:** 118 windows removed (8.3%) — noisy sitting windows and near-silent walking segments filtered before training.

### 4. Machine Learning

4 models trained and compared on a stratified 80/20 random split (train=1041, test=260):

| Model | Train Acc | Test Acc |
|-------|-----------|----------|
| KNN | 1.000 | 0.781 |
| Bagged Ensemble | 0.846 | 0.758 |
| **Boosted Ensemble** | **0.910** | **0.785** ✓ |
| Subspace KNN | 0.916 | 0.777 |

**Per-class accuracy (best model — Boosted):**

| Activity | Accuracy | Test samples |
|----------|----------|-------------|
| sitting | 96.4% | 28 |
| running | 82.9% | 41 |
| stairsup | 82.5% | 40 |
| stairsdown | 78.9% | 57 |
| walking | 69.1% | 94 |

---

## Generalization: Cross-Person Holdout Test

Train on 2 users, test on the 3rd — the hard test.

| Test setup | Best model | Accuracy |
|------------|------------|----------|
| Random stratified split | Boosted | **78.5%** |
| Holdout Kişi_01 | Bagged Ensemble | 48.2% |
| Holdout Kişi_02 | Boosted | 40.1% |
| Holdout Kişi_03 | Bagged Ensemble | 55.2% |

The drop is real — and informative. With ~470 windows per person, the model learns both universal activity patterns and person-specific gait signatures. **Production path:** larger per-user training sets → transfer learning → on-device personalization.

<details>
<summary>Per-class breakdown — holdout tests</summary>

**Holdout Kişi_01** (n=421)

| Activity | Accuracy |
|----------|----------|
| running | 100% |
| sitting | 75.0% |
| stairsup | 53.6% |
| walking | 30.5% |
| stairsdown | 28.0% |

**Holdout Kişi_02** (n=469)

| Activity | Accuracy |
|----------|----------|
| sitting | 100% |
| stairsdown | 92.4% |
| running | 74.5% |
| stairsup | 0% |
| walking | 0% |

**Holdout Kişi_03** (n=411)

| Activity | Accuracy |
|----------|----------|
| walking | 66.7% |
| running | 69.2% |
| stairsup | 46.0% |
| sitting | 54.5% |
| stairsdown | 29.2% |

</details>

---

## Session Metrics

| User | Activity | Duration | Steps | Cadence | Calories | MET |
|------|----------|----------|-------|---------|----------|-----|
| Kişi_01 | sitting | 61.8 s | 2 | 1.9 spm | 1.83 kcal | 1.3 |
| Kişi_01 | walking | 157.0 s | 131 | 50.1 spm | 15.4 kcal | 4.3 |
| Kişi_01 | running | 78.2 s | 111 | 85.1 spm | 14.8 kcal | 8.3 |
| Kişi_01 | stairsup | 83.4 s | 28 | 20.2 spm | 15.2 kcal | 8.0 |
| Kişi_01 | stairsdown | 85.8 s | 125 | 87.5 spm | 6.84 kcal | 3.5 |
| Kişi_02 | sitting | 75.2 s | 1 | 0.8 spm | 1.85 kcal | 1.3 |
| Kişi_02 | walking | 224.4 s | 141 | 37.7 spm | 18.2 kcal | 4.3 |
| Kişi_02 | running | 52.5 s | 61 | 69.7 spm | 8.24 kcal | 8.3 |
| Kişi_02 | stairsup | 88.7 s | 90 | 60.9 spm | 13.4 kcal | 8.0 |
| Kişi_02 | stairsdown | 93.4 s | 92 | 59.1 spm | 6.18 kcal | 3.5 |
| Kişi_03 | sitting | 68.9 s | 16 | 13.9 spm | 1.49 kcal | 1.3 |
| Kişi_03 | walking | 166.6 s | 160 | 57.6 spm | 11.9 kcal | 4.3 |
| Kişi_03 | running | 80.8 s | 142 | 105.5 spm | 11.2 kcal | 8.3 |
| Kişi_03 | stairsup | 89.7 s | 106 | 70.9 spm | 11.9 kcal | 8.0 |
| Kişi_03 | stairsdown | 74.2 s | 84 | 67.9 spm | 4.33 kcal | 3.5 |

---

## Personalized Health Insights

Calories computed via MET formula (ACSM 2011 Compendium): `kcal = MET × weight_kg × duration_hr`  
BMR via Mifflin-St Jeor: `88.36 + (13.4 × kg) + (4.8 × cm) − (5.7 × age)`

**Same exercise, different physiological cost:**

| User | Steps | Calories | GPS Distance | WHO Target | BMR% |
|------|-------|----------|-------------|------------|------|
| Kişi_01 | 397 | **54.0 kcal** | 458 m | 25% | 2.9% |
| Kişi_02 | 385 | 47.9 kcal | 712 m | 28% | 3.0% |
| Kişi_03 | 508 | 40.9 kcal | 861 m | 26% | 2.5% |

- **Kişi_01** — Highest calorie output. Body weight is the multiplier.
- **Kişi_02** — Longest GPS distance (712 m). Slowest cadence, longest walking session.
- **Kişi_03** — Most steps and highest cadence efficiency. Lowest calorie burn despite most movement.

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
│   ├── fitness_logger.m       # Data recording (improved third.m)
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

% 2. Process the saved file — auto-detects MATLAB Mobile or logger format
S = fitness_process('walking_01.mat')

% 3. Inspect outputs
S.steps        % step count
S.gps.speed    % Haversine-derived speed in m/s
S.feat         % 23-feature matrix — feed directly to your classifier
```

---

## License

MIT © 2026 r9xdty
