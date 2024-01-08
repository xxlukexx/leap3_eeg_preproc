function [file, val] = LEAP_EEG_checkMarkersOneFolder(path_folder)

    if iscell(path_folder)
        [file, val] = cellfun(@LEAP_EEG_checkMarkersOneFolder, path_folder, 'uniform', false);
        val = vertcat(val{:});
        file = vertcat(file{:});
        return
    end
    
    d = dir([path_folder, filesep, '*.set']);
    numFiles = length(d);
    val = false(numFiles, 1);
    file = cell(numFiles, 1);
    parfor i = 1:numFiles
        file{i} = fullfile(d(i).folder, d(i).name);
%         disp(path_file)
        val(i) = LEAP_EEG_checkMarkersOneFile(file{i});
    end
        











end