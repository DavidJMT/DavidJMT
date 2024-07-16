function [EEG_filt, ECG_data,fc] = apply_filters(data, fs, channels)
%
% Input:        data - raw eeg data in the format (data,channel)
%               fs - sample frequency 
%
%               channels - all the channel's name from the electrodes 
% Output:       EEG_filt - filtered EEG signal 
%               ECG_data - raw ECG signal without ground component 
%
% Description:  This function can be divided into the various steps of filtering the EEG
%               signal:
%               1st -> Elimination of the DC component with a IIRNOTCH filter as well as
%               the 37 Hz
%               2nd -> Application of a bandpass from 0.5 to 80 Hz, since this is the
%               frequencies our desired EEG bands vary.
%               3rd -> Plotting the filters for visualization.

    disp('-----Applying filters-----');
    %Remove ECGground electrode from ECG electrode 
    data(:,20) = data(:,21)-data(:,20);
    data(:,21) = [];
    
    EEG_data = data(:, 1:end - 1);
    ECG_data = data(:, end);

    fc = [37 50];
    wo = fc / (fs / 2);
    bw = wo / 30;

    [b, a] = iirnotch(wo(1), bw(1));
    filtData = filtfilt(b, a, EEG_data);

    [b, a] = iirnotch(wo(2), bw(2));
    filtData = filtfilt(b, a, filtData);

    fc = [0.5 80];
    EEG_filt = bandpass(filtData, fc, fs, 'ImpulseResponse', 'fir');

    plotting = input('Do you want to plot the filtered data? "Yes" OR "No" \n ','s');
    if strcmp(plotting, "Yes")
        for i = 1:19
            figure;
            subplot(2, 1, 1);
            time = (0:numel(EEG_filt(:, i)) - 1) / fs;
            plot(time, EEG_filt(:, i));
            xlabel('Time (s)'); ylabel('Voltage (V)'); title(string(channels(i)) + '- Time Domain');

            subplot(2, 1, 2);
            num_elements = numel(EEG_filt(:, i));
            freq_x = (-num_elements/2:num_elements/2 - 1) * fs / num_elements;
            freq_data = fftshift(fft(EEG_filt(:, i)));
            plot(freq_x, abs(freq_data), 'm'); xlim(fc);
            xlabel('Frequency (Hz)'); ylabel('Fourier Transform');
            title(string(channels(i)) + '- Frequency Domain');
        end
        sgtitle('After Filter');
    end
end