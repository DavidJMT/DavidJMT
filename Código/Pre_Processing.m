clear; close all; clc;
%% Step 1
subj = input('Choose the Participant: ','s');

[data, channels, fs] = cut_process_trc(subj,"2");
plot_stft(data, channels, fs,'1');

file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEGs/EEG_', subj,'.mat'];
save(file_path,'fs','channels','data');
disp(['Initial EEG_', subj, '.mat saved successfully.']);

%% Step 2 - Visualization and Filtering

% Import and plot raw data
import_and_plot_data(subj, fs,"2");

% Apply filters to data
[EEG_filt, ECG_data, fc] = apply_filters(data, fs, channels);

file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEGs_Filtered/EEG_', subj,'_filtered.mat'];
save(file_path,'fs','channels','EEG_filt','ECG_data','fc');
disp(['Filtered EEG_', subj, '_filtered.mat saved successfully.']);

%% Step 3 - ICA

[processedData, ECG_filt] = perform_ica(subj, EEG_filt, ECG_data, channels, fs);

%% Step 4 - Visualization and Saving
% Plot STFT of processed data
plot_stft(processedData, channels, fs,'1');

% Save final processed data
save(['/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEG_Processed/EEG_', subj, '_processed.mat'], 'fs', 'channels', 'processedData','ECG_filt');
disp(['Processed information saved to EEG_', subj, '_processed.mat successfully.']);
