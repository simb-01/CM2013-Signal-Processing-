clc;
close all;
clearvars -except config;

% Add src directory and subdirectories to path
addpath(genpath('src'));

% Load configuration
run('config.m'); % This will load config variables into the workspace

fprintf('--- Sleep Scoring Pipeline - Iteration %d ---\n', CURRENT_ITERATION);
folderpath = 'D:\HuaweiMoveData\Users\Rina\Desktop\signal\CM2013-Signal-Processing-\data\training';
[all_data, all_labels, all_info] = load_all_data(folderpath, 'EEG');

% 2. Preprocessing
preprocessed_data = [];

cache_filename_preprocess = sprintf('preprocessed_data_iter%d.mat', CURRENT_ITERATION);
if USE_CACHE
    preprocessed_data = load_cache(cache_filename_preprocess, CACHE_DIR);
end

if isempty(preprocessed_data)
    preprocessed_data = preprocess_all_subjects(all_data, all_info);
    if (USE_CACHE ==false)
        save_cache(preprocessed_data, cache_filename_preprocess, CACHE_DIR);
    end
end

