import numpy as np
from src.data_loader import load_training_data, load_holdout_data
import os

def test_load_training_data():
    # Test multi-channel training data loading
    dummy_edf_path = os.path.join('../data/sample', 'R1.edf')
    dummy_xml_path = os.path.join('../data/sample', 'R1.xml')
    multi_channel_data, labels, info = load_training_data(dummy_edf_path, dummy_xml_path)

    # Test multi-channel structure
    assert isinstance(multi_channel_data, dict)
    assert 'eeg' in multi_channel_data
    assert 'eog' in multi_channel_data
    assert 'emg' in multi_channel_data

    # Test data shapes for multi-channel format
    assert multi_channel_data['eeg'].shape == (240, 2, 3000)  # 240 epochs, 2 EEG channels, 3000 samples
    assert multi_channel_data['eog'].shape == (240, 2, 3000)  # 240 epochs, 2 EOG channels, 3000 samples
    assert multi_channel_data['emg'].shape == (240, 1, 6000)  # 240 epochs, 1 EMG channel, 6000 samples (200Hz)

    assert isinstance(labels, np.ndarray)
    assert labels.shape == (240,)  # 240 epoch labels

    assert isinstance(info, dict)
    assert 'eeg_names' in info
    assert 'epoch_length' in info
    assert info['epoch_length'] == 30

def test_load_holdout_data():
    # Test multi-channel holdout data loading
    dummy_holdout_path = os.path.join('../data/holdout', 'dummy_holdout.edf')
    multi_channel_data, info = load_holdout_data(dummy_holdout_path)

    # Test multi-channel structure
    assert isinstance(multi_channel_data, dict)
    assert 'eeg' in multi_channel_data

    # Test data shapes for holdout format
    assert multi_channel_data['eeg'].shape == (240, 2, 3000)  # 240 epochs, 2 EEG channels, 3000 samples

    assert isinstance(info, dict)
    assert 'n_epochs' in info
    assert info['n_epochs'] == 240
