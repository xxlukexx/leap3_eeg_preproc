s1 = 23;
s2 = 1436;

tab_eeg = tab(s1:s2, :);

ses = readtable('/Volumes/for_dianna/EEG_in/109057020142/EEG/session_files/session1/mmn.csv');
code_ses = ses.EEGCode;

for i = 1:size(tab_eeg, 1)

    val_eeg = extractNumeric(tab_eeg.type{i});
    val_ses = code_ses(i);
    match = isequal(val_eeg, val_ses);
    if match
        match_str = 'match';
    else
        match_str = '<strong> MISMATH </strong>';
    end

    fprintf('EEG: %s | ses: %d     %s\n', tab_eeg.type{i}, code_ses(i), match_str)


end

