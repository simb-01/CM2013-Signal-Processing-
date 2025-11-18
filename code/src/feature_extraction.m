% function feature_data = feature_extraction(data)
% % FEATURE_EXTRACTION - 时间域 + Welch + DWT 特征提取
% %
% % 输入:
% %   data: 1xN cell，每个 cell [nEpochs x nChannels x nSamples]
% % 输出:
% %   feature_data: 1xN cell，每个 cell [nEpochs x nFeatures x nChannels]
% 
% % 获取 CURRENT_ITERATION
% try
%     CURRENT_ITERATION = evalin('caller','CURRENT_ITERATION');
% catch
%     CURRENT_ITERATION = 1;
% end
% fprintf('Extracting features for iteration %d...\n', CURRENT_ITERATION);
% 
% nrSubjects = numel(data);
% feature_data = cell(1, nrSubjects);
% 
% % ----------------------
% % 1️⃣ 时间域特征
% % ----------------------
% time_features_cell = extract_all_features(data);  % 输出: 1xN cell, [nEpochs x nChannels x 16]
% 
% if CURRENT_ITERATION >= 2
%     % ----------------------
%     % 2️⃣ Welch 特征
%     % ----------------------
%     welch_features_cell = extract_welch_features(data); % 输出: 1xN cell, [nEpochs x nChannels x 11]
% 
%     % ----------------------
%     % 3️⃣ DWT 特征
%     % ----------------------
%     dwt_features_cell = extract_dwt_features(data);     % 输出: 1xN cell, [nEpochs x nChannels x 42]
% end
% 
% % ----------------------
% % 拼接每个 subject
% % ----------------------
% for subj_idx = 1:nrSubjects
%     time_feats = time_features_cell{subj_idx}; % [nEpochs x nChannels x 16]
%     
%     if CURRENT_ITERATION >=2
%         welch_feats = welch_features_cell{subj_idx}; % [nEpochs x nChannels x 11]
%         dwt_feats   = dwt_features_cell{subj_idx};   % [nEpochs x nChannels x 42]
%         
%         % 沿 feature 维度拼接：nTime + nWelch + nDWT
%         subj_features = cat(3, time_feats, welch_feats, dwt_feats); % [nEpochs x nChannels x totalFeatures]
%     else
%         subj_features = time_feats; % Iteration 1
%     end
%     
%     % 调整输出维度为 [nEpochs x nFeatures x nChannels]
%     feature_data{subj_idx} = permute(subj_features, [1 3 2]);
% end
% 
% fprintf('\n=== Feature extraction complete ===\n');
% end
function feature_data = feature_extraction(data)
% FEATURE_EXTRACTION - 时间域 + Welch + DWT 特征提取（可选跳过时域）
%
% 输入:
%   data: 1xN cell，每个 cell [nEpochs x nChannels x nSamples]
% 输出:
%   feature_data: 1xN cell，每个 cell [nEpochs x nFeatures x nChannels]
%
% 说明：
% - 如果想临时只测试 Welch+DWT，可在 caller workspace 设置：
%       EXTRACT_TIME = false;
%   默认 EXTRACT_TIME = true。
% - 函数会输出每个 subject 的特征维度信息（每通道、每 epoch 的特征数量）
% - 会输出每个方法的大致耗时，便于定位瓶颈

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
    EXTRACT_TIME = false;
end
if ~islogical(EXTRACT_TIME)
    EXTRACT_TIME = logical(EXTRACT_TIME);
end
if EXTRACT_TIME
    fprintf('Time-domain extraction: ENABLED\n');
else
    fprintf('Time-domain extraction: DISABLED (only testing Welch/DWT)\n');
end

nrSubjects = numel(data);
feature_data = cell(1, nrSubjects);

% ---------------- 计时器/统计 ----------------
total_t_time = 0;
total_t_welch = 0;
total_t_dwt = 0;

