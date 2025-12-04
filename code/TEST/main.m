clc;
close all;
clearvars -except config;

addpath(genpath('src'));
run('config.m');

%% --------- Initialize struct ---------
numSubjects = 10;

Subjects = cell(1, numSubjects);
SubjectTemplate = struct( 'ID', [], 'labels', [], 'channels', [], 'sampling_rates', [], 'preprocessed_data', [], 'features', []);

for i = 1:numSubjects
    Subjects{i} = SubjectTemplate;
end

%% --------- Load data ---------

Subjects = load_all_data_TEST(Subjects, TRAINING_DIR, {'EEG','EOG','EMG'});

%% --------- Preprocessing ---------

Subjects = preprocess_all_subjects_TEST(Subjects);

%% --------- Feature Extraction ---------

Subjects = feature_extraction_TEST(Subjects);

%% --------- Feature Scaling/Normalization ---------

for subj_idx = 1:numSubjects
    nrChannels = numel(Subjects{subj_idx}.channels);
    for ch = 1:nrChannels
        channel_features = Subjects{subj_idx}.features{ch};
        nrFeatures = size(channel_features, 2);
        for f = 1:nrFeatures
            vec = channel_features(:, f); % epochs for this feature
            mu = mean(vec);
            sigma = std(vec) + eps;      % avoid division by zero

            % z-score normalization
            channel_features(:, f) = (vec - mu) / sigma;
        end         
        Subjects{subj_idx}.features{ch} = channel_features;
    end
end

%% --------- Save/Load Subjects ---------

CURRENT_ITERATION = 3;
USE_CACHE = false;
cache_subjects = sprintf('subjects_data_iter%d.mat', CURRENT_ITERATION);

if(USE_CACHE) 
    Subjects = load_cache(cache_subjects, CACHE_DIR);
else 
    save_cache(Subjects, cache_subjects, CACHE_DIR);
end

%%       THIS IS THE ONLY SECTION TO RUN       !!!!!!!!!
% ------------------------------------------------------

all_true = [];
all_pred = [];
% Using LOSO performance testing 
for test_subj = 1:10
    % 默认参数: window=1, cv_ratio=0.2, use_smote=true, N1_label=2, n_smote_new=2000
    [model, Y_test, Y_pred] = run_context_training_TEST(Subjects, test_subj);

    % Store results
    all_true = [all_true; Y_test];
    all_pred = [all_pred; Y_pred];

    % Calculate metrics
    accuracy = sum(Y_pred == Y_test) / length(Y_test) * 100;
    confMat = confusionmat(Y_test, Y_pred);

    fprintf('\n=== Test Subject %d Set Performance ===\n', test_subj);
    fprintf('Overall Accuracy: %.2f%%\n', accuracy);
    fprintf('Confusion Matrix:\n');
    disp(confMat);

    % Calculate per-class accuracy
    stage_names = {'Wake', 'N1', 'N2', 'N3', 'REM'};
    fprintf('\nPer-Class Accuracy:\n');
    for stage = 0:4
        idx = (Y_test == stage);
        if sum(idx) > 0
            stage_acc = sum(Y_pred(idx) == Y_test(idx)) / sum(idx) * 100;
            fprintf('  %s: %.2f%% (%d epochs)\n', stage_names{stage+1}, stage_acc, sum(idx));
        end
    end

    fprintf('Subject %d: Accuracy %.2f%%\n', test_subj, mean(Y_pred == Y_test)*100);

    % 6. Visualization
    visualize_results(Y_pred, Y_test);

    % 7. Report Generation
    generate_report(Y_pred, Y_test);
end

% Evaluate after all folds
overall_acc = mean(all_true == all_pred);
fprintf('LOSO mean accuracy: %.2f%%\n', overall_acc*100);


%% --------- Get and Save Model for Holdout Prediction ---------

CURRENT_ITERATION = 3;
cache_model = sprintf('model_final_iter%d.mat',  CURRENT_ITERATION);

model = run_context_get_model_TEST(Subjects);
save_cache(model, cache_model, CACHE_DIR);
