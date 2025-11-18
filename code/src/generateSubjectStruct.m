function S = generateSubjectStruct(preprocessedData3D, featuresData3D, all_labels)
    % 通道总数目标
    totalChannels = 6;
    N = numel(preprocessedData3D);
    S = struct();

    for i = 1:N
        subjName = sprintf('subject%02d', i);

        %% 当前数据
        data3D = preprocessedData3D{i};       % [nEpochs x nChannels x nSamples]
        feat3D = featuresData3D{i};           % [nEpochs x nChannels x nFeatures]
        labelsCell = all_labels{i};           % [labels x nEpochs]

        [nEpochs, nChannels, nSamples] = size(data3D);
        [~, ~, nFeatures] = size(feat3D);

        %% 初始化 cell，填充 0
        preprocessedCell = cell(1, totalChannels);
        featureCell = cell(1, totalChannels);

        % 先填充现有通道数据
        for ch = 1:nChannels
            preprocessedCell{ch} = squeeze(data3D(:, ch, :));   % [nEpochs x nSamples]
            featureCell{ch} = squeeze(feat3D(:, ch, :));        % [nEpochs x nFeatures]
        end

        % 后面没有的通道补零
        for ch = nChannels+1:totalChannels
            preprocessedCell{ch} = zeros(nEpochs, nSamples);
            featureCell{ch} = zeros(nEpochs, nFeatures);
        end

        % labels 转置
        labelsMatrix = labelsCell';  % [nEpochs x labels]

        % channelNames 和 samplingRate
        channelNames = {'EEGsec', 'ECG', 'EMG', 'EOGL', 'EOGR', 'EEG'};
        samplingRates = [125, 125, 125, 50, 50, 125];

        % 保存结构体
        S.(subjName) = struct( ...
            'id', i, ...
            'samplingRate', samplingRates, ...
            'channelNames', {channelNames}, ...
            'preprocessed_data', {preprocessedCell}, ...
            'features', {featureCell}, ...
            'labels', labelsMatrix ...
        );
    end
end
