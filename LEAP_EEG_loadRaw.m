function [data, ops] = LEAP_EEG_loadRaw(folderPath, site, wave, ops)
    
    ops.LEAP_EEG_loadRaw = false;
    data = [];
    
% check that channel location definition can be found

    ops.FoundChannelLocationFile =...
        exist('standard-10-5-cap385.elp', 'file') == 2;
    if ~ops.FoundChannelLocationFile, return, end %check the channel file, can we plot this? 
    
    % check path exists
    ops.FolderPathValid = exist(folderPath, 'dir') == 7;
    if ~ops.FolderPathValid, return, end
    
    % the folder path is the path to the folder containing 'raw_files' and 'sesion_data' subfolders. It is named with the ID of the participant.
    % Find this in the full asbolute path that was passed in
    pParts = strsplit(folderPath, filesep);
    if ~isempty(pParts)
        idFolderPath = pParts{end};
    end
    
    % a valid PSC2 ID is numeric. Attempt to convert the ID found in the
    % folder path from a string to a number. If this fails, the ID was not
    % numeric, and therefore not a valid PSC2
    ops.ValidPSC2 = ~isnan(str2double(idFolderPath));
    %temporary comment below on luke's suggestion
    if ~ops.ValidPSC2, return, end
    ID = idFolderPath;
        
% check site code is valid, and perform site-specific operations

    % get a list of all site codes, and whether that site does EEG
    [siteCodes, siteLabels, doesEEG] = LEAPGetSiteCodes;
    
    % filter for only sites that do EEG
    siteCodes = siteCodes(doesEEG);
    
    % check that the site code for the current dataset is valid, and from a site that did EEG
    site = upper(site); %converts the site to upper case
    ops.SiteValid = ismember(site, siteCodes) || ismember(site, siteLabels);
    if ~ops.SiteValid, return, end

    % if a site labels (e.g. 'MANNHEIM') is supplied in place of a site code (e.g. 'CIMH') then convert the label to a code
    siteIdx = find(strcmpi(siteLabels, site));
    if ~isempty(siteIdx), site = siteCodes{siteIdx}; end
    
% locate files inside the data folder. Depending upon the site (and therefore the EEG system) these will differ, so handle each system separately
    
    % get contents of folder
    %rawPath = fullfile(folderPath, 'raw_files');
    %rawPath = [folderPath, filesep, 'raw_files'];

    rawPath = fullfile(folderPath, 'EEG/raw_files'); %folders have the EEG file; DI: added EEG subfolder because they have it in between
    d = dir(rawPath); %list files inside the directory
    files = shiftdim(struct2cell(d), 1);
    
    % define raw files according to site. First we define all expected
    % files, and then the file to actually load. For example, Brainvision
    % data is comprised of .eeg, .vhdr and .vmrk. All need to be present,
    % but the .eeg is the file we actually pass to the loading function
    switch site
        case {'CIMH', 'KCL', 'RUNMC'}
            
            % Brainvision sites
            sought = {'.eeg', '.vhdr', '.vmrk'};
            toLoad = [1, 0, 0];
            loadFunction = 'FILE-IO';
            
        case 'UCBM'
            
            % Micromed (in EEGLab format)
            sought = {'.set', '.fdt'};
            toLoad = [1, 0];
            loadFunction = 'POP_LOADSET';
            
        case 'UMCU'
            
            % Biosemi
            sought = {'Faces.bdf', 'MMN.bdf', 'Nonsocial_Social.bdf',...
                'RS.bdf'};
            toLoad = [1, 1, 1, 1];
            loadFunction = 'FILE-IO';
            
    end
    
    % search for matching files
    numSought = length(sought);
    found = false(1, numSought);
    foundIdx = [];
    
    for f = 1:length(sought)
        
        tmp = find(cellfun(@(x) ~isempty(strfind(x, sought{f})),...
            files(:, 1)));
        
        % check that only one file was found
        ops.CorrectNumberRawFiles = length(tmp) <= 1;
        if ~ops.CorrectNumberRawFiles
            return
        end

        found(f) = ~isempty(tmp);
        if found(f) && toLoad(f), foundIdx(end + 1) = tmp; end
        
    end
    
    % check for missing files
    ops.AllExpectedRawFilesFound = all(found);
    if ~any(found), return, end
    
%     switch site
%         case 'UMCU'
%             % UMCU saves their data in separate files for each task.
%             % Therefore this function will be called multiple times for
%             % each subject. This means that we only expect to find one of
%             % the possible four raw files.
%             ops.AllExpectedRawFilesFound = any(found);
% 
%         otherwise
%             % for sites other than UMCU, data are saved in one session
%             % file. Therefore we require that all expected files are found
% 
%     end
%     if ~ops.AllExpectedRawFilesFound, return, end

% load raw data

    numToLoad = length(foundIdx);
    data = cell(1, numToLoad);
    for f = 1:numToLoad
        try
            switch loadFunction

                case 'POP_LOADSET'
                    % use EEGLab format
                    data{f} = pop_loadset(...
                        'filename', files{foundIdx(f)},...
                        'filepath', rawPath);

                case 'FILE-IO'
                    % use EEGLab's file-io plugin
                    data{f} = pop_fileio(...
                        fullfile(rawPath, files{foundIdx(f)}));

            end
        catch ERR
            ops.LoadedAllRawFiles = false;
            ops.LoadRawError = ERR.message;
            ops.LoadRawTarget = files{foundIdx(f)};
            return
            
        end
        % load channel locations
        data{f} = pop_chanedit(data{f}, 'lookup', 'standard-10-5-cap385.elp');
         
        % add site and study code to data struct
        data{f}.euaims.id = ID;
        data{f}.euaims.study = 'LEAP';
        data{f}.euaims.wave = wave;
        data{f}.euaims.site = site;
        data{f}.euaims.rawpath = rawPath;
        data{f}.euaims.files = files;
        data{f}.euaims.rawfile = files{foundIdx(f)};
        data{f}.euaims.comments = {};
        
        % if from Utecht, tag data with task name
        namefiles = sought(found);
        switch namefiles{f}
            case 'Faces.bdf'
                data{f}.euaims.task = 'FACE_ERP';
            case 'MMN.bdf'
                data{f}.euaims.task = 'MMN';
            case 'Nonsocial_Social.bdf'
                data{f}.euaims.task = 'SOCIAL_NONSOCIAL_VIDEOS';
            case 'RS.bdf'
                data{f}.euaims.task = 'RESTING_STATE';
            otherwise
                data{f}.euaims.task = 'ALL_TASKS';
        end
        
        % create audit struct and log loading
        data{f}.euaims.audit(1).date = now;
        data{f}.euaims.audit(1).datestr = datestr(now, 'yyyymmdd');
        data{f}.euaims.audit(1).time = datestr(now, 'HH:MM:SS');
        data{f}.euaims.audit(1).text = 'Raw data loaded';
            
    end
    ops.LoadedAllRawFiles = true;
    
    % check for empty datasets
    hasData = find(cellfun(@(x) ~isempty(x.data), data));
    ops.NoEmptyDatasets = ~isempty(hasData);
    if ~ops.NoEmptyDatasets
        ops.EmptyDataSet = files{foundIdx};
        return
    end
    data = data(hasData);
            
    ops.LEAP_EEG_loadRaw = true;

    end
