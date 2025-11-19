function feature_data = feature_extraction(data)
% FEATURE_EXTRACTION - 时间域 + AR + Welch + DWT 特征提取
%
% 输入:
%   data: 1xN cell，每个 cell [nEpochs x nChannels x nSamples]
% 输出:
%   feature_data: 1xN cell，每个 cell [nEpochs x nFeatures x nChannels]
%
% 可选参数（caller workspace）:
%   EXTRACT_TIME = true/false (是否提取时域特征)
%   CURRENT_ITERATION = 迭代次数（>=2时提取 AR/Welch/DWT）

fprintf('Starting feature extraction...\n');

% ---------------- 获取 CURRENT_ITERATION ----------------
try
    CURRENT_ITERATION = evalin('caller','CURRENT_ITERATION');
catch
    CURRENT_ITERATION = 1;
end
fprintf('Extracting features for iteration %d...\n', CURRENT_ITERATION);

% ---------------- 可选开关：是否提取时域（默认 true） ----------------
try
    EXTRACT_TIME = evalin('caller','EXTRACT_TIME');
catch
    EXTRACT_TIME = true;
end
if ~islogical(EXTRACT_TIME)
    EXTRACT_TIME = logical(EXTRACT_TIME);
end
if EXTRACT_TIME
    fprintf('Time-domain extraction: ENABLED\n');
else
    fprintf('Time-domain extraction: DISABLED\n');
end

nrSubjects = numel(data);
feature_data = cell(1, nrSubjects);

% ---------------- 初始化计时器 ----------------
total_t_time = 0;
total_t_ar   = 0;
total_t_welch= 0;
total_t_dwt  = 0;

% ---------------- 时间域特征 ----------------
time_features_cell = cell(1, nrSubjects);
if EXTRACT_TIME
    t0 = tic;
    fprintf('\nExtracting TIME-DOMAIN features for all subjects...\n');
    time_features_cell = extract_all_features(data); % [nEpochs x nChannels x nTime]
    total_t_time = toc(t0);
    fprintf('Time-domain extraction finished in %.2f s\n', total_t_time);
end

% ---------------- AR / Welch / DWT 特征 ----------------
ar_features_cell    = cell(1,nrSubjects);
welch_features_cell = cell(1,nrSubjects);
dwt_features_cell   = cell(1,nrSubjects);

if CURRENT_ITERATION >= 2
    % AR 特征
    t0 = tic;
    fprintf('\nExtracting AR features for all subjects...\n');
    ar_features_cell = extract_AR_features(data); % [nEpochs x nChannels x 13]
    total_t_ar = toc(t0);
    fprintf('AR extraction finished in %.2f s\n', total_t_ar);

    % Welch 特征
    t0 = tic;
    fprintf('\nExtracting Welch features for all subjects...\n');
    welch_features_cell = extract_welch_features(data); % [nEpochs x nChannels x 11]
    total_t_welch = toc(t0);
    fprintf('Welch extraction finished in %.2f s\n', total_t_welch);

    % DWT 特征
    t0 = tic;
    fprintf('\nExtracting DWT features for all subjects...\n');
    dwt_features_cell = extract_dwt_features(data); % [nEpochs x nChannels x 42]
    total_t_dwt = toc(t0);
    fprintf('DWT extraction finished in %.2f s\n', total_t_dwt);
end

% ---------------- 拼接特征 ----------------
for subj_idx = 1:nrSubjects
    subj_data = data{subj_idx};
    [nEpochs, nChannels, ~] = size(subj_data);

    % 时间域
    if EXTRACT_TIME
        time_feats = time_features_cell{subj_idx};
        nTime = size(time_feats,3);
    else
        time_feats = zeros(nEpochs, nChannels, 0);
        nTime = 0;
    end

    % AR/Welch/DWT
    if CURRENT_ITERATION >= 2
        ar_feats    = ar_features_cell{subj_idx};
        welch_feats = welch_features_cell{subj_idx};
        dwt_feats   = dwt_features_cell{subj_idx};
        nAR    = size(ar_feats,3);
        nWelch = size(welch_feats,3);
        nDWT   = size(dwt_feats,3);
    else
    ar_feats = zeros(nEpochs, nChannels, 0);
    welch_feats = zeros(nEpochs, nChannels, 0);
    dwt_feats = zeros(nEpochs, nChannels, 0);
    nAR = 0;
    nWelch = 0;
    nDWT = 0;
    end

    % 拼接: [nEpochs x nChannels x totalFeaturesPerChannel]
    subj_features = cat(3, time_feats, ar_feats, welch_feats, dwt_feats);
    totalFeaturesPerChannel = size(subj_features,3);
    feature_data{subj_idx} = subj_features;

    % 输出 summary
    fprintf('\nSubject %d summary:\n', subj_idx);
    fprintf('  nEpochs = %d, nChannels = %d\n', nEpochs, nChannels);
    fprintf('  features per epoch per CHANNEL = %d (time=%d, AR=%d, welch=%d, dwt=%d)\n', ...
        totalFeaturesPerChannel, nTime, nAR, nWelch, nDWT);
    fprintf('  subj_features size = [%d x %d x %d]\n', size(subj_features));
end

% ---------------- 总时长统计 ----------------
fprintf('\n=== Timing summary ===\n');
if EXTRACT_TIME
    fprintf('Time-domain total time: %.2f s\n', total_t_time);
else
    fprintf('Time-domain skipped\n');
end
if CURRENT_ITERATION >= 2
    fprintf('AR total time:       %.2f s\n', total_t_ar);
    fprintf('Welch total time:    %.2f s\n', total_t_welch);
    fprintf('DWT total time:      %.2f s\n', total_t_dwt);
end

fprintf('\n=== Feature extraction COMPLETE ===\n');

end
