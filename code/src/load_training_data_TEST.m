
function [multi_channel_data, labels, channel_info] = load_training_data_TEST(edfFilePath, xmlFilePath, desiredChannels)
%% Load EDF and XML files for sleep scoring (only full 30s epochs)
%
% Outputs:
%   multi_channel_data : [nEpochs x nChannels x nSamples]
%   labels             : [nEpochs x 1] sleep stage labels
%   channel_info       : struct with .labels and .samples

fprintf('Loading training data from %s and %s...\n', edfFilePath, xmlFilePath);

%% 1. Load EDF
[hdr, record] = edfread(edfFilePath);  % record: [nChannels x nSamplesTotal]
if isempty(hdr)
    error('EDF header empty.');
end

%% 2. Load XML annotations
[~, stages, ~, ~] = readXML(xmlFilePath); % stages 按秒展开
if isempty(stages)
    error('XML annotation empty.');
end

%% 3. Extract relevant channels
if nargin < 3 || isempty(desiredChannels)
    desiredChannels = {'EEG','EOG','EMG'};
end
idx = find(contains(hdr.label, desiredChannels, 'IgnoreCase', true));
if isempty(idx)
    error('None of the desired channels were found in the EDF file.');
end
selectedLabels = hdr.label(idx);
Fs_vec = hdr.samples(idx);
nChannels = numel(idx);

%% 4. Determine number of full 30-second epochs
epochSec = 30;

% 每通道 EDF 可用完整 epoch 数
nEpochs_per_ch = zeros(1, nChannels);
for ch = 1:nChannels
    totalSamples_ch = length(record(idx(ch),:));
    nEpochs_per_ch(ch) = floor(totalSamples_ch / (Fs_vec(ch)*epochSec));
end

% XML 可用完整 epoch 数
nEpochs_xml = floor(length(stages)/epochSec);

% 最终 epoch 数 = EDF 和 XML 都可用的最小值
nEpochs = min([nEpochs_per_ch, nEpochs_xml]);

if nEpochs < 1
    error('Not enough data for one full 30-second epoch.');
end

nSamples = 30 * max(Fs_vec);  % 输出每 epoch 的样本数（最高采样率通道）

%% 5. Segment EDF into epochs
multi_channel_data = cell(1, nChannels);  % 1 x B cell array

for ch = 1:nChannels
    Fs = Fs_vec(ch);
    samplesPerEpoch = Fs * epochSec;
    
    % Initialize matrix for this channel
    channelData = zeros(nEpochs, samplesPerEpoch);
    
    for e = 1:nEpochs
        startIdx = (e-1)*samplesPerEpoch + 1;
        endIdx   = e*samplesPerEpoch;
        channelData(e,1:samplesPerEpoch) = record(idx(ch), startIdx:endIdx);
    end
    
    multi_channel_data{ch} = channelData;  % store in cell
end 


%% 6. Compress stages into 30-second epochs
labels = zeros(nEpochs,1);
for e = 1:nEpochs
    startIdx = (e-1)*epochSec + 1;
    endIdx   = e*epochSec;  % 完整 30 秒，必然 <= length(stages)
    labels(e) = mode(stages(startIdx:endIdx)); 
end
 channel_info.labels  = selectedLabels;
 channel_info.samples = Fs_vec;

% 
% fprintf('Loaded %d full 30s epochs and %d channels: %s\n', nEpochs, nChannels, strjoin(selectedLabels, ', '));
% % % %% 6. Visualization
% % % 
% % % % 6.1 Plot 30-second epoch of each selected signal
% % % epochNumber = 1; % 选择第一个epoch
% % % figure('Name','EEG/EOG/EMG 30s Epoch','Color','w');
% % % for i = 1:nChannels
% % %     Fs = hdr.samples(idx(i));
% % %     signal = squeeze(multi_channel_data(epochNumber,i,1:Fs*30));
% % %     subplot(nChannels,1,i);
% % %     plot((1:length(signal))/Fs, signal);
% % %     ylabel(selectedLabels{i});
% % %     xlim([0 30]);
% % %     title(['Channel ' selectedLabels{i}]);
% % % end
% % % sgtitle(sprintf('30-second Epoch #%d', epochNumber));
% % % 
% % 6.2 Plot Hypnogram
% figure('Name','Hypnogram','Color','w');
% time_min = (1:nEpochs)*30/60; % 每个 epoch 30 秒，转分钟
% plot(time_min, labels, '-o','MarkerSize',2);
% ylim([-1 5]);   % 为视觉效果稍微放宽一点
% set(gca, 'ytick', 0:4, ...
%          'yticklabel', {'Wake','N1','N2','N3','REM'});
% xlabel('Time (Minutes)');
% ylabel('Sleep Stage');
% title('Hypnogram');
% box off;
end
