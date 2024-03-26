%% DI: LEAP3 EEG DATA PRE-PROCESSING - MASTER SCRIPT
   %DI (k2371654@kcl.ac.uk) modified the script of LM in Jan 2024

    clc; clear variables; close all;  
    
    fprintf('<strong>LEAP EEG preprocessing pipeline starting up...</strong>');

    % paralell toolboxteLog
    delete(gcp('nocreate'))
    if isempty(gcp('nocreate')), parpool('local', 2); end

    %add the paths to scripts
    addpath(genpath('/Users/diannailyka/Documents/leap3_eeg_preproc')) %path to LM's scripts
    addpath(genpath('/Users/diannailyka/Documents/eeglab2023.1')) %path to EEGLab functions
    addpath('/Users/diannailyka/Documents/fieldtrip-20230118', '-end'); %FT but without the subfolders (conflict of functions!); 
    addpath ('/Users/diannailyka/Documents/lm_tools'); %add LM's lm_tools - functions parProgress
    addpath ('/Users/diannailyka/Documents/TaskEngine2'); %add LM's lm_tools - functions parProgress

    %DI: set-up the in & out folders 
    path_out = ('/Volumes/for_dianna/EEG_out'); %output folder
    file_folder=('/Volumes/for_dianna/EEG_in'); %general folder
    cd(file_folder)
    fileList = dir(file_folder); 
    %some files are random and have a fullstop in the beginning, filter those out
    keepIndex = ~startsWith({fileList.name}, '.'); fileList = fileList(keepIndex);
    numSubs = size(fileList, 1);

    % process

    clear fut
    fc = 0;
    parGUID = parProgress('INIT');
    ops = cell(numSubs, 1);
    
    % load the session log folder
    session_log = readtable('/Volumes/for_dianna/EEG session_V02_2018-03-14_17_11_13.csv', 'VariableNamingRule', 'preserve');
    session_log.ID = cellstr(string(session_log.ID));
    
    for f = 1:numSubs
        
        path_datafile = fullfile(file_folder, fileList(f).name);
        [~, IDchk, ~] = fileparts(path_datafile);
        idx = find(strcmp(session_log.ID, IDchk));

        site = session_log.Centre(idx);
        wave = 2; % DI: change, potentially index from a different list.

        % init operations array
        ops{f} = struct;
        ops{f}.id = IDchk;
        ops{f}.PipelineSuccess = false;
        
        path_raw=path_datafile;

    % send for processing on a worker
    
        % increment parallel future counter
        fc = fc + 1;
        
        % create parallel future
        fut(fc) = parfeval(@LEAP_EEG_doPreproc, 1, path_raw, site, wave,...
            path_out, ops{f});
        
        % update status
        tm = sprintf(' [%s] ', datestr(now, 'HH:MM:SS'));
        msg = sprintf('Sent dataset %d of %d to worker ', f, numSubs);
        msg_id = sprintf('[%s]\n', IDchk);
        cprintf(tm);
        cprintf('green', msg);
        cprintf([1.0, 0.5, 0.0], msg_id);
        
    end
    
    cprintf('green', '\n\nWaiting for first worker to complete...\n');

% get results from workers
    for f = 1:fc
        
        % retrieve result from worker
        [idx_return, tmp_ops] = fetchNext(fut);
        
        % store operations in correct element in array
        ops{idx_return} = tmp_ops;
        
        % update status
        tm = sprintf(' [%s] ', datestr(now, 'HH:MM:SS'));
        msg = sprintf('Received result %d of %d from worker ', f, fc);
        msg_id = sprintf('[%s]\n', ops{idx_return}.id);
        cprintf('*red', tm);
        if ops{idx_return}.PipelineSuccess
            cprintf('green', msg);
        else
            cprintf('red', msg);
        end
        cprintf([1.0, 0.5, 0.0], msg_id);
        
    end

% clean up / save results

    res = teLogExtract(ops); %DI: cannot extract, ask Luke
    file_ops = fullfile(path_out, sprintf('operations_%s.mat', datetimeStr));
    % save(file_ops, 'ops', 'session_log', 'res')
    save(['save_', datestr(now, 'yyyymmdd_HHMMSS'), '.mat'], 'ops', 'session_log', 'res');
    file_res = fullfile(path_out, sprintf('results_%s.xlsx', datetimeStr));
    writetable(res, file_res)

    % join tables
    tab_preproc = outerjoin(session_log, res, 'LeftKeys',...
        'ID', 'RightKeys', 'id');
    
    % remove excluded IDs
    % idx_excl = strcmpi(tab_preproc.id, 'excluded');
    % tab_preproc(idx_excl, :) = [];
    
    idx_nonempty = ~strcmpi(tab_preproc.id, '');
    tab_preproc = tab_preproc(idx_nonempty, :);

    % write out joined table
     [pth, fil, ext] = fileparts(path_out);
     file_master_joined = fullfile(path_out, sprintf('%s.preproc.xlsx', fil));
     writetable(tab_preproc, file_master_joined)
     writetable(tab_preproc, 'joined_table.xlsx')



