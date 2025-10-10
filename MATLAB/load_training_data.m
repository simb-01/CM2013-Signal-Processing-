function [multi_channel_data, labels, channel_info] = load_training_data(edfFilePath, xmlFilePath, desiredChannels)
%% Load EDF and XML files for sleep scoring
% Inputs:
%   edfFilePath    - EDF file path
%   xmlFilePath    - XML annotation file path
%   desiredChannels - (optional) cell array of strings
% Outputs:
%   multi_channel_data - [nEpochs x nChannels x nSamples] selected signals
%   labels             - [nEpochs x 1] sleep stage labels
%   channel_info       - struct with channel names and sampling rates

fprintf('Loading training data from %s and %s...\n', edfFilePath, xmlFilePath);

%% 1. Load EDF
[hdr, record] = edfread(edfFilePath);  % record: [nChannels x nSamplesTotal]

%% 2. Load XML annotations
[~, stages, ~, ~] = readXML(xmlFilePath); % stages 按秒展开

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
% 将按秒展开的 stages 压缩成 30 秒 epoch
epochSec = 30;
stages_epoch = zeros(1, nEpochs);
for e = 1:nEpochs
    startIdx = (e-1)*epochSec + 1;
    endIdx   = min(e*epochSec, length(stages));
    stages_epoch(e) = mode(stages(startIdx:endIdx)); % 取众数
end

labels = stages_epoch; 
channel_info.labels = selectedLabels;
channel_info.samples = hdr.samples(idx);

fprintf('Loaded %d epochs and %d channels: %s\n', nEpochs, nChannels, strjoin(selectedLabels, ', '));

%% 6. Visualization

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
time_min = (1:nEpochs)*30/60; % 每个 epoch 30 秒，转分钟
plot(time_min, labels, '-o','MarkerSize',2);
ylim([0 6]);
set(gca,'ytick',[0:6],'yticklabel',{'REM','','N3','N2','N1','Wake',''});
xlabel('Time (Minutes)');
ylabel('Sleep Stage');
title('Hypnogram');
box off;

end
