function [eeg_data, labels] = data_loader_load_training_data(filePath)
%% Loads training data from an EDF file and its corresponding XML annotation file.
% For the jumpstart, this function creates dummy data.
% Replace this with actual EDF/XML loading logic.

fprintf('Loading training data from %s...\n', filePath);
% Dummy data: 10 minutes of data at 100 Hz, 30-second epochs
nEpochs = 20;
nSamples = 30 * 100;
eeg_data = randn(nEpochs, nSamples);
labels = randi([0, 4], 1, nEpochs); % 5 sleep stages (0-4)

end

function eeg_data = data_loader_load_holdout_data(filePath)
%% Loads holdout data from an EDF file.
% For the jumpstart, this function creates dummy data.
% Replace this with actual EDF loading logic.

fprintf('Loading holdout data from %s...\n', filePath);
% Dummy data: 10 minutes of data at 100 Hz, 30-second epochs
nEpochs = 20;
nSamples = 30 * 100;
eeg_data = randn(nEpochs, nSamples);

end

function [hdr, record] = data_loader_read_edf(filePath)
%% Reads an EDF file using the provided edfread function.
% Note: Use the custom edfread if the built-in MATLAB one is incompatible.

fprintf('Reading EDF file: %s\n', filePath);
% Placeholder for actual edfread call
% [hdr, record] = edfread(filePath);

% Dummy output for now
hdr.samples = [100, 100, 100]; % Example sampling rates
hdr.label = {'EEG Fpz-Cz', 'EOG horizontal', 'EMG chin'};
record = randn(3, 20*30*100); % Example dummy record

end
