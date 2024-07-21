
% Load your EEG data
% For example, let's assume eeg_data is a matrix with dimensions (n_channels, n_samples)
% eeg_data = ... (load your EEG data here)

% Step 1: Apply FastICA
% Adjust the number of components as needed
num_components = 19;  % Set the number of ICA components you want

% Perform ICA using FastICA
[icasig, A, W] = fastICA(EEG_filt', num_components, 'negentropy');  % Transpose eeg_data to match fastica requirements

icaComponents = icasig'; % Each row is an ICA component

% Create dummy channel locations (adjust according to your actual data)
num_channels = size(EEG_filt, 2);
chanlocs = struct();
for i = 1:num_channels
    chanlocs(i).labels = sprintf('Ch%d', i);  % Channel labels (e.g., 'Ch1', 'Ch2', ...)
    chanlocs(i).X = rand();  % Random X-coordinate (replace with actual data)
    chanlocs(i).Y = rand();  % Random Y-coordinate (replace with actual data)
    chanlocs(i).Z = rand();  % Random Z-coordinate (replace with actual data)
end

% Create EEG structure with fields required by ICLabel
EEG = struct();
EEG.icawinv = W';         % Unmixing matrix (transpose if needed)
EEG.icasphere = eye(num_components);  % Sphere matrix (identity if not available)
EEG.icaweights = A;       % Mixing matrix
EEG.icachansind = 1:num_channels; % Channel indices (assuming all components are used)
EEG.srate = 512;          % Sampling rate (adjust according to your data)
EEG.ref = 'average';      % Reference (set to 'average' or as appropriate)
EEG.icaact = icaComponents'; % ICA activations or components
EEG.chanlocs = chanlocs;  % Channel locations


% Use ICLabel
try
    TEST = iclabel(EEG);
catch ME
    disp('Error using iclabel:');
    disp(ME.message);
    return;
end

% Display results
disp('Classification labels (one-hot encoded):');
disp(labels);

disp('Classification scores (probabilities):');
disp(scores);

% Example: Display a sample component and its classification
componentIndex = 1;  % Choose an index for a sample component
disp(['Component ' num2str(componentIndex) ' classification:']);
disp(['Labels: ' num2str(labels(componentIndex, :))]);
disp(['Scores: ' num2str(scores(componentIndex, :))]);
