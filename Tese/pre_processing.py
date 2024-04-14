#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
@author: davidteixeira
"""
from scipy.io import loadmat
from scipy.signal import iirnotch, filtfilt, butter, spectrogram
import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import FastICA

plt.rcParams['figure.max_open_warning'] = 100

# Importing the data with data related to the video 
subj = int(input("Choose the Participant: "))
file_path = '/Users/davidteixeira/Documents/Universidade/Tese/EEG_{}.mat'.format(subj)
data_mat = loadmat(file_path)
fs = int(np.squeeze(data_mat['fs']))  #becomes a scalar
channels = data_mat['channels']
data = data_mat['data'].T #(19xn)

# Plot the data for the subject before filter
for i in range(0,channels.size):
    plt.figure()

    # Time domain
    plt.subplot(2, 1, 1)
    time = np.arange(0, len(data[i, :])/fs, 1/fs)
    plt.plot(time, data[i, :],linewidth=0.05)
    plt.xlabel('Time (s)'); plt.ylabel('Voltage (V)'); plt.title(str(channels[0][i]) + ' - Time Domain')

    # Frequency domain
    plt.subplot(2, 1, 2)
    num_elements = len(data[i, :])
    freq_x = np.arange(-num_elements//2, num_elements//2) * fs / num_elements
    freq_data = np.fft.fftshift(np.fft.fft(data[i, :]))
    plt.plot(freq_x, np.abs(freq_data), 'm',linewidth=0.5)
    plt.xlabel('Frequency (Hz)'); plt.ylabel('Fourier Transform')
    plt.title(str(channels[0][i]) + ' - Frequency Domain')
plt.show()

# Filtering
fc = np.array([37, 50])  # The data were filtered between 0.5–70.0 Hz using a 50 Hz Notch filter to remove power line noise
wo = fc / (fs / 2)
Q=30 #Q = w0/bw

b, a = iirnotch(wo[0], Q)
filtData = filtfilt(b, a, data)

b, a = iirnotch(wo[1], Q)
filtData = filtfilt(b, a, filtData)

# Apply bandpass filter
fc_bandpass = [0.5, 80]  # Bandpass filter cut frequencies
fc_low = fc_bandpass[0]
fc_high = fc_bandpass[1]
nyquist = 0.5 * fs
low = fc_low / nyquist
high = fc_high / nyquist
order = 4  # Filter order

b, a = butter(order, [low, high], btype='band',analog=False)
filtData = filtfilt(b, a, filtData)

# Plot the data for the subject after filter
for i in range(channels.size):
    plt.figure()
    
    # Time domain
    plt.subplot(2, 1, 1)
    time = np.arange(0, len(filtData[i, :])/fs, 1/fs)
    plt.plot(time, filtData[i, :],linewidth=0.05)
    plt.xlabel('Time (s)'); plt.ylabel('Voltage (V)'); plt.title(str(channels[0][i]) + ' - Time Domain')
    
    # Frequency domain
    plt.subplot(2, 1, 2)
    num_elements = len(filtData[i, :])
    freq_x = np.arange(-num_elements//2, num_elements//2) * fs / num_elements
    freq_data = np.fft.fftshift(np.fft.fft(filtData[i, :]))
    plt.plot(freq_x, np.abs(freq_data), 'm',linewidth=0.5); plt.xlim(fc)
    plt.xlabel('Frequency (Hz)'); plt.ylabel('Fourier Transform'); plt.title(str(channels[0][i]) + ' - Frequency Domain')
plt.close()

# ICA
r = channels.size
ica = FastICA(n_components=r)
Zfica = ica.fit_transform(filtData.T)
W = ica.mixing_
T = ica.whitening_
Zfica = Zfica.T

#Plot each IC in the time and frequency domains
for i in range(1, r):
    plt.figure()
    
    # Time domain plot
    plt.subplot(2, 1, 1)
    t = np.arange(0, len(Zfica[i-1,:])/fs, 1/fs)
    plt.plot(t, Zfica[i-1,:], linewidth=0.05)
    plt.xlabel('Time (s)'); plt.ylabel('Voltage'); plt.title(f'Component {i} - Time Domain'); plt.xlim([0, 200])
    
    # Frequency domain plot
    plt.subplot(2, 1, 2)
    num_elements = len(Zfica[i-1, :])
    freq_x = np.arange(-num_elements//2, num_elements//2) * fs / num_elements
    freq_data = np.fft.fftshift(np.fft.fft(Zfica[i, :]))
    plt.plot(freq_x, np.abs(freq_data), 'm')
    plt.xlim(fc_bandpass); plt.xlabel('Frequency (Hz)'); plt.ylabel('Fourier Transform'); plt.title(f'Component {i} - Frequency Domain')
plt.close()

# Plot all ICs in the same graph
for i in range(r):
    plt.subplot(r, 1, i + 1)
    t = np.arange(0, len(Zfica[i, :])) / fs
    plt.plot(t, Zfica[i, :], '-',  linewidth=0.1)
    plt.xlim([0, 50])
    plt.ylabel(str(i + 1))
plt.close()

#Reconstruction of the EEG data without the noisy IC
noisy_components = []  
n = int(input("How many components will you want to remove: ")) 
for i in range(n):
    number = int(input('Insert Noisy Component:')) - 1
    noisy_components.append(number) 

#Eliminate noisy components
T[:, noisy_components] = 0
processedData = (T @ Zfica)

# Plot the reconstructed EEG data after ICA
for i in range(channels.size):
    plt.figure()

    # Time domain
    plt.subplot(2, 1, 1)
    time = np.arange(0, len(processedData[i, :]) / fs, 1 / fs)
    plt.plot(time, processedData[i, :])
    plt.xlabel('Time (s)'); plt.ylabel('Voltage (V)'); plt.title(str(channels[0][i]) + ' - Time Domain')
    
    # Frequency domain
    plt.subplot(2, 1, 2)
    num_elements = len(processedData[i-1, :])
    freq_x = np.arange(-num_elements//2, num_elements//2) * fs / num_elements
    freq_data = np.fft.fftshift(np.fft.fft(processedData[i, :]))
    plt.plot(freq_x, np.abs(freq_data), 'm')
    plt.xlabel('Frequency (Hz)'); plt.ylabel('Fourier Transform'); plt.title(str(channels[0][i]) + ' - Frequency Domain')
    plt.xlim(fc)  # Set frequency range
plt.close()

#Plotting the spectrogram
for i in range(channels.size):
    f, t, Sxx = spectrogram(processedData[i, :], fs=1/(1/fs), nperseg=int(0.5/(1/fs)), noverlap=int(0.45/(1/fs)), nfft=int(5/(1/fs)))
    plt.figure()
    plt.pcolormesh(t, f, 10 * np.log10(Sxx), shading='gouraud')
    plt.colorbar(label='Power (dB)'); plt.ylim(fc) 
    plt.title("Short Time Fourier Transform - " + str(channels[0][i])); plt.ylabel('Frequency [Hz]'); plt.xlabel('Time [sec]')
plt.close()

np.savez(f'/Users/davidteixeira/Documents/GitHub/DavidJMT/Tese/EEG_{subj}_processed.npz', fs=fs, channels=channels, filtData=filtData)
print("User information saved to 'EEG_1.txt' successfully.")
