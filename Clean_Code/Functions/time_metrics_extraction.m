function metrics = time_metrics_extraction(rr_intervals)

%Calculate Heart Rate for each segment
heart_rate = 60 ./ rr_intervals; %before stimulus

% Time-domain Features
mean_rr = mean(rr_intervals);
sdnn = std(rr_intervals); 
rmssd = sqrt(mean(diff(rr_intervals).^2)); 
nn50 = sum(abs(diff(rr_intervals)) > 0.05);
pnn50 = nn50 / length(rr_intervals);
nn20 = sum(abs(diff(rr_intervals)) > 0.02);
pnn20 = nn20 / length(rr_intervals);

%Display Results
fprintf('Mean RR Interval: %.4f seconds\n', mean_rr);
fprintf('SDNN (HRV): %.4f seconds\n', sdnn);
fprintf('Mean Heart Rate: %.2f bpm\n', mean(heart_rate));
fprintf('RMSSD: %.4f ms\n', rmssd);
fprintf('NN50: %d\n', nn50);
fprintf('pNN50: %.4f\n', pnn50);
fprintf('NN20: %d\n', nn20);
fprintf('pNN20: %.4f\n\n', pnn20);

metrics = [mean_rr, sdnn, rmssd, nn50,pnn50, nn20, pnn20];
end