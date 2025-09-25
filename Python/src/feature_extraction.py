import numpy as np

def extract_time_domain_features(epoch):
    """
    Extracts time-domain features from a single epoch.

    Args:
        epoch (np.ndarray): A 1D array representing one epoch of EEG data.

    Returns:
        dict: A dictionary of features.
    """
    features = {
        'mean': np.mean(epoch),
        'median': np.median(epoch),
        'std': np.std(epoch),
        # TODO: Add the other 13 time-domain features from the guide
    }
    return features

def extract_features(data, config):
    """
    Extracts features from the preprocessed data based on the current iteration.

    Args:
        data (np.ndarray): The preprocessed EEG data.
        config (module): The configuration module.

    Returns:
        np.ndarray: A 2D array of features (n_epochs, n_features).
    """
    print("Extracting features...")
    if config.CURRENT_ITERATION == 1:
        # Iteration 1: Time-domain features
        all_features = []
        for epoch in data:
            features = extract_time_domain_features(epoch)
            all_features.append(list(features.values()))
        features = np.array(all_features)
    elif config.CURRENT_ITERATION == 2:
        # TODO: Implement frequency-domain feature extraction
        print("Warning: No frequency-domain features defined for this iteration. Returning empty features.")
        features = np.array([[] for _ in range(data.shape[0])])
    else:
        # Placeholder for more advanced feature extraction
        print("Warning: No features defined for this iteration. Returning empty features.")
        features = np.array([[] for _ in range(data.shape[0])])

    return features
