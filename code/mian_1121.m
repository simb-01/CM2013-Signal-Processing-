clc;
close all;
clearvars -except config;

% Add src directory and subdirectories to path
addpath(genpath('src'));

% Load configuration
run('config.m'); % This will load config variables into the workspace


fprintf('--- Sleep Scoring Pipeline - Iteration %d ---\n', CURRENT_ITERATION);

do = false;
if do
% folderpath = 'D:\HuaweiMoveData\Users\Rina\Desktop\signal\CM2013-Signal-Processing-\data\training';
[all_data, all_labels, all_info] = load_all_data(TRAINING_DIR, 'EEG');
%% 

% 2. Preprocessing
preprocessed_data = [];

cache_filename_preprocess = sprintf('preprocessed_data_iter%d.mat', CURRENT_ITERATION);
if USE_CACHE
    preprocessed_data = load_cache(cache_filename_preprocess, CACHE_DIR);
end

if isempty(preprocessed_data)
    %[all_data, all_labels, all_info] = load_all_data(folderpath, 'EEG');

    preprocessed_data = preprocess_all_subjects(all_data, all_info);
    if (USE_CACHE == false)
        save_cache(preprocessed_data, cache_filename_preprocess, CACHE_DIR);
    end
end


%% 

% 3. Feature Extraction
features = [];
cache_filename_features = sprintf('features_iter%d.mat', CURRENT_ITERATION);
%USE_CACHE = true;

if USE_CACHE
    features = load_cache(cache_filename_features, CACHE_DIR);
end

if isempty(features)
    features = feature_extraction(preprocessed_data);
    if (USE_CACHE == false)
        save_cache(features, cache_filename_features, CACHE_DIR);
    end
end
%% 


end

% 4.subject struct
S = [];
cache_filename_struct = sprintf('subject_struct_iter%d.mat', CURRENT_ITERATION);

if USE_CACHE
    S = load_cache(cache_filename_struct, CACHE_DIR);
end

if isempty(S)
    S = generateSubjectStruct(preprocessed_data, features, all_labels);
    if ~USE_CACHE
        save_cache(S, cache_filename_struct, CACHE_DIR);
    end
end

if do
% Test basic information of Subject01
disp('--- Subject01 Basic Information ---');

% Subject ID
disp('Subject01 ID:');
disp(S.subject01.id);

% Channel names
disp('Subject01 channel names:');
disp(S.subject01.channelNames);

% Sampling rates
disp('Subject01 sampling rates:');
disp(S.subject01.samplingRate);

% Preprocessed data size of channel 2 (second real channel)
disp('Subject01 preprocessed_data size of channel 2 (second real channel):');
disp(size(S.subject01.preprocessed_data{2}));  % [nEpochs x nSamples]

% Features size of channel 2 (second real channel)
disp('Subject01 features size of channel 2 (second real channel):');
disp(size(S.subject01.features{2}));  % [nEpochs x nFeatures]

% Preprocessed data size of channel 3 (first zero-padded channel)
disp('Subject01 preprocessed_data size of channel 3 (zero-padded channel):');
disp(size(S.subject01.preprocessed_data{3}));

% Features size of channel 3 (zero-padded channel)
disp('Subject01 features size of channel 3 (zero-padded channel):');
disp(size(S.subject01.features{3}));

% Labels size
disp('Subject01 labels size:');
disp(size(S.subject01.labels));  % [nEpochs x labels]

% Optionally, display a small portion of the second real channel data
disp('First 5 rows and 10 samples of second real channel preprocessed_data:');
disp(S.subject01.preprocessed_data{2}(1:5, 1:10));

disp('First 5 rows and 5 features of second real channel features:');
disp(S.subject01.features{2}(1:5, 1:5));
end

%%


data(1) = S.subject01;
data(2) = S.subject02;
data(3) = S.subject03;
data(4) = S.subject04;
data(5) = S.subject05;
data(6) = S.subject06;
data(7) = S.subject07;
data(8) = S.subject08;
data(9) = S.subject09;
data(10) = S.subject10;

N = length(data);

all_true = [];
all_pred = [];

for test_subj = 1:1  %1:N
    % Collect test features/labels (held-out subject)
    X_test = data(test_subj).features{1};  % X_test = cell2mat(X_test);
    Y_test = data(test_subj).labels;

    Y_test = repmat(Y_test, 1, size(X_test, 2));
    X_test = X_test(:);     
    Y_test = Y_test(:); 
    
    % Collect training data (all other subjects)
    X_train = [];
    Y_train = [];
    for train_subj = 1:N   %setdiff(1:N, test_subj)
        X_train = [X_train; data(train_subj).features{1}];
        Y_train = [Y_train; data(train_subj).labels];
    end
    Y_train = repmat(Y_train, 1, size(X_train, 2));
    X_train = X_train(:);     
    Y_train = Y_train(:);   

    % Train the model 
    model = train_classifier(X_train, Y_train);

    % Predict for test set
    Y_pred = predict(model, X_test);

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






    % Save the trained model for inference
    model_filename = sprintf('model_testedOnSubj%d_iter%d.mat', test_subj, CURRENT_ITERATION);
    save_cache(model, model_filename, CACHE_DIR);

    % 6. Visualization
    visualize_results(Y_pred, Y_test);

    % 7. Report Generation
    generate_report(Y_pred, Y_test);

    % fprintf('--- Pipeline Finished ---\n');

end

% Evaluate after all folds
overall_acc = mean(all_true == all_pred);
fprintf('LOSO mean accuracy: %.2f%%\n', overall_acc*100);

