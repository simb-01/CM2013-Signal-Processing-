function feature_data = extract_n1_unique_features_TEST(data)
    fs = 125;
    nrFeatures = 5;
    try
        N1_STANDARDIZE = evalin('caller', 'N1_STANDARDIZE');
    catch
        N1_STANDARDIZE = true;
    end

    nrEpochs = size(data, 1);    
    
    feature_data = zeros(nrEpochs, nrFeatures);


    for epoch_idx = 1:nrEpochs
        epoch_signal = data(epoch_idx, :)';
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

        delta = bandpower_from_psd(pxx,f,0.5,4);
        theta = bandpower_from_psd(pxx,f,4,8);
        alpha = bandpower_from_psd(pxx,f,8,12);
        beta  = bandpower_from_psd(pxx,f,12,30);
        total_power = bandpower_from_psd(pxx,f,0.5,30);
        high_gamma = bandpower_from_psd(pxx,f,30,50);

        theta_alpha = theta / (alpha+eps);
        theta_delta = theta / (delta+eps);
        beta_ratio = beta / (total_power+eps);

        pxx_norm = pxx ./ (sum(pxx)+eps);
        spectral_entropy = -sum(pxx_norm .* log(pxx_norm + eps));

        feature_data(epoch_idx, :) = [theta_alpha, theta_delta, beta_ratio, high_gamma, spectral_entropy];
    end
    
 
    % 
    % % z-score 标准化
    % if N1_STANDARDIZE
    %     X = reshape(subj_features, [], 5);
    %     mu = mean(X,1); sigma = std(X,[],1)+eps;
    %     Xz = (X - mu) ./ sigma;
    %     subj_features = reshape(Xz, nEpochs, nChannels, 5);
    % end
    % 
    % feature_data{subj_idx} = subj_features;


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
