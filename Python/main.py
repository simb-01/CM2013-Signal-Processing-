import config
from src.data_loader import load_training_data
from src.preprocessing import preprocess
from src.feature_extraction import extract_features
from src.feature_selection import select_features
from src.classification import train_classifier
from src.visualization import visualize_results
from src.report import generate_report
from src.utils import save_cache, load_cache
import os

def main():
    print(f"--- Sleep Scoring Pipeline - Iteration {config.CURRENT_ITERATION} ---")

    # 1. Load Data
    # For jumpstart, we're using dummy data. In a real scenario, you'd iterate through files.
    edf_file = os.path.join(config.TRAINING_DIR, "dummy.edf") # Placeholder
    eeg_data, labels = load_training_data(edf_file)

    # 2. Preprocessing
    preprocessed_data = None
    cache_filename_preprocess = f"preprocessed_data_iter{config.CURRENT_ITERATION}.joblib"
    if config.USE_CACHE:
        preprocessed_data = load_cache(cache_filename_preprocess, config.CACHE_DIR)
    
    if preprocessed_data is None:
        preprocessed_data = preprocess(eeg_data, config)
        if config.USE_CACHE:
            save_cache(preprocessed_data, cache_filename_preprocess, config.CACHE_DIR)

    # 3. Feature Extraction
    features = None
    cache_filename_features = f"features_iter{config.CURRENT_ITERATION}.joblib"
    if config.USE_CACHE:
        features = load_cache(cache_filename_features, config.CACHE_DIR)

    if features is None:
        features = extract_features(preprocessed_data, config)
        if config.USE_CACHE:
            save_cache(features, cache_filename_features, config.CACHE_DIR)

    # 4. Feature Selection
    selected_features = select_features(features, labels, config)

    # 5. Classification
    model = train_classifier(selected_features, labels, config)

    # 6. Visualization
    visualize_results(model, selected_features, labels, config)

    # 7. Report Generation
    generate_report(model, selected_features, labels, config)

    print("--- Pipeline Finished ---")

if __name__ == "__main__":
    main()
