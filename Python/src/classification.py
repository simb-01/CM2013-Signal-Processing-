from sklearn.neighbors import KNeighborsClassifier
from sklearn.svm import SVC
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

def train_classifier(features, labels, config):
    """
    Trains a classifier based on the current iteration.

    Args:
        features (np.ndarray): The input features.
        labels (np.ndarray): The corresponding labels.
        config (module): The configuration module.

    Returns:
        object: The trained classifier.
    """
    print("Training classifier...")

    # TODO: Implement proper cross-validation instead of a simple train/test split.
    X_train, X_test, y_train, y_test = train_test_split(features, labels, test_size=0.2, random_state=42)

    # TODO: Address class imbalance. 
    # Techniques to consider:
    # 1. Oversampling minority classes (e.g., using SMOTE from imblearn).
    # 2. Undersampling majority classes.
    # 3. Using class weights in the classifier.

    if config.CURRENT_ITERATION == 1:
        model = KNeighborsClassifier(n_neighbors=config.KNN_N_NEIGHBORS)
    elif config.CURRENT_ITERATION == 2:
        # TODO: Tune hyperparameters for SVM
        model = SVC()
    elif config.CURRENT_ITERATION >= 3:
        # TODO: Tune hyperparameters for Random Forest
        model = RandomForestClassifier()
    else:
        raise ValueError(f"Invalid iteration number: {config.CURRENT_ITERATION}")

    model.fit(X_train, y_train)

    # Evaluate on the test set (for demonstration purposes)
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    print(f"Test accuracy: {accuracy:.2f}")

    return model
