function [model, Y_test, Y_pred] = run_context_training_TEST(subjects_data, test_subj_idx)

%% ---------------- Parameters ----------------
window = 3;            % context window ±window
cv_ratio = 0.2;        % validation ratio
use_smote = true;      % SMOTE-like augmentation
N1_label = 1;          % rare class label
n_smote_new = 4000;    % number of new SMOTE samples
smote_k = 10;          % SMOTE neighbors
rf_numTrees = 300;     % random forest trees
rf_minLeaf = 5;        % minimum leaf size

numSubjects = numel(subjects_data);
fprintf('Running optimized context training: window=%d, cv_ratio=%.2f, use_smote=%d\n', window, cv_ratio, use_smote);

%% ---------------- 1) Merge all subjects' features ----------------
X_all = [];
Y_all = [];
subj_epoch_counts = [];

for s = 1:numSubjects
    subj = subjects_data{s};
    if ~isfield(subj,'features') || ~isfield(subj,'labels')
        continue;
    end
    
    featCell = subj.features;           % 1×B cell array (channels)
    labels = subj.labels(:);            % nEpochs × 1
    channelFeatures = [];
    
    % Concatenate all channels horizontally
    for ch = 1:numel(featCell)
        channelFeatures = [channelFeatures, featCell{ch}];
    end
    
    X_all = [X_all; channelFeatures];
    Y_all = [Y_all; labels];
    subj_epoch_counts = [subj_epoch_counts; size(channelFeatures,1)];
end

% Map each epoch to a subject index
subject_idx = [];
for s = 1:numel(subj_epoch_counts)
    subject_idx = [subject_idx; repmat(s, subj_epoch_counts(s), 1)];
end

fprintf('Merged features: total samples=%d, total features=%d, subjects=%d\n', ...
        size(X_all,1), size(X_all,2), numSubjects);
tabulate(Y_all);

%% ---------------- 2) Normalize ----------------
X_all_log = log1p(abs(X_all)) .* sign(X_all);  % log-transform preserving sign
X_all_scaled = zscore(X_all_log,0,1);

%% ---------------- 3) Context window ----------------
X_ctx = make_context_features(X_all_scaled, window, subj_epoch_counts);
fprintf('Context features: samples=%d, features=%d (window=%d)\n', size(X_ctx,1), size(X_ctx,2), window);

%% ---------------- 4) Leave-One-Subject-Out split ----------------
rng(0);

test_subj = test_subj_idx;                   % index of test subject
test_idx  = (subject_idx == test_subj);
train_idx = ~test_idx;

X_train = X_ctx(train_idx,:);
Y_train = Y_all(train_idx);
X_test  = X_ctx(test_idx,:);
Y_test  = Y_all(test_idx);

fprintf('LOSO: test subject = %d, train samples = %d, test samples = %d\n', ...
        test_subj, sum(train_idx), sum(test_idx));
fprintf('Original training distribution (LOSO):\n');
tabulate(Y_train);

%% ---------------- 5) Oversampling ----------------
if use_smote
    fprintf('Applying SMOTE-like augmentation for class %d, n_new=%d, k=%d ...\n', N1_label, n_smote_new, smote_k);
    [X_bal, Y_bal] = smote_like(X_train, Y_train, N1_label, n_smote_new, smote_k);
else
    fprintf('Applying simple oversample ...\n');
    [X_bal, Y_bal] = oversample_n1(X_train,Y_train);
end
fprintf('After augmentation training distribution:\n'); tabulate(Y_bal);

%% ---------------- 6) Train Random Forest ----------------
Y_bal_str = cellstr(num2str(Y_bal));           
classes_bal_str = unique(Y_bal_str);

% compute class weights
nSamplesPerClass = histc(Y_bal, unique(Y_bal));
classWeights = max(nSamplesPerClass)./nSamplesPerClass;
weightsVec = zeros(size(Y_bal));
for i = 1:numel(classes_bal_str)
    weightsVec(Y_bal==str2double(classes_bal_str{i})) = classWeights(i);
end

model = TreeBagger(rf_numTrees, X_bal, Y_bal_str, ...
    'OOBPrediction','on', 'MinLeafSize', rf_minLeaf, ...
    'ClassNames', classes_bal_str, 'Weights', weightsVec);

%% ---------------- 7) Test ----------------
Y_pred_str = predict(model, X_test);
Y_pred = str2double(Y_pred_str);

[C, order] = confusionmat(Y_test,Y_pred);
disp('Confusion matrix (rows=true, cols=pred):'); disp(C);

