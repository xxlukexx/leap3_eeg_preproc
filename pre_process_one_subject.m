    % paths
    clc
    clear
    path_eeglab = 'C:\Program Files\MATLAB\R2019a\toolbox\eeglab14_1_2b_chirag';
%     addpath(path_eeglab);
    addpath('C:\Users\k1926099\Documents\EU_AIMS_EEG_code\EEG_chirag\EEG_chirag');
%     eeglab
    path_datafile = "C:\Users\k1926099\OneDrive - King's College London\EEG_data_LEAP_3\820045100";
    path_out = "C:\Users\k1926099\OneDrive - King's College London\EEG_data_LEAP_3\820045100_output\";
    wave = 2;
    LEAP_EEG_doPreproc(path_datafile, 'KCL', wave, path_out)

     LEAP_EEG_doPreproc("C:\Users\k1926099\OneDrive - King's College London\EEG_data_LEAP_3\820045100", 'KCL', 3, path_out)
    % eeglab - i have access to all these
%     addpath(path_eeglab);
%     addpath([path_eeglab '/functions/popfunc/'])
%     addpath([path_eeglab '/plugins/dipfit2.3/standard_BESA/'])
%     addpath([path_eeglab '/plugins/dipfit2.3/'])
%     addpath([path_eeglab '/functions/adminfunc'])
%     addpath([path_eeglab '/plugins/fileio'])
%     addpath([path_eeglab '/functions/guifunc'])
%     addpath([path_eeglab '/functions/sigprocfunc'])
%     addpath([path_eeglab '/plugins/firfilt1.6.1'])
    
    
%function_name
%LEAP_EEG_doPreproc(path_datafile,site, wave, path_out, ops)
clc
clear
cd 'C:\Users\k1926099\Documents\EU_AIMS_EEG_code\EEG_chirag\EEG_chirag';
path_datafile = "C:\Users\k1926099\OneDrive - King's College London\EEG_data_LEAP_3\820045100";
path_out = "C:\Users\k1926099\OneDrive - King's College London\EEG_data_LEAP_3\820045100_output\";
site = 'KCL';
wave = 3;
LEAP_EEG_doPreproc(path_datafile, site, wave, path_out)

