function plot_stft(data, channels, fs,cut)
%
% Input:        data - raw eeg data in the format .mat (data,channel)
%               fs - sample frequency
%               channels - all the channel's name from the electrodes
%               cut - setting for plotting the STFT '1' for plotting with
%               limits or '2' for plotting without limits
%
% Description:  This function is used for the plot of the STFT
%               (Short-Time Fourier Transform) with or without the 0.5-80Hz
%               limit.

if cut == "1"
    for i=1:length(channels)-2 %for all the channels
        figure; spectrogram(data(:,i),1/(1/fs),0.5/(1/fs),5/(1/fs),fs,'yaxis'); title("Short Time Fourier Transform- "+channels(i)); 
        ylim ([0.5 80]);
        stimulus_time_1 = 66.5/60;
        stimulus_time_2 = 200.5/60;
        stimulus_time_3 = 247.45/60;
        hold on;
        line([stimulus_time_1, stimulus_time_1], ylim, 'Color', 'red', 'LineWidth', 0.4);
        line([stimulus_time_2, stimulus_time_2], ylim, 'Color', 'blue', 'LineWidth', 0.4);
        line([stimulus_time_3, stimulus_time_3], ylim, 'Color', 'black', 'LineWidth', 0.4);
        hold off;

    end
else
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
end