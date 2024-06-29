function qrs_i_raw = ecg_processing(ecg_signal, stimulus, fs)

% Define the stimulus time based on the input stimulus type
if stimulus == 1
    stimulus_time = 66.5;
elseif stimulus == 2
    stimulus_time = 200.5;
else 
    stimulus_time = 247.45;
end

%Applying the pan_tompkin function
[~, qrs_i_raw, ~] = pan_tompkin(ecg_signal, fs);

stimulus_sample = round(stimulus_time * fs);
duration = 15; %Duration before and after stimulus in seconds
start_sample = stimulus_sample - round(duration * fs);
end_sample = stimulus_sample + round(duration * fs);

% Segment the QRS locations
qrs_locs_before = qrs_i_raw(qrs_i_raw >= start_sample & qrs_i_raw < stimulus_sample);
qrs_locs_after = qrs_i_raw(qrs_i_raw >= stimulus_sample & qrs_i_raw <= end_sample);

% Calculate RR Intervals for each segment
rr_intervals_before = diff(qrs_locs_before) / fs; %before stimulus
rr_intervals_after = diff(qrs_locs_after) / fs; %after stimulus

% Calculate Heart Rate for each segment
heart_rate_before = 60 ./ rr_intervals_before; %before stimulus
heart_rate_after = 60 ./ rr_intervals_after; %after stimulus

% Calculate HRV (SDNN) for each segment
mean_rr_before = mean(rr_intervals_before);
sdnn_before = std(rr_intervals_before); % Standard deviation of RR intervals before stimulus
mean_rr_after = mean(rr_intervals_after);
sdnn_after = std(rr_intervals_after); % Standard deviation of RR intervals after stimulus

% Display Results
fprintf('Before Stimulus:\n');
fprintf('Mean RR Interval: %.4f seconds\n', mean_rr_before);
fprintf('SDNN (HRV): %.4f seconds\n', sdnn_before);
fprintf('Mean Heart Rate: %.2f bpm\n\n', mean(heart_rate_before));

fprintf('After Stimulus:\n');
fprintf('Mean RR Interval: %.4f seconds\n', mean_rr_after);
fprintf('SDNN (HRV): %.4f seconds\n', sdnn_after);
fprintf('Mean Heart Rate: %.2f bpm\n', mean(heart_rate_after));

% Statistical Comparison (e.g., t-test)
[~, p_rr] = ttest2(rr_intervals_before, rr_intervals_after);
[~, p_hr] = ttest2(heart_rate_before, heart_rate_after);

fprintf('\nStatistical Comparison (t-test):\n');
fprintf('RR Intervals: p-value = %.4f\n', p_rr);
fprintf('Heart Rate: p-value = %.4f\n', p_hr);

% Plotting the Results
t = (1:length(ecg_signal)) / fs;

figure;
subplot(2, 1, 1);
plot(t, ecg_signal);
hold on;
plot(t(qrs_locs_before), ecg_signal(qrs_locs_before), 'ro');
plot(t(qrs_locs_after), ecg_signal(qrs_locs_after), 'go');
xline(stimulus_time, '--k', 'Stimulus');
title('ECG Signal with Detected QRS Complexes');
xlabel('Time (s)'); ylabel('Amplitude');
legend('ECG Signal', 'QRS Before Stimulus', 'QRS After Stimulus', 'Stimulus Time');

subplot(2, 1, 2);
plot(rr_intervals_before);
hold on;
plot(length(rr_intervals_before) + (1:length(rr_intervals_after)), rr_intervals_after);
xline(length(rr_intervals_before), '--k', 'Stimulus');
title('RR Intervals Before and After Stimulus');
xlabel('Beat Number'); ylabel('RR Interval (s)');
legend('RR Intervals Before', 'RR Intervals After', 'Stimulus Time');

% Print whenever the heart rate goes up
fprintf('\nHeart Rate Changes After Stimulus (first %.2f seconds):\n', duration);
for i = 2:length(heart_rate_after)
    if heart_rate_after(i) > heart_rate_after(i-1)
        fprintf('Heart rate increased from %.2f bpm to %.2f bpm at time %.2f seconds after stimulus.\n', ...
                heart_rate_after(i-1), heart_rate_after(i), (qrs_locs_after(i) / fs) - stimulus_time);
    end
end

end
