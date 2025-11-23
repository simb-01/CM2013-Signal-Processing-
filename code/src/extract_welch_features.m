% function feature_data = extract_welch_features(eeg_cell)
% % EXTRACT_WELCH_FEATURES - 提取 Welch 频域特征
% %
% % 输入:
% %   eeg_cell: 1xN cell，每个 cell 是 [nEpochs x nChannels x nSamples]
% % 输出:
% %   feature_data: 1xN cell，每个 cell [nEpochs x nChannels x nFreqFeatures]
% %
% % 这个文件包含所需的辅助子函数：bandpower_from_psd, spectral_edge_frequency
% 
% feature_data = cell(1, numel(eeg_cell));
% 
% try
%     fs = evalin('caller', 'fs');
% catch
%     fs = 125; % 默认采样率
%     fprintf('Warning: fs not found, using default fs=%d Hz\n', fs);
% end
% 
% % Welch 参数
% win_sec = 4;
% bands = [0.5 4; 4 8; 8 12; 12 30];
% nFreqFeatures = length(bands)*2 + 3; % 带功率 + 相对功率 + 谱熵/峰值/谱边缘
% 
% for subj_idx = 1:numel(eeg_cell)
%     subj_data = eeg_cell{subj_idx};   % [nEpochs x nChannels x nSamples]
%     [nEpochs, nChannels, ~] = size(subj_data);
%     
%     % 输出三维 [nEpochs x nChannels x nFreqFeatures]
%     subj_features = zeros(nEpochs, nChannels, nFreqFeatures);
%     
%     for epoch_idx = 1:nEpochs
%         for ch_idx = 1:nChannels
%             epoch_signal = squeeze(subj_data(epoch_idx, ch_idx, :))';
%             epoch_signal = double(epoch_signal(:))'; % 行向量，确保类型
%             
%             % pwelch 参数（自动退化到信号长度）
%             nperseg = round(win_sec*fs);
%             nperseg = min(nperseg, length(epoch_signal));
%             noverlap = round(0.5*nperseg);
%             window_use = hamming(nperseg);
%             [pxx,f] = pwelch(epoch_signal, window_use, noverlap, [], fs);
%             
%             % 带功率
%             band_powers = zeros(1, size(bands,1));
%             for b = 1:size(bands,1)
%                 band_powers(b) = bandpower_from_psd(pxx,f,bands(b,1),bands(b,2));
%             end
%             total_power = bandpower_from_psd(pxx,f,0.5,30);
%             rel_powers = band_powers / (total_power + eps);
%             
%             % 谱熵 / 峰值 / 谱边缘
%             pxx_norm = pxx / (sum(pxx)+eps);
%             spectral_entropy = -sum(pxx_norm .* log(pxx_norm + eps));
%             [~, idxmax] = max(pxx);
%             peak_freq = f(idxmax);
%             spectral_edge = spectral_edge_frequency(pxx, f, 0.95);
%             
%             freq_feats = [band_powers, rel_powers, spectral_entropy, peak_freq, spectral_edge];
%             
%             % 存入三维矩阵
%             subj_features(epoch_idx, ch_idx, :) = freq_feats;
%         end
%     end
%     feature_data{subj_idx} = subj_features;
% end
% 
% fprintf('\n=== Welch features extracted for all subjects ===\n');
% 
% end
% 
% %% ----------------- 子函数: 计算带功率 -----------------
% function bp = bandpower_from_psd(pxx,f,fmin,fmax)
% % 使用 trapezoidal rule 在 PSD 上积分得到 band power
% idx = find(f>=fmin & f<=fmax);
% if isempty(idx)
%     bp = 0;
% else
%     bp = trapz(f(idx), pxx(idx));
% end
% end
% 
% %% ----------------- 子函数: 计算谱边缘频率 -----------------
% function edge_freq = spectral_edge_frequency(pxx,f,quantile)
% % 找到频率使累计归一化功率达到 quantile（例如 0.95）
% pxx_norm = pxx ./ (sum(pxx)+eps);
% cumulative = cumsum(pxx_norm);
% idx = find(cumulative >= quantile, 1);
% if isempty(idx)
%     edge_freq = f(end);
% else
%     edge_freq = f(idx);
% end
% end
function feature_data = extract_welch_features(eeg_cell)
% EXTRACT_WELCH_FEATURES - 提取 Welch 频域特征（含 log + zscore 标准化）
%
% 输入:
%   eeg_cell: 1xN cell，每个 cell 是 [nEpochs x nChannels x nSamples]
% 输出:
%   feature_data: 1xN cell，每个 cell [nEpochs x nChannels x nFreqFeatures]
%
% 可选 caller workspace 参数:
%   fs (default 125)
%   WELCH_STANDARDIZE (default true) - 是否对特征做 zscore
%   WELCH_GLOBAL_STATS (default false) - 若 true 使用 caller 中的 WELCH_MU / WELCH_SIGMA
%   WELCH_MU, WELCH_SIGMA (用于 GLOBAL 标准化，shape = [1 x nFeatures])
%   WELCH_KEEP_EXTRA (default true) - 是否保留 spectral_entropy / peak_freq / spectral_edge
%
% 说明:
%   - 绝对带功率会先做 log10(x + eps) 以压缩长尾。
%   - z-score 默认在每个 subject 内计算（避免一次性用全部 subject 的统计量，除非设置 WELCH_GLOBAL_STATS=true 并提供 WELCH_MU/WELCH_SIGMA）。
%   - 如果你要在训练/测试间保持一致，请在训练阶段计算 WELCH_MU/WELCH_SIGMA 并传入测试阶段。

