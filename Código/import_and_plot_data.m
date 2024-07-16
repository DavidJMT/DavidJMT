function import_and_plot_data(subj, fs,plotting)
  
    file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEGs/EEG_', subj,'.mat'];
    load(file_path);
    
    if strcmp(plotting, "1")
        disp('-----Plotting the data-----')
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
        sgtitle('ECG Electrodes')

    
end