function n1_feature_data = extract_n1_unique_features(eeg_cell)
% EXTRACT_N1_UNIQUE_FEATURES - 提取仅用于 N1 的独有特征
%
% 输入:
%   eeg_cell: 1xN cell，每个 cell 是 [nEpochs x nChannels x nSamples]
% 输出:
%   n1_feature_data: 1xN cell，每个 cell [nEpochs x nChannels x nUniqueFeatures]
%
% 特征:
%   1. θ/α 比值
%   2. θ/δ 比值
%   3. β/总功率
%   4. 高频功率 (30-50 Hz)
%   5. 谱熵

n1_feature_data = cell(1, numel(eeg_cell));
try
    fs = evalin('caller', 'fs');
catch
    fs = 125;
    fprintf('Warning: fs not found, using default fs=%d Hz\n', fs);
end

try
    N1_STANDARDIZE = evalin('caller', 'N1_STANDARDIZE');
catch
    N1_STANDARDIZE = true;
end

for subj_idx = 1:numel(eeg_cell)
    subj_data = eeg_cell{subj_idx};
    [nEpochs, nChannels, ~] = size(subj_data);
    
    subj_features = zeros(nEpochs, nChannels, 5); % 5 个独有特征
    
    for epoch_idx = 1:nEpochs
        for ch_idx = 1:nChannels
            epoch_signal = squeeze(subj_data(epoch_idx, ch_idx, :))';
            epoch_signal = double(epoch_signal(:))';
            
            % pwelch 参数
            nperseg = round(4*fs); % 4 秒窗口
            nperseg = min(nperseg, length(epoch_signal));
            noverlap = round(0.5*nperseg);
            if nperseg <= 0
                pxx = zeros(1,1); f = 0;
            else
                window_use = hamming(nperseg);
                nfft = max(256, 2^nextpow2(nperseg));
                [pxx,f] = pwelch(epoch_signal, window_use, noverlap, nfft, fs);
            end
            
            % 频段功率
            delta = bandpower_from_psd(pxx,f,0.5,4);
            theta = bandpower_from_psd(pxx,f,4,8);
            alpha = bandpower_from_psd(pxx,f,8,12);
            beta  = bandpower_from_psd(pxx,f,12,30);
            total_power = bandpower_from_psd(pxx,f,0.5,30);
            high_gamma = bandpower_from_psd(pxx,f,30,50); % 高频功率
            
            % N1 独有特征
            theta_alpha = theta / (alpha+eps);
            theta_delta = theta / (delta+eps);
            beta_ratio = beta / (total_power+eps);
            
            % 谱熵
            pxx_norm = pxx ./ (sum(pxx)+eps);
            spectral_entropy = -sum(pxx_norm .* log(pxx_norm + eps));
            
            subj_features(epoch_idx, ch_idx, :) = [theta_alpha, theta_delta, beta_ratio, high_gamma, spectral_entropy];
        end
    end
    
    % z-score 标准化
    if N1_STANDARDIZE
        X = reshape(subj_features, [], 5);
        mu = mean(X,1); sigma = std(X,[],1)+eps;
        Xz = (X - mu) ./ sigma;
        subj_features = reshape(Xz, nEpochs, nChannels, 5);
    end
    
    n1_feature_data{subj_idx} = subj_features;
end

fprintf('\n=== N1-unique features extracted (zscore=%s) for all subjects ===\n', ternary(N1_STANDARDIZE,'true','false'));

end

%% ---------------- 子函数 ----------------
function bp = bandpower_from_psd(pxx,f,fmin,fmax)
idx = find(f>=fmin & f<=fmax);
if isempty(idx)
    bp = 0;
else
    bp = trapz(f(idx), pxx(idx));
end
end

function out = ternary(cond, a, b)
if cond, out=a; else, out=b; end
end
