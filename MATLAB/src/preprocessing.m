function preprocessed_data = preprocess(data, config)
%% STUDENT IMPLEMENTATION AREA: Preprocess EEG data based on current iteration.
%
% This is a MINIMAL example. Students should expand this significantly:
%
% Iteration 1: Basic filtering (current example is just a starting point)
% Iteration 2+: Add more sophisticated preprocessing:
% - Artifact removal (eye blinks, muscle artifacts)
% - Channel selection and re-referencing
% - Epoch extraction (30-second windows)
% - Data quality checks
% - Normalization/standardization

fprintf('Preprocessing data for iteration %d...\n', config.CURRENT_ITERATION);

% TODO: Students need to implement proper preprocessing based on iteration:
if config.CURRENT_ITERATION == 1
    % EXAMPLE: Very basic low-pass filter (students should expand)
    fs = 100; % TODO: Get actual sampling rate from data/config
    preprocessed_data = lowpass_filter(data, config.LOW_PASS_FILTER_FREQ, fs);

    % TODO: Students should add:
    % - High-pass filtering
    % - Epoch extraction (30-second windows)
    % - Channel selection

elseif config.CURRENT_ITERATION == 2
    % TODO: Students implement enhanced preprocessing:
    % - Better filtering (bandpass)
    % - Artifact detection/removal
    % - Re-referencing
    fprintf('TODO: Implement enhanced preprocessing for iteration 2\n');
    preprocessed_data = data; % Placeholder - students must implement

elseif config.CURRENT_ITERATION >= 3
    % TODO: Students implement advanced preprocessing:
    % - Multi-signal processing (EEG + EOG + EMG)
    % - Advanced artifact removal
    % - Signal quality assessment
    fprintf('TODO: Implement advanced preprocessing for iteration 3+\n');
    preprocessed_data = data; % Placeholder - students must implement

else
    error('Invalid iteration: %d', config.CURRENT_ITERATION);
end

end

function y = lowpass_filter(data, cutoff, fs, order)
% EXAMPLE IMPLEMENTATION: Simple low-pass Butterworth filter.
%
% Students should understand this basic filter and consider:
% - Is 40Hz the right cutoff for EEG?
% - What about high-pass filtering?
% - Should you use bandpass instead?
% - What about notch filtering for powerline interference?

if nargin < 4
    order = 5;
end

% TODO: Students may want to implement additional filtering:
% - High-pass filter to remove DC drift
% - Notch filter for 50/60 Hz powerline noise
% - Bandpass filter (e.g., 0.5-40 Hz for EEG)

nyquist = 0.5 * fs;
normal_cutoff = cutoff / nyquist;
[b, a] = butter(order, normal_cutoff, 'low');
y = filter(b, a, data);

end
