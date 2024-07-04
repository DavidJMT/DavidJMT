function [processedData, ECG_filt] = perform_ica(subj, ~, ECG_data, ~, fs)

    disp('-----Performing ICA-----')
    file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEGs_Filtered/EEG_', subj,'_filtered.mat'];
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
    
    Zica(noisy_components,:)=0;
    %Reconstruct the signal
    processedData = (T \ W' * Zica)';
    
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

end
