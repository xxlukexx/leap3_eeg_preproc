function [data, ops] = LEAP_EEG_Preprocess(data, ops)

    ops.LEAP_EEG_Preprocess = false;
    
    % get number of files (e.g. Utrecht have four separate BDF files, ones
    % for each task)
    numFiles = length(data);
    for f = 1:numFiles
        
        switch data{f}.euaims.site

            case 'CIMH'
                
                % Separate channel groups depending on original referencing:
                % - group 1. FT9, Fpz, EOGL, EOGR are referenced to Fz
                % - group 2. other channels: referenced to their average
                labelg1 = {'FT9','Fpz', 'EOGL','EOGR','EOGHdiff'};
                id_g1   = find( cellfun(@(x) any(strcmpi(x,labelg1)),...
                    {data{f}.chanlocs.labels} )); %channels referenced to Fz
                id_g2  = setdiff(1:length(data{f}.chanlocs),id_g1); %Channels referenced to their average
                id_FCz = strcmpi({data{f}.chanlocs.labels},'FCz'); %FcZ
                id_Fz  = strcmpi({data{f}.chanlocs.labels},'Fz');  %Fz

                % For group 2 channels, ch --> ch - FCz
                dataref = data{f}.data(id_FCz,:);
                for ich=1:length(id_g2)
                    data{f}.data(id_g2(ich),:) = data{f}.data(id_g2(ich),:)...
                        - dataref;
                    data{f}.chanlocs(id_g2(ich)).ref='FCz';
                end
                % For group 1 channels that are not EOG, ch --> ch + (Fz-FCz)
                labelg1={'FT9','Fpz'};
                id_g1 =find( cellfun(@(x) any(strcmpi(x,labelg1)),...
                    {data{f}.chanlocs.labels} ));
                for ich=1:length(id_g1)
                    data{f}.data(id_g1(ich),:) = data{f}.data(id_g1(ich),:)...
                        + data{f}.data(id_Fz,:);
                    data{f}.chanlocs(id_g1(ich)).ref='FCz';
                end
                

            case {'UMCU','UCBM'}
                
                % Subtract FCz value from all channels for all non EOG or
                % mastoid channels
                id_FCz= strcmpi({data{f}.chanlocs.labels},'FCz'); %FcZ
                label_notrereference={'EOGA','EOGB','ML','MR','EOGL','EOGR','EOGHdiff'};
                id_notrereference =find( cellfun(@(x) any(strcmpi(x,label_notrereference)), {data{f}.chanlocs.labels} )); %channels referenced to Fz
                id_rereference = setdiff(1:length(data{f}.chanlocs),id_notrereference);

                dataref = data{f}.data(id_FCz,:);
                for ich=1:length(id_rereference)
                    data{f}.data(id_rereference(ich),:) =...
                        data{f}.data(id_rereference(ich),:) - dataref;
                    data{f}.chanlocs(id_rereference(ich)).ref='FCz';
                end
                
            case {'KCL','RUNMC'} %already referenced to FCz
                for ich=find(data{f}.channelpresent')
                    data{f}.chanlocs(ich).ref='FCz';
                end
                
        end

        %  resampling
        %  freq       - frequency to resample (Hz)
        %  fc         - anti-aliasing filter cutoff (pi rad / sample) {default 0.9} --> 0.6 for 300Hz
        %  df         - anti-aliasing filter transition band width (pi rad / sample) {default 0.2}
        %  fc = (desiredFC in Hz)/Fsample *2
        if data{f}.srate>1000
             data{f} = pop_resample(data{f}, 1000, 0.6, 0.2);
        end
        
    end
    
    ops.LEAP_EEG_Preprocess = true;

end