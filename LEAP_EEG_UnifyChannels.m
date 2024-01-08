function [data, ops] = LEAP_EEG_UnifyChannels(data, ops)

    ops.LEAP_EEG_UnifyChannels = false;

    % load channel info template
    ops.ChannelTemplateFound = exist('euaimschan.mat', 'file') == 2; 
    if ~ops.ChannelTemplateFound, return, end
    load('euaimschan.mat')
    
    % get number of files (e.g. Utrecht have four separate BDF files, ones
    % for each task)
    numFiles = length(data);
    for f = 1:numFiles

        % rearrange channels
        [data{f}, ops] = euaims_channel_rearrange(data{f},...
            data{f}.euaims.site, ops);
        if ~ops.euaims_channel_rearrange, return, end

        % reorder channels according to layout
        data{f}.chaninfo = euaimschan.chaninfo;
        data{f}.euaims.chaninfo.templatelabels = {euaimschan.chanlocs.labels};
        data{f}.euaims.chaninfo.channelpresent = false(euaimschan.nbchan,1);
        
        % find which channels are present and in which order
        ideuaimschan = nan(euaimschan.nbchan,1);
        for ich=1:euaimschan.nbchan
            idchaux = find(strcmpi( {data{f}.chanlocs.labels},...
                euaimschan.chanlocs(ich).labels ) );
            if ~isempty(idchaux)
                data{f}.euaims.chaninfo.channelpresent(ich) = true;
                ideuaimschan(ich)=idchaux;
            end
        end
        data{f}.channelpresent = data{f}.euaims.chaninfo.channelpresent;

        if sum(data{f}.euaims.chaninfo.channelpresent) ~= data{f}.nbchan
            data{f}.euaims.comments{end+1} = ...
                ' some channels were not in the electrode template and were not inlcuded';
        end
        data{f}.euaims.chaninfo.npresentch = data{f}.nbchan;
        
        % Reorder
        rawdata= data{f}.data;
        data{f}.data = nan(length(euaimschan.chanlocs),size(rawdata,2)); % create Nchan x Nsamples
        data{f}.data(data{f}.euaims.chaninfo.channelpresent,:) = ...
            rawdata(ideuaimschan(data{f}.euaims.chaninfo.channelpresent) , : );
        data{f}.chanlocs = euaimschan.chanlocs;
        data{f}.nbchan   = euaimschan.nbchan;

        % read impedance values
        if any(strcmpi(data{f}.euaims.site,{'KCL','CIMH'}))
            hdrfile = ~cellfun('isempty', strfind(data{f}.euaims.files(:,1),'.vhdr')) ;
            data{f} = euaims_read_impedance_values(fullfile(data{f}.euaims.rawpath,...
                data{f}.euaims.files{hdrfile,1}),data{f});
        end
                        
    end
    
    ops.LEAP_EEG_UnifyChannels = true;

end