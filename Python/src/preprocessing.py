from scipy.signal import butter, lfilter
import numpy as np

def lowpass_filter(data, cutoff, fs, order=5):
    """
    Applies a low-pass Butterworth filter to the data.

    Args:
        data (np.ndarray): The input signal.
        cutoff (float): The cutoff frequency of the filter.
        fs (int): The sampling frequency of the signal.
        order (int): The order of the filter.

    Returns:
        np.ndarray: The filtered signal.
    """
    nyquist = 0.5 * fs
    normal_cutoff = cutoff / nyquist
    b, a = butter(order, normal_cutoff, btype='low', analog=False)
    y = lfilter(b, a, data)
    return y

def preprocess(data, config):
    """
    Preprocesses the EEG data based on the current iteration.

    Args:
        data (np.ndarray): The input EEG data.
        config (module): The configuration module.

    Returns:
        np.ndarray: The preprocessed data.
    """
    print("Preprocessing data...")
    if config.CURRENT_ITERATION == 1:
        # Iteration 1: Simple low-pass filter
        fs = 100  # Assuming 100 Hz sampling rate for dummy data
        preprocessed_data = lowpass_filter(data, config.LOW_PASS_FILTER_FREQ, fs)
    else:
        # Placeholder for more advanced preprocessing in later iterations
        print("Warning: No preprocessing defined for this iteration. Returning raw data.")
        preprocessed_data = data
    
    return preprocessed_data
