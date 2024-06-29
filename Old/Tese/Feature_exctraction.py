import numpy as np
from scipy.signal import spectrogram, welch, csd
import pandas as pd
import matplotlib.pyplot as plt
from scipy import stats
from statsmodels.stats.multicomp import pairwise_tukeyhsd
from scipy.stats import kstest

def findDataDistribution(method,neutData,StimData,signifChannels):
        
        print("Kolmogorov-Smirnov test ("+method+")\n\n") 
        
        for i in range(len(signifChannels)):
            for j in range(i+1,len(signifChannels)):
        
                #neutral data
                normalized_data_n = (neutData[i,j,:]-np.mean(neutData[i,j,:]))/np.std(neutData[i,j,:])
                h_neut = kstest(normalized_data_n, 'norm')
                if h_neut==1: #h=0 -> normal distribution
                    print(signifChannels[i]+"-"+signifChannels[j]+" (neutral) doesn't have a normal distribution\n")
        
                #stimulus data
                normalized_data_s = (StimData[i,j,:]-np.mean(StimData[i,j,:]))/np.std(StimData[i,j,:])
                h_stim = kstest(normalized_data_s, 'norm')
                if h_stim==1: #h=0 -> normal distribution
                    print(signifChannels[i]+"-"+signifChannels[j]+" (stimulus) doesn't have a normal distribution\n")


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
columnNames=[]; 

for c in range(len(channels)):
    for b in range(len(bands)):
        columnNames += [channels[c] + "_" + bands[b]]

#Boxplots for each frequency band and channel, englobing all the participants
for i in range(len(channels)):
    for j in range(len(bands)):
        label = channels[i] + "_" + bands[j]
        label_index = columnNames.index(label)

        data_flattened = []
        for k in range(5):  # Assuming there are 5 time points
            data_k = all_subj[:, k, label_index]
            datai_k = data_k.reshape(all_subj.shape[0], -1)
            data_flattened.append(datai_k.flatten())

        plt.figure()
        plt.boxplot(data_flattened, sym='', labels=['t(neutral)', 't(stimulus)', 't(stimulus+1)', 't(stimulus+2)','t(stimulus+3)'])
        plt.title(f"Channel: {channels[i]}; Frequency Band: {bands[j]}")
        plt.ylabel('Relative PSD')
        plt.close()

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
                
                if h.pvalue < 0.05:  # h.pvalue -> p-value of the test
                    print(f"Group {channels[i]}_{bands[j]} (segment{k}) doesn't have a normal distribution")

print("Relevant features based on Kruscal-Wallis\n\n")

num_comparisons = len(channels) * len(bands)
alpha = 0.05  # Or your chosen significance level
bonferroni_alpha = alpha / num_comparisons

for i in range(len(channels)):
    for j in range(len(bands)):
        label = channels[i] + "_" + bands[j]

        data = [all_subj[:, 0, columnNames.index(label)],
                all_subj[:, 1, columnNames.index(label)],
                all_subj[:, 2, columnNames.index(label)],
                all_subj[:, 3, columnNames.index(label)],
                all_subj[:, 4, columnNames.index(label)]]

        # Perform Kruskal-Wallis 
        result = stats.kruskal(data[0], data[1], data[2], data[3], data[4])
        print(f"Channel: {channels[i]}; Frequency Band: {bands[j]}")
        print("Statistic:", result.statistic)
        print("p-value:", result.pvalue)

        # If Kruskal-Wallis is significant, perform Tukey's HSD
        if result.pvalue < bonferroni_alpha:
            data_all = np.concatenate(data)
            groups = np.repeat(['t(neutral)', 't(stimulus)', 't(stimulus+1)', 't(stimulus+2)', 't(stimulus+3)'], len(data[0]))
            tukey_result = pairwise_tukeyhsd(data_all, groups)
            print(tukey_result)

# Areas of interest (channels) obtained from the Kruscal-Wallis test

significantChannels = ['Fp1', 'Fp2', 'F7', 'Fz', 'F8', 'T3', 'C3', 'Cz', 'T4', 'T5']  

# Indices of brain areas of interest (channels)
areasOfInterest = []
for i in range(len(significantChannels)):
        areasOfInterest.append(channels.index(significantChannels[i]))

