
subj = input('Choose the Participant: ','s');

file_path = ['/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/TRCs/EEG_', subj, '.TRC'];
allData = trc_file(file_path);
allData.get_electrode_info();
[data] = allData.def_data_access(allData.a_n_data_secs, 5, allData.a_file_elec_cell);
channels = allData.a_file_elec_cell;
Unitytime = readtable('/Users/davidteixeira/Documents/GitHub/DavidJMT/Dados/EEG_time.xlsx');

data_eeg = allData.a_start_ts;
serial_date1 = datetime(data_eeg);
serial_date2 = Unitytime.Var1(str2double(subj));

% Calculate time difference
time_difference_days = serial_date2 - serial_date1;
disp(['The time difference is: ', char(time_difference_days)])

%Change the beginning of the video

save(['/Users/davidteixeira/Desktop/EEGs_ForTIme/EEG', subj, '.mat'], 'data');
disp(['Initial EEG_', subj, '.mat saved successfully.']);
