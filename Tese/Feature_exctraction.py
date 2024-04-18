import numpy as np
from scipy.signal import spectrogram
import pandas as pd
import matplotlib.pyplot as plt
from scipy import stats
from statsmodels.stats.multicomp import pairwise_tukeyhsd

participants = np.array([9, 18, 19, 24]) #list for the participants
numPartic = len(participants)
numChannels = 19
fs = 512
condition = input("Choose one condition: threat, sound, rock: ")


# Feature Extraction
stimulus_length = np.arange(round(122.8 * fs), round(123.8 * fs))  # threat stimulus appearance- 122.8s to 123.8s
neutral_length = np.arange(20 * fs, 101 * fs, fs)

# stimulusData and neutralData will be posteriorly used in the connectivity analysis
stimulusData = np.zeros((numChannels, len(stimulus_length), numPartic))  # stimulusData variable will contain the EEG time series correspondent to the threat stimulus apperance
neutralData = np.zeros((numChannels, len(stimulus_length), len(neutral_length), numPartic))  # neutralData will contain the EEG time series correspondent to several neutral instants (from 20s to 100s)

bands = ["delta", "theta", "alpha", "beta", "gamma"]  # bands names
freqBands = np.array([[0.5, 4], [4, 7], [8, 12], [13, 30], [30, 80]])  # frequency range for each band

all_subj = np.zeros((numPartic, 5, 19 * len(bands)))

for participant in range(numPartic):
    file_path = '/Users/davidteixeira/Documents/GitHub/DavidJMT/Tese/EEG_{}_processed.npz'.format(participants[participant])
    data_load = np.load(file_path, allow_pickle=True )
    processedData = data_load ['filtData']
    channels = data_load['channels'].tolist()

    # saves the temporal data corresponding to the neutral state
    neutIdx = 0
    for neut in range(len(neutral_length)):
        neutralData[:, :, neutIdx, participant] = processedData[:,range(neut,neut + fs)]
        neutIdx += 1

    # saves the temporal data corresponding to the threat stimulus
    stimulusData[:, :, participant] = processedData[:,stimulus_length]

    allChanFeats = np.zeros((0, len(freqBands)))
    for c in range(len(channels)):  # for all the channels
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
    all_subj[participant, :, :] = allChanFeats.T

    print(participant+1)

# create column names for the final features table
columnNames=[]; #column names for the final features table

for c in range(len(channels)):
    for b in range(len(bands)):
        columnNames += [channels[c] + "_" + bands[b]]

#Boxplots for each frequency band and channel, englobing all the participants
for i in range(len(channels)):
    for j in range(len(bands)):
        label = channels[i] + "_" + bands[j]
        indices = np.where(np.array(columnNames) == label)[0]

        data_0 = all_subj[:, 0, indices]
        data_1 = all_subj[:, 1, indices]
        data_2 = all_subj[:, 2, indices]
        data_3 = all_subj[:, 3, indices]
        data_4 = all_subj[:, 4, indices]

        datai_0 = data_0.reshape(all_subj.shape[0], -1)
        datai_1 = data_1.reshape(all_subj.shape[0], -1)
        datai_2 = data_2.reshape(all_subj.shape[0], -1)
        datai_3 = data_3.reshape(all_subj.shape[0], -1)
        datai_4 = data_4.reshape(all_subj.shape[0], -1)

        data = [datai_0, datai_1, datai_2, datai_3, datai_4]

        data_flattened = [array.flatten() for array in data]

        plt.figure()
        plt.boxplot(data_flattened, sym='', labels=['t(neutral)', 't(stimulus)', 't(stimulus+1)', 't(stimulus+2)','t(stimulus+3)'])
        plt.title(f"Channel: {channels[i]}; Frequency Band: {bands[j]}")
        plt.ylabel('Relative PSD')
        plt.close()


# for i in range(len(channels)):
#     for j in range (len(bands)):
#         label = channels[i] + "_" + bands[j]
#         indices = np.where(np.array(columnNames) == label)[0]
#         print(indices)
#         data = [all_subj[:, 0, indices],
#                 all_subj[:, 1, indices],
#                 all_subj[:, 2, indices],
#                 all_subj[:, 3, indices],
#                 all_subj[:, 4, indices]]
        
#         result = stats.kruskal(data[0], data[1], data[2], data[3], data[4])

#         print("Statistic:", result.statistic)
#         print("p-value:", result.pvalue)


from scipy.stats import kstest
import numpy as np

print("Kolmogorov-Smirnov test\n")

for i in range(len(channels)):
    for j in range(len(bands)):
        for k in range(len(segments)):
            label = channels[i] + "_" + bands[j]

            data = all_subj[:, k, columnNames.index(label)]
            std_dev = np.std(data)
            if std_dev > 0:  # Check if standard deviation is greater than zero
                normalized_data = (data - np.mean(data)) / std_dev
                h = kstest(normalized_data, 'norm')
            else:
                print(f"Standard deviation of data for group {channels[i]}_{bands[j]} (segment{k}) is zero or close to zero")

            if h == 1:  # h=0 -> normal distribution
                print(f"Group {channels[i]}_{bands[j]} (segment{k}) doesn't have a normal distribution")


print("Relevant features based on Kruscal-Wallis\n\n")

for i in range(len(channels)):
    for j in range(len(bands)):
        label = channels[i] + "_" + bands[j]

        # Assuming you have imported necessary libraries and have the required data
        # Replace the following lines with actual data and function calls
            # Replace the following line with actual data
        data = [all_subj[:, 0, columnNames.index(label)],
                all_subj[:, 1, columnNames.index(label)],
                all_subj[:, 2, columnNames.index(label)],
                all_subj[:, 3, columnNames.index(label)],
                all_subj[:, 4, columnNames.index(label)]]

        # Perform Kruskal-Wallis test
        result = stats.kruskal(data[0], data[1], data[2], data[3], data[4])
        
        print("Statistic:", result.statistic)
        print("p-value:", result.pvalue)

        # # Multiple comparison (with Bonferroni correction)
        # gnames = pairwise_tukeyhsd(result, ['t(neutral)', 't(stimulus)', 't(stimulus+1)', 't(stimulus+2)', 't(stimulus+3)'])
        # print(f"Channel: {channels[i]}; Frequency Band: {bands[j]}")

        # idx = [k for k in range(len(c)) if c[k, 6] <= 0.05]
        # # c[:, 6] -> column with the p values
        # # c[:, 6] <= 0.05 -> p values <= significance level 0.05

        # if len(idx) > 0:  # If there are p values < 0.05
        #     for k in idx:
        #         if c[k, 1] == 1 or c[k, 2] == 1:
        #             # Because we want the significant difference compared with the instant before stimulus (neutral condition)
        #             print(f"{label} ({c[k, 1]}, {c[k, 2]})")