numRelevChann = len(areasOfInterest)  # number of areas/channels of interest (discriminative between the neutral and stimulus conditions)

# Remove the irrelevant channels
neutralData = neutralData[areasOfInterest, :, :, :]
stimulusData = stimulusData[areasOfInterest, :, :]


#----------------- Functional Connectivity -----------------
# Frequency band to be analysed
bandOfInterest = input("Choose one band: all, delta, theta, alpha, beta, gamma: ")
LowerFreq = float(input('Lower frequency: ')) #[0.5 80], [0.5 4], [4 7], [8 12], [13 30], [30 80]
UpperFreq = float(input('Upper frequency: '))
freqRange = [LowerFreq, UpperFreq]

# Initialize arrays
preCoherence = np.zeros((numRelevChann, numRelevChann, neutralData.shape[2], numPartic))
preImagCoherence = np.zeros((numRelevChann, numRelevChann, neutralData.shape[2], numPartic))
posCoherence = np.zeros((numRelevChann, numRelevChann, numPartic))
posImagCoherence = np.zeros((numRelevChann, numRelevChann, numPartic))


for p in range(numPartic):
    for i in range(numRelevChann):
        for j in range(numRelevChann):
            # Pre-Stimulus
            for neutIdx in range(neutralData.shape[2]):
                # Compute cross-spectral power density
                f, pre_Sxy = csd(neutralData[i, :, neutIdx, p], neutralData[j, :, neutIdx, p], fs=fs, nperseg=2048)
                f, pre_Sxx = welch(neutralData[i, :, neutIdx, p], fs=fs, nperseg=2048)
                f, pre_Syy = welch(neutralData[j, :, neutIdx, p], fs=fs, nperseg=2048)

                # Restrict to frequency band of interest
                freqIdx = np.where((f >= freqRange[0]) & (f <= freqRange[1]))
                pre_Sxy = pre_Sxy[freqIdx]
                pre_Sxx = pre_Sxx[freqIdx]
                pre_Syy = pre_Syy[freqIdx]

                preCoherency = pre_Sxy / np.sqrt(pre_Sxx * pre_Syy)  # Coherency
                preCoherence[i, j, neutIdx, p] = np.mean(np.abs(preCoherency))
                preImagCoherence[i, j, neutIdx, p] = np.mean(np.abs(np.imag(preCoherency)))

            # Pos-Stimulus
            f, pos_Sxy = csd(stimulusData[i, :, p], stimulusData[j, :, p], fs=fs, nperseg=2048)
            f, pos_Sxx = welch(stimulusData[i, :, p], fs=fs, nperseg=2048)
            f, pos_Syy = welch(stimulusData[j, :, p], fs=fs, nperseg=2048)

            pos_Sxy = pos_Sxy[freqIdx]
            pos_Sxx = pos_Sxx[freqIdx]
            pos_Syy = pos_Syy[freqIdx]

            posCoherency = pos_Sxy / np.sqrt(pos_Sxx * pos_Syy)
            posCoherence[i, j, p] = np.mean(np.abs(posCoherency))
            posImagCoherence[i, j, p] = np.mean(np.abs(np.imag(posCoherency)))


# Average of connectivity across the several neutral instants
preCoherence = np.mean(preCoherence, axis=2)
preImagCoherence = np.mean(preImagCoherence, axis=2)

# Average of all the participants
avgPreCoherence = np.mean(preCoherence, axis=2)
avgPreImagCoherence = np.mean(preImagCoherence, axis=2)
avgPosCoherence = np.mean(posCoherence, axis=2)
avgPosImagCoherence = np.mean(posImagCoherence, axis=2)

# Pos-Pre (difference between the connectivity values of the neutral and threat conditions)
diffCoherence = avgPosCoherence - avgPreCoherence
diffImagCoherence = avgPosImagCoherence - avgPreImagCoherence

# kstest to find data distribution
findDataDistribution('Coherence',preCoherence,posCoherence,significantChannels)
print("-----\n")
findDataDistribution('Imaginary Part of Coherence',preImagCoherence,posImagCoherence,significantChannels)
