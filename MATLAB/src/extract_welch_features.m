function feature_data = extract_welch_features(eeg_cell)
% EXTRACT_WELCH_FEATURES - 提取 Welch 频域特征
%
% 输入:
%   eeg_cell: 1xN cell，每个 cell 是 [nEpochs x nChannels x nSamples]
% 输出:
%   feature_data: 1xN cell，每个 cell [nEpochs x nChannels x nFreqFeatures]
%
% 这个文件包含所需的辅助子函数：bandpower_from_psd, spectral_edge_frequency

feature_data = cell(1, numel(eeg_cell));

try
    fs = evalin('caller', 'fs');
catch
    fs = 125; % 默认采样率
    fprintf('Warning: fs not found, using default fs=%d Hz\n', fs);
end

% Welch 参数
win_sec = 4;
bands = [0.5 4; 4 8; 8 12; 12 30];
nFreqFeatures = length(bands)*2 + 3; % 带功率 + 相对功率 + 谱熵/峰值/谱边缘

for subj_idx = 1:numel(eeg_cell)
    subj_data = eeg_cell{subj_idx};   % [nEpochs x nChannels x nSamples]
    [nEpochs, nChannels, ~] = size(subj_data);
    
    % 输出三维 [nEpochs x nChannels x nFreqFeatures]
    subj_features = zeros(nEpochs, nChannels, nFreqFeatures);
    
    for epoch_idx = 1:nEpochs
        for ch_idx = 1:nChannels
            epoch_signal = squeeze(subj_data(epoch_idx, ch_idx, :))';
            epoch_signal = double(epoch_signal(:))'; % 行向量，确保类型
            
            % pwelch 参数（自动退化到信号长度）
            nperseg = round(win_sec*fs);
            nperseg = min(nperseg, length(epoch_signal));
            noverlap = round(0.5*nperseg);
            window_use = hamming(nperseg);
            [pxx,f] = pwelch(epoch_signal, window_use, noverlap, [], fs);
            
            % 带功率
            band_powers = zeros(1, size(bands,1));
            for b = 1:size(bands,1)
                band_powers(b) = bandpower_from_psd(pxx,f,bands(b,1),bands(b,2));
            end
            total_power = bandpower_from_psd(pxx,f,0.5,30);
            rel_powers = band_powers / (total_power + eps);
            
            % 谱熵 / 峰值 / 谱边缘
            pxx_norm = pxx / (sum(pxx)+eps);
            spectral_entropy = -sum(pxx_norm .* log(pxx_norm + eps));
            [~, idxmax] = max(pxx);
            peak_freq = f(idxmax);
            spectral_edge = spectral_edge_frequency(pxx, f, 0.95);
            
            freq_feats = [band_powers, rel_powers, spectral_entropy, peak_freq, spectral_edge];
            
            % 存入三维矩阵
            subj_features(epoch_idx, ch_idx, :) = freq_feats;
        end
    end
    feature_data{subj_idx} = subj_features;
end

fprintf('\n=== Welch features extracted for all subjects ===\n');

end

%% ----------------- 子函数: 计算带功率 -----------------
function bp = bandpower_from_psd(pxx,f,fmin,fmax)
% 使用 trapezoidal rule 在 PSD 上积分得到 band power
idx = find(f>=fmin & f<=fmax);
if isempty(idx)
    bp = 0;
else
    bp = trapz(f(idx), pxx(idx));
end
end

%% ----------------- 子函数: 计算谱边缘频率 -----------------
function edge_freq = spectral_edge_frequency(pxx,f,quantile)
% 找到频率使累计归一化功率达到 quantile（例如 0.95）
pxx_norm = pxx ./ (sum(pxx)+eps);
cumulative = cumsum(pxx_norm);
idx = find(cumulative >= quantile, 1);
if isempty(idx)
    edge_freq = f(end);
else
    edge_freq = f(idx);
end
end
