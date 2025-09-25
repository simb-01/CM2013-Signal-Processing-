function preprocessed_data = preprocessing_preprocess(data, config)
%% Preprocesses the EEG data based on the current iteration.

fprintf('Preprocessing data...\n');

if config.CURRENT_ITERATION == 1
    % Iteration 1: Simple low-pass filter
    fs = 100; % Assuming 100 Hz sampling rate for dummy data
    preprocessed_data = lowpass_filter(data, config.LOW_PASS_FILTER_FREQ, fs);
else
    % Placeholder for more advanced preprocessing in later iterations
    fprintf('Warning: No preprocessing defined for this iteration. Returning raw data.\n');
    preprocessed_data = data;
end

end

function y = lowpass_filter(data, cutoff, fs, order)
% Applies a low-pass Butterworth filter to the data.

if nargin < 4
    order = 5;
end

nyquist = 0.5 * fs;
normal_cutoff = cutoff / nyquist;
[b, a] = butter(order, normal_cutoff, 'low');
y = filter(b, a, data);

end
