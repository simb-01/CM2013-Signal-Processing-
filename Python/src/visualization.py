import matplotlib.pyplot as plt
import numpy as np
from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay
import pyedflib
import xml.etree.ElementTree as ET

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

def plot_sample_epoch(edf_path, epoch_idx=0, epoch_duration=30):
    """
    Plot all signals from a sample epoch in an EDF file.

    Args:
        edf_path (str): Path to the EDF file.
        epoch_idx (int): Index of the epoch to plot (default: 0).
        epoch_duration (int): Duration of each epoch in seconds (default: 30).
    """
    try:
        # Open EDF file
        with pyedflib.EdfReader(edf_path) as edf:
            n_channels = edf.signals_in_file
            channel_labels = edf.getSignalLabels()
            sampling_freqs = [edf.getSampleFrequency(i) for i in range(n_channels)]

            # Calculate epoch boundaries
            start_time = epoch_idx * epoch_duration

            # Create subplots for each channel
            fig, axes = plt.subplots(n_channels, 1, figsize=(15, 2*n_channels), sharex=True)
            if n_channels == 1:
                axes = [axes]

            print(f"\nPlotting Epoch {epoch_idx} (Time: {start_time}-{start_time+epoch_duration}s)")
            print("="*70)

            for ch_idx in range(n_channels):
                fs = sampling_freqs[ch_idx]
                label = channel_labels[ch_idx]

                # Calculate sample indices for this epoch
                start_sample = int(start_time * fs)
                n_samples = int(epoch_duration * fs)

                # Read signal data for this epoch
                signal = edf.readSignal(ch_idx, start=start_sample, n=n_samples)

                # Create time axis in seconds
                time = np.arange(len(signal)) / fs + start_time

                # Plot signal
                axes[ch_idx].plot(time, signal, linewidth=0.5)
                axes[ch_idx].set_ylabel(f'{label}\n({fs} Hz)', fontsize=10)
                axes[ch_idx].grid(True, alpha=0.3)
                axes[ch_idx].set_xlim(start_time, start_time + epoch_duration)

                print(f"  {label}: {fs} Hz, {len(signal)} samples")

            axes[-1].set_xlabel('Time (seconds)', fontsize=12)
            axes[0].set_title(f'Sleep Signals - Epoch {epoch_idx} ({epoch_duration}s window)', fontsize=14, fontweight='bold')

            plt.tight_layout()
            plt.show()

    except FileNotFoundError:
        print(f"Error: EDF file not found at {edf_path}")
    except Exception as e:
        print(f"Error reading EDF file: {str(e)}")

def plot_hypnogram(xml_path, edf_path=None):
    """
    Plot hypnogram (sleep stage progression) from XML annotations.

    Args:
        xml_path (str): Path to the XML annotation file.
        edf_path (str, optional): Path to EDF file to get recording duration.
    """
    try:
        # Parse XML file
        tree = ET.parse(xml_path)
        root = tree.getroot()

        # Extract sleep stages and times
        epochs = []
        stages = []

        # Try different XML structures (Compumedics format)
        for event in root.findall('.//ScoredEvent'):
            event_type = event.find('EventType')
            event_concept = event.find('EventConcept')
            start = event.find('Start')
            duration = event.find('Duration')

            if event_type is not None and 'Stage' in event_type.text:
                if event_concept is not None and start is not None:
                    stage_name = event_concept.text
                    start_time = float(start.text)
                    dur = float(duration.text) if duration is not None else 30.0

                    epochs.append(start_time / 30.0)  # Convert to epoch number

                    # Map stage names to numeric labels
                    stage_map = {
                        'Wake|0': 0, 'Stage1|1': 1, 'Stage2|2': 2,
                        'Stage3|3': 3, 'Stage4|3': 3, 'REM|5': 4,
                        'Wake': 0, 'N1': 1, 'N2': 2, 'N3': 3, 'REM': 4,
                        '0': 0, '1': 1, '2': 2, '3': 3, '4': 3, '5': 4
                    }

                    # Try to match stage name
                    stage_label = None
                    for key in stage_map:
                        if key in stage_name:
                            stage_label = stage_map[key]
                            break

                    if stage_label is not None:
                        stages.append(stage_label)

        if not epochs:
            print("Warning: No sleep stage annotations found in XML file")
            print("The XML file may be in a different format or empty")
            return

        # Convert to numpy arrays
        epochs = np.array(epochs)
        stages = np.array(stages)

        # Create hypnogram plot
        fig, ax = plt.subplots(figsize=(15, 5))

        # Plot as step function
        stage_names = ['Wake', 'N1', 'N2', 'N3', 'REM']
        stage_colors = ['red', 'orange', 'green', 'blue', 'purple']

        # Create step plot
        for i in range(len(epochs)-1):
            ax.hlines(stages[i], epochs[i], epochs[i+1],
                     colors=stage_colors[int(stages[i])], linewidth=2)

        # Styling
        ax.set_yticks(range(5))
        ax.set_yticklabels(stage_names)
        ax.set_ylabel('Sleep Stage', fontsize=12, fontweight='bold')
        ax.set_xlabel('Epoch Number (30s epochs)', fontsize=12, fontweight='bold')
        ax.set_title('Hypnogram - Sleep Stage Progression', fontsize=14, fontweight='bold')
        ax.grid(True, alpha=0.3, axis='x')
        ax.set_ylim(-0.5, 4.5)

        # Add time axis on top
        ax2 = ax.twiny()
        ax2.set_xlim(ax.get_xlim())
        ax2.set_xlabel('Time (hours)', fontsize=12, fontweight='bold')
        # Convert epochs to hours
        max_epoch = int(epochs[-1])
        hour_ticks = np.arange(0, max_epoch, 120)  # 120 epochs = 1 hour
        ax2.set_xticks(hour_ticks)
        ax2.set_xticklabels([f'{h/120:.1f}' for h in hour_ticks])

        plt.tight_layout()
        plt.show()

        # Print statistics
        print("\nSleep Stage Statistics:")
        print("="*70)
        print(f"Total epochs: {len(stages)}")
        print(f"Total duration: {len(stages)*30/3600:.2f} hours")
        print("\nStage distribution:")
        for stage_idx, stage_name in enumerate(stage_names):
            count = np.sum(stages == stage_idx)
            percentage = count / len(stages) * 100
            print(f"  {stage_name}: {count} epochs ({percentage:.1f}%)")

    except FileNotFoundError:
        print(f"Error: XML file not found at {xml_path}")
    except Exception as e:
        print(f"Error reading XML file: {str(e)}")
        import traceback
        traceback.print_exc()

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
