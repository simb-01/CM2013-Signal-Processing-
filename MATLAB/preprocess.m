% function preprocessed_data = preprocess(data)
% %% STUDENT IMPLEMENTATION AREA: Preprocess EEG data based on current iteration.
% %
% % This is a MINIMAL example. Students should expand this significantly:
% %
% % Iteration 1: Basic filtering (current example is just a starting point)
% % Iteration 2+: Add more sophisticated preprocessing:
% % - Artifact removal (eye blinks, muscle artifacts)
% % - Channel selection and re-referencing
% % - Epoch extraction (30-second windows)
% % - Data quality checks
% % - Normalization/standardization
% %
% % Note: This function expects config variables to be in the base workspace
% 
% % Get config variables from caller's workspace
% try
%     CURRENT_ITERATION = evalin('caller', 'CURRENT_ITERATION');
%     LOW_PASS_FILTER_FREQ = evalin('caller', 'LOW_PASS_FILTER_FREQ');
% catch
%     error('Config variables not found. Make sure config.m has been run in the calling function.');
% end
% 
% fprintf('Preprocessing data for iteration %d...\n', CURRENT_ITERATION);
% 
% % TODO: Students need to implement proper preprocessing based on iteration:
% if CURRENT_ITERATION == 1
%     % EXAMPLE: Very basic low-pass filter (students should expand)
%     fs = 125; % Actual EEG sampling rate: 125 Hz (TODO: Get from data/config)
%     preprocessed_data = lowpass_filter(data, LOW_PASS_FILTER_FREQ, fs);
% 
%     % TODO: Students should add:
%     % - High-pass filtering
%     % - Epoch extraction (30-second windows)
%     % - Channel selection
% 
% elseif CURRENT_ITERATION == 2
%     % TODO: Students implement enhanced preprocessing:
%     % - Better filtering (bandpass)
%     % - Artifact detection/removal
%     % - Re-referencing
%     fprintf('TODO: Implement enhanced preprocessing for iteration 2\n');
%     preprocessed_data = data; % Placeholder - students must implement
% 
% elseif CURRENT_ITERATION >= 3
%     % TODO: Students implement advanced preprocessing:
%     % - Multi-signal processing (EEG + EOG + EMG)
%     % - Advanced artifact removal
%     % - Signal quality assessment
%     fprintf('TODO: Implement advanced preprocessing for iteration 3+\n');
%     preprocessed_data = data; % Placeholder - students must implement
% 
% else
%     error('Invalid iteration: %d', CURRENT_ITERATION);
% end
% 
% end
% 
% function y = lowpass_filter(data, cutoff, fs, order)
% % EXAMPLE IMPLEMENTATION: Simple low-pass Butterworth filter.
% %
% % Students should understand this basic filter and consider:
% % - Is 40Hz the right cutoff for EEG?
% % - What about high-pass filtering?
% % - Should you use bandpass instead?
% % - What about notch filtering for powerline interference?
% 
% if nargin < 4
%     order = 5;
% end
% 
% % TODO: Students may want to implement additional filtering:
% % - High-pass filter to remove DC drift
% % - Notch filter for 50/60 Hz powerline noise
% % - Bandpass filter (e.g., 0.5-40 Hz for EEG)
% 
% nyquist = 0.5 * fs;
% normal_cutoff = cutoff / nyquist;
% [b, a] = butter(order, normal_cutoff, 'low');
% y = filter(b, a, data);
% 
% end
% 
% function y = preprocess(data)
% % PREPROCESS EEG SIGNAL (单通道多 epoch)
% % 输入 data: 1084x3750 单通道 EEG，每列一个 epoch
% % 输出 y: 滤波后信号，维度不变
% 
% fs = 125;  % 默认采样率
% [nepochs, nsamples] = size(data);
% 
% %% 滤波参数
% hp_cutoff = 0.3;       % 高通截止频率
% hp_order  = 4;
% powerline_freq = 50;   % 工频
% Q = 60;                % Notch 品质因数
% bp_low  = 0.3;         % 带通低频
% bp_high = 40;          % 带通高频
% bp_order = 4;
% 
% % 预分配输出
% y = zeros(size(data));
% 
% %% 对每个 epoch 单独滤波
% for i = 1:nepochs
%     x_orig = double(data(i,:))';  % 当前 epoch，列向量
%     x = x_orig;
% 
%     % 1. 高通滤波
%     x = butterworth_filter(x, fs, hp_cutoff, 'high', hp_order);
%     if i == 1
%         plot_freq_subplot(x_orig, x, fs, sprintf('High-pass Filter %.1f Hz', hp_cutoff));
%     end
% 
%     % 2. 陷波滤波 (50 Hz)
%     x = notch_filter(x, fs, powerline_freq, Q);
%     if i == 1
%         plot_freq_subplot(x_orig, x, fs, 'Notch Filter 50Hz');
%     end
% 
%     % 3. 带通滤波
%     x = butterworth_filter(x, fs, [bp_low, bp_high], 'bandpass', bp_order);
%     if i == 1
%         plot_freq_subplot(x_orig, x, fs, sprintf('Bandpass Filter %.1f-%.1f Hz', bp_low, bp_high));
%     end
% 
%     % 保存回输出矩阵
%     y(i,:) = x';
% end
% 
% end
% 
% %% ----------------- 子函数 -----------------
% 
% function y = butterworth_filter(x, fs, cutoff, type, order)
% x = double(x(:));
% nyquist = fs/2;
% if strcmpi(type, 'bandpass')
%     wn = cutoff/nyquist;
% else
%     wn = cutoff/nyquist;
% end
% [b,a] = butter(order, wn, type);
% y = filtfilt(b, a, x);
% end
% 
% function y = notch_filter(x, fs, f0, Q)
% % CASCADED STABLE NOTCH FILTER (纯 MATLAB)
% x = double(x(:));
% if numel(x) < 12 || f0 >= fs/2
%     y = x;
%     return;
% end
% 
% % 第一级 notch
% w0 = 2*pi*f0/fs;
% alpha = sin(w0)/(2*Q);
% 
% b = [1 -2*cos(w0) 1];
% a = [1+alpha -2*cos(w0) 1-alpha];
% b = b/(1+alpha);
% a = a/(1+alpha);
% 
% y = filtfilt(b, a, x);
% 
% % 第二级 notch
% y = filtfilt(b, a, y);
% % 第三级 notch
% y = filtfilt(b, a, y);
% % 第四级 notch
% y = filtfilt(b, a, y);
% 
% end
% 
% function plot_freq_subplot(x_orig, x_filt, fs, title_str)
% N = length(x_orig);
% f = (0:N/2)*fs/N;
% X = abs(fft(x_orig-mean(x_orig)))/N;
% Y = abs(fft(x_filt-mean(x_filt)))/N;
% X = 2*X(1:N/2+1);
% Y = 2*Y(1:N/2+1);
% ylim_max = max([X; Y]);
% 
% figure;
% subplot(1,2,1);
% plot(f,X,'b','LineWidth',1.2); xlabel('Frequency (Hz)'); ylabel('Amplitude'); title('Original'); grid on; xlim([0 fs/2]); ylim([0 ylim_max]);
% subplot(1,2,2);
% plot(f,Y,'r','LineWidth',1.2); xlabel('Frequency (Hz)'); ylabel('Amplitude'); title(['Filtered: ', title_str]); grid on; xlim([0 fs/2]); ylim([0 ylim_max]);
% end
% 
% 
function y = preprocess(data)
% PREPROCESS EEG SIGNAL (Single-channel, multiple epochs, FIR notch)
% Input: data - 1084x3750 single-channel EEG, each column is an epoch
% Output: y - filtered signal, same size as input

