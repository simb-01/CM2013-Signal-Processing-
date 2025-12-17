Repository Structure
The key MATLAB folders/files in Final-Code are organized as follows (names may need minor adjustment to match your repo):

MATLAB/

config.m – Global configuration: iteration number, enabled modalities (EEG/EOG/EMG), classifier choice (kNN/SVM/RF), paths.​

main.m – Main entry point for training & evaluation (LOSO or other CV) for the selected iteration.​

run_inference.m – Script to run the final trained model on holdout data and generate submission.csv.​

dataloader.m – EDF/XML loader (EEG, later extended to EOG, EMG).

preprocessing.m – Bandpass / notch filters and modality‑specific preprocessing.

feature_extraction.m – Time‑domain, spectral and multimodal features.

classification.m (or trainclassifier.m) – Model training logic (k‑NN, SVM, Random Forest) and evaluation.

report.m / visualization.m – Confusion matrices, metrics tables, hypnograms and plots.​

data/

train/ – Training EDF/XML files (not included in the repo; expected path).

holdout/ – Holdout EDF/XML files (for run_inference.m).

submission/ – Output folder for submission.csv.​

cache/

Preprocessed signals and feature matrices to speed up re‑runs.​

reports/

iter*_results.mat / .csv – Saved metrics per iteration.​

final_report.pdf – Written project report (placed here in Iteration 4).​

.github/

CI and PR templates (optional, used earlier in the course).​

Adjust paths in config.m if your local layout differs.

2. Requirements
MATLAB R2021a or later (project was developed and tested on a recent MATLAB version).​

Required Toolboxes:

Signal Processing Toolbox (filters, PSD, spectrograms).​

Statistics and Machine Learning Toolbox (k‑NN, SVM, TreeBagger / Random Forest).​

Data:

Polysomnography data in EDF format and labels in XML, as provided in the CM2013 course.​

3. Quickstart
3.1. Clone and set paths
matlab
% In MATLAB
cd /path/to/CM2013-Signal-Processing-
addpath(genpath('MATLAB'));
Check and edit config.m:

CURRENT_ITERATION = 4 (final system).

Paths to training and holdout data.

Classifier type and enabled modalities.

3.2. Run final evaluation (LOSO)
matlab
% Run final LOSO evaluation for Iteration 4
config;        % loads global config
main;          % trains and evaluates using LOSO
Expected output:

Metrics printed to command window (accuracy, Cohen’s kappa, macro‑F1).​

Confusion matrix figures for the final model.

Metrics saved under reports/ (e.g., iter4_results.mat or similar).​

3.3. Generate final submission
matlab
% Generate final submission.csv for holdout data
config;
run_inference;
This will:

Load the final trained model (or retrain, depending on config).

Run inference on all holdout EDF files.

Write data/submission/submission.csv with rows:

text
record_number,epoch_number,label
1,0,W
1,1,N1
...
(Exact label encoding depends on your implementation; see report/README notes.)

4. Configuration
All global settings are controlled via config.m. Typical parameters:

Iteration / mode

CURRENT_ITERATION = 1 | 2 | 3 | 4

Signals / modalities

Flags like USE_EEG, USE_EOG, USE_EMG.

Classifier

CLASSIFIER_TYPE = 'knn' | 'svm' | 'rf'

Model‑specific hyperparameters (e.g., KNN_NEIGHBORS, SVM kernel/C, RF number of trees).​​

Data paths

Paths for training and holdout EDF/XML files.

Caching

USE_CACHE and cache folder paths for preprocessed signals and features.​

Make sure to set CURRENT_ITERATION = 4 + appropriate classifier/modalities for final runs.

5. Evaluation Protocol
Primary evaluation: Leave‑One‑Subject‑Out (LOSO) cross‑validation on training subjects.​

Each subject is held out once; metrics are averaged and standard deviations reported.

Metrics:

Overall accuracy.

Cohen’s kappa.

Macro‑averaged F1.

Per‑class precision/recall/F1 and confusion matrices.​​

The final report includes:

Metric tables per iteration (1–4).​

Confusion matrices for the final model.

Discussion of which stages (e.g., N1/REM) benefit from spectral or multimodal features.​

6. Reproducibility & Smoke Tests
Before running full LOSO or inference:

Run a small smoke test on a subset of data:

matlab
config;
% Optionally set a flag in config for a "small" run
main;    % should complete quickly without errors
Check that:

Data shapes are correct (epochs × channels/features).

No NaN/Inf in feature matrices.

Metrics look reasonable (not random).​

A brief smoke‑test description and how to execute it are included in the README so others can quickly verify the setup.​

7. Final Deliverables
For the course submission (Iteration 4) the repository contains or supports:​

Code: Final MATLAB pipeline with configuration and scripts to reproduce results.

Final submission.csv: Produced by run_inference.m for the holdout set.

Final report (reports/final_report.pdf): Methods, results and analysis across iterations.

Slides: Final presentation in reports/ or presentation/ folder.

Project management evidence: ClickUp board (external) showing completed tasks and iteration history.

