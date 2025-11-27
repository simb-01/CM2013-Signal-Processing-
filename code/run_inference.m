%function run_inference()
%% Script to run inference on hold-out data and generate submission file.

% clc;
% close all;
% clearvars -except config;

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
[all_data1, all_info1] = load_all_holdout_data(folderpath, {'EEG','EMG','EOG'});        
%% 
USE_CACHE = false;
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
%% 
%% 假设你想看第 1 个文件的最后一个 epoch
for i = 1:numel(holdout_features)
    data = holdout_features{i};                   % [nEpochs x nChannels x nSamples]
    nEpochs = size(data,1);                % 当前 epoch 数
    % 如果想和 Python 对齐，丢掉最后一个 epoch
    holdout_features{i} = data(1:nEpochs-1,:,:);  
end
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

% %% ---------------- 1) 合并 B 中所有 subject 的特征 ----------------
% subjectNamesB = fieldnames(B);
% totalSubjectsB = numel(subjectNamesB);
% 
% X_allB = [];
% subj_epoch_countsB = [];
% 
% for s = 1:totalSubjectsB
%     subjName = subjectNamesB{s};
%     subj = B.(subjName);
%     if ~isfield(subj, 'features')
%         warning('Subject %s missing features, skipping', subjName);
%         continue;
%     end
%     featCell = subj.features;
%     
%     % Combine channels horizontally
%     channelFeatures = [];
%     for ch = 1:5
%         f = featCell{ch};
%         channelFeatures = [channelFeatures, f];
%     end
%     
%     X_allB = [X_allB; channelFeatures];
%     subj_epoch_countsB = [subj_epoch_countsB; size(channelFeatures,1)];
% end
% 
% fprintf('Merged holdout features: samples=%d, features=%d, subjects=%d\n', size(X_allB,1), size(X_allB,2), numel(subj_epoch_countsB));
% 
% %% ---------------- 2) 归一化（使用训练集均值和标准差） ----------------
% % 使用训练集 X_all 的均值和 std
% X_allB_log = log1p(abs(X_allB)) .* sign(X_allB);
% 
% X_allB_scaled = (X_allB_log - mu) ./ (sigma + eps);  % 防止除0

%% ---------------- 4) 预测 ----------------
% predictions = predict(model, X_allB_ctx);
%% 
predict_B_corrected();
predictions = Y_pred_all ;



%% 

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

%end
