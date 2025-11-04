function all_data_preproc = preprocess_all_subjects(all_data, all_info)
% PREPROCESS_ALL_SUBJECTS
% Apply preprocessing to all subjects and all channels,
% and plot the first epoch (time-domain) of each channel for each subject.
%
% Input:
%   all_data - cell array, each cell is [nEpochs x nChannels x nSamples]
%   all_info - cell array, each contains channel_info for that subject
%
% Output:
%   all_data_preproc - cell array of same size as all_data,
%                      containing preprocessed signals
%
% Example:
%   [all_data, all_labels, all_info] = load_all_data('data', {'EEG','EOG','EMG'});
%   all_data_preproc = preprocess_all_subjects(all_data, all_info);

fs = 125;  % Sampling rate (Hz)
nSubjects = numel(all_data);
all_data_preproc = cell(size(all_data));  % preallocate

for subj = 1:nSubjects
    data = all_data{subj};  % [nEpochs x nChannels x nSamples]
    [nEpochs, nChannels, nSamples] = size(data);

    fprintf('\n--- Preprocessing subject %d/%d ---\n', subj, nSubjects);
    processed_data = zeros(size(data));

    for ch = 1:nChannels
        % Extract single-channel data across all epochs
        channel_data = squeeze(data(:, ch, :));  % [nEpochs x nSamples]

        % Get channel name if available
        if nargin > 1 && ~isempty(all_info{subj}) && ch <= numel(all_info{subj}.labels)
            ch_label = all_info{subj}.labels{ch};
        else
            ch_label = sprintf('Channel%d', ch);
        end

        fprintf('   Processing %s...\n', ch_label);

        % Call your single-channel preprocessing function
        y = preprocess(channel_data);

        % Store filtered data
        processed_data(:, ch, :) = y;
    end

    % Save processed data for this subject
    all_data_preproc{subj} = processed_data;

      %% -------- Plot first epoch (time-domain) --------
epochNumber = 1; % Select first epoch
figure('Name', sprintf('Subject %d - EEG/EOG/EMG 30s Epoch (Filtered)', subj), 'Color', 'w');

for ch = 1:nChannels
    Fs = fs;
    signal = squeeze(processed_data(epochNumber, ch, :));

    subplot(nChannels, 1, ch);
    plot((1:length(signal))/Fs, signal, 'Color', [0 0.4470 0.7410], 'LineWidth', 0.3);
    ylabel(sprintf('Ch%d', ch));
    xlim([0 nSamples/Fs]);
    title(['Channel ' all_info{subj}.labels{ch}]);
end

sgtitle(sprintf('Subject %d - 30-second Epoch #%d (Filtered)', subj, epochNumber));



fprintf('\n✅ All subjects have been successfully preprocessed and plotted!\n');
end
