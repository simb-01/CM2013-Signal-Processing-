function model = classification_train_classifier(features, labels, config)
%% Trains a classifier based on the current iteration.

fprintf('Training classifier...\n');

% TODO: Implement proper cross-validation instead of a simple train/test split.
% For simplicity, we'll use all data for training in this jumpstart.

% TODO: Address class imbalance.
% Techniques to consider:
% 1. Oversampling minority classes (e.g., using `oversample` function if available).
% 2. Undersampling majority classes.
% 3. Using class weights in the classifier (if supported by the chosen classifier).

if config.CURRENT_ITERATION == 1
    model = fitcknn(features, labels, 'NumNeighbors', config.KNN_N_NEIGHBORS);
elseif config.CURRENT_ITERATION == 2
    % TODO: Tune hyperparameters for SVM
    model = fitcsvm(features, labels);
elseif config.CURRENT_ITERATION >= 3
    % TODO: Tune hyperparameters for Random Forest
    model = TreeBagger(100, features, labels, 'Method', 'classification');
else
    error('Invalid iteration number: %d', config.CURRENT_ITERATION);
end

% Evaluate on the training set (for demonstration purposes)
% In a real scenario, you would use a separate validation set or cross-validation.
predictions = predict(model, features);
accuracy = sum(predictions == labels') / length(labels);
fprintf('Training accuracy: %.2f\n', accuracy);

end
