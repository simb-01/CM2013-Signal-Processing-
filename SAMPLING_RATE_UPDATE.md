# Sampling Rate Update Summary

## Issue Identified
The Python jumpstart code had **incorrect hardcoded sampling frequencies** in the dummy data that did not match the actual study data.

## Actual Sampling Rates (From Study Data)
Based on the signal table provided:

| Signal Type | Channels | Sampling Rate | Samples per 30s Epoch |
|-------------|----------|---------------|----------------------|
| **EEG** | C3-A2, C4-A1 | **125 Hz** | 3,750 samples |
| **EOG** | EOG(L), EOG(R) | **50 Hz** | 1,500 samples |
| **EMG** | EMG | **125 Hz** | 3,750 samples |
| **ECG** | ECG | 125 Hz | 3,750 samples |
| **Respiration** | Thor RES, Abdo RES | 10 Hz | 300 samples |
| **SpO2/Heart Rate** | SaO2, H.R. | 1 Hz | 30 samples |

## Previous Incorrect Values
- EEG: 100 Hz ❌ (was hardcoded, should be 125 Hz ✓)
- EOG: 100 Hz ❌ (was hardcoded, should be 50 Hz ✓)
- EMG: 200 Hz ❌ (was hardcoded, should be 125 Hz ✓)

## Files Updated

### 1. `Python/src/data_loader.py`
**Changes:**
- Updated dummy data generation to use correct sampling rates
- EEG: 125 Hz (3,750 samples per 30s epoch)
- EOG: 50 Hz (1,500 samples per 30s epoch)
- EMG: 125 Hz (3,750 samples per 30s epoch)
- Updated `channel_info` dictionary with correct frequencies
- Updated documentation comments with actual study rates
- Updated `create_30_second_epochs()` documentation with correct rates

### 2. `Python/src/preprocessing.py`
**Changes:**
- Updated EEG sampling rate: `eeg_fs = 125` (was 100)
- Updated EOG sampling rate: `eog_fs = 50` (was 100)
- Updated EMG sampling rate: `emg_fs = 125` (was 200)
- Fixed iteration logic: EOG starts in iteration 2 (not 3)
- Updated EMG lowpass cutoff to 70 Hz (from 100 Hz) to match new Nyquist
- Updated single-channel preprocessing: `fs = 125` (was 100)

### 3. `Python/README.md`
**Changes:**
- Updated "First Run Results" section with correct sample counts
- Updated "What Students Must Implement" section with actual rates
- Added note about hardware high-pass filters (0.15 Hz already applied)

### 4. `PROJECT_GUIDE.md`
**Changes:**
- Added comprehensive signal information table with all 15 channels
- Updated glossary with correct sampling rates
- Added hardware filtering information
- Added signal processing considerations

### 5. PowerPoint Presentation
**Changes:**
- Updated all slides mentioning sampling rates
- Added detailed signal specifications table (Slide 35)
- Added signal processing considerations slide

## Key Points for Students

### MNE Will Read Correct Rates Automatically
When students implement real EDF loading using MNE:
```python
raw = mne.io.read_raw_edf(edf_file_path, preload=True)
```
MNE will automatically read the **correct sampling rates** from the EDF file headers. Students do NOT need to hardcode these values.

### What Students Should Do
1. **Read sampling rates from EDF**: Use `raw.info['sfreq']` for each channel
2. **Handle different rates appropriately**:
   - Option A: Resample all to common rate (e.g., 100 Hz)
   - Option B: Process at native rates and extract features separately
3. **Calculate epoch samples correctly**: `samples_per_epoch = sampling_rate * 30`

### Hardware Filtering Already Applied
Students should note that hardware high-pass filters have already been applied:
- EEG/EOG/EMG/ECG: 0.15 Hz high-pass
- Respiration: 0.05 Hz high-pass

Students should design additional filters accordingly (e.g., no need for very low frequency high-pass).

## Impact on Feature Extraction
With correct sampling rates:
- More samples per epoch for EEG (3,750 vs 3,000) = better frequency resolution
- Fewer samples per epoch for EOG (1,500 vs 3,000) = appropriate for slower eye movements
- Fewer samples per epoch for EMG (3,750 vs 6,000) = still adequate for muscle activity

## Testing
The jumpstart code will now generate dummy data with correct dimensions that match what students will encounter when loading real EDF files.

## Status
✅ All files updated
✅ Documentation updated
✅ PowerPoint presentation updated
✅ Consistent across all materials