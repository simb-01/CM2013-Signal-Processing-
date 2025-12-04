function [multi_channel_data, channel_info] = load_holdout_data_TEST(edfFilePath, desiredChannels)
%LOAD_HOLDOUT_DATA  Load EDF holdout data (no labels, no XML).
% Segment signals into 30-second epochs and return:
%   multi_channel_data : [nEpochs x nChannels x nSamples]  
%   channel_info       : struct with fields:
%                          .labels  - channel names
%                          .samples - sampling rates
%
% Usage:
%   [data, info] = load_holdout_data("xx.edf")
%   [data, info] = load_holdout_data("xx.edf", {'EEG','EOG'})

if nargin < 2 || isempty(desiredChannels)
    desiredChannels = {'EEG','EOG','EMG'};     % 默认通道关键字
end

fprintf('Loading EDF (holdout): %s\n', edfFilePath);

%% 1. Read EDF
[hdr, record] = edfread(edfFilePath);   % record: [nChannels x nSamples]

if isempty(hdr)
    error('EDF header empty.');
end

%% 2. Select channels by keywords (contains, case-insensitive)
if ischar(desiredChannels)
    desiredChannels = {desiredChannels};
end

mask = false(1, numel(hdr.label));
for k = 1:numel(desiredChannels)
    mask = mask | contains(hdr.label, desiredChannels{k}, 'IgnoreCase', true);
end

idx = find(mask);
if isempty(idx)
    error('No desired channels found in EDF.');
end

selectedLabels = hdr.label(idx);
Fs_vec = hdr.samples(idx);   % sampling rate for each selected channel

%% 3. Determine epochs (30s)
epochSec = 30;
totalSamples = size(record,2);

% each channel may have different Fs
nEpochs_per_ch = floor(totalSamples ./ (Fs_vec * epochSec));
nEpochs = min(nEpochs_per_ch);

if nEpochs < 1
    error('Not enough data for 30s epoch.');
end

%% 4. Output size
nChannels = numel(idx);
nSamples = epochSec * max(Fs_vec);   % pad to highest sampling rate

multi_channel_data = cell(1, nChannels);  % 1 x B cell array

%% 5. Extract each channel & epoch (zero-pad right side)
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



%% 6. Channel info
channel_info.labels  = selectedLabels;
channel_info.samples = Fs_vec;

fprintf('Holdout data loaded: %d epochs × %d channels × %d samples.\n', ...
        nEpochs, nChannels, nSamples);

end
