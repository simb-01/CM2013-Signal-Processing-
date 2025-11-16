function feature_data = extract_dwt_features(eeg_cell)
% EXTRACT_DWT_FEATURES - DWT特征，每个频段提取7个统计特征
% 输入:
%   eeg_cell: 1xN cell，每个 cell [nEpochs x nChannels x nSamples]
% 输出:
%   feature_data: 1xN cell，每个 cell [nEpochs x nChannels x nDWTFeatures]

feature_data = cell(1, numel(eeg_cell));

fs = 125;
level = 5;
wname = 'db4';

for subj_idx = 1:numel(eeg_cell)
    subj_data = eeg_cell{subj_idx};
    [nEpochs, nChannels, ~] = size(subj_data);
    
    nBands = 6; % D1-D5 + A5
    nFeaturesPerBand = 7;
    subj_features = zeros(nEpochs, nChannels, nBands*nFeaturesPerBand);
    
    for epoch_idx = 1:nEpochs
        for ch_idx = 1:nChannels
            signal = squeeze(subj_data(epoch_idx, ch_idx, :))';
            [C,L] = wavedec(signal, level, wname);
            
            bands = {detcoef(C,L,1), detcoef(C,L,2), detcoef(C,L,3), ...
                     detcoef(C,L,4), detcoef(C,L,5), appcoef(C,L,wname,5)};
            
            feats = [];
            for b = 1:nBands
                x = bands{b};
                feats = [feats, ...
                    mean(x), ...        % Mean
                    var(x), ...         % Variance
                    sqrt(mean(x.^2)),...% RMS
                    skewness(x), ...    % Skewness
                    kurtosis(x), ...    % Kurtosis
                    sum(x.^2), ...      % Energy
                    -sum((x.^2)/sum(x.^2) .* log((x.^2)/sum(x.^2)+eps))]; % Entropy
            end
            
            subj_features(epoch_idx, ch_idx, :) = feats;
        end
    end
    feature_data{subj_idx} = subj_features;
end

fprintf('\n=== DWT features (7 per band) extracted ===\n');
end
