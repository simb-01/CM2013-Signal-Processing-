function feature_data = extract_dwt_features_TEST(data)

feature_data = [];
fs = 125;
level = 5;

wname = 'db4';

        nEpochs = size(data, 1);    

    nBands = 6; % D1-D5 + A5
    nFeaturesPerBand = 7;
    
    for epoch_idx = 1:nEpochs
        epoch_signal = data(epoch_idx, :)';       
        [C,L] = wavedec(epoch_signal, level, wname);
            
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
            
        feature_data(epoch_idx, :) = feats;        
        
    end

fprintf('\n=== DWT features (7 per band) extracted ===\n');
end
