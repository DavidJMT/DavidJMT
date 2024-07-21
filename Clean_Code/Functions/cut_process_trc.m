function [data, channels, fs] = cut_process_trc(subj,plotting)
%
% Input:        subj - number of the participants which EEG will be read
%               plotting - setting for plotting '1' 
%
% Output:       channels - all the channel's name from the electrodes 
%               data - raw EEG signal
%               fs - sampling frequency
%
% Description:  This function uses the MATLAB function trc_file to exctract
%               for the MATLAB to be able to read the TRC file and turn it
%               to into a readible MATLAB variable. Besides, this cuts the
%               signal for the size of the video (4min and 25s) exctracting
%               the values from the Excel that has all the starting times 
%               of the video.

    file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/TRCs/EEG_', subj, '.TRC'];
    allData = trc_file(file_path);
    allData.get_electrode_info();
    [data] = allData.def_data_access(allData.a_n_data_secs, 5, allData.a_file_elec_cell);
    channels = allData.a_file_elec_cell;
    fs = allData.a_samp_freq;

    %Option 1 - Utilise the difference from the video
    Unitytime = readtable('/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEG_time.xlsx');
    
    if strcmp(plotting, "1")
        disp("Plotting raw data")
        for i = 1:length(channels) - 2
            figure;
            spectrogram(data(i,:), 1/(1/fs), 0.5/(1/fs), 5/(1/fs), fs, 'yaxis');
            title("Short Time Fourier Transform- " + channels(i));
        end
    end
    
    data_eeg = allData.a_start_ts; 
    serial_date1 = datetime(data_eeg); 
    serial_date2 = Unitytime.Var1(str2double(subj));
    
    % Calculate time difference
    time_difference_days = serial_date2 - serial_date1;
    disp(['The time difference is: ', char(time_difference_days)])
    
    %Change the beginning of the video
    init_video = input('Video starts at: ');
    video_duration = 265;
    inicio = init_video * fs;
    fim = (init_video * fs) + (video_duration*fs);
    data=data(:,inicio:fim)'; %Remove the instants before and after the video
end
