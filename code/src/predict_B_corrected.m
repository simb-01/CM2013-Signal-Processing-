%% predict_B_corrected.m
% Predict all samples in Subjects using existing model (no labels required)

window = 3;             
CACHE_DIR = './cache';
CURRENT_ITERATION = 3;
cache_model = sprintf('model_final_iter%d.mat',  CURRENT_ITERATION);
model = load_cache(cache_model, CACHE_DIR);


if ~exist('Subjects','var')
    error('Variable Subjects not found in workspace.');
end

Y_pred_all = [];

% --- Merge all subject features ---

C = HoldoutSubjects;  % or HoldoutSubjects, whichever you are predicting on

for i = 1:numel(C)
    fprintf('Subject %d:\n', i);
    for ch = 1:numel(C{i}.features)
        F = C{i}.features{ch};
        if isempty(F)
            fprintf('  ch %d: EMPTY\n', ch);
        else
            fprintf('  ch %d: [%d x %d]\n', ch, size(F,1), size(F,2));
        end
    end
end
numSubjects = numel(HoldoutSubjects);
X_all = [];
subj_epoch_counts = [];

for s = 1:numSubjects
    subj = HoldoutSubjects{s};
    
    if ~isfield(subj, 'features')
        warning('Subject %d missing features, skipping', s);
        continue;
    end
    
    featCell = subj.features;
    channelFeatures = [];
    
    for ch = 1:numel(featCell)
        channelFeatures = [channelFeatures, featCell{ch}];
    end
    
    X_all = [X_all; channelFeatures];
    subj_epoch_counts = [subj_epoch_counts; size(channelFeatures,1)];
end

% --- Normalization ---
X_all_log = log1p(abs(X_all)) .* sign(X_all);
X_all_scaled = zscore(X_all_log, 0, 1);

% --- Context window ---
X_ctx = make_context_features(X_all_scaled, window, subj_epoch_counts);

expected_dim = size(model.X, 2);
current_dim  = size(X_ctx, 2);

fprintf('Model expects features = %d\n', expected_dim);
fprintf('Prediction features    = %d\n', current_dim);

% --- Predict ---
fprintf('Predicting %d samples...\n', size(X_ctx, 1));
Y_pred_all = predict(model, X_ctx);

disp('Prediction completed.');

%% ------------------ Context Feature Construction ------------------
function X_ctx = make_context_features(X_all, window, subj_epoch_counts)
N = size(X_all,1);
D = size(X_all,2);
W = window;
X_ctx = zeros(N, D*(2*W+1));

starts = cumsum([1; subj_epoch_counts(1:end-1)]);
ends   = cumsum(subj_epoch_counts);

for s = 1:numel(starts)
    sidx = starts(s);
    eidx = ends(s);
    
    for i = sidx:eidx
        block = zeros(1, D*(2*W+1));
        pos = 1;
        
        for t = -W:W
            j = i + t;
            if j < sidx || j > eidx
                block(pos:pos+D-1) = 0;
            else
                block(pos:pos+D-1) = X_all(j,:);
            end
            pos = pos + D;
        end
        
        X_ctx(i,:) = block;
    end
end
end
