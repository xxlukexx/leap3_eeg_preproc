function ops = LEAP_EEG_doPreproc(path_datafile,...
    site, wave, path_out, ops)
        
        % check output path
        ops.OutputPathValid = exist(path_out, 'dir') == 7;
        if ~ops.OutputPathValid, return, end

        % check data file path
        ops.InputPathValid = exist(path_datafile, 'file') == 7;
        if ~ops.InputPathValid, return, end

        %manage paths - output paths
        [~, filename, ~] = fileparts(path_datafile); %repetitive step from before but learning the ID numb
        path_subfolder = fullfile(path_out, filename); %create the unique folder output name path
        ops.OutputPath = path_subfolder;
        
        % track success flag
        suc = true;
    
        % read file
        [data, ops] = LEAP_EEG_loadRaw(path_datafile, site, wave, ops);
        suc = suc && ops.LEAP_EEG_loadRaw;
       
        % unify channels - DI: do not see the function for channel z-score or flat channels 
        if suc
            [data, ops] = LEAP_EEG_UnifyChannels(data, ops);
            suc = suc && ops.LEAP_EEG_UnifyChannels;
        end

        % preprocess (resample, reref, filter) %DI: not filtering here
        if suc
            [data, ops] = LEAP_EEG_Preprocess(data, ops);
            suc = suc && ops.LEAP_EEG_Preprocess;
        end
        
        % Segment and update events
        if suc
            [data, ops] = LEAP_EEG_TaskSegment(data, ops);
        end
        
        ops.PipelineSuccess = ops.LEAP_EEG_loadRaw &&...
            ops.LEAP_EEG_UnifyChannels &&...
            ops.LEAP_EEG_Preprocess &&...
            ops.LEAP_EEG_TaskSegment;
        
        % write output data
        if ops.PipelineSuccess
            
            numData = length(data);
            for d = 1:numData
                
                % save processed data
                task = lower(data{d}.euaims.task);
                %outPath = [path_out, filesep, task];
                outPath = strcat(path_out, filesep, task); %DI addition
                outFile = [filename, '_', task];

                %if ~exist(outPath, 'dir'), mkdir(outPath); end
                if ~isfolder(outPath), mkdir(outPath); end

                %pop_saveset(data{d}, 'filename', outFile, 'filepath', outPath);
                pop_saveset(data{d}, 'filename', outFile, 'filepath', char(outPath));

                ops.(sprintf('OutputFile_%s', data{d}.euaims.task)) =...
                    fullfile(outPath, outFile);
                
                % Store comments in cell (useful to build subject overview,
                % delete for future release)
                if isempty(data{d}.euaims.comments)
                    comment = 1;
                else
                    comment = data{d}.euaims.comments;
                end       
                
                data{d} = [];

            end
            
            clear data
            
        end
 
%     catch ERR
% 
%         ops.Error = ERR.message;
%         return
%         
%     end
    
end