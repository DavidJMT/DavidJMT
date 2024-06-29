%% Main Script
clear; close all; clc;

% Get participant and data file path
subj = input('Choose the Participant: ','s');
file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/EEGs/EEG_', subj, '.TRC'];

% Load and process data
[data, channels, fs] = load_and_preprocess_data(file_path);

% Plot Short-Time-Fourier Transform (STFT) if required
plot_stft(data, channels, fs);

% Adjust data to video duration
[data, fs] = adjust_to_video(data, fs);

% Plot STFT after adjusting to video
plot_stft(data, channels, fs);

% Save initial processed data
save_initial_data(subj, data, channels, fs);

% Import and plot raw data
import_and_plot_data(subj, fs);

% Apply filters to data
[EEG_filt, ECG_data] = apply_filters(data, fs, channels);

% Save filtered data
save_filtered_data(subj, EEG_filt, channels, fs);

% Perform ICA
processedData = perform_ica(subj, EEG_filt, ECG_data, channels, fs);

% Plot reconstructed data after ICA
plot_reconstructed_data(processedData, channels, fs);

% Plot STFT of processed data
plot_stft(processedData, channels, fs);

% Save final processed data
save_final_data(subj, EEG_filt, processedData, ECG_data, channels, fs);

%% Functions

function [data, channels, fs] = load_and_preprocess_data(file_path)
    allData = trc_file(file_path);
    allData.get_electrode_info();
    [data] = allData.def_data_access(allData.a_n_data_secs, 5, allData.a_file_elec_cell);
    channels = allData.a_file_elec_cell;
    fs = allData.a_samp_freq;
end

function plot_stft(data, channels, fs)
    plotting = input('Do you want to plot Short-Time-Fourier Transform? "Yes" OR "No" \n ','s');
    if strcmp(plotting, "Yes")
        for i = 1:length(channels) - 2
            figure;
            spectrogram(data(i,:), 1/(1/fs), 0.5/(1/fs), 5/(1/fs), fs, 'yaxis');
            title("Short Time Fourier Transform- " + channels(i));
        end
    end
end

function [data, fs] = adjust_to_video(data, fs)
    init_video = input('Video starts at: ');
    video_duration = 265;
    inicio = init_video * fs;
    fim = (init_video * fs) + (video_duration * fs);
    data = data(:, inicio:fim)';
end

function save_initial_data(subj, data, channels, fs)
    file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/EEGs/EEG_', subj, '.mat'];
    save(file_path, 'fs', 'channels', 'data');
    disp(['Initial EEG_', subj, '.mat saved successfully.']);
end

function import_and_plot_data(subj, fs)
    disp('-----Plotting the data-----');
    file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/EEGs/EEG_', subj, '.mat'];
    load(file_path, 'data', 'channels');

    plotting = input('Do you want to plot the raw data? "Yes" OR "No" \n ','s');
    if strcmp(plotting, "Yes")
        plot_raw_data(data, channels, fs);
    end

    data(:, 20) = data(:, 21) - data(:, 20);
    data(:, 21) = [];
end

function plot_raw_data(data, channels, fs)
    for i = 1:19
        figure;
        subplot(2, 1, 1);
        time = 0:1/fs:1/fs*(length(data(:, i)) - 1);
        plot(time, data(:, i));
        xlabel('Time (s)'); ylabel('Voltage (V)'); title(string(channels(i)) + '- Time Domain');

        subplot(2, 1, 2);
        num_elements = numel(data(:, i));
        freq_x = (-num_elements/2:num_elements/2 - 1) * fs / num_elements;
        freq_data = fftshift(fft(data(:, i)));
        plot(freq_x, abs(freq_data), 'm');
        xlabel('Frequency (Hz)'); ylabel('Fourier Transform');
        title(string(channels(i)) + '- Frequency Domain');
    end
    sgtitle('Before Filter');

    figure;
    for j = 1:2
        subplot(2, 1, j)
        time = 0:1/fs:1/fs*(length(data(:, 20)) - 1);
        plot(time, data(:, 20 + j - 1))
        title(['ECG Channel ', num2str(j)]); xlabel('Time (s)'); ylabel('Amplitude')
    end
    sgtitle('ECG Signals with Ground Channel');
end

function [EEG_filt, ECG_data] = apply_filters(data, fs, channels)
    disp('-----Applying filters-----');

    EEG_data = data(:, 1:end - 1);
    ECG_data = data(:, end);

    fc = [37 50];
    wo = fc / (fs / 2);
    bw = wo / 30;

    [b, a] = iirnotch(wo(1), bw(1));
    filtData = filtfilt(b, a, EEG_data);

    [b, a] = iirnotch(wo(2), bw(2));
    filtData = filtfilt(b, a, filtData);

    fc = [0.5 80];
    EEG_filt = bandpass(filtData, fc, fs, 'ImpulseResponse', 'fir');

    plot_filtered_data(EEG_filt, channels, fs);
end

