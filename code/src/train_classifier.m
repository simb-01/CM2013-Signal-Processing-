function [model] = train_classifier(features, labels)
%% Train classifier - wrapper that accesses config from caller's workspace
try
    CURRENT_ITERATION = evalin('caller', 'CURRENT_ITERATION');
    CLASSIFIER_TYPE = evalin('caller', 'CLASSIFIER_TYPE');
catch
    CURRENT_ITERATION = 1;
    CLASSIFIER_TYPE = 'knn';
end

fprintf('Training %s classifier for iteration %d...\n', CLASSIFIER_TYPE, CURRENT_ITERATION);

X_train = features; 
Y_train = labels(:);         
% [X_train, Y_train, X_test, Y_test] = partition(features, labels);

% Simple classifiers
switch lower(CLASSIFIER_TYPE)
    case 'knn'
        try
            KNN_N_NEIGHBORS = evalin('caller', 'KNN_N_NEIGHBORS');
        catch
            KNN_N_NEIGHBORS = 5;
        end
        model = fitcknn(X_train, Y_train, 'NumNeighbors', KNN_N_NEIGHBORS, 'Standardize',1);
        fprintf('k-NN classifier trained with k=%d\n', KNN_N_NEIGHBORS);
    case 'svm'
    % 获取参数
    try
        SVM_C = evalin('caller', 'SVM_C');
        SVM_KERNEL = evalin('caller', 'SVM_KERNEL');
    catch
        SVM_C = 1.0;
        SVM_KERNEL = 'linear';  % 默认用线性核更稳
    end

    classNames = unique(Y_train);
    counts = histc(Y_train, classNames);
    classWeights = max(counts)./counts;  % 少数类权重更高
    sampleWeights = zeros(size(Y_train));
    for i = 1:numel(classNames)
        sampleWeights(Y_train == classNames(i)) = classWeights(i);
    end

    t = templateSVM('Standardize', true, 'KernelFunction', SVM_KERNEL, 'BoxConstraint', SVM_C);
    model = fitcecoc(X_train, Y_train, ...
                     'Learners', t, ...
                     'ClassNames', classNames, ...
                     'Coding', 'onevsall', ...
                     'Prior', 'uniform', ...
                     'Weights', sampleWeights);

    fprintf('SVM classifier (ECOC, one-vs-all) trained with %s kernel, BoxConstraint=%g\n', ...
            SVM_KERNEL, SVM_C);




    % Add new classifiers here as needed:
    % case 'tree'
    %     model = fitctree(X_train, Y_train);
    %     fprintf('Decision Tree classifier trained.\n');
    otherwise
        warning('Unknown CLASSIFIER_TYPE: %s. Using k-NN as fallback.', CLASSIFIER_TYPE);
        model = fitcknn(X_train, Y_train, 'NumNeighbors', 5, 'Standardize',1);
end

