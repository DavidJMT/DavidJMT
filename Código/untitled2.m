% Load EEGLAB and necessary paths
[ALLEEG, EEG, CURRENTSET, ALLCOM] = eeglab;

file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEGs/EEG_2.mat'];
load(file_path);

% Load your EEG data (this is just an example, replace with your actual data)
EEG = pop_loadset;
 
% Define your channel names (19 EEG channels + 2 ECG channels)
channelNames = {'Fp1', 'Fp2', 'F7', 'F3', 'Fz', 'F4', 'F8', 'T3', 'C3', 'Cz', 'C4', 'T4', 'T5', 'P3', 'Pz', 'P4', 'T6', 'O1', 'O2', 'ECG1', 'ECG2'};

% Create a basic channel location structure
defaultLocations = {
    'Fp1', -3.5, 5; 'Fp2', 3.5, 5;
    'F7', -4.5, 3.5; 'F3', -1.5, 3.5; 'Fz', 0, 4; 'F4', 1.5, 3.5; 'F8', 4.5, 3.5;
    'T3', -6, 0; 'C3', -3, 0; 'Cz', 0, 0; 'C4', 3, 0; 'T4', 6, 0;
    'T5', -4.5, -3.5; 'P3', -1.5, -3.5; 'Pz', 0, -4; 'P4', 1.5, -3.5; 'T6', 4.5, -3.5;
    'O1', -3.5, -5; 'O2', 3.5, -5;
    'ECG1', NaN, NaN; 'ECG2', NaN, NaN % ECG channels without spatial locations
};

EEG.chanlocs = struct('labels', [], 'X', [], 'Y', [], 'Z', []);
for i = 1:length(channelNames)
    EEG.chanlocs(i).labels = channelNames{i};
    idx = find(strcmp(defaultLocations(:, 1), channelNames{i}));
    if ~isempty(idx)
        EEG.chanlocs(i).X = defaultLocations{idx, 2};
        EEG.chanlocs(i).Y = defaultLocations{idx, 3};
        EEG.chanlocs(i).Z = 0; % Z-coordinate is 0 for 2D topography
    else
        % Handle channels that don't have a predefined location
        EEG.chanlocs(i).X = NaN;
        EEG.chanlocs(i).Y = NaN;
        EEG.chanlocs(i).Z = NaN;
    end
end

% Ensure your data has an ICA decomposition
% If you haven't run ICA yet, you can do it like this:
EEG = pop_runica(EEG, 'extended', 1, 'interupt', 'on');

% Call the iclabel function
EEG = iclabel(EEG);

% Save the results
%pop_saveset(EEG, 'filename', 'your_data_with_iclabel.set', 'filepath', 'path_to_your_data/');
