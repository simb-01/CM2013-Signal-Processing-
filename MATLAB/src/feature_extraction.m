function features = feature_extraction_extract_features(data, config)
%% Extracts features from the preprocessed data based on the current iteration.

fprintf('Extracting features...\n');

if config.CURRENT_ITERATION == 1
    % Iteration 1: Time-domain features
    all_features = zeros(size(data, 1), 3); % Mean, Median, Std
    for i = 1:size(data, 1)
        epoch = data(i, :);
        all_features(i, 1) = mean(epoch);
        all_features(i, 2) = median(epoch);
        all_features(i, 3) = std(epoch);
        % TODO: Add the other 13 time-domain features from the guide
    end
    features = all_features;
elseif config.CURRENT_ITERATION == 2
    % TODO: Implement frequency-domain feature extraction
    fprintf('Warning: No frequency-domain features defined for this iteration. Returning empty features.\n');
    features = zeros(size(data, 1), 0);
else
    % Placeholder for more advanced feature extraction
    fprintf('Warning: No features defined for this iteration. Returning empty features.\n');
    features = zeros(size(data, 1), 0);
end

end
