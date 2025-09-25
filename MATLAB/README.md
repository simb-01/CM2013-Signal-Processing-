# Sleep Scoring Project - MATLAB Jumpstart

This directory contains a jumpstart project for the automatic sleep scoring system, implemented in MATLAB. It provides a modular, function-based design to help students quickly get started and develop further.

## Project Planning and Iterative Development

This project follows an agile, iterative development approach as outlined in the `Sleep_Scoring_Complete_Guide.md` file in the root directory. The `config.m` file allows you to set the `CURRENT_ITERATION` to control the behavior of the pipeline, enabling progressive development and testing of features.

## How to Use the Jumpstart

### 1. Setup

Ensure you have MATLAB installed. No specific toolbox installations are strictly required for the basic jumpstart, but the Signal Processing Toolbox and Statistics and Machine Learning Toolbox will be beneficial for further development.

### 2. Project Structure

```
/MATLAB/
├── cache/                  % Stores cached preprocessed data and extracted features
├── data/                   % Contains raw data files
│   ├── training/           % Labeled data for training and validation
│   └── holdout/            % Unlabeled data for final inference and competition submission
├── src/                    % Source code for different modules of the pipeline
│   ├── data_loader.m       % Handles loading EDF and XML files
│   ├── preprocessing.m     % Contains functions for signal preprocessing (e.g., filtering)
│   ├── feature_extraction.m % Extracts features from preprocessed data
│   ├── feature_selection.m % Selects relevant features (placeholder)
│   ├── classification.m    % Implements classification algorithms
│   ├── visualization.m     % For plotting results (e.g., confusion matrix)
│   ├── report.m            % Generates summary reports
│   ├── inference.m         % Handles making predictions on hold-out data
│   └── utils/              % Utility functions (e.g., caching)
├── tests/                  % Unit tests for each module (optional, can be implemented using MATLAB's testing framework)
├── main.m                  % Orchestrates the training and evaluation pipeline
├── run_inference.m         % Script to run inference on hold-out data and generate submission file
└── config.m                % Project configuration (iterations, file paths, model parameters)
```

### 3. Running the Training and Evaluation Pipeline

To run the full pipeline (data loading, preprocessing, feature extraction, classification, visualization, and reporting) for the current iteration defined in `config.m`:

1.  Open MATLAB.
2.  Navigate to the `/MATLAB/` directory.
3.  Run the `main.m` script from the MATLAB command window:
    ```matlab
    main
    ```

### 4. Running Inference and Generating Submission File

After training your model using `main.m`, you can run inference on the hold-out data and generate a `submission.csv` file:

1.  Open MATLAB.
2.  Navigate to the `/MATLAB/` directory.
3.  Run the `run_inference.m` script from the MATLAB command window:
    ```matlab
    run_inference
    ```

This will create a `submission.csv` file in the `data/` directory, formatted as `record_number,epoch_number,label`.

### 5. Configuration

The `config.m` file is central to managing the project. You can adjust:
*   `CURRENT_ITERATION`: To switch between different stages of development (1-4).
*   `USE_CACHE`: To enable/disable caching of intermediate results.
*   File paths, preprocessing parameters, and model hyperparameters.

## Data Information

### Data Structure

*   **`data/training/`**: This directory should contain EDF files and their corresponding XML annotation files for training and validation of your models. These files have associated sleep stage labels.
*   **`data/holdout/`**: This directory should contain EDF files for which you need to predict sleep stages. These files do *not* have associated labels and are used for competition submission.

### EDF File Format

EDF (European Data Format) is a standard file format for storing physiological and biological signals. It can store multiple signals (e.g., EEG, EOG, EMG) and includes metadata like sampling frequency and channel names. Sleep stages are typically labeled for every 30-second epoch.

To read EDF files in MATLAB, the `edfread` function is available. **Note:** The provided EDF files might not be compatible with the built-in `edfread` in MATLAB. You should use the `edfread` function provided in this module (if available) or a custom implementation.

### XML Annotation Files

XML (Extensible Markup Language) files are used to store structured data, including annotations for the EDF signals. These annotations typically contain the sleep stage labels for each epoch.

For more details on the Compumedics Annotation Format, refer to: [https://github.com/nsrr/edf-editor-translator/wiki/Compumedics-Annotation-Format](https://github.com/nsrr/edf-editor-translator/wiki/Compumedics-Annotation-Format)

## Iteration Planning (Refer to `Sleep_Scoring_Complete_Guide.md`)

The `Sleep_Scoring_Complete_Guide.md` provides a detailed plan for iterative development, including:
*   **Iteration 1 (Weeks 1-2.5):** Basic Pipeline (EEG, Time features, k-NN)
*   **Iteration 2 (Weeks 2.5-5):** Enhanced Processing (EEG, Time+Freq features, SVM)
*   **Iteration 3 (Weeks 5-7.5):** Multi-Signal (EEG+EOG, Selected features, RF)
*   **Iteration 4 (Weeks 7.5-10):** Full System (All signals, Optimized features, RF-opt)

Students are encouraged to follow this plan, updating the `CURRENT_ITERATION` in `config.m` as they progress.

## Competition Submission

For the competition, you will submit a CSV file generated by `run_inference.m`. The format should be:

```csv
record_number,epoch_number,label
1,0,Wake
1,1,N1
...
```

`record_number` refers to the identifier of the EDF file, and `epoch_number` is the 0-indexed sequence of 30-second epochs within that record. `label` is the predicted sleep stage.
