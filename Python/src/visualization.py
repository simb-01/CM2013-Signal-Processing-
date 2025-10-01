import matplotlib.pyplot as plt
import numpy as np
from sklearn.metrics import confusion_matrix, ConfusionMatrixDisplay
import xml.etree.ElementTree as ET

# Try to import MNE for EDF reading (more lenient than pyedflib)
try:
    import mne
    HAS_MNE = True
except ImportError:
    HAS_MNE = False
    try:
        import pyedflib
        HAS_PYEDFLIB = True
    except ImportError:
        HAS_PYEDFLIB = False

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
    if not HAS_MNE and not HAS_PYEDFLIB:
        print("Error: Neither MNE nor pyedflib is installed.")
        print("Please install one: pip install mne  OR  pip install pyedflib")
        return

    try:
        # Calculate epoch boundaries
        start_time = epoch_idx * epoch_duration

        if HAS_MNE:
            # Use MNE (more lenient with EDF format issues)
            raw = mne.io.read_raw_edf(edf_path, preload=True, verbose=False)

            n_channels = len(raw.ch_names)
            channel_labels = raw.ch_names
            sampling_freqs = [raw.info['sfreq']] * n_channels  # MNE resamples to common rate

            # Extract data for this epoch
            start_sample = int(start_time * raw.info['sfreq'])
            stop_sample = int((start_time + epoch_duration) * raw.info['sfreq'])
            data, times = raw[:, start_sample:stop_sample]
            times = times + start_time  # Offset to epoch start time

        else:
            # Fallback to pyedflib
            with pyedflib.EdfReader(edf_path) as edf:
                n_channels = edf.signals_in_file
                channel_labels = edf.getSignalLabels()
                sampling_freqs = [edf.getSampleFrequency(i) for i in range(n_channels)]

                data = []
                for ch_idx in range(n_channels):
                    fs = sampling_freqs[ch_idx]
                    start_sample = int(start_time * fs)
                    n_samples = int(epoch_duration * fs)
                    signal = edf.readSignal(ch_idx, start=start_sample, n=n_samples)
                    data.append(signal)

                # Create time axis
                max_samples = max(len(d) for d in data)
                times = np.linspace(start_time, start_time + epoch_duration, max_samples)

        # Create subplots for each channel
        fig, axes = plt.subplots(n_channels, 1, figsize=(15, 2*n_channels), sharex=True)
        if n_channels == 1:
            axes = [axes]

        print(f"\nPlotting Epoch {epoch_idx} (Time: {start_time}-{start_time+epoch_duration}s)")
        print("="*70)

        for ch_idx in range(n_channels):
            label = channel_labels[ch_idx]

            if HAS_MNE:
                signal = data[ch_idx]
                fs = sampling_freqs[ch_idx]
                time_axis = times
            else:
                signal = data[ch_idx]
                fs = sampling_freqs[ch_idx]
                time_axis = np.arange(len(signal)) / fs + start_time

            # Plot signal
            axes[ch_idx].plot(time_axis, signal, linewidth=0.5)
            axes[ch_idx].set_ylabel(f'{label}\n({int(fs)} Hz)', fontsize=10)
            axes[ch_idx].grid(True, alpha=0.3)
            axes[ch_idx].set_xlim(start_time, start_time + epoch_duration)

            print(f"  {label}: {int(fs)} Hz, {len(signal)} samples")

        axes[-1].set_xlabel('Time (seconds)', fontsize=12)
        axes[0].set_title(f'Sleep Signals - Epoch {epoch_idx} ({epoch_duration}s window)', fontsize=14, fontweight='bold')

        plt.tight_layout()
        plt.show()

    except FileNotFoundError:
        print(f"Error: EDF file not found at {edf_path}")
    except Exception as e:
        print(f"Error reading EDF file: {str(e)}")
        import traceback
        traceback.print_exc()

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
            event_concept = event.find('EventConcept')
            start = event.find('Start')
            duration = event.find('Duration')

            if event_concept is not None and start is not None:
                stage_name = event_concept.text

                # Check if this is a sleep stage event
                # Formats: SDO:WakeState, SDO:NonRapidEyeMovementSleep-N1, SDO:RapidEyeMovementSleep
                # Also support older formats: Wake|0, Stage1|1, etc.
                # Exclude arousal events and other non-stage events
                is_sleep_stage = False
                if 'WakeState' in stage_name or 'RapidEyeMovementSleep' in stage_name or 'NonRapidEyeMovementSleep' in stage_name:
                    is_sleep_stage = True
                elif 'Wake|' in stage_name or 'REM|' in stage_name:
                    is_sleep_stage = True
                elif any(f'Stage{i}' in stage_name for i in range(1, 5)):
                    is_sleep_stage = True
                elif any(f'|{i}' in stage_name for i in range(6)):
                    is_sleep_stage = True

                if is_sleep_stage:
                    start_time = float(start.text)
                    dur = float(duration.text) if duration is not None else 30.0

                    epochs.append(start_time / 30.0)  # Convert to epoch number

                    # Map stage names to numeric labels (0=Wake, 1=N1, 2=N2, 3=N3, 4=REM)
                    stage_label = None

                    if 'WakeState' in stage_name or stage_name == 'Wake' or 'Wake|0' in stage_name:
                        stage_label = 0
                    elif 'N1' in stage_name or 'Stage1' in stage_name or '|1' in stage_name:
                        stage_label = 1
                    elif 'N2' in stage_name or 'Stage2' in stage_name or '|2' in stage_name:
                        stage_label = 2
                    elif 'N3' in stage_name or 'Stage3' in stage_name or 'Stage4' in stage_name or '|3' in stage_name or '|4' in stage_name:
                        stage_label = 3
                    elif 'RapidEyeMovementSleep' in stage_name or stage_name == 'REM' or '|5' in stage_name:
                        stage_label = 4

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
        for i in range(len(epochs)):
            # Draw horizontal line for this epoch
            if i < len(epochs) - 1:
                # Use next epoch as end point
                ax.hlines(stages[i], epochs[i], epochs[i+1],
                         colors=stage_colors[int(stages[i])], linewidth=2)
            else:
                # Last epoch - extend by one epoch duration (30s)
                ax.hlines(stages[i], epochs[i], epochs[i] + 1,
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