% ---------------- 如果启用时域，先提取（可能比较慢） ----------------
time_features_cell = cell(1, nrSubjects);
if EXTRACT_TIME
    t0 = tic;
    fprintf('\nStart extracting TIME-DOMAIN features for all subjects...\n');
    time_features_cell = extract_all_features(data);  % 期望输出: 1xN cell, [nEpochs x nChannels x 16]
    total_t_time = toc(t0);
    fprintf('Time-domain extraction finished in %.2f s\n', total_t_time);
else
    % 留空占位，后面直接用 zeros 或跳过
    time_features_cell = cell(1, nrSubjects);
end

% ---------------- Iteration >=2 时提取 Welch / DWT ----------------
if CURRENT_ITERATION >= 2
    % Welch
    t0 = tic;
    fprintf('\nStart extracting WELCH features for all subjects...\n');
    welch_features_cell = extract_welch_features(data); % 1xN cell, [nEpochs x nChannels x 11]
    total_t_welch = toc(t0);
    fprintf('Welch extraction finished in %.2f s\n', total_t_welch);
    
    % DWT
    t0 = tic;
    fprintf('\nStart extracting DWT features for all subjects...\n');
    dwt_features_cell = extract_dwt_features(data);     % 1xN cell, [nEpochs x nChannels x 42]
    total_t_dwt = toc(t0);
    fprintf('DWT extraction finished in %.2f s\n', total_t_dwt);
else
    welch_features_cell = {};
    dwt_features_cell = {};
end

% ---------------- 拼接每个 subject（输出为 [nEpochs x nFeatures x nChannels]） ----------------
for subj_idx = 1:nrSubjects
    subj_data = data{subj_idx};
    [nEpochs, nChannels, ~] = size(subj_data);
    
    % 获取各方法的特征维度（每通道）
    if EXTRACT_TIME
        time_feats = time_features_cell{subj_idx}; % [nEpochs x nChannels x nTime]
        nTime = size(time_feats, 3);
    else
        time_feats = zeros(nEpochs, nChannels, 0);
        nTime = 0;
    end
    
    if CURRENT_ITERATION >= 2
        welch_feats = welch_features_cell{subj_idx}; % [nEpochs x nChannels x nWelch]
        dwt_feats   = dwt_features_cell{subj_idx};   % [nEpochs x nChannels x nDWT]
        nWelch = size(welch_feats, 3);
        nDWT   = size(dwt_feats, 3);
    else
        welch_feats = zeros(nEpochs, nChannels, 0);
        dwt_feats = zeros(nEpochs, nChannels, 0);
        nWelch = 0; nDWT = 0;
    end
    
  subj_features = cat(3, time_feats, welch_feats, dwt_feats); % [nEpochs x nChannels x totalFeaturesPerChannel]
totalFeaturesPerChannel = size(subj_features, 3); % 每个通道特征数

feature_data{subj_idx} = subj_features;   % 输出 [nEpochs x nChannels x nFeatures]

% 输出信息
fprintf('\nSubject %d summary:\n', subj_idx);
fprintf('  nEpochs = %d, nChannels = %d\n', nEpochs, nChannels);
fprintf('  features per epoch per CHANNEL = %d (time=%d, welch=%d, dwt=%d)\n', ...
        totalFeaturesPerChannel, nTime, nWelch, nDWT);
fprintf('  Sanity check: subj_features size = [%d x %d x %d]\n', ...
        size(subj_features,1), size(subj_features,2), size(subj_features,3));

end

% ---------------- 总时长小结 ----------------
fprintf('\n=== Timing summary ===\n');
if EXTRACT_TIME
    fprintf('Time-domain total time: %.2f s\n', total_t_time);
else
    fprintf('Time-domain skipped by EXTRACT_TIME=false\n');
end
if CURRENT_ITERATION >=2
    fprintf('Welch total time: %.2f s\n', total_t_welch);
    fprintf('DWT total time:   %.2f s\n', total_t_dwt);
end

fprintf('\n=== Feature extraction complete ===\n');
end
