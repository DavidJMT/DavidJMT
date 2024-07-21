function [rr_intervals_before,rr_intervals_after] = ecg_processing(qrs_i_raw, stimulus, fs)

% Define the stimulus time based on the input stimulus type
if stimulus == 1
    stimulus_time = 66.5;
elseif stimulus == 2
    stimulus_time = 200.5;
else 
    stimulus_time = 247.45;
end

stimulus_sample = round(stimulus_time * fs);
duration = 20; %Duration before and after stimulus in seconds
start_sample = stimulus_sample - round(duration * fs);
end_sample = stimulus_sample + round(duration * fs);

% Segment the QRS locations
qrs_locs_before = qrs_i_raw(qrs_i_raw >= start_sample & qrs_i_raw < stimulus_sample);
qrs_locs_after = qrs_i_raw(qrs_i_raw >= stimulus_sample & qrs_i_raw <= end_sample);

% Calculate RR Intervals for each segment
rr_intervals_before = diff(qrs_locs_before) / fs; %before stimulus
rr_intervals_after = diff(qrs_locs_after) / fs; %after stimulus




