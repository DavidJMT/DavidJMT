%% Read raw data and remove excess data from non-relevant video

subj = 9;

allData = trc_file('/Users/davidteixeira/EEG_1.TRC');
allData.get_electrode_info();
[data] = allData.def_data_access (allData.a_n_data_secs,5,allData.a_file_elec_cell); %[data,time]=def_data_access(self, wsize, step, channs_cell, offset)

channels = allData.a_file_elec_cell; % self.a_file_elec_cell -> cell array containing the names of all electrodes presented in the file
fs = allData.a_samp_freq; %sampling frequency

%init_video = 0;
%video_duration = 335;
%data = data(init_video * fs (init_video * fs + (video_duration * fs)) - 1, :); %remove the instants before and after the video

% Save the file after removing the instants before and after the video
save('/Users/davidteixeira/Documents/Universidade/Tese/EEG_1.mat','fs','channels','data'); %saves in .mat file




