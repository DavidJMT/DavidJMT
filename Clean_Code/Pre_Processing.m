clear; close all; clc;
%% Step 1
subj = input('Choose the Participant: ','s');

[data, channels, fs] = cut_process_trc(subj,'2');
%plot_stft(data, channels, fs,'1');

% Remove ECG ground electrode from ECG Lead
data(:,20) = data(:,21) - data(:,20); 
EEG_data = data(:, 1:19); ECG_data = data(:, 20);  

file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEGs/EEG_', subj,'.mat'];
save(file_path,'fs','channels','EEG_data',"ECG_data");
disp(['Initial EEG_', subj, '.mat saved successfully.']);

%% Step 2 - EEG Visualization and Filtering

% Import and plot raw data
import_and_plot_data(subj, fs,"2");

% Apply filters to EEG
EEG_filt = apply_filters(EEG_data, fs, channels,'1');

file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEGs_Filtered/EEG_', subj,'_filtered.mat'];
save(file_path,'fs','channels','EEG_filt','ECG_data');
disp(['Filtered EEG_', subj, '_filtered.mat saved successfully.']);

%% Step 3 - ICA

processedData= perform_ica(EEG_filt, ECG_data, channels, fs);

%% Step 4 - Visualization and Saving

%plot_stft(processedData, channels, fs,'1');

% Save final processed data
save(['/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEG_Processed/EEG_', subj, '_processed.mat'], 'fs', 'channels', 'processedData','ECG_data');
disp(['Processed information saved to EEG_', subj, '_processed.mat successfully.']);

%% Change something in the files?

% file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEG_Processed/EEG__processed.mat'];
% load(file_path);