% ---------------- 参数和默认 ----------------
feature_data = cell(1, numel(eeg_cell));
try
    fs = evalin('caller', 'fs');
catch
    fs = 125;
    fprintf('Warning: fs not found, using default fs=%d Hz\n', fs);
end

% optional flags from caller
try
    WELCH_STANDARDIZE = evalin('caller', 'WELCH_STANDARDIZE');
catch
    WELCH_STANDARDIZE = true;
end
try
    WELCH_GLOBAL_STATS = evalin('caller', 'WELCH_GLOBAL_STATS');
catch
    WELCH_GLOBAL_STATS = false;
end
try
    WELCH_KEEP_EXTRA = evalin('caller', 'WELCH_KEEP_EXTRA');
catch
    WELCH_KEEP_EXTRA = true;
end

% if global stats requested, read them (expect row vectors)
if WELCH_GLOBAL_STATS
    try
        WELCH_MU = evalin('caller', 'WELCH_MU');
        WELCH_SIGMA = evalin('caller', 'WELCH_SIGMA');
        if isempty(WELCH_MU) || isempty(WELCH_SIGMA)
            error('WELCH_MU or WELCH_SIGMA empty');
        end
    catch
        error('WELCH_GLOBAL_STATS=true but WELCH_MU / WELCH_SIGMA not found in caller workspace');
    end
end

% Welch 参数
win_sec = 4;
bands = [0.5 4; 4 8; 8 12; 12 30];
nBands = size(bands,1);

% 计算输出特征数（根据 WELCH_KEEP_EXTRA 决定）
if WELCH_KEEP_EXTRA
    nFreqFeatures = nBands + nBands + 3; % band_powers + rel_powers + (entropy, peak, edge)
else
    nFreqFeatures = nBands + nBands; % 仅 band_powers + rel_powers
end

