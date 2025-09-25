import numpy as np
from src.data_loader import load_training_data, load_holdout_data
import os

def test_load_training_data():
    # Assuming dummy.edf exists in data/training for path reference
    dummy_edf_path = os.path.join('../data/training', 'dummy.edf')
    eeg_data, labels = load_training_data(dummy_edf_path)
    assert isinstance(eeg_data, np.ndarray)
    assert isinstance(labels, np.ndarray)
    assert eeg_data.shape == (20, 3000) # 20 epochs, 3000 samples per epoch
    assert labels.shape == (20,)

def test_load_holdout_data():
    # Assuming dummy_holdout.edf exists in data/holdout for path reference
    dummy_holdout_path = os.path.join('../data/holdout', 'dummy_holdout.edf')
    eeg_data = load_holdout_data(dummy_holdout_path)
    assert isinstance(eeg_data, np.ndarray)
    assert eeg_data.shape == (20, 3000) # 20 epochs, 3000 samples per epoch
