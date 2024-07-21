function EEG_filt = apply_filters(data, fs, channels, plotting)
%
% Input:        data - raw eeg data in the format .trc (data,channel)
%               fs - sample frequency
%
% Output:       channels - all the channel's name from the electrodes
%               EEG_filt - filtered EEG signal
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

fc = [37 50];
wo = fc / (fs / 2);
bw = wo / 30;

% Design the first peak filter
[b, a] = iirnotch(wo(1), bw(1));
filtData = filtfilt(b, a, data);

% Design the second peak filter
[b, a] = iirnotch(wo(2), bw (2));
filtData = filtfilt(b, a, filtData);

fc = [0.5 80];
EEG_filt = bandpass(filtData, fc, fs, 'ImpulseResponse', 'fir');

if strcmp(plotting, "1")
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
        xlabel('Frequency (Hz)'); ylabel('Fourier Transform'); title(string(channels(i)) + '- Frequency Domain');
    end
    sgtitle('After Filter');
end
end
