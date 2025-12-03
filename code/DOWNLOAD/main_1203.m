clc;
close all;
clearvars -except config;

% Add src directory and subdirectories to path
addpath(genpath('src'));

% Load configuration
run('config.m'); % This will load config variables into the workspace


fprintf('--- Sleep Scoring Pipeline - Iteration %d ---\n', CURRENT_ITERATION);

do = false;
if do
% folderpath = 'D:\HuaweiMoveData\Users\Rina\Desktop\signal\CM2013-Signal-Processing-\data\training';
[all_data, all_labels, all_info] = load_all_data(TRAINING_DIR, {'EEG','EMG','EOG'});
%% 

% 2. Preprocessing
CURRENT_ITERATION=2;
preprocessed_data = [];
USE_CACHE = false;
cache_filename_preprocess = sprintf('preprocessed_data_iter%d.mat', CURRENT_ITERATION);
if USE_CACHE
    preprocessed_data = load_cache(cache_filename_preprocess, CACHE_DIR);
end

if isempty(preprocessed_data)
    %[all_data, all_labels, all_info] = load_all_data(folderpath, 'EEG');

    preprocessed_data = preprocess_all_subjects(all_data, all_info);
    if (USE_CACHE == false)
        save_cache(preprocessed_data, cache_filename_preprocess, CACHE_DIR);
    end
end


%% 
 CURRENT_ITERATION=2;
% 3. Feature Extraction
features = [];
cache_filename_features = sprintf('features_iter%d.mat', CURRENT_ITERATION);
USE_CACHE = false;

if USE_CACHE
    features = load_cache(cache_filename_features, CACHE_DIR);
end

if isempty(features)
    features = feature_extraction(preprocessed_data);
    if (USE_CACHE == false)
        save_cache(features, cache_filename_features, CACHE_DIR);
    end
end
end
%% 


% 4.subject struct
S = [];
cache_filename_struct = sprintf('subject_struct_iter%d (5ch).mat', 2); %CURRENT_ITERATION);

if USE_CACHE
     S = load_cache(cache_filename_struct, CACHE_DIR);
end

if isempty(S)
    S = generateSubjectStruct(preprocessed_data, features, all_labels);
    if ~USE_CACHE
        save_cache(S, cache_filename_struct, CACHE_DIR);
    end
end

% ------------------------------------------------------
%%       THIS IS THE ONLY SECTION TO RUN       !!!!!!!!!
% ------------------------------------------------------
if do
all_true = [];
all_pred = [];
% Using LOSO performance testing 
for test_subj = 1:10
    % 默认参数: window=1, cv_ratio=0.2, use_smote=true, N1_label=2, n_smote_new=2000
    [model, Y_test, Y_pred] = run_context_training(S, test_subj);

    % Store results
    all_true = [all_true; Y_test];
    all_pred = [all_pred; Y_pred];

    % Calculate metrics
    accuracy = sum(Y_pred == Y_test) / length(Y_test) * 100;
    confMat = confusionmat(Y_test, Y_pred);

    fprintf('\n=== Test Subject %d Set Performance ===\n', test_subj);
    fprintf('Overall Accuracy: %.2f%%\n', accuracy);
    fprintf('Confusion Matrix:\n');
    disp(confMat);

    % Calculate per-class accuracy
    stage_names = {'Wake', 'N1', 'N2', 'N3', 'REM'};
    fprintf('\nPer-Class Accuracy:\n');
    for stage = 0:4
        idx = (Y_test == stage);
        if sum(idx) > 0
            stage_acc = sum(Y_pred(idx) == Y_test(idx)) / sum(idx) * 100;
            fprintf('  %s: %.2f%% (%d epochs)\n', stage_names{stage+1}, stage_acc, sum(idx));
        end
    end

    fprintf('Subject %d: Accuracy %.2f%%\n', test_subj, mean(Y_pred == Y_test)*100);

    % 6. Visualization
    visualize_results(Y_pred, Y_test);

    % 7. Report Generation
    generate_report(Y_pred, Y_test);
end

% Evaluate after all folds
overall_acc = mean(all_true == all_pred);
fprintf('LOSO mean accuracy: %.2f%%\n', overall_acc*100);

end
%%


model = run_context_get_model(S);





%%
if do
%  CURRENT_ITERATION=2;
% subjectNames = fieldnames(S);
% totalSubjects = numel(subjectNames);
% 
% X_all = [];
% Y_all = [];
% 
% for s = 2:totalSubjects
%     subj = S.(subjectNames{s});
%     featCell = subj.features;     
%     labels = subj.labels(:);      % [nEpochs x 1]
% 
%     % 合并前两个通道特征
%     channelFeatures = [];
%     for ch = 1:5
%         f = featCell{ch};             % [nEpochs x nFeatures]
%         channelFeatures = [channelFeatures, f];  % 水平拼接
%     end
% 
%     % 累加所有 subject
%     X_all = [X_all; channelFeatures];   % [sum_nEpochs x totalFeatures]
%     Y_all = [Y_all; labels];            % [sum_nEpochs x 1]
% end
% X_all_log = log1p(abs(X_all)) .* sign(X_all);  % 保留正负，压缩大数
% X_all_scaled = zscore(X_all_log, 0, 1);       % 列归一化
% 
% fprintf('Total training samples: %d, Total features: %d\n', size(X_all,1), size(X_all,2));

