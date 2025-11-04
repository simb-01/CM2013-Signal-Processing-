function [all_data, all_labels, all_info] = load_all_data(dataDir, desiredChannels)
%% Load all EDF/XML pairs from a given folder
% This function automatically loads multiple subjects' sleep data (EDF + XML pairs)
% using the provided 'load_training_data' function.
%
% Inputs:
%   dataDir         - Directory path containing EDF and XML files (e.g., R1.edf, R1.xml, ...)
%   desiredChannels - Cell array of channel names to extract,[EEGsec, ECG, EMG, EOGL, EOGR, EEG]
%
% Outputs:
%   all_data   - Cell array, each cell is [nEpochs x nChannels x nSamples] for one subject
%   all_labels - Cell array, each cell is [nEpochs x 1] sleep stage labels
%   all_info   - Cell array of structs with channel names and sampling rates
%
fprintf('Scanning folder: %s\n', dataDir);

% Find all EDF files in the directory
edfFiles = dir(fullfile(dataDir, '*.edf'));
if isempty(edfFiles)
    error('No EDF files found in folder: %s', dataDir);
end

nSubjects = numel(edfFiles);
fprintf('Found %d EDF files.\n', nSubjects);

% Initialize output cell arrays
all_data = cell(1, nSubjects);
all_labels = cell(1, nSubjects);
all_info = cell(1, nSubjects);

% Loop through each EDF/XML pair
for i = 1:nSubjects
    [~, name, ~] = fileparts(edfFiles(i).name);
    edfPath = fullfile(dataDir, [name '.edf']);
    xmlPath = fullfile(dataDir, [name '.xml']);

    % Check if XML annotation file exists
    if ~isfile(xmlPath)
        warning('XML file not found for %s, skipping...', name);
        continue;
    end

    fprintf('\n=== Loading %s ===\n', name);
    [multi_channel_data, labels, info] = load_training_data(edfPath, xmlPath, desiredChannels);

    % Store results in cell arrays
    all_data{i} = multi_channel_data;
    all_labels{i} = labels;
    all_info{i} = info;
end

fprintf('\nAll data loading finished. (%d EDF files found)\n', nSubjects);
end
