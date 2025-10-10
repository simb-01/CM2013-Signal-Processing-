function [multi_channel_data, labels, channel_info] = load_training_data(edfFilePath, xmlFilePath, desiredChannels)
%% STUDENT IMPLEMENTATION AREA: Load EDF and XML files.
%% Load EDF and XML files for sleep scoring
% Inputs:
%   edfFilePath    - EDF file path
%   xmlFilePath    - XML annotation file path
%   desiredChannels - (optional) cell array of strings, 
% {{'SaO2'}    {'HR'}    {'EEGsec'}    {'ECG'}    {'EMG'}    {'EOGL'}    {'EOGR'}    {'EEG'} 
% {'THORRES'}    {'ABDORES'}    {'POSITION'}{'LIGHT'}    {'NEWAIR'}    {'OXstat'}}
% Outputs:
%   multi_channel_data - [nEpochs x nChannels x nSamples] selected signals
%   labels             - [nEpochs x 1] sleep stage labels
%   channel_info       - struct with channel names and sampling rates
fprintf('Loading training data from %s and %s...\n', edfFilePath, xmlFilePath);

%% 1. Load EDF
[hdr, record] = edfread(edfFilePath);  % record: [nChannels x nSamplesTotal]

%% 2. Load XML annotations
[~, stages, ~, ~] = readXML(xmlFilePath);

%% 3. Extract relevant channels
if nargin < 3 || isempty(desiredChannels)
    desiredChannels = {'EEG','EOG','EMG'}; % 默认
end
idx = find(contains(hdr.label, desiredChannels, 'IgnoreCase', true));
if isempty(idx)
    error('None of the desired channels were found in the EDF file.');
end
selectedLabels = hdr.label(idx);

%% 4. Segment into 30-second epochs
nChannels = numel(idx);
nEpochs = min(floor(length(record(idx(1),:)) ./ (30 .* hdr.samples(idx(1)))));
nSamples = 30 * max(hdr.samples(idx)); 

multi_channel_data = zeros(nEpochs, nChannels, nSamples);
for ch = 1:nChannels
    Fs = hdr.samples(idx(ch));
    for e = 1:nEpochs
        startIdx = (e-1)*Fs*30 + 1;
        endIdx   = e*Fs*30;
        multi_channel_data(e,ch,1:Fs*30) = record(idx(ch), startIdx:endIdx);
    end
end

%% 5. Match epochs with sleep stage labels
labels = stages(1:nEpochs);
channel_info.labels = selectedLabels;
channel_info.samples = hdr.samples(idx);

fprintf('Loaded %d epochs and %d channels: %s\n', nEpochs, nChannels, strjoin(selectedLabels, ', '));

%% ✅ 6. Visualization Section (added)
% -----------------------------
% 6.1 Plot 30-second epoch of each selected signal
epochNumber = 1; % 选择第一个epoch
figure('Name','EEG/EOG/EMG 30s Epoch','Color','w');
for i = 1:nChannels
    Fs = hdr.samples(idx(i));
    signal = squeeze(multi_channel_data(epochNumber,i,1:Fs*30));
    subplot(nChannels,1,i);
    plot((1:length(signal))/Fs, signal);
    ylabel(selectedLabels{i});
    xlim([0 30]);
    title(['Channel ' selectedLabels{i}]);
end
sgtitle(sprintf('30-second Epoch #%d', epochNumber));

% 6.2 Plot Hypnogram
figure('Name','Hypnogram','Color','w');
plot(((1:length(labels))*30)./60, labels, 'LineWidth', 1.5);
ylim([0 6]);
set(gca,'YTick',0:6,'YTickLabel',{'REM','','N3','N2','N1','Wake',''});
xlabel('Time (minutes)');
ylabel('Sleep Stage');
title('Hypnogram (Sleep Stage over Time)');
grid on;
% -----------------------------

end
