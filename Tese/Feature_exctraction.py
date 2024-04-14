import numpy as np
from scipy.signal import spectrogram
import pandas as pd
import matplotlib.pyplot as plt

participants = np.array([9,2]) #list for the participants
numPartic = len(participants)
numChannels = 19
fs = 512
condition = input("Choose one condition: threat, sound, rock: ")

# Feature Extraction
stimulus_length = np.arange(round(122.8 * fs), round(123.8 * fs))  # threat stimulus appearance- 122.8s to 123.8s

# stimulusData and neutralData will be posteriorly used in the connectivity analysis
stimulusData = np.zeros((numChannels, len(stimulus_length), numPartic))  # stimulusData variable will contain the EEG time series correspondent to the threat stimulus apperance
neutralData = np.zeros((numChannels, len(stimulus_length), len(range(20 * fs, 101 * fs, fs)), numPartic))  # neutralData will contain the EEG time series correspondent to several neutral instants (from 20s to 100s)

bands = ["delta", "theta", "alpha", "beta", "gamma"]  # bands names
freqBands = np.array([[0.5, 4], [4, 7], [8, 12], [13, 30], [30, 80]])  # frequency range for each band

all_subj = np.zeros((numPartic, 5, 19 * len(bands)))
#if condition == 'rock':
#    all_subj = np.zeros((numPartic, 5, 19 * len(bands)))  # 5= number of time instants to be analyzed
#else:
#    all_subj = np.zeros((numPartic, 5, 19 * len(bands)))  # 4= number of time instants to be analyzed

for part in range(numPartic):
    file_path = '/Users/davidteixeira/Documents/GitHub/DavidJMT/Tese/EEG_9_processed.npz'
    #file_path = '/Users/davidteixeira/Documents/GitHub/DavidJMT/Tese/EEG_{}_processed.npz'.format(participants[part])
    data_load = np.load(file_path, allow_pickle=True )
    processedData = data_load ['filtData']
    channels = data_load['channels']

    # saves the temporal data corresponding to the neutral state
    neutIdx = 0
    for neut in range(20 * fs, 101 * fs, fs):
        neutralData[:, :, neutIdx, part] = processedData[:,range(neut,neut + fs)]
        neutIdx += 1

    # saves the temporal data corresponding to the threat stimulus
    stimulusData[:, :, part] = processedData[:,stimulus_length]

    allChanFeats = np.zeros((0, len(freqBands)))
    for c in range(channels.size):  # for all the channels
        # Spectrogram using STFT
        frequencies, time, p = spectrogram(processedData, fs=fs, window='hann', nperseg=fs, noverlap=0.5/(1/fs), nfft=5/(1/fs))

        # find neutral indices
        neutral_idx1 = np.abs(time - 20).argmin()  # index corresponding to instant 20 s (start of the neutral part)
        neutral_idx2 = np.abs(time - 100).argmin()  # index corresponding to instant 100 s (end of the neutral part)

        # find stimulus index
        if condition == 'threat':
            condit_idx = np.abs(time - 123).argmin()  # threat -> 123 s (threat_idx -> [122.5 123.5]s)
        elif condition == 'sound':
            condit_idx = np.abs(time - 194).argmin()  # sound -> 194 s (sound_idx -> [193.5 194.5]s)
        else:  # rock
            condit_idx = np.abs(time - 286).argmin()  # bird -> 285 s (bird_idx -> [284.5 285.5]s)

        # Indices corresponding to the time segments of interest
        segments = [neutral_idx1, condit_idx, condit_idx + 1, condit_idx + 2, condit_idx + 3]  # 1 before stimulus and 3 after stimulus
        #if condition == 'rock':
        #    segments = [neutral_idx1, condit_idx, condit_idx + 1, condit_idx + 2, condit_idx + 3]  # 1 before stimulus and 4 after stimulus

        featsArray = np.zeros((0, len(freqBands)))
        for i in range(len(segments)):  # for each time segment
            feats = np.zeros((1, len(freqBands)))

            for b in range(len(freqBands)):  # for each frequency band
                if i == 0:  # i=1 corresponds to the neutral (before stimulus) time segment
                    for ii in range(neutral_idx1, neutral_idx2 + 1):
                        # absolute power of the considered frequency band
                        feats[0, b] += np.sum(p[:,np.where((frequencies >= freqBands[b, 0]) & (frequencies <= freqBands[b, 1]))[0], ii])

                    # mean of (neutral_idx1:neutral_idx2) neutral segments
                    feats[0, b] /= (neutral_idx2 - neutral_idx1 + 1)

                # absolute power of the considered frequency band
                feats[0, b] = np.sum(p[:,np.where((frequencies >= freqBands[b, 0]) & (frequencies <= freqBands[b, 1]))[0], segments[i]])

            # relative power of each frequency band
            feats = feats / np.sum(p[:,np.where((frequencies >= 0.5) & (frequencies <= 80)), segments[i]])
            featsArray = np.vstack((featsArray, feats))

        allChanFeats = np.vstack((allChanFeats, featsArray))
    all_subj[part, :, :] = allChanFeats.T

    print(part)
    print(feats)

# create column names for the final features table
columnNames=[]; #column names for the final features table

for c in range(1,len(channels)):
    for b in range(1,len(bands)):
        columnNames += [channels[c] + "_" + bands[b]]


#create table with column names
# Reshape it to a 2-D array (adjust the shape as needed)
#all_subj_2d = all_subj.reshape(5, 95)

# Create a DataFrame
#all_subj_df = pd.DataFrame(all_subj_2d)
#all_subj_table=pd.DataFrame(all_subj);
#all_subj_feats=all_subj_df.values;

#print(all_subj_feats.size)

# Create a DataFrame
all_subj_2d = all_subj.reshape(all_subj.shape[0], -1)
all_subj_df = pd.DataFrame(all_subj_2d)

# To access the data in the DataFrame (equivalent to .Variables in MATLAB)
all_subj_feats = all_subj_df.values

for i in range(len(channels)):
    for j in range(len(bands)):
        label = f"{channels[i]}_{bands[j]}"
        data = [all_subj[:, 0, np.where(columnNames == label)[0][0]],
                all_subj[:, 1, np.where(columnNames == label)[0][0]],
                all_subj[:, 2, np.where(columnNames == label)[0][0]],
                all_subj[:, 3, np.where(columnNames == label)[0][0]]]

        plt.figure()
        plt.boxplot(data, sym='', labels=['t(neutral)', 't(stimulus)', 't(stimulus+1)', 't(stimulus+2)'])
        plt.title(f"Channel: {channels[i]}; Frequency Band: {bands[j]}")
        plt.ylabel('Relative PSD')
        plt.show()