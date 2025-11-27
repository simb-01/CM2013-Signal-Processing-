%% predict_B_corrected.m
% Predict all samples in B using existing model (no labels needed)

window = 3;                 % context window
CACHE_DIR = './cache';
CURRENT_ITERATION = 2;      % 根据你的模型版本修改

% Load the single model
cache_filename_model_final = sprintf('model_final_iter%d.mat', CURRENT_ITERATION);
model=load_cache(cache_filename_model_final, CACHE_DIR);

if ~exist('B','var')
    error('Variable B not found in workspace.');
end

Y_pred_all = [];

% 获取所有 subject
subjectNames = fieldnames(B);

% 合并所有 subject 的特征
X_all = [];
subj_epoch_counts = [];

for s = 1:numel(subjectNames)
    subjName = subjectNames{s};
    subj = B.(subjName);
    if ~isfield(subj,'features')
        warning('Subject %s missing features, skipping', subjName);
        continue;
    end
    featCell = subj.features;
    channelFeatures = [];
    for ch = 1:5
        channelFeatures = [channelFeatures, featCell{ch}];
    end
    X_all = [X_all; channelFeatures];
    subj_epoch_counts = [subj_epoch_counts; size(channelFeatures,1)];
end

% 归一化
X_all_log = log1p(abs(X_all)) .* sign(X_all);
X_all_scaled = zscore(X_all_log, 0, 1);

% 上下文拼接
X_ctx = make_context_features(X_all_scaled, window, subj_epoch_counts);

% 预测
Y_pred_all = predict(model, X_ctx);

fprintf('Total predicted samples: %d\n', numel(Y_pred_all));



%% ------------------ 上下文拼接函数 ------------------
function X_ctx = make_context_features(X_all, window, subj_epoch_counts)
N = size(X_all,1); D = size(X_all,2); W = window;
X_ctx = zeros(N, D*(2*W+1));
starts = cumsum([1; subj_epoch_counts(1:end-1)]);
ends   = cumsum(subj_epoch_counts);
for s=1:numel(starts)
    sidx = starts(s); eidx = ends(s);
    for i=sidx:eidx
        block = zeros(1, D*(2*W+1));
        pos = 1;
        for t=-W:W
            j = i+t;
            if j<sidx || j>eidx
                block(pos:pos+D-1)=0;
            else
                block(pos:pos+D-1)=X_all(j,:);
            end
            pos = pos+D;
        end
        X_ctx(i,:) = block;
    end
end
end
