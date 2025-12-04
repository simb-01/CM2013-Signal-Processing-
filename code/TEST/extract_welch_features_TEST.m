function feature_data = extract_welch_features_TEST(data)

    feature_data = [];
    fs = 125;

    WELCH_KEEP_EXTRA = false;

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

    win_sec = 4;
    bands = [0.5 4; 4 8; 8 12; 12 30];
    nBands = size(bands,1);

    if WELCH_KEEP_EXTRA
        nFreqFeatures = nBands + nBands + 3; % band_powers + rel_powers + (entropy, peak, edge)
    else
        nFreqFeatures = nBands + nBands; % 仅 band_powers + rel_powers
    end

    nrEpochs = size(data, 1);    

    for epoch_idx = 1:nrEpochs
        epoch_signal = data(epoch_idx, :)';       
        nperseg = round(win_sec*fs);
        nperseg = min(nperseg, length(epoch_signal));
        noverlap = round(0.5*nperseg);
        if nperseg <= 0
            pxx = zeros(1,1);
            f = 0;
        else                  
            window_use = hamming(nperseg);                  
            nfft = max(256, 2^nextpow2(nperseg));                   
            [pxx,f] = pwelch(epoch_signal, window_use, noverlap, nfft, fs);
        end
            
        band_powers = zeros(1, nBands); 
        for b = 1:nBands
           band_powers(b) = bandpower_from_psd(pxx,f,bands(b,1),bands(b,2));
        end
                
        total_power = bandpower_from_psd(pxx,f,0.5,30);
        rel_powers = band_powers ./ (total_power + eps);
                           
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
              
        feature_data(epoch_idx, :) = freq_feats;        
    end      
end

%     F = subj_features; % nEpochs x nChannels x nFreqFeatures
%     % 对绝对功率做 log10
%     for b = 1:nBands
%         F(:,:,b) = log10( squeeze(F(:,:,b)) + eps );
%     end
% 
%     % z-score 标准化：按 feature 维度在 (epochs * channels) 上做统计
%     if WELCH_STANDARDIZE
%         X = reshape(F, [], nFreqFeatures); % (nEpochs*nChannels) x nFreqFeatures
%         if WELCH_GLOBAL_STATS
%             % 使用 caller 提供的 WELCH_MU / WELCH_SIGMA
%             mu = WELCH_MU;
%             sigma = WELCH_SIGMA;
%             if numel(mu) ~= nFreqFeatures || numel(sigma) ~= nFreqFeatures
%                 error('WELCH_MU / WELCH_SIGMA length mismatch with nFreqFeatures');
%             end
%         else
%             % 在当前 subject 上计算 mu/sigma
%             mu = mean(X,1);
%             sigma = std(X,[],1) + eps;
%             % 将 mu/sigma 回写到 caller workspace（便于调试/外部查看）
%             try
%                 assignin('caller', sprintf('WELCH_MU_SUBJ_%d', subj_idx), mu);
%                 assignin('caller', sprintf('WELCH_SIGMA_SUBJ_%d', subj_idx), sigma);
%             catch
%                 % ignore
%             end
%         end
%         Xz = (X - mu) ./ sigma;
%         F = reshape(Xz, nrEpochs, nrChannels, nFreqFeatures);
%     end
% 
%     feature_data{subj_idx} = F;
% end
% 
% fprintf('\n=== Welch features extracted (log + %s) for all subjects ===\n', ...
%     ternary(WELCH_STANDARDIZE, 'zscore', 'no-zscore'));
% 
% end

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