%% 
 tabulate(Y_all)

%% 
 
    % Train the model 
%     model = train_classifier_randomforest(X_all_scaled, Y_all);
%% 

 model_filename = sprintf('model_final_iter%d.mat',  CURRENT_ITERATION);
     save_cache(model, model_filename, CACHE_DIR);
    %load_cache(model, model_filename, CACHE_DIR);
%     %% 
%  CURRENT_ITERATION=2;
% subjectNames = fieldnames(S);
% totalSubjects = numel(subjectNames);
% Y_test = [];
% X_test = [];
% 
% for s = 1:1   % 这里可以改成 1:totalSubjects
%     subj = S.(subjectNames{s});
%     featCell = subj.features;     
%     channelFeatures = [];
%     labels = subj.labels(:);
%     
%     for ch = 1:5
%         f = featCell{ch};             % [nEpochs x nFeatures]
%         channelFeatures = [channelFeatures, f];  % 水平拼接
%     end
% 
%     % 累加所有 subject
%     X_test = [X_test; channelFeatures];   % [sum_nEpochs x totalFeatures]
%     Y_test = [Y_test; labels];
% end
% 
% % 特征处理
% X_test_log = log1p(abs(X_test)) .* sign(X_test);  % 保留正负，压缩大数
% X_test_scaled = zscore(X_test_log, 0, 1);       % 列归一化
% 
% % 预测
% Y_pred = predict(model, X_test_scaled);
% 
% % 混淆矩阵
% confMat = confusionmat(Y_test, Y_pred);
% 
% % 整体准确率
% accuracy = sum(Y_pred == Y_test) / length(Y_test) * 100;
% 
% % 每类准确率
% stage_names = {'Wake', 'N1', 'N2', 'N3', 'REM'};
% num_classes = numel(stage_names);
% per_class_acc = zeros(num_classes,1);
% for stage = 0:4
%     idx = (Y_test == stage);
%     if sum(idx) > 0
%         per_class_acc(stage+1) = sum(Y_pred(idx) == Y_test(idx)) / sum(idx) * 100;
%     end
% end
% 
% % F1 Score
% precision = zeros(num_classes,1);
% recall    = zeros(num_classes,1);
% f1score   = zeros(num_classes,1);
% 
% for stage = 0:4
%     TP = sum(Y_pred == stage & Y_test == stage);
%     FP = sum(Y_pred == stage & Y_test ~= stage);
%     FN = sum(Y_pred ~= stage & Y_test == stage);
%     
%     if TP + FP > 0
%         precision(stage+1) = TP / (TP + FP);
%     else
%         precision(stage+1) = 0;
%     end
%     
%     if TP + FN > 0
%         recall(stage+1) = TP / (TP + FN);
%     else
%         recall(stage+1) = 0;
%     end
%     
%     if precision(stage+1) + recall(stage+1) > 0
%         f1score(stage+1) = 2 * precision(stage+1) * recall(stage+1) / (precision(stage+1) + recall(stage+1));
%     else
%         f1score(stage+1) = 0;
%     end
% end
% 
% macroF1 = mean(f1score);  % 平均 F1 Score (Macro F1)
% 
% % 输出结果
% fprintf('\n=== Test Subject %d Set Performance ===\n', 1);
% fprintf('Overall Accuracy: %.2f%%\n', accuracy);
% fprintf('Confusion Matrix:\n');
% disp(confMat);
% 
% fprintf('\nPer-Class Accuracy:\n');
% for stage = 1:num_classes
%     fprintf('  %s: %.2f%%\n', stage_names{stage}, per_class_acc(stage));
% end
% 
% fprintf('\nPer-Class F1 Score:\n');
% for stage = 1:num_classes
%     fprintf('  %s: F1 = %.3f\n', stage_names{stage}, f1score(stage));
% end
% 
% fprintf('Macro F1 Score: %.3f\n', macroF1);
% 
% 
% 
% 
% 
% 
% %% 
% 
%     % 6. Visualization
%     visualize_results(Y_pred, Y_test);
% 
%     % 7. Report Generation
%     generate_report(Y_pred, Y_test);
% 
%     % fprintf('--- Pipeline Finished ---\n');
% 
% 
% 
% % Evaluate after all folds
% overall_acc = mean(all_true == all_pred);
% fprintf('LOSO mean accuracy: %.2f%%\n', overall_acc*100);
% 
end