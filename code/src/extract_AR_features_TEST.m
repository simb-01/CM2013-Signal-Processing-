function feature_data = extract_AR_features_TEST(data)

    feature_data = [];
    bands = [0.5 4; 4 8; 8 13; 13 30; 30 50];  % Delta, Theta, Alpha, Beta, Gamma
    nrBands = size(bands,1);
    Fs = 125;
    order = 16;
    nfft = 1024;
    threshold = 0.95;
    nrFeatures = 13;


    nrEpochs = size(data, 1);    

        absPower = zeros(nrEpochs, nrBands);
        relPower = zeros(nrEpochs, nrBands);
        SEF = zeros(nrEpochs, 1);
        peakFreq = zeros(nrEpochs, 1);
        spectralEntropy = zeros(nrEpochs, 1);

        for epoch_idx = 1:nrEpochs
        epoch_signal = data(epoch_idx, :)';       
        epoch_signal = epoch_signal - mean(epoch_signal);
                [pxx, f] = pburg(epoch_signal, order, nfft, Fs);


                [~, idx_peak] = max(pxx);
                peakFreq(epoch_idx, 1) = f(idx_peak);

                p = pxx / sum(pxx);
                p(p == 0) = eps;  

                specEn_norm = -sum(p .* log2(p)) / log2(length(p));

                spectralEntropy(epoch_idx, 1) = specEn_norm;
            
                cumulative_power = cumsum(pxx);
                total_power = cumulative_power(end);

                cumulative_power_norm = cumulative_power/total_power;

                SEF_idx = find(cumulative_power_norm >= threshold, 1, 'first');
                SEF(epoch_idx, 1) = f(SEF_idx);

          
                for band_idx = 1:nrBands
                    idx = f >= bands(band_idx, 1) & f < bands(band_idx, 2);
                    absPower(epoch_idx, band_idx) = trapz(f(idx), pxx(idx));
                end
            
                totalPower = sum(squeeze(absPower(epoch_idx, :)));

                for band_idx = 1:nrBands
                    relPower(epoch_idx, band_idx) = absPower(epoch_idx, band_idx)/totalPower;
                end
        end

        feature_data = cat(2, absPower, relPower, SEF, peakFreq, spectralEntropy);
    
end
