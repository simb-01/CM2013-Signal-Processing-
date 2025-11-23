function [model] = train_classifier1(features, labels)
X_train = features; 
Y_train = labels(:);

% 获取 SVM 参数
try
    SVM_C = evalin('caller', 'SVM_C');
    SVM_KERNEL = evalin('caller', 'SVM_KERNEL');
catch
    SVM_C = 1.0;
    SVM_KERNEL = 'linear';
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
end
