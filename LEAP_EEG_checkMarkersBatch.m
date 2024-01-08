[file, val] = LEAP_EEG_checkMarkersOneFolder(path_folders);

bad = file(~val);
[~, fil] = cellfun(@fileparts, bad, 'UniformOutput', false);
parts = cellfun(@(x) strsplit(x, '_'), fil, 'UniformOutput', false);
tab = table;
tab.id = cellfun(@(x) x{1}, parts, 'UniformOutput', false);
tab.file = bad;
tab = LEAP_appendMetadata_t1t2(tab, 'id');
tab = sortrows(tab, 'id');

data = cell(size(tab, 1), 1);
parfor i = 1:size(tab, 1)
    
    try
        data{i} = pop_loadset(tab.file{i});
    catch ERR
        data{i} = ERR.message;
    end
    
end
tab.data = data;