fs = 125;  % Default sampling rate
[nepochs, nsamples] = size(data);

%% Filter parameters
hp_cutoff = 0.3;       % High-pass cutoff frequency
hp_order  = 4;
powerline_freq = 50;   % Powerline frequency
notch_bw = 1;           % ±1 Hz bandwidth for FIR notch
bp_low  = 0.3;         % Bandpass low frequency
bp_high = 40;          % Bandpass high frequency
bp_order = 4;

% Preallocate output
y = zeros(size(data));

%% Filter each epoch independently
for i = 1:nepochs
    x_orig = double(data(i,:))';  % Current epoch as column vector
    x = x_orig;

    % 1. High-pass filtering
    x = butterworth_filter(x, fs, hp_cutoff, 'high', hp_order);
    if i == 1
        plot_freq_subplot(x_orig, x, fs, sprintf('High-pass Filter %.1f Hz', hp_cutoff));
    end

    % 2. FIR notch filtering (50 Hz)
    x = fir_notch_filter(x, fs, powerline_freq, notch_bw);
    if i == 1
        plot_freq_subplot(x_orig, x, fs, 'FIR Notch Filter 50Hz');
    end

    % 3. Bandpass filtering
    x = butterworth_filter(x, fs, [bp_low, bp_high], 'bandpass', bp_order);
    if i == 1
        plot_freq_subplot(x_orig, x, fs, sprintf('Bandpass Filter %.1f-%.1f Hz', bp_low, bp_high));
    end

    % Save filtered epoch back to output
    y(i,:) = x';
