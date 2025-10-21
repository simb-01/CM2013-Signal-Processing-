function features = extract_features_v1(data)

%% Extract features - wrapper that accesses config from caller's workspace

% This function should handle both single-channel (old format) and
% multi-channel data (new format with 2 EEG + 2 EOG + 1 EMG channels).
%
% Iteration 1: 16 time-domain features per EEG channel
% Iteration 2: 31+ features (time + frequency domain) per channel
% Iteration 3: Multi-signal features (EEG + EOG + EMG)
% Iteration 4: Optimized feature set (selected subset)

% Get CURRENT_ITERATION from caller's workspace
try
    CURRENT_ITERATION = evalin('caller', 'CURRENT_ITERATION');
catch
    CURRENT_ITERATION = 1; % Default
end

fprintf('Extracting features for iteration %d...\n', CURRENT_ITERATION);

% Detect if we have multi-channel data structure
if isstruct(data) && isfield(data, 'eeg')
    fprintf('Processing multi-channel data (EEG + EOG + EMG)\n');
    features = extract_multi_channel_features(data, CURRENT_ITERATION);
else
    fprintf('Processing single-channel data (backward compatibility)\n');
    features = extract_single_channel_features(data, CURRENT_ITERATION);
end
end

function features = extract_multi_channel_features(multi_channel_data, CURRENT_ITERATION)
%% Extract features from multi-channel data: 2 EEG + 2 EOG + 1 EMG channels.
% Students should expand this significantly!
% I need multi-channel-data to test this, which isn't possible until
% preprocessing is done.

n_epochs = size(multi_channel_data.eeg, 1);
all_features = [];

for epoch_idx = 1:n_epochs
    epoch_features = [];

    % EEG features (2 channels)
    for ch = 1:size(multi_channel_data.eeg, 2)
        eeg_signal = squeeze(multi_channel_data.eeg(epoch_idx, ch, :));
        eeg_features = extract_time_domain_features_per_epoch(eeg_signal);
        epoch_features = [epoch_features, eeg_features];
    end

    if CURRENT_ITERATION >= 3
        % Add EOG features (2 channels)
        for ch = 1:size(multi_channel_data.eog, 2)
            eog_signal = squeeze(multi_channel_data.eog(epoch_idx, ch, :));
            eog_features = extract_eog_features(eog_signal);
            epoch_features = [epoch_features, eog_features];
        end

        % Add EMG features (1 channel)
        emg_signal = squeeze(multi_channel_data.emg(epoch_idx, 1, :));
        emg_features = extract_emg_features(emg_signal);
        epoch_features = [epoch_features, emg_features];
    end

    all_features = [all_features; epoch_features];
end

if CURRENT_ITERATION == 1
    
    expected = 2 * 3; % 2 EEG channels × 3 features each
    fprintf('Multi-channel Iteration 1: %d features (target: %d+)\n', size(features, 2), expected);
    fprintf('Students must implement remaining 13 time-domain features per EEG channel!\n');
elseif CURRENT_ITERATION >= 3
    fprintf('Multi-channel features extracted: %d total\n', size(features, 2));
    fprintf('(2 EEG + 2 EOG + 1 EMG channels)\n');
end

end

function features = extract_single_channel_features(data, CURRENT_ITERATION)
%% Backward compatibility for single-channel data.

if CURRENT_ITERATION == 1
    features = extract_time_domain_features_per_channel(data, CURRENT_ITERATION);
elseif CURRENT_ITERATION == 2
    % TODO: Students must implement frequency-domain features
    fprintf('TODO: Students must implement frequency-domain feature extraction\n');
    fprintf('Target: ~31 features (time + frequency domain)\n');
    features = zeros(size(data, 1), 0); % Empty features - students must implement

elseif CURRENT_ITERATION >= 3
    % TODO: Students must implement multi-signal features
    fprintf('TODO: Students should use multi-channel data format for iteration 3+\n');
    features = zeros(size(data, 1), 0); % Empty features - students must implement

