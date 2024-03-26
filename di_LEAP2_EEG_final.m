%% DI: LEAP3 EEG DATA PRE-PROCESSING - MASTER SCRIPT
   %DI (k2371654@kcl.ac.uk) modified the script of LM in Jan 2024

    clc; clear variables; close all;  
    
    fprintf('<strong>LEAP EEG preprocessing pipeline starting up...</strong>');

    %add the paths to scripts
    addpath(genpath('/Users/diannailyka/Documents/leap3_eeg_preproc')) %path to LM's scripts
    addpath ('/Users/diannailyka/Documents/lm_tools'); 
    addpath ('/Users/diannailyka/Documents/TaskEngine2'); 
    addpath('/Users/diannailyka/Documents/fieldtrip-20230118', '-end'); %FT but without the subfolders (conflict of functions!); 
    
    %addpath(genpath('/Users/diannailyka/Documents/eeglab2023.1')) %path to EEGLab functions
    path_eeglab = '/Users/diannailyka/Documents/eeglab2023.1';
    addpath(path_eeglab);
    addpath([path_eeglab '/functions/popfunc/'])
    addpath([path_eeglab '/functions/adminfunc'])
    addpath([path_eeglab '/functions/guifunc'])
    addpath([path_eeglab '/functions/sigprocfunc'])
    addpath([path_eeglab '/plugins/dipfit'])
    addpath([path_eeglab '/plugins/Fileio20240110'])
    addpath([path_eeglab '/plugins/firfilt'])
    %addpath(genpath(fullfile(path_eeglab, 'plugins', 'Biosig3.8.3'))); %many functions intersect with matlab

    %DI: set-up the in & out folders 
    path_out = ('/Volumes/for_dianna/EEG_out'); %output folder
    file_folder=('/Volumes/for_dianna/EEG_in'); %general folder
    cd(file_folder)
    fileList = dir(file_folder); 
    %some files are random and have a fullstop in the beginning, filter those out
    keepIndex = ~startsWith({fileList.name}, '.'); fileList = fileList(keepIndex);
    numSubs = size(fileList, 1);

    % process

    ops = cell(numSubs, 1);
    
    % load the session log folder
    session_log = readtable('/Volumes/for_dianna/EEG session_V02_2018-03-14_17_11_13.csv', 'VariableNamingRule', 'preserve');
    session_log.ID = cellstr(string(session_log.ID));
    for f = 1:numSubs
        
        path_datafile = fullfile(file_folder, fileList(f).name);
        [~, IDchk, ~] = fileparts(path_datafile);
        idx = find(strcmp(session_log.ID, IDchk));
    
       if ~isempty(idx) %if it is present in the list, extract parameters and run preprocessing

        site = session_log.Centre(idx);
        wave = 2; % DI: change, potentially index from a different list.

        % init operations array
        ops{f} = struct;
        ops{f}.id = IDchk;
        ops{f}.PipelineSuccess = false;

        path_raw=path_datafile;    
       
       ops{f} = LEAP_EEG_doPreproc (path_raw, site, wave,...
            path_out, ops{f});
       else
       end 
    end

   % clean up / save results
   cd(path_out)
   res = teLogExtract(ops); %DI: cannot extract, ask Luke
   %matfile
   file_ops = fullfile(path_out, sprintf('operations_%s.mat', datetimeStr));save(file_ops, 'ops', 'session_log', 'res')
   %output ops
   file_res = fullfile(path_out, sprintf('_results_%s.xlsx', datetimeStr));
   writetable(res, file_res)

    % join tables -one large files
    tab_preproc = outerjoin(session_log, res, 'LeftKeys',...
        'ID', 'RightKeys', 'id');
    writetable(tab_preproc, '_EEG_full_joint.xlsx')
    
    %
    idx_nonempty = ~strcmpi(tab_preproc.id, '');
    tab_preproc = tab_preproc(idx_nonempty, :);
    writetable(tab_preproc, '_joined_table.xlsx')

% % % %% files with issues 
% indices_to_delete = [50
%                     91
%                     93
%                     108
%                     129
%                     133
%                     175
%                     203
%                     220
%                     221
%                     222
%                     228
%                     264
%                     266
%                     273
%                     274
%                     275
%                     290
%                     294
%                     332
%                     341
%                     342
%                     361
%                     381];
% fileList(indices_to_delete) = [];
% % 
% % Keep the problematic ones
% fileList = fileList(indices_to_delete);
% % 
% % 
% % 
