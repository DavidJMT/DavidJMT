function import_and_plot_data(subj, fs,plotting)
%
% Input:        subj - number of the participants which EEG will be read
%               fs - sample frequency
%               plotting - setting for plotting '1' for plotting or '' for
%               not plotting
%
% Description:  This function is utilized to load the EEG file and to plot
%               the data to be viwed.

file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEGs/EEG_', subj,'.mat'];
load(file_path);

if strcmp(plotting, "1")
    disp('-----Plotting the data-----')
    for i = 1:19
        figure;

        % Time domain
        subplot(2, 1, 1);
        time = 0:1/fs:1/fs*(length(EEG_data(:,i))-1);
        plot(time, EEG_data(:, i));
        xlabel('Time (s)'); ylabel('Voltage (V)'); title(string(channels(i))+'- Time Domain');

        % Frequency domain
        subplot(2, 1, 2);
        num_elements = numel(EEG_data(:, i));
        freq_x = (-num_elements/2:num_elements/2 - 1) * fs / num_elements;
        freq_data = fftshift(fft(EEG_data(:, i)));
        plot(freq_x, abs(freq_data), 'm');
        xlabel('Frequency (Hz)'); ylabel('Fourier Transform');
        title(string(channels(i))+'- Frequency Domain');
    end
    sgtitle('Before Filter');
end