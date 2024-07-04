function metrics = calculate_frequency_domain(rr_intervals)

    rr_time = cumsum(rr_intervals); % Cumulative sum to get time instances of R-R intervals
    fs_interp = 4; % Interpolated sampling frequency in Hz 
    t_interp = 0:1/fs_interp:rr_time(end); % Create a time vector for interpolation
    rr_interp = interp1(rr_time, rr_intervals, t_interp, 'pchip'); % Interpolate using cubic Hermite polynomial

    % Perform power spectral density (PSD) estimation
    [pxx, f] = pwelch(rr_interp, [], [], [], fs_interp);

    % Define frequency bands
    lf_band = [0.04 0.15];
    hf_band = [0.15 0.4];

    % Integrate the power within each band
    lf = bandpower(pxx, f, lf_band, 'psd');
    hf = bandpower(pxx, f, hf_band, 'psd');
    lf_hf_ratio = lf / hf;
    
    fprintf('LF Power: %.4f\n', lf);
    fprintf('HF Power: %.4f\n', hf);
    fprintf('LF/HF Ratio: %.4f\n\n', lf_hf_ratio);

    metrics = {lf, hf, lf_hf_ratio};
end