import matplotlib.pyplot as plt
from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay

def plot_confusion_matrix(y_true, y_pred, class_names):
    """
    Plots a confusion matrix.

    Args:
        y_true (np.ndarray): The true labels.
        y_pred (np.ndarray): The predicted labels.
        class_names (list): The names of the classes.
    """
    cm = confusion_matrix(y_true, y_pred)
    disp = ConfusionMatrixDisplay(confusion_matrix=cm, display_labels=class_names)
    disp.plot()
    plt.title("Confusion Matrix")
    plt.show()

def visualize_results(model, features, labels, config):
    """
    Visualizes the results of the classification.

    Args:
        model (object): The trained model.
        features (np.ndarray): The input features.
        labels (np.ndarray): The corresponding labels.
        config (module): The configuration module.
    """
    print("Visualizing results...")
    # TODO: Add more visualizations as needed (e.g., feature importance).
    class_names = ['Wake', 'N1', 'N2', 'N3', 'REM']
    y_pred = model.predict(features)
    plot_confusion_matrix(labels, y_pred, class_names)
