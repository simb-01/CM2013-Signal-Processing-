clc;
close all;
clearvars -except config;

% Add src directory and subdirectories to path
addpath(genpath('src'));

% Load configuration
run('config.m'); % This will load config variables into the workspace

fprintf('--- Sleep Scoring Pipeline - Iteration %d ---\n', CURRENT_ITERATION);
folderpath = 'D:\HuaweiMoveData\Users\Rina\Desktop\signal\CM2013-Signal-Processing-\data\training';
%[all_data, all_labels, all_info] = load_all_data(folderpath, 'EEG');
%% 

% 2. Preprocessing
preprocessed_data = [];

cache_filename_preprocess = sprintf('preprocessed_data_iter%d.mat', CURRENT_ITERATION);
USE_CACHE = true;
if USE_CACHE
    preprocessed_data = load_cache(cache_filename_preprocess, CACHE_DIR);
end

if isempty(preprocessed_data)
    [all_data, all_labels, all_info] = load_all_data(folderpath, 'EEG');

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