else
    error('Invalid iteration: %d', CURRENT_ITERATION);
end

end

function features = extract_time_domain_features_per_epoch(epoch)
features = [
    mean(epoch),                % Mean
    median(epoch),              % Median
    std(epoch),                 % Standard Deviation
    var(epoch),                 % Variance
    rms(epoch),                 % Root Mean Square
    min(epoch),                 % Minimum
    max(epoch),                 % Maximum
    range(epoch),               % Range (Peak to Peak)
    skewness(epoch),            % Skewness
    kurtosis(epoch),            % Kurtosis
    zero_crossings(epoch),      % Zero Crossings
    hjorth_activity(epoch),     % Hjorth Activity
    hjorth_mobility(epoch),     % Hjorth Mobility
    hjorth_complexity(epoch),   % Hjorth Complexity
    sum(epoch.^2),              % Total Signal Energy
    %sampen(epoch, 2, 0.2)      % Sample Entropy   
    sum(epoch.^2),              % Total Signal Energy .. I have this here in place of sampen, just temporary
];
end

function features = extract_time_domain_features_per_channel(data, CURRENT_ITERATION)

n_epochs = size(data, 1);
n_features_per_epoch = 16;
features = zeros(n_epochs, n_features_per_epoch);

for i = 1:n_epochs
    epoch = data(i, :);
    features(i, :) = extract_time_domain_features_per_epoch(epoch);
end
end

function rms_val = rms(signal)
rms_val = sqrt(mean(signal.^2));
end

function zeroCrossings = zero_crossings(epoch)
    zeroCrossings = sum(diff(sign(epoch)) ~= 0);
end

function hjorthActivity = hjorth_activity(epoch)
    hjorthActivity = var(epoch);
end

function hjorthMobility = hjorth_mobility(epoch)
    a = var(diff(epoch));
    b = var(epoch);
    hjorthMobility = sqrt(a/b);
end

function hjorthComplexity = hjorth_complexity(epoch)
    a = hjorth_mobility(diff(epoch));
    b = hjorth_mobility(epoch);
    hjorthComplexity = a/b;
end

function se = sampen(epoch, m, r2)

N = length(epoch);
r = r2 * std(epoch);

% Count matches of length m
B = 0;
for i = 1:N-m
    for j = i+1:N-m
        if max(abs(epoch(i:i+m-1) - epoch(j:j+m-1))) <= r
            B = B + 1;
        end
    end
end

% Count matches of length m+1
A = 0;
for i = 1:N-m-1
    for j = i+1:N-m-1
        if max(abs(epoch(i:i+m) - epoch(j:j+m))) <= r
            A = A + 1;
        end
    end
end

% Compute Sample Entropy
if B == 0
    se = NaN; % avoid division by zero
else
    se = -log(A / B);
end
end

% The rest of the code is not part of Iteration 1.

function features = extract_eog_features(eog_signal)
%% STUDENT TODO: Extract EOG-specific features for eye movement detection.
%
% EOG signals are used to detect:
% - Rapid eye movements (REM sleep indicator)
% - Slow eye movements
% - Eye blinks and artifacts

features = [
    mean(eog_signal),                          % Mean
    std(eog_signal),                           % Standard deviation
    max(eog_signal) - min(eog_signal)          % Range
];

% TODO: Students should add:
% - Eye movement detection features
% - Rapid vs slow movement discrimination
% - Cross-channel correlations (left vs right eye)

end


function features = extract_emg_features(emg_signal)
%% STUDENT TODO: Extract EMG-specific features for muscle tone detection.
%
% EMG signals are used to detect:
% - Muscle tone levels (high in wake, low in REM)
% - Muscle twitches and artifacts
% - Sleep-related muscle activity

features = [
    mean(emg_signal),                          % Mean
    std(emg_signal),                          % Standard deviation
    rms(emg_signal)                           % RMS
];

end
