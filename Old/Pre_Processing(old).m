%% Pre_processing of the data
clear; close all; clc;

subj = input('Choose the Participant: ','s');
file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/EEGs/EEG_', subj, '.TRC'];

allData = trc_file(file_path);
allData.get_electrode_info();
[data] = allData.def_data_access (allData.a_n_data_secs,5,allData.a_file_elec_cell); %[data,time]=def_data_access(self, wsize, step, channs_cell, offset)
channels = allData.a_file_elec_cell; % self.a_file_elec_cell -> cell array containing the names of all electrodes presented in the file
fs = allData.a_samp_freq;

plotting = input('Do you want to plot Short-Time-Fourier Transform? "Yes" OR "No" \n ','s');
if strcmp(plotting, "Yes")
    for i=1:length(channels)-2 %for all the channels
        figure; spectrogram(data(i,:),1/(1/fs),0.5/(1/fs),5/(1/fs),fs,'yaxis');
        title("Short Time Fourier Transform- "+channels(i))
    end
end

data_game = input('Date from Unity (yyyy-MM-dd HH:mm:ss): ','s'); % '2024-04-29 19:52:07' 
data_eeg = allData.a_start_ts; 
serial_date1 = datetime(data_eeg); 
serial_date2 = datetime(data_game);

% Calculate time difference
time_difference_days = serial_date2 - serial_date1;
disp(['The time difference is: ', char(time_difference_days)])

%Change the beginning of the video
init_video = input('Video starts at: ');
video_duration = 265;
inicio = init_video * fs;
fim = (init_video * fs) + (video_duration*fs);
data=data(:,inicio:fim)'; %Remove the instants before and after the video

plotting = input('Do you want to plot Short-Time-Fourier Transform? "Yes" OR "No" \n ','s');
if strcmp(plotting, "Yes")
    for i=1:length(channels)-2 %for all the channels
        figure; spectrogram(data(:,i),1/(1/fs),0.5/(1/fs),5/(1/fs),fs,'yaxis'); title("Short Time Fourier Transform- "+channels(i))
        stimulus_time_1 = 66.5/60;  
        stimulus_time_2 = 200.5/60;
        stimulus_time_3 = 247.45/60;
        hold on;
        line([stimulus_time_1, stimulus_time_1], ylim, 'Color', 'red', 'LineWidth', 0.4);
        line([stimulus_time_2, stimulus_time_2], ylim, 'Color', 'blue', 'LineWidth', 0.4);
        line([stimulus_time_3, stimulus_time_3], ylim, 'Color', 'black', 'LineWidth', 0.4);
        hold off;
    end
end

file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/EEGs/EEG_', subj,'.mat'];
save(file_path,'fs','channels','data'); %saves in .mat file
disp(['Initial EEG_', subj, '.mat saved successfully.']);

%% Import data

disp('-----Plotting the data-----')
file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/EEGs/EEG_', subj,'.mat'];
load(file_path);

plotting = input('Do you want to plot the raw data? "Yes" OR "No" \n ','s');
if strcmp(plotting, "Yes")
    for i = 1:19
        figure;

        % Time domain
        subplot(2, 1, 1);
        time = 0:1/fs:1/fs*(length(data(:,i))-1);
        plot(time, data(:, i));
        xlabel('Time (s)'); ylabel('Voltage (V)'); title(string(channels(i))+'- Time Domain');

        % Frequency domain
        subplot(2, 1, 2);
        num_elements = numel(data(:, i));
        freq_x = (-num_elements/2:num_elements/2 - 1) * fs / num_elements;
        freq_data = fftshift(fft(data(:, i)));
        plot(freq_x, abs(freq_data), 'm');
        xlabel('Frequency (Hz)'); ylabel('Fourier Transform');
        title(string(channels(i))+'- Frequency Domain');
    end

    sgtitle('Before Filter');

    figure;
    for j = 1:2
        subplot(2, 1, j)
        time = 0:1/fs:1/fs*(length(data(:,20))-1);
        plot(time, data(:,20 + j - 1))
        title(['ECG Channel ', num2str(j)]); xlabel('Time (s)'); ylabel('Amplitude')
    end
    sgtitle('ECG Signals with Ground Channel')

    data(:,20) = data(:,21)-data(:,20);
    data(:,21) = [];
else
    data(:,20) = data(:,21)-data(:,20);
    data(:,21) = [];
end

%% Filtering 
disp('-----Applying filters-----')

EEG_data = data(:, 1:end-1);
ECG_data = data(:, end); 

fc = [37 50]; 
wo = fc / (fs / 2); 
bw=wo/30; % bw = wi/Q

[b, a]=iirnotch(wo(1), bw(1));  %notch filter- 37Hz
filtData=filtfilt(b, a, EEG_data); 

[b, a]=iirnotch(wo(2), bw(2)); %notch filter- 50Hz
filtData=filtfilt(b, a, filtData);

%bandpass filter 
fc=[0.5  80]; 
EEG_filt=bandpass(filtData, fc, fs, ImpulseResponse="fir"); 

%Plot the EEG for the subject after filter
plotting = input('Do you want to plot the filtered data? "Yes" OR "No" \n ','s');
if strcmp(plotting, "Yes")
    for i = 1:19
        figure;
    
        % Time domain
        subplot(2, 1, 1);
        time = (0:numel(EEG_filt(:, i))-1) / fs;
        plot(time, EEG_filt(:, i));
        xlabel('Time (s)'); ylabel('Voltage (V)'); title(string(channels(i))+'- Time Domain');
    
        % Frequency domain
        subplot(2, 1, 2);
        num_elements = numel(EEG_filt(:, i));
        freq_x = (-num_elements/2:num_elements/2 - 1) * fs / num_elements;
        freq_data = fftshift(fft(EEG_filt(:, i)));
        plot(freq_x, abs(freq_data), 'm');
        xlabel('Frequency (Hz)'); ylabel('Fourier Transform');
        title(string(channels(i))+'- Frequency Domain'); xlim(fc);
    end
    sgtitle('After Filter');
end

file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/EEGs/EEG_', subj,'_filtered.mat'];
save(file_path,'fs','channels','filtData','fc'); %saves in .mat file
disp(['Filtered EEG_', subj, '_filtered.mat saved successfully.']);

%% Performing ICA

disp('-----Performing ICA-----')
file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/EEGs/EEG_', subj,'_filtered.mat'];
load(file_path);

filtData_complete = EEG_filt;
filtData_complete(:,20) = ECG_data;

r=length(channels)-1; %number of independent components to be computed
[Zica, W, T, mu] = fastICA(filtData_complete',r,'negentropy');

plotting = input('Do you want to plot the each IC Component? "Yes" OR "No" \n ','s');
if strcmp(plotting, "Yes")
    for i = 1:r
        figure;

        % Time domain plot
        subplot(2, 1, 1);
        t = (0:1/fs:1/fs*(length(Zica(i,:))-1));
        plot(t, Zica(i, :))
        xlabel('Time (s)'); ylabel('Voltage'); title('Component '+string(i)+' - Time Domain'); xlim([0, 200]);

        % Frequency domain plot
        subplot(2, 1, 2);
        num_elements = numel(Zica(i, :));
        freq_x = (-num_elements/2:num_elements/2 - 1) * fs / num_elements;
        freq_data = fftshift(fft(Zica(i, :)));
        plot(freq_x, abs(freq_data),'m');
        xlabel('Frequency (Hz)'); xlim(fc); ylabel('Fourier Transform'); 
        title('Component '+string(i)+' - Frequency Domain');
    end
    sgtitle('FastICA')
end

%Check for Components strongly correlated to the ECG signal
list_corr =[];
component_indices = 1:r; 

for i = 1:r
    correlation = corrcoef(filtData_complete(:,20)', Zica(i,:));
    list_corr = [list_corr correlation(1, 2)];
end

[corr_sorted, idx_sorted] = sort(list_corr, 'descend');

fprintf('\nTop 5 correlations:\n');
for i = 1:5
    fprintf('Correlation %d: %.4f (Component: %d)\n', i, corr_sorted(i), component_indices(idx_sorted(i)));
end

%Eliminate Noisy components 
noisy_components = []; 
n = input('How many components will you want to remove: ');

for i = 1:n
    number = input('Insert Noisy Component: ');
    noisy_components = [noisy_components, number];
end

T(:,noisy_components)=0;

%Reconstruct the signal
processedData = (T \ (W' * Zica))';

 % Plot the reconstructed EEG and ECG data after ICA
plotting = input('Do you want to plot the each recontructed EEG after ICA? "Yes" OR "No" \n ','s');
if strcmp(plotting, "Yes")
    for i = 1:19
        figure;
    
        % Time domain
        subplot(2, 1, 1);
        time = (0:numel(processedData(:, i))-1) / fs;
        plot(time, processedData(:, i));
        xlabel('Time (s)'); ylabel('Voltage (V)'); title(string(channels(i))+'- Time Domain');
    
        % Frequency domain
        subplot(2, 1, 2);
        num_elements = numel(processedData(:, i));
        freq_x = (-num_elements/2:num_elements/2 - 1) * fs / num_elements;
        freq_data = fftshift(fft(processedData(:, i)));
        plot(freq_x, abs(freq_data), 'm');
        xlabel('Frequency (Hz)'); ylabel('Fourier Transform'); 
        title(string(channels(i))+'- Frequency Domain'); xlim(fc); 
    end
    sgtitle('After ICA');
    
    figure;
    time = 0:1/fs:1/fs*(length(processedData(:,20))-1);
    plot(time,processedData(:,20))
end

%Check Correlation of ECG in the end to ensure it is working correctly
y = corr(processedData(:,20),filtData_complete(:,20));
fprintf('\nCorrelation of idx = 20 with the ECG is : %.1f\n', y);

%Separte EEG and ECG 
ECG_filt = processedData(:,20); 
processedData(:,20)=[];
%% Plot spectrogram using Short-Time-Fourier Transform

plotting = input('Do you want to plot Short-Time-Fourier Transform? "Yes" OR "No" \n ','s');
if strcmp(plotting, "Yes")
    for i=1:length(channels)-2 %for all the channels
        figure; spectrogram(processedData(:,i),1/(1/fs),0.5/(1/fs),5/(1/fs),fs,'yaxis'); 
        ylim(fc);
        title("Short Time Fourier Transform- "+channels(i))
        stimulus_time_1 = 65.5/60;  
        stimulus_time_2 = 200.5/60;
        stimulus_time_3 = 247.45/60;
        hold on;
        line([stimulus_time_1, stimulus_time_1], ylim, 'Color', 'red', 'LineWidth', 0.4);
        line([stimulus_time_2, stimulus_time_2], ylim, 'Color', 'blue', 'LineWidth', 0.4);
        line([stimulus_time_3, stimulus_time_3], ylim, 'Color', 'black', 'LineWidth', 0.4);
        hold off;
    end
end

%% Save

save(['/Users/davidteixeira/Documents/GitHub/DavidJMT/EEG_Processed/EEG_', subj, '_processed.mat'], 'fs', 'channels', 'filtData', 'processedData','ECG_filt');
disp(['Processed information saved to EEG_', subj, '_processed.mat successfully.']);

