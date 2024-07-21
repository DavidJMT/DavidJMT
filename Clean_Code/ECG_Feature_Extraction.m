clear; close all; clc;

% List of participants
participants = [3, 4, 5, 6, 7, 8, 9, 10, 11];

% Initialize arrays to store metrics for all participants
all_time_metrics_before = [];
all_time_metrics_after = [];
all_frequency_metrics_before = [];
all_frequency_metrics_after = [];

% Loop through each participant
for participant = participants
    fprintf('Processing Participant %d\n', participant);

    data_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEG_Processed/EEG_', num2str(participant), '_processed.mat'];
    load(data_path, 'fs', 'ECG_filt');

    [~, qrs_i_raw, ~] = pan_tompkin(ECG_filt, fs);

    stimulus_type = 1;
    [rr_intervals_before, rr_intervals_after] = ecg_processing(qrs_i_raw, stimulus_type, fs);

    %Time Domain Features
    metrics_before = time_metrics_extraction(rr_intervals_before);
    metrics_after = time_metrics_extraction(rr_intervals_after);

    % Store the time metrics
    all_time_metrics_before = [all_time_metrics_before; metrics_before];
    all_time_metrics_after = [all_time_metrics_after; metrics_after];

    % Frequency Domain Features
    frequency_metrics_before = frequency_metrics_extraction(rr_intervals_before);
    frequency_metrics_after = frequency_metrics_extraction(rr_intervals_after);

    % Store the frequency metrics
    all_frequency_metrics_before = [all_frequency_metrics_before; frequency_metrics_before];
    all_frequency_metrics_after = [all_frequency_metrics_after; frequency_metrics_after];
end
close all;
%% Boxplot for comparison before vs after across all participants

% Time Domain Features
labels = {'Mean RR', 'SDNN', 'RMSSD', 'NN50', 'pNN50', 'NN20', 'pNN20'};
for i = 2:length(labels)
    figure;
    titleString = sprintf('%s Variation Across Participants', labels{i});
    boxplot([all_time_metrics_before(:,i); all_time_metrics_after(:,i)], [repmat({'Before Stimulus'}, size(all_time_metrics_before, 1), 1); repmat({'After Stimulus'}, size(all_time_metrics_after, 1), 1)]);
    title(titleString);
end

% Frequency Domain Features
labels = {'LF', 'HF', 'LF/HF Ratio'};
for i = 1:length(labels)
    figure;
    titleString = sprintf('%s Variation Across Participants', labels{i});
    boxplot([all_frequency_metrics_before(:,i), all_frequency_metrics_after(:,i)], [repmat({'Before Stimulus'}, size(all_time_metrics_before, 1), 1); repmat({'After Stimulus'}, size(all_time_metrics_after, 1), 1)]);
    title(titleString);
end

fprintf('All participants processed and plots generated.\n');

%% Kruskal-Wallis Test and Boxplot for comparison before vs after across all participants

% Time Domain Features
labels_time = {'Mean RR', 'SDNN', 'RMSSD', 'NN50', 'pNN50', 'NN20', 'pNN20'};
for i = 2:length(labels_time)
    % Perform Kruskal-Wallis test
    [p, tbl, stats] = kruskalwallis([all_time_metrics_before(:,i); all_time_metrics_after(:,i)], ...
                                    [repmat({'Before Stimulus'}, size(all_time_metrics_before, 1), 1); ...
                                    repmat({'After Stimulus'}, size(all_time_metrics_after, 1), 1)], ...
                                    'off');
    fprintf('Kruskal-Wallis Test for %s: p-value = %.4f\n', labels_time{i}, p);
end

% Frequency Domain Features
labels_freq = {'LF', 'HF', 'LF/HF Ratio'};
for i = 1:length(labels_freq)
    % Perform Kruskal-Wallis test
    [p, tbl, stats] = kruskalwallis([all_frequency_metrics_before(:,i); all_frequency_metrics_after(:,i)], ...
                                    [repmat({'Before Stimulus'}, size(all_frequency_metrics_before, 1), 1); ...
                                    repmat({'After Stimulus'}, size(all_frequency_metrics_after, 1), 1)], ...
                                    'off');
    fprintf('Kruskal-Wallis Test for %s: p-value = %.4f\n', labels_freq{i}, p);
end

fprintf('All participants processed and plots generated.\n');