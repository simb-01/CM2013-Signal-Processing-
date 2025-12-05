function Subjects = feature_extraction_TEST(subjects_data)

%USE_TIME_FEATURES = false;
%USE_AR_FEATURES = false;
%USE_WELCH_FEATURES = false;
%USE_DWT_FEATURES = false;
%USE_N1_FEATURES = false;

nrSubjects = numel(subjects_data);

for i = 1:nrSubjects
    fprintf('\n=== Starting feature extraction of Subject %d ===\n', i);

    subjChannels = subjects_data{i}.channels;
    preprocessedData = subjects_data{i}.preprocessed_data;
    nrChannels = numel(subjChannels);
    channelFeatures = cell(1, nrChannels);

    for ch = 1:nrChannels
        chName = subjChannels{ch};
        data = preprocessedData{ch};
        nrEpochs = size(data,1);

        features = [];
        fprintf('\n=== Starting feature extraction of channel %s ===\n', chName);

        if strcmpi(chName, 'EEG') || strcmpi(chName, 'EEGsec')
            features = extract_eeg_features(data);
        elseif strcmpi(chName, 'EMG')
            features = extract_emg_features(data);      
        elseif strcmpi(chName, 'EOGL') || strcmpi(chName, 'EOGR')
            features = extract_eog_features(data);
        else
        end
        channelFeatures{ch} = features;
    end
    subjects_data{i}.features = channelFeatures;
    fprintf('\n=== Feature extraction of Subject %d complete ===\n', i);

end
Subjects = subjects_data;
end


function eeg_features = extract_eeg_features(channel_data)
eeg_features_time = extract_all_features_TEST(channel_data);
eeg_features_welch = extract_welch_features_TEST(channel_data);
eeg_features_N1 = extract_n1_unique_features_TEST(channel_data);
eeg_features = [eeg_features_time, eeg_features_welch, eeg_features_N1];
end

function eog_features = extract_eog_features(channel_data)
% channel_data: epochs x samples
nrEpochs = size(channel_data,1);
fs = 125;  % sampling rate
eog_features = zeros(nrEpochs,5);

% 1) Peak amplitude
peak_amp = max(abs(channel_data), [], 2);

% 2) Variance
var_epoch = var(channel_data, 0, 2);

% 3) Zero-crossing rate
% sign(channel_data) -> diff -> count nonzeros
zero_crossings = sum(diff(sign(channel_data),1,2)~=0, 2);

% 4) Number of rapid deflections (REM proxy)
% High-pass filter all epochs at once
hp_epoch = highpass(channel_data', 0.5, fs)';  % transpose trick
% Threshold = 0.5 * std of each epoch
thresh = 0.5 * std(hp_epoch, 0, 2);
rapid_deflections = sum(abs(hp_epoch) > thresh, 2);

% 5) Mean absolute derivative
mean_deriv = mean(abs(diff(channel_data,1,2)), 2);

% Combine features
eog_features = [peak_amp, var_epoch, zero_crossings, rapid_deflections, mean_deriv];
end

function emg_features = extract_emg_features(channel_data)
% channel_data: epochs x samples
nrEpochs = size(channel_data,1);
emg_features = zeros(nrEpochs,4);

fs = 125;  % Sampling frequency

% 1) Signal power (mean squared amplitude)
sig_power = mean(channel_data.^2, 2);  % mean across samples (row-wise)

% 2) Variance
var_epoch = var(channel_data, 0, 2);

% 3) RMS
rms_val = sqrt(sig_power);  % RMS = sqrt(mean squared amplitude)

% 4) High-frequency power (20-40 Hz)
% Apply bandpass to all epochs at once
% Use designfilt + filtfilt for efficiency
d = designfilt('bandpassiir','FilterOrder',4, ...
               'HalfPowerFrequency1',20,'HalfPowerFrequency2',40, ...
               'SampleRate',fs);
hf_power = mean(filtfilt(d, channel_data')'.^2, 2);  % transpose trick

% Combine features
emg_features = [sig_power, var_epoch, hf_power, rms_val];
end
