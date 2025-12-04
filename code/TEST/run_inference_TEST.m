clc;
close all;
clearvars -except config;

addpath(genpath('src'));
run('config.m');

%% --------- Initialize struct ---------
numSubjects = 10;

HoldoutSubjects = cell(1, numSubjects);
SubjectTemplate = struct( 'ID', [], 'channels', [], 'sampling_rates', [], 'preprocessed_data', [], 'features', []);

for i = 1:numSubjects
    HoldoutSubjects{i} = SubjectTemplate;
end

%% --------- Load data ---------

HoldoutSubjects = load_all_holdout_data_TEST(HoldoutSubjects, HOLDOUT_DIR, {'EEG','EOG','EMG'});

%% --------- Preprocessing ---------

HoldoutSubjects = preprocess_all_subjects_TEST(HoldoutSubjects);

%% --------- Feature Extraction ---------

HoldoutSubjects = feature_extraction_TEST(HoldoutSubjects);

%% --------- Feature Scaling/Normalization ---------

for subj_idx = 1:numSubjects
    nrChannels = numel(HoldoutSubjects{subj_idx}.channels);
    for ch = 1:nrChannels
        channel_features = HoldoutSubjects{subj_idx}.features{ch};
        nrEpochs = size(channel_features, 2);
        for f = 1:nrEpochs
            vec = channel_features(:, f); % epochs for this feature
            mu = mean(vec);
            sigma = std(vec) + eps;      % avoid division by zero

            % z-score normalization
            channel_features(:, f) = (vec - mu) / sigma;
        end         
        HoldoutSubjects{subj_idx}.features{ch} = channel_features;
    end
end


%% --------- Remove Last Epoch ---------

for subj_idx = 1:10
    nrChannels = numel(HoldoutSubjects{subj_idx}.channels);
    for ch = 1:nrChannels
        channel_features = HoldoutSubjects{subj_idx}.features{ch};
        nrEpochs = size(channel_features, 1);
        channel_features =  channel_features(1:nrEpochs-1,:);
        HoldoutSubjects{subj_idx}.features{ch} = channel_features;
    end
end

%% --------- Save/Load Subjects ---------

CURRENT_ITERATION = 3;
USE_CACHE = false;
cache_subjects = sprintf('HoldoutSubjects_data_iter%d.mat', CURRENT_ITERATION);

if(USE_CACHE) 
    HoldoutSubjects = load_cache(cache_subjects, CACHE_DIR);
else 
    save_cache(HoldoutSubjects, cache_subjects, CACHE_DIR);
end

%%
CURRENT_ITERATION = 3;
cache_model = sprintf('model_final_iter%d.mat',  CURRENT_ITERATION);
model = load_cache(cache_model, CACHE_DIR);

predict_B_corrected();
predictions = Y_pred_all;

tabulate(predictions)
% 假设你有每个样本的 epoch 数
num_epochs = [1018, 1016, 1066, 1068, 1018, 958, 1067, 1066, 1068, 1066];  % 举例

record_numbers = [];
epoch_numbers  = [];

for i = 1:length(num_epochs)
    n = num_epochs(i);
    record_numbers = [record_numbers; repmat(i, n, 1)];  % 每个样本重复 n 次
    epoch_numbers  = [epoch_numbers; (0:n-1)'];            % 生成 1 到 n 的序列
end
tmpConfig.DATA_DIR = DATA_DIR;
tmpConfig.SUBMISSION_FILE = SUBMISSION_FILE;
% 5. Generate Submission File
inference_generate_submission_file(predictions, record_numbers, epoch_numbers, tmpConfig);

fprintf('--- Inference Finished ---\n');
