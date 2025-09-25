function main()
%% Main script to run the sleep scoring pipeline.

clc;
close all;
clearvars -except config;

% Load configuration
run('config.m'); % This will load config variables into the workspace

fprintf('--- Sleep Scoring Pipeline - Iteration %d ---\n', CURRENT_ITERATION);

% 1. Load Data
% For jumpstart, we're using dummy data. In a real scenario, you'd iterate through files.
edf_file = fullfile(TRAINING_DIR, "dummy.edf"); % Placeholder
[eeg_data, labels] = data_loader_load_training_data(edf_file);

% 2. Preprocessing
preprocessed_data = [];
cache_filename_preprocess = sprintf('preprocessed_data_iter%d.mat', CURRENT_ITERATION);
if USE_CACHE
    preprocessed_data = load_cache(cache_filename_preprocess, CACHE_DIR);
end

if isempty(preprocessed_data)
    preprocessed_data = preprocessing_preprocess(eeg_data, config);
    if USE_CACHE
        save_cache(preprocessed_data, cache_filename_preprocess, CACHE_DIR);
    end
end

% 3. Feature Extraction
features = [];
cache_filename_features = sprintf('features_iter%d.mat', CURRENT_ITERATION);
if USE_CACHE
    features = load_cache(cache_filename_features, CACHE_DIR);
end

if isempty(features)
    features = feature_extraction_extract_features(preprocessed_data, config);
    if USE_CACHE
        save_cache(features, cache_filename_features, CACHE_DIR);
    end
end

% 4. Feature Selection
selected_features = feature_selection_select_features(features, labels, config);

% 5. Classification
model = classification_train_classifier(selected_features, labels, config);

% Save the trained model for inference
model_filename = sprintf('model_iter%d.mat', CURRENT_ITERATION);
save_cache(model, model_filename, CACHE_DIR);

% 6. Visualization
visualization_visualize_results(model, selected_features, labels, config);

% 7. Report Generation
report_generate_report(model, selected_features, labels, config);

fprintf('--- Pipeline Finished ---\n');

end
