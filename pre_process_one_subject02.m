    % paths
    clc
    clear
    
    % eeglab - i have access to all these
    path_eeglab = '/Users/luke/code/Dev/eeglab14_1_2b';
%     path_eeglab = 'C:\Program Files\MATLAB\R2019a\toolbox\eeglab14_1_2b_chirag';
    addpath(path_eeglab);
    addpath([path_eeglab '/functions/popfunc/'])
    addpath([path_eeglab '/plugins/dipfit2.3/standard_BESA/'])
    addpath([path_eeglab '/plugins/dipfit2.3/'])
    addpath([path_eeglab '/functions/adminfunc'])
    addpath([path_eeglab '/plugins/Fileio20191119'])
    addpath([path_eeglab '/functions/guifunc'])
    addpath([path_eeglab '/functions/sigprocfunc'])
    addpath([path_eeglab '/plugins/firfilt1.6.2'])    
    
%     addpath('C:\Users\k1926099\Documents\EU_AIMS_EEG_code\EEG_chirag\EEG_chirag');
    wave = 3;
    
    path_datafile = '/Volumes/ram/820042107';
    path_out = '/Volumes/ram/820042107_output';
    
%     path_datafile = 'C:\Users\k1926099\OneDrive - King''s College London\EEG_data_LEAP_3\820042107';
%     path_out = 'C:\Users\k1926099\OneDrive - King''s College London\EEG_data_LEAP_3\820042107_output';
    LEAP_EEG_doPreproc(path_datafile, 'KCL', wave, path_out)

    file_in = '/Volumes/ram/820042107_output/resting_state/820042107_resting_state.set';
    LEAP_EEG_restingstate_subSegment(file_in, path_out);
