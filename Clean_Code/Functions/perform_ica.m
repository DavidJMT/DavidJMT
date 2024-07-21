function [processedData] = perform_ica(EEG_filt , ECG_data, channels, fs)

disp('-----Performing ICA-----')

fc = [0.5,80];

%% Compute independent components
r=19; %number of independent components to be computed
[Zica, W, T, ~] = fastICA(EEG_filt',r,'negentropy');

for i = 1:r
    figure;
    sgtitle('Independent Components')

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
    xlabel('Frequency (Hz)'); xlim(fc); ylabel('Fourier Transform'); title('Component '+string(i)+' - Frequency Domain');
end

%% Identify noisy components for drift and muscle artifacts

artifact_components = [];

% Define frequency bands
high_freq_band = [30 100]; % Example high-frequency range for muscle artifacts
low_freq_band = [0.1 1];   % Example low-frequency range for drift

for i = 1:r
    % Compute power spectrum using Welch's method
    [pxx, f] = pwelch(Zica(i,:), [], [], [], fs);

    % Ensure frequency band ranges are within the computed spectrum
    high_freq_band_idx = (f >= high_freq_band(1)) & (f <= high_freq_band(2));
    low_freq_band_idx = (f >= low_freq_band(1)) & (f <= low_freq_band(2));

    % Compute power in the defined bands
    high_freq_power = bandpower(pxx, f, high_freq_band, 'psd');
    low_freq_power = bandpower(pxx, f, low_freq_band, 'psd');

    % Thresholds for artifact detection (these may need tuning)
    if high_freq_power > 0.5 || low_freq_power > 0.5
        artifact_components = [artifact_components, i];
    end
end

% Convert artifact_components to a string for printing
if isempty(artifact_components)
    fprintf('No components are detected as artifacts.\n');
else
    % Convert the list of artifact components to a comma-separated string
    artifact_str = num2str(artifact_components);
    fprintf('The component(s) %s are probably related to drift or muscle artifact.\n', artifact_str);
end

%% Check for Components strongly correlated for cardiac artifacts
% Initialize list to store correlations and their corresponding component indices
list_corr = [];
component_indices = 1:r;

% Compute correlations
for i = 1:r
    correlation = corrcoef(ECG_data(:,1)', Zica(i,:));
    list_corr = [list_corr, correlation(1, 2)];
end
% Filter correlations greater than 0.3
threshold = 0.3;
high_corr_indices = list_corr > threshold;

% Extract high correlations and their indices
high_corr_values = list_corr(high_corr_indices);
high_corr_components = component_indices(high_corr_indices);

if isempty(high_corr_values)
    fprintf('No components have correlations greater than %.1f. with ECG signal \n', threshold);
else
    for i = 1:length(high_corr_values)
        fprintf('Correlation: %.4f (Component: %d) with ECG signal. \n', high_corr_values(i), high_corr_components(i));
    end
end

%% Eliminate Noisy components
noisy_components = [];
n = input('How many components will you want to remove: ');

for i = 1:n
    number = input('Insert Noisy Component: ');
    noisy_components = [noisy_components, number];
end

Zica(noisy_components,:)=0;

%% Reconstruct the EEG signal
processedData = (T \ W' * Zica)';

% Plot the reconstructed EEG and ECG data after ICA
plotting = input('Do you want to plot the each recontructed EEG after ICA? "Yes" OR "No" \n ','s');
if strcmp(plotting, "Yes")
    for i = 1:19
        figure;
        sgtitle('EEG Signal after FastICA');
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

end

%Check Correlation of ECG in the end to ensure it is working correctly
y = corr(processedData(:,19),EEG_filt(:,19));
fprintf('\nCorrelation of idx = 19 with the electrode 19 is : %.1f\n', y);


end
