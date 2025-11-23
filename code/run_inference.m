%function run_inference()
%% Script to run inference on hold-out data and generate submission file.

clc;
close all;
clearvars -except config;

% Add src directory and subdirectories to path
addpath(genpath('src'));

% Load configuration
run('config.m'); % This will load config variables into the workspace

fprintf('--- Sleep Scoring Inference - Iteration %d ---\n', CURRENT_ITERATION);

% Load the trained model (assuming it was saved during training)
model_filename = sprintf('model_iter%d.mat', CURRENT_ITERATION);
model = load_cache(model_filename, CACHE_DIR);
% if isempty(model)
%     fprintf('Error: Trained model not found. Please run main.m first to train a model.\n');
%     return;
% end

% 1. Load Hold-out Data
% For jumpstart, we're using dummy data. In a real scenario, you'd iterate through files.
% holdout_edf_file = fullfile(HOLDOUT_DIR, "                                                                                                                                                     dummy_holdout.edf"); % Placeholder
% holdout_eeg_data = data_loader_load_holdout_data(holdout_edf_file);
%                                                       
folderpath = 'D:\HuaweiMoveData\Users\Rina\Desktop\signal\CM2013-Signal-Processing-\data\Holdout';                         
[all_data1, all_info1] = load_all_holdout_data(folderpath, 'EEG');        
%% 

% 2. Preprocessing (using the same logic as training)
preprocessed_holdout_data = [];
cache_filename_preprocess_holdout = sprintf('preprocessed_holdout_data_iter%d.mat', CURRENT_ITERATION);
if USE_CACHE    
    preprocessed_holdout_data = load_cache(cache_filename_preprocess_holdout, CACHE_DIR);
end

if isempty(preprocessed_holdout_data)
    preprocessed_holdout_data = preprocess_all_subjects(all_data1, all_info1);
    
    if (USE_CACHE == false)
        save_cache(preprocessed_holdout_data, cache_filename_preprocess_holdout, CACHE_DIR);
    end
end
%% 

% 3. Feature Extraction (using the same logic as training)
CURRENT_ITERATION=2;
USE_CACHE = false;
holdout_features = [];
cache_filename_features_holdout = sprintf('features_holdout_iter%d.mat', CURRENT_ITERATION);
if USE_CACHE
    holdout_features = load_cache(cache_filename_features_holdout, CACHE_DIR);
end

if isempty(holdout_features)
    holdout_features = feature_extraction(preprocessed_holdout_data);
    if (USE_CACHE == false)
        save_cache(holdout_features, cache_filename_features_holdout, CACHE_DIR);
    end
end
%% 
save_cache(holdout_features, cache_filename_features_holdout, CACHE_DIR);
%% 4.subject struct
B = [];

cache_filename_struct = sprintf('subject_struct_iter%d.mat', CURRENT_ITERATION);

% if USE_CACHE
%     S = load_cache(cache_filename_struct, CACHE_DIR);
% end

if isempty(B)
    B = generateholdStruct(preprocessed_holdout_data, holdout_features);
    if ~USE_CACHE
        save_cache(B, cache_filename_struct, CACHE_DIR);
    end
end

%% 
cache_filename_model_final = sprintf('model_final_iter%d.mat', CURRENT_ITERATION);
model=load_cache(cache_filename_model_final, CACHE_DIR);

% 4. Make Inference
subjectNames = fieldnames(B);
totalSubjects = numel(subjectNames);

X_all1 = [];
for s = 1:10  % 你只用前两个 subject
    subj = B.(subjectNames{s});
    featCell = subj.features;     

    channelFeatures = [];
    for ch = 1:2
        f = featCell{ch};             
        channelFeatures = [channelFeatures, f];  % 水平拼接
    end

    X_all1 = [X_all1; channelFeatures];
end
X_all1_log = log1p(abs(X_all1)) .* sign(X_all1);
X_all1_scaled = zscore(X_all1_log, 0, 1);       % 列归一化
fprintf('Total inference samples: %d, Total features: %d\n', size(X_all1,1), size(X_all1,2));

% 做预测
predictions = predict(model, X_all1_scaled);
figure;
subplot(1,2,1);
boxplot(X_all_scaled(:,1:20)); title('Training set features (first 20)');
subplot(1,2,2);
boxplot(X_all1_scaled(:,1:20)); title('Test set features (first 20)');


%% 

tabulate(predictions)
% 假设你有每个样本的 epoch 数
num_epochs = [1019, 1017, 1067, 1069, 1019, 959, 1068, 1067, 1069, 1067];  % 举例

record_numbers = [];
epoch_numbers  = [];

for i = 1:length(num_epochs)
    n = num_epochs(i);
    record_numbers = [record_numbers; repmat(i, n, 1)];  % 每个样本重复 n 次
    epoch_numbers  = [epoch_numbers; (1:n)'];            % 生成 1 到 n 的序列
end
tmpConfig.DATA_DIR = DATA_DIR;
tmpConfig.SUBMISSION_FILE = SUBMISSION_FILE;
% 5. Generate Submission File
inference_generate_submission_file(predictions, record_numbers, epoch_numbers, tmpConfig);

fprintf('--- Inference Finished ---\n');

%end