end

end

%% ----------------- Subfunctions -----------------

function y = butterworth_filter(x, fs, cutoff, type, order)
x = double(x(:));
nyquist = fs/2;
if strcmpi(type, 'bandpass')
    wn = cutoff/nyquist;
else
    wn = cutoff/nyquist;
end
[b,a] = butter(order, wn, type);
y = filtfilt(b, a, x);
end

function y = fir_notch_filter(x, fs, f0, bw)
% FIR bandstop (notch) filter with zero-phase
% x: input column vector
% fs: sampling rate
% f0: notch frequency
% bw: bandwidth (Hz)
numtaps = 401; % FIR filter order, adjustable
f1 = (f0 - bw/2)/(fs/2);
f2 = (f0 + bw/2)/(fs/2);
b = fir1(numtaps-1, [f1 f2], 'stop'); % FIR bandstop filter
y = filtfilt(b, 1, x);
end

% Original IIR notch filter commented out
% function y = notch_filter(x, fs, f0, Q)
% % CASCADED STABLE NOTCH FILTER (pure MATLAB)
% x = double(x(:));
% if numel(x) < 12 || f0 >= fs/2
%     y = x;
%     return;
% end
% w0 = 2*pi*f0/fs;
% alpha = sin(w0)/(2*Q);
% b = [1 -2*cos(w0) 1];
% a = [1+alpha -2*cos(w0) 1-alpha];
% b = b/(1+alpha);
% a = a/(1+alpha);
% y = filtfilt(b, a, x);
% y = filtfilt(b, a, y);
% end

function plot_freq_subplot(x_orig, x_filt, fs, title_str)
N = length(x_orig);
f = (0:N/2)*fs/N;
X = abs(fft(x_orig-mean(x_orig)))/N;
Y = abs(fft(x_filt-mean(x_filt)))/N;
X = 2*X(1:N/2+1);
Y = 2*Y(1:N/2+1);
ylim_max = max([X; Y]);

figure;
subplot(1,2,1);
plot(f,X,'b','LineWidth',1.2); xlabel('Frequency (Hz)'); ylabel('Amplitude'); title('Original'); grid on; xlim([0 fs/2]); ylim([0 ylim_max]);
subplot(1,2,2);
plot(f,Y,'r','LineWidth',1.2); xlabel('Frequency (Hz)'); ylabel('Amplitude'); title(['Filtered: ', title_str]); grid on; xlim([0 fs/2]); ylim([0 ylim_max]);
end

