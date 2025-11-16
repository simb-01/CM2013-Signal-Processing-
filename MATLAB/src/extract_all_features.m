function feature_data = extract_all_features(data)
    feature_data = [];
    nrFeatures = 16;
    nrSubjects = numel(data);

    for subject_idx = 1:nrSubjects 
        fprintf('\n=== Starting feature extraction of Subject %d ===\n', subject_idx);

        current_subject_data = data{subject_idx};
        nrEpochs = size(current_subject_data, 1);
        nrChannels = size(current_subject_data, 2);
        subject_features = zeros(nrEpochs, nrChannels, nrFeatures);
    
        for epoch_idx = 1:nrEpochs
            for channel_idx = 1:nrChannels
                epoch_signal = squeeze(current_subject_data(epoch_idx, channel_idx, :));
                epoch_features = extract_time_domain_features_per_epoch(epoch_signal)';
                subject_features(epoch_idx, channel_idx, :) = epoch_features;
            end
        end
        feature_data{subject_idx} = subject_features;
        fprintf('\n=== Feature extraction of Subject %d complete===\n', subject_idx);
    end

    function features = extract_time_domain_features_per_epoch(epoch)
        features = [
        mean(epoch),                % Mean
        median(epoch),              % Median
        std(epoch),                 % Standard Deviation
        var(epoch),                 % Variance
        rms(epoch),                 % Root Mean Square
        min(epoch),                 % Minimum
        max(epoch),                 % Maximum
        range(epoch),               % Range (Peak to Peak)
        skewness(epoch),            % Skewness
        kurtosis(epoch),            % Kurtosis
        zero_crossings(epoch),      % Zero Crossings
        hjorth_activity(epoch),     % Hjorth Activity
        hjorth_mobility(epoch),     % Hjorth Mobility
        hjorth_complexity(epoch),   % Hjorth Complexity
        sum(epoch.^2),              % Total Signal Energy
        sampen(epoch, 2, 0.2)       % Sample Entropy   
        ];
    end

    function features = extract_time_domain_features_per_channel(data, CURRENT_ITERATION)

        n_epochs = size(data, 1);
        n_features_per_epoch = 16;
        features = zeros(n_epochs, n_features_per_epoch);

        for i = 1:n_epochs
            epoch = data(i, :);
            features(i, :) = extract_time_domain_features_per_epoch(epoch);
        end
    end

    function rms_val = rms(signal)
        rms_val = sqrt(mean(signal.^2));
    end

    function zeroCrossings = zero_crossings(epoch)
        zeroCrossings = sum(diff(sign(epoch)) ~= 0);
    end

    function hjorthActivity = hjorth_activity(epoch)
        hjorthActivity = var(epoch);
    end

    function hjorthMobility = hjorth_mobility(epoch)
        a = var(diff(epoch));
        b = var(epoch);
        hjorthMobility = sqrt(a/b);
    end

    function hjorthComplexity = hjorth_complexity(epoch)
        a = hjorth_mobility(diff(epoch));
        b = hjorth_mobility(epoch);
        hjorthComplexity = a/b;
    end

% ----------------------------------------------------------------------- %
%                           H    Y    D    R    A                         %
% ----------------------------------------------------------------------- %
% Function 'sampen' computes the Sample Entropy of a given signal.        %
%                                                                         %
%   Input parameters:                                                     %
%       - signal:       Signal vector with dims. [1xN]                    %
%       - m:            Embedding dimension (m < N).                      %
%       - r:            Tolerance (percentage applied to the SD).         %
%       - dist_type:    (Optional) Distance type, specified by a string.  %
%                       Default value: 'chebychev' (type help pdist for   %
%                       further information).                             %
%                                                                         %
%   Output variables:                                                     %
%       - value:        SampEn value. Since SampEn is not defined whenever%
%                       B = 0, the output value in that case is NaN.      %
% ----------------------------------------------------------------------- %
% NOTE: THIS CODE IS CREDITED TO VICTOR MARTÍNEZ-CAGIGAL

    function value = sampen(signal, m, r, dist_type)

        % Error detection and defaults
        if nargin < 3 
            error('Not enough parameters.');
        end
        if nargin < 4
            dist_type = 'chebychev';
        end
        if ~isvector(signal)
            error('The signal parameter must be a vector.');
        end
        if ~ischar(dist_type)
            error('Distance must be a string.');
        end
        if m > length(signal)
            error('Embedding dimension must be smaller than the signal length (m<N).');
        end
    
        % Useful parameters
        signal = signal(:)';
        N = length(signal);     % Signal length
        sigma = std(signal);    % Standard deviation
    
        % Create the matrix of matches
        matches = NaN(m+1,N);
        for i = 1:1:m+1
            matches(i,1:N+1-i) = signal(i:end);
        end
        matches = matches';

        % Check the matches for m
        d_m = pdist(matches(:,1:m), dist_type);
        if isempty(d_m)
            % If B = 0, SampEn is not defined: no regularity detected
            %   Note: Upper bound is returned
            value = Inf;
        else
            % Check the matches for m+1
            d_m1 = pdist(matches(:,1:m+1), dist_type);
        
            % Compute A and B
            %   Note: logical operations over NaN values are always 0
            B = sum(d_m  <= r*sigma);
            A = sum(d_m1 <= r*sigma);

            % Sample entropy value
            %   Note: norm. comes from [nchoosek(N-m+1,2)/nchoosek(N-m,2)]
            value = -log((A/B)*((N-m+1)/(N-m-1))); 
        end
    
        % If A=0 or B=0, SampEn would return an infinite value. However, the
        % lowest non-zero conditional probability that SampEn should
        % report is A/B = 2/[(N-m-1)(N-m)]
        if isinf(value)
            % Note: SampEn has the following limits:
            %       - Lower bound: 0
            %       - Upper bound: log(N-m)+log(N-m-1)-log(2)
            value = -log(2/((N-m-1)*(N-m)));
        end
    end
    fprintf('\n=== All features extracted! ===\n');
end