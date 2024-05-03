%% Read raw data and remove excess data from non-relevant video

subj = 24;
file_path = sprintf('/Users/davidteixeira/Documents/GitHub/DavidJMT/EEGs/EEG_%d.TRC', subj);

allData = trc_file(file_path);
allData.get_electrode_info();
[data] = allData.def_data_access (allData.a_n_data_secs,5,allData.a_file_elec_cell); %[data,time]=def_data_access(self, wsize, step, channs_cell, offset)

channels = allData.a_file_elec_cell; % self.a_file_elec_cell -> cell array containing the names of all electrodes presented in the file
fs = allData.a_samp_freq; %sampling frequency

% Date definition
data_game = '2024-04-29 19:52:07' % Format: YYYY-MM-DD HH:MM:SS
data_eeg = allData.a_start_ts % Format: YYYY-MM-DD HH:MM:SS

% Convert dates to serial date numbers
serial_date1 = datetime(data_eeg);
serial_date2 = datetime(data_game);

% Calculate time difference in days
time_difference_days = serial_date2 - serial_date1

%%
init_video = 32;
video_duration = 290;
inicio = init_video*fs;
fim = init_video * fs + (video_duration*fs);
data=data(:,inicio:fim); %remove the instants before and after the video

% Save the file after removing the instants before and after the video
file_path = sprintf('/Users/davidteixeira/Documents/GitHub/DavidJMT/EEGs/EEG_%d.mat', subj);
save(file_path,'fs','channels','data'); %saves in .mat file