nClasses = numel(order);
prec = zeros(nClasses,1); rec = zeros(nClasses,1); f1 = zeros(nClasses,1); support = zeros(nClasses,1);
for i=1:nClasses
    TP = C(i,i);
    FN = sum(C(i,:)) - TP;
    FP = sum(C(:,i)) - TP;
    prec(i) = TP/(TP+FP+eps);
    rec(i)  = TP/(TP+FN+eps);
    f1(i)   = 2*prec(i)*rec(i)/(prec(i)+rec(i)+eps);
    support(i) = sum(C(i,:));
end

fprintf('\nPer-Class Accuracy (recall):\n');
for i=1:nClasses
    fprintf('  Class %d: %.2f%% (support=%d)\n', order(i), rec(i)*100, support(i));
end

fprintf('\nPer-Class F1 Score:\n');
for i=1:nClasses
    fprintf('  Class %d: F1 = %.3f\n', order(i), f1(i));
end

macroF1 = mean(f1);
overallAcc = sum(diag(C))/sum(C(:));
fprintf('\nOverall Accuracy: %.2f%%\n', overallAcc*100);
fprintf('Macro F1 Score: %.3f\n', macroF1);

%% ---------------- 8) Save model ----------------
CURRENT_ITERATION = 3;
CACHE_DIR = 'new_cache/';
model_filename = sprintf('model_testedOnSubj%d_iter%d.mat', test_subj, CURRENT_ITERATION);
save_cache(model, model_filename, CACHE_DIR);

%% ---------------- 9) Plot confusion matrix ----------------
figure;
imagesc(C); colormap('hot'); colorbar;
xlabel('Predicted'); ylabel('True');
title(sprintf('Confusion Matrix (Acc %.2f%%, MacroF1 %.3f)', overallAcc*100, macroF1));
set(gca,'XTick',1:nClasses,'XTickLabel',compose('P%d',order));
set(gca,'YTick',1:nClasses,'YTickLabel',compose('T%d',order));
textStrings = strtrim(cellstr(num2str(C(:))));
[xm, ym] = meshgrid(1:nClasses); text(xm(:), ym(:), textStrings(:),'HorizontalAlignment','center');
set(gca,'YDir','reverse');

end

%% ==================== Helper functions ====================

function X_ctx = make_context_features(X_all, window, subj_epoch_counts)
N = size(X_all,1); D = size(X_all,2); W = window;
X_ctx = zeros(N,D*(2*W+1));
starts = cumsum([1; subj_epoch_counts(1:end-1)]);
ends   = cumsum(subj_epoch_counts);
for s=1:numel(starts)
    sidx = starts(s); eidx = ends(s);
    for i = sidx:eidx
        block = zeros(1,D*(2*W+1));
        pos=1;
        for t=-W:W
            j=i+t;
            if j<sidx || j>eidx
                block(pos:pos+D-1)=0;
            else
                block(pos:pos+D-1)=X_all(j,:);
            end
            pos=pos+D;
        end
        X_ctx(i,:) = block;
    end
end
end

function [X_aug, y_aug] = smote_like(X,y,target_class,n_new,k)
if nargin<4, n_new=1000; end
if nargin<5, k=5; end
idx = find(y==target_class);
Xc = X(idx,:);
n_c = size(Xc,1);
if n_c<2, X_aug=X; y_aug=y; warning('Too few target samples for SMOTE.'); return; end
[idxNN, ~] = knnsearch(Xc,Xc,'K',min(k+1,n_c));
idxNN = idxNN(:,2:end);
Xnew = zeros(n_new,size(X,2));
for i=1:n_new
    s = randi(n_c);
    neigh = idxNN(s, randi(size(idxNN,2)));
    gap = rand(1,size(X,2));
    Xnew(i,:) = Xc(s,:) + gap.*(Xc(neigh,:)-Xc(s,:));
end
X_aug = [X; Xnew];
y_aug = [y; repmat(target_class,n_new,1)];
end

function [X_bal, y_bal] = oversample_n1(X,y)
classes = unique(y); nPerClass=histc(y,classes); maxN=max(nPerClass);
X_bal=[]; y_bal=[];
for i=1:length(classes)
    idx = find(y==classes(i)); Xi=X(idx,:); yi=y(idx);
    repeat = ceil(maxN/numel(idx));
    X_bal=[X_bal; repmat(Xi,repeat,1)];
    y_bal=[y_bal; repmat(yi,repeat,1)];
end
end
