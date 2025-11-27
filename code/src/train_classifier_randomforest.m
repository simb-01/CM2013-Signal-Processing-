function [model] = train_classifier_randomforest(features, labels)
% train_classifier1  使用随机森林（Bagged trees）训练分类器
%   输入:
%       features - N-by-D 特征矩阵
%       labels   - N-by-1 标签向量（可为数值或分类）
%   输出:
%       model    - 返回的分类模型（ClassificationEnsemble）

X_train = features;
Y_train = labels(:);

% 读取可选的随机森林参数（如果在调用者 workspace 中存在）
try
    RF_NumTrees = evalin('caller', 'RF_NumTrees');
catch
    RF_NumTrees = 100; % 默认树数量
end
try
    RF_MaxNumSplits = evalin('caller', 'RF_MaxNumSplits'); % 控制树的最大分裂数（复杂度）
catch
    RF_MaxNumSplits = []; % 空表示使用默认（完全生长）
end
try
    RF_MinLeafSize = evalin('caller', 'RF_MinLeafSize');
catch
    RF_MinLeafSize = 1; % 每个叶子的最小样本数
end

% 计算类别权重 / 样本权重（保持与你原来 SVM 的加权逻辑类似）
classNames = unique(Y_train);
counts = histc(Y_train, classNames);
classWeights = max(counts)./counts;  % 少数类权重更高
sampleWeights = zeros(size(Y_train));
for i = 1:numel(classNames)
    sampleWeights(Y_train == classNames(i)) = classWeights(i);
end

% 创建决策树基础学习器的模板
if isempty(RF_MaxNumSplits)
    t = templateTree('MinLeafSize', RF_MinLeafSize); 
else
    t = templateTree('MaxNumSplits', RF_MaxNumSplits, 'MinLeafSize', RF_MinLeafSize);
end

% 使用 Bagging (随机森林风格) 训练分类集成
% 使用 'Method','Bag' 与上面定义的模板树
model = fitcensemble(X_train, Y_train, ...
    'Method', 'Bag', ...
    'Learners', t, ...
    'NumLearningCycles', RF_NumTrees, ...
    'ClassNames', classNames, ...
    'Weights', sampleWeights, ...
    'Prior', 'uniform');

fprintf('Random Forest (Bagged trees) trained: NumTrees=%d, MaxNumSplits=%s, MinLeafSize=%g\n', ...
    RF_NumTrees, mat2str(RF_MaxNumSplits), RF_MinLeafSize);
end
