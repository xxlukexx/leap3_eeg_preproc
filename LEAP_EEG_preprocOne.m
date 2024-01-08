function tmp = LEAP_EEG_preprocOne(id)

    path_master     = '/Volumes/Projects/LEAP/_preproc/in/eeg/LEAP_EEG_master.xlsx';
    path_in = '/Volumes/Projects/LEAP/_preproc/in/eeg/bl';
    tab_master = readtable(path_master);
    
    % find site
    idx = strcmpi(tab_master.Clinical_Subjects, id);
    if ~any(idx), error('ID not found: %s', id), end
    site = tab_master.site{idx};
    
    % preocess
    path_data = fullfile(path_in, id);
    path_out = fullfile(tempdir, 'eegpreproctmp');
    if ~exist(path_out, 'dir'), mkdir(path_out); end
    tmp = LEAP_EEG_doPreproc(path_data, site, 'BASELINE', path_out, struct);

end