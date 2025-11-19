function [all_data, all_info] = load_all_holdout_data(dataDir, desiredChannels)
%LOAD_ALL_HOLDOUT_DATA  Load all holdout EDF files in a folder (no XML, no labels).
%
% Usage:
%   [all_data, all_info] = load_all_holdout_data(dataDir)
%   [all_data, all_info] = load_all_holdout_data(dataDir, {'EEG','EOG'})
%
% Inputs:
%   dataDir         - directory containing .edf files
%   desiredChannels - optional cell array of channel keywords (default {'EEG','EOG','EMG'})
%
% Outputs:
%   all_data  - cell array (1 x nFiles) where each cell is [nEpochs x nChannels x nSamples]
%   all_info  - cell array (1 x nFiles) of structs with fields .labels and .samples

if nargin < 2
    desiredChannels = {'EEG','EOG','EMG'};
end

if ~isfolder(dataDir)
    error('Directory does not exist: %s', dataDir);
end

fprintf('Scanning folder: %s\n', dataDir);

% find EDF files
edfFiles = dir(fullfile(dataDir, '*.edf'));
if isempty(edfFiles)
    error('No EDF files found in folder: %s', dataDir);
end

% extract names and numeric tokens for numeric sort
names = {edfFiles.name};
nums = nan(size(names));
for i = 1:numel(names)
    token = regexp(names{i}, '\d+', 'match');
    if ~isempty(token)
        nums(i) = str2double(token{1});
    end
end
[~, idxSort] = sort(nums);
edfFiles = edfFiles(idxSort);

nFiles = numel(edfFiles);
all_data = cell(1, nFiles);
all_info = cell(1, nFiles);

processed = 0;
for i = 1:nFiles
    try
        edfPath = fullfile(dataDir, edfFiles(i).name);

        fprintf('\n=== Processing %s (%d of %d) ===\n', edfFiles(i).name, i, nFiles);

        % Call the holdout loader (must be in path)
        [multi_channel_data, channel_info] = load_holdout_data(edfPath, desiredChannels);

        processed = processed + 1;
        all_data{processed} = multi_channel_data;
        all_info{processed} = channel_info;

        fprintf('Loaded %s: epochs=%d, channels=%d, samples=%d\n', ...
                edfFiles(i).name, size(multi_channel_data,1), size(multi_channel_data,2), size(multi_channel_data,3));
    catch ME
        warning('Failed to load %s: %s', edfFiles(i).name, ME.message);
        % skip file
    end
end

% Trim unused cells if some files failed
if processed < nFiles
    all_data = all_data(1:processed);
    all_info = all_info(1:processed);
end

fprintf('\nFinished. %d / %d files processed successfully.\n', processed, nFiles);
end