function plot_filtered_data(EEG_filt, channels, fs)
    plotting = input('Do you want to plot the filtered data? "Yes" OR "No" \n ','s');
    if strcmp(plotting, "Yes")
        for i = 1:19
            figure;
            subplot(2, 1, 1);
            time = (0:numel(EEG_filt(:, i)) - 1) / fs;
            plot(time, EEG_filt(:, i));
            xlabel('Time (s)'); ylabel('Voltage (V)'); title(string(channels(i)) + '- Time Domain');

            subplot(2, 1, 2);
            num_elements = numel(EEG_filt(:, i));
            freq_x = (-num_elements/2:num_elements/2 - 1) * fs / num_elements;
            freq_data = fftshift(fft(EEG_filt(:, i)));
            plot(freq_x, abs(freq_data), 'm');
            xlabel('Frequency (Hz)'); ylabel('Fourier Transform');
            title(string(channels(i)) + '- Frequency Domain');
        end
        sgtitle('After Filter');
    end
end

function save_filtered_data(subj, EEG_filt, channels, fs)
    file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/EEGs/EEG_', subj, '_filtered.mat'];
    save(file_path, 'fs', 'channels', 'EEG_filt');
    disp(['Filtered EEG_', subj, '_filtered.mat saved successfully.']);
end

function processedData = perform_ica(subj, EEG_filt, ECG_data, channels, fs)
    disp('-----Performing ICA-----');
    file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/EEGs/EEG_', subj, '_filtered.mat'];
    load(file_path, 'EEG_filt', 'channels');

    filtData_complete = EEG_filt;
    filtData_complete(:, 20) = ECG_data;

    r = length(channels) - 1;
    [Zica, W, T, mu] = fastICA(filtData_complete', r, 'negentropy');

    plot_ica_components(Zica, channels, fs);

    noisy_components = identify_noisy_components(Zica, filtData_complete, r);

    T(:, noisy_components) = 0;
    processedData = (T \ (W' * Zica))';
end

function plot_ica_components(Zica, channels, fs)
    plotting = input('Do you want to plot each IC Component? "Yes" OR "No" \n ','s');
    if strcmp(plotting, "Yes")
        r = size(Zica, 1);
        for i = 1:r
            figure;
            subplot(2, 1, 1);
            t = (0:1/fs:1/fs*(length(Zica(i,:)) - 1));
            plot(t, Zica(i, :));
            xlabel('Time (s)'); ylabel('Voltage'); title('Component ' + string(i) + ' - Time Domain');

            subplot(2, 1, 2);
            num_elements = numel(Zica(i, :));
            freq_x = (-num_elements/2:num_elements/2 - 1) * fs / num_elements;
            freq_data = fftshift(fft(Zica(i, :)));
            plot(freq_x, abs(freq_data), 'm');
            xlabel('Frequency (Hz)'); ylabel('Fourier Transform'); title('Component ' + string(i) + ' - Frequency Domain');
        end
        sgtitle('FastICA');
    end
end

function noisy_components = identify_noisy_components(Zica, filtData_complete, r)
    list_corr = [];
    for i = 1:r
        correlation = corrcoef(filtData_complete(:, 20)', Zica(i, :));
        list_corr = [list_corr correlation(1, 2)];
    end

    [corr_sorted, idx_sorted] = sort(list_corr, 'descend');
    fprintf('\nTop 5 correlations:\n');
    for i = 1:5
        fprintf('Correlation %d: %.4f (Component: %d)\n', i, corr_sorted(i), idx_sorted(i));
    end

    noisy_components = [];
    n = input('How many components will you want to remove: ');
    for i = 1:n
        number = input('Insert Noisy Component: ');
        noisy_components = [noisy_components, number];
    end
end

function plot_reconstructed_data(processedData, channels, fs)
    plotting = input('Do you want to plot the each reconstructed EEG after ICA? "Yes" OR "No" \n ','s');
    if strcmp(plotting, "Yes")
        for i = 1:19
            figure;
            subplot(2, 1, 1);
            time = (0:numel(processedData(:, i)) - 1) / fs;
            plot(time, processedData(:, i));
            xlabel('Time (s)'); ylabel('Voltage (V)'); title(string(channels(i)) + '- Time Domain');

            subplot(2, 1, 2);
            num_elements = numel(processedData(:, i));
            freq_x = (-num_elements/2:num_elements/2 - 1) * fs / num_elements;
            freq_data = fftshift(fft(processedData(:, i)));
            plot(freq_x, abs(freq_data), 'm');
            xlabel('Frequency (Hz)'); ylabel('Fourier Transform');
            title(string(channels(i)) + '- Frequency Domain');
        end
        sgtitle('After ICA');

        figure;
        time = 0:1/fs:1/fs*(length(processedData(:, 20)) - 1);
        plot(time, processedData(:, 20));
    end
end

function save_final_data(subj, EEG_filt, processedData, ECG_data, channels, fs)
    file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/EEG_Processed/EEG_', subj, '_processed.mat'];
    save(file_path, 'fs', 'channels', 'EEG_filt', 'processedData', 'ECG_data');
    disp(['Processed information saved to EEG_', subj, '_processed.mat successfully.']);
end