% ---------------- 主循环 ----------------
for subj_idx = 1:numel(eeg_cell)
    subj_data = eeg_cell{subj_idx};   % [nEpochs x nChannels x nSamples]
    [nEpochs, nChannels, ~] = size(subj_data);
    
    subj_features = zeros(nEpochs, nChannels, nFreqFeatures);
    
    for epoch_idx = 1:nEpochs
        for ch_idx = 1:nChannels
            epoch_signal = squeeze(subj_data(epoch_idx, ch_idx, :))';
            epoch_signal = double(epoch_signal(:))'; % 行向量
            
            % pwelch 参数
            nperseg = round(win_sec*fs);
            nperseg = min(nperseg, length(epoch_signal));
            noverlap = round(0.5*nperseg);
            if nperseg <= 0
                % 处理非常短的信号（防止错误）
                pxx = zeros(1,1);
                f = 0;
            else
                window_use = hamming(nperseg);
                nfft = max(256, 2^nextpow2(nperseg));
                [pxx,f] = pwelch(epoch_signal, window_use, noverlap, nfft, fs);
            end
            
            % 带功率（绝对）
            band_powers = zeros(1, nBands);
            for b = 1:nBands
                band_powers(b) = bandpower_from_psd(pxx,f,bands(b,1),bands(b,2));
            end
            total_power = bandpower_from_psd(pxx,f,0.5,30);
            rel_powers = band_powers ./ (total_power + eps);
            
            % 额外特征（可选）
            if WELCH_KEEP_EXTRA
                pxx_norm = pxx ./ (sum(pxx)+eps);
                spectral_entropy = -sum(pxx_norm .* log(pxx_norm + eps));
                [~, idxmax] = max(pxx);
                if isempty(idxmax)
                    peak_freq = 0;
                else
                    peak_freq = f(idxmax);
                end
                spectral_edge = spectral_edge_frequency(pxx, f, 0.95);
                
                freq_feats = [band_powers, rel_powers, spectral_entropy, peak_freq, spectral_edge];
            else
                freq_feats = [band_powers, rel_powers];
            end
            
            subj_features(epoch_idx, ch_idx, :) = freq_feats;
        end
    end
    
    % ---------------- log + 标准化 ----------------
    % 对绝对带功率列做 log10 变换以压缩长尾：band_powers 为列 1:nBands
    % 特征布局在 freq_feats 中： [band_powers(1:nBands), rel_powers(1:nBands), (opt extras)]
    F = subj_features; % nEpochs x nChannels x nFreqFeatures
    % 对绝对功率做 log10
    for b = 1:nBands
        F(:,:,b) = log10( squeeze(F(:,:,b)) + eps );
    end
    
    % z-score 标准化：按 feature 维度在 (epochs * channels) 上做统计
    if WELCH_STANDARDIZE
        X = reshape(F, [], nFreqFeatures); % (nEpochs*nChannels) x nFreqFeatures
        if WELCH_GLOBAL_STATS
            % 使用 caller 提供的 WELCH_MU / WELCH_SIGMA
            mu = WELCH_MU;
            sigma = WELCH_SIGMA;
            if numel(mu) ~= nFreqFeatures || numel(sigma) ~= nFreqFeatures
                error('WELCH_MU / WELCH_SIGMA length mismatch with nFreqFeatures');
            end
        else
            % 在当前 subject 上计算 mu/sigma
            mu = mean(X,1);
            sigma = std(X,[],1) + eps;
            % 将 mu/sigma 回写到 caller workspace（便于调试/外部查看）
            try
                assignin('caller', sprintf('WELCH_MU_SUBJ_%d', subj_idx), mu);
                assignin('caller', sprintf('WELCH_SIGMA_SUBJ_%d', subj_idx), sigma);
            catch
                % ignore
            end
        end
        Xz = (X - mu) ./ sigma;
        F = reshape(Xz, nEpochs, nChannels, nFreqFeatures);
    end
    
    feature_data{subj_idx} = F;
end

fprintf('\n=== Welch features extracted (log + %s) for all subjects ===\n', ...
    ternary(WELCH_STANDARDIZE, 'zscore', 'no-zscore'));

end

%% ----------------- 子函数: 计算带功率 -----------------
function bp = bandpower_from_psd(pxx,f,fmin,fmax)
idx = find(f>=fmin & f<=fmax);
if isempty(idx)
    bp = 0;
else
    bp = trapz(f(idx), pxx(idx));
end
end

%% ----------------- 子函数: 计算谱边缘频率 -----------------
function edge_freq = spectral_edge_frequency(pxx,f,quantile)
pxx_norm = pxx ./ (sum(pxx)+eps);
cumulative = cumsum(pxx_norm);
idx = find(cumulative >= quantile, 1);
if isempty(idx)
    edge_freq = f(end);
else
    edge_freq = f(idx);
end
end

%% ----------------- 小辅助函数 -----------------
function out = ternary(cond, a, b)
if cond
    out = a;
else
    out = b;
end
end
