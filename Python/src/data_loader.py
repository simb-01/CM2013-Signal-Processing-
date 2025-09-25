import numpy as np
import mne


def load_training_data(file_path):
    """
    Loads training data from an EDF file and its corresponding XML annotation file.

    For the jumpstart, this function creates dummy data.
    Replace this with actual EDF/XML loading logic.

    Args:
        file_path (str): The path to the EDF file.

    Returns:
        tuple: A tuple containing:
            - eeg_data (np.ndarray): The EEG data.
            - labels (np.ndarray): The sleep stage labels.
    """
    print(f"Loading training data from {file_path}...")
    # Dummy data: 10 minutes of data at 100 Hz, 30-second epochs
    n_epochs = 20
    n_samples = 30 * 100 
    eeg_data = np.random.randn(n_epochs, n_samples)
    labels = np.random.randint(0, 5, n_epochs) # 5 sleep stages
    return eeg_data, labels

def load_holdout_data(file_path):
    """
    Loads holdout data from an EDF file.

    For the jumpstart, this function creates dummy data.
    Replace this with actual EDF loading logic.

    Args:
        file_path (str): The path to the EDF file.

    Returns:
        np.ndarray: The EEG data.
    """
    print(f"Loading holdout data from {file_path}...")
    # Dummy data: 10 minutes of data at 100 Hz, 30-second epochs
    n_epochs = 20
    n_samples = 30 * 100
    eeg_data = np.random.randn(n_epochs, n_samples)
    return eeg_data


def read_edf(file_path):
    """
    Reads an EDF file using the MNE library.

    Args:
        file_path (str): The path to the EDF file.

    Returns:
        mne.io.Raw: The raw EDF data.
    """
    return mne.io.read_raw_edf(file_path, preload=True, verbose=False)
