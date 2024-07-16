clear; close all; clc;
%% ECG Feature Extraction

participant = 10;
load('/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEG_Processed/EEG_'+string(participant)+'_processed.mat','fs','ECG_filt') 

%Applying the pan_tompkin function
[~, qrs_i_raw, ~] = pan_tompkin(ECG_filt, fs);
[rr_intervals_before,rr_intervals_after] = ecg_processing(ECG_filt,qrs_i_raw,1,fs);

%% Time Domain Features
fprintf('Before Stimulus:\n');
metrics_before= Extractions(rr_intervals_before);

fprintf('\nAfter Stimulus:\n');
metrics_after = Extractions(rr_intervals_after);

%% Boxplot for comparasion before vs after

labels = {'Heart Rate', 'Mean RR', 'SDNN', 'RMSSD', 'NN50', 'pNN50', 'NN20', 'pNN20'};
for i=1:length(metrics_after) 
    figure;
    titleString = sprintf('%s Variation', labels{i});
    represent_boxplot(metrics_before{i},metrics_after{i}, titleString)
end

%% Frequency Domain Features
fprintf('Before Stimulus:\n');
frequency_metrics_before = calculate_frequency_domain(rr_intervals_before);

fprintf('After Stimulus:\n');
frequency_metrics_after = calculate_frequency_domain(rr_intervals_after);

%% Boxplot for comparasion before vs after

labels = {'LF', 'HF', 'LF/HF Ratio'};
for i=1:length(frequency_metrics_after)
    figure;
    titleString = sprintf('%s Variation', labels{i});
    represent_boxplot(frequency_metrics_before{i},frequency_metrics_after{i}, titleString)
end


