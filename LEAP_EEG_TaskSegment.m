function [data, ops] = LEAP_EEG_TaskSegment(data, ops)

ops.LEAP_EEG_TaskSegment = false;

tasks= {'RESTING_STATE','MMN','FACE_ERP','SOCIAL_NONSOCIAL_VIDEOS'};
corrEvPath = '/Volumes/Projects/LEAP/_preproc/in/eeg/Correctedevents'; %DI: LEAP2 - not present

switch data{1}.euaims.site
    
    case 'UMCU' % Utrecht data already segmented, has no issues with event values except for one subject
        
        for itask = 1:length(data)
            
            if ~isfield(data{itask},'urevent') || isempty(data{itask}.urevent)
                data{itask}.urevent = data{itask}.event;
            end
            
            if strcmpi(data{1}.euaims.id,'150761304327') && ...
                    ismember(data{itask}.euaims.task,{'RESTING_STATE','MMN'})
                for iev = 1:length(data{itask}.event)
                    data{itask}.event(iev).type= data{itask}.event(iev).type -2^9;
                end
                
            end
            if strcmpi(data{itask}.euaims.task,'SOCIAL_NONSOCIAL_VIDEOS')
                % Utrecht used a different coding for these videos
                for iev = 1:length(data{itask}.event)
                    switch data{itask}.event(iev).type
                        case {10, 12}
                            data{itask}.event(iev).type = 12;
                        case {11, 13}
                            data{itask}.event(iev).type = 11;
                    end
                end
                
            end
            
            % convert all event types to strings
            for iev = 1:length(data{itask}.event)
                data{itask}.event(iev).type = num2str(data{itask}.event(iev).type);
            end
            
            ops.(sprintf('TaskPresent_%s', data{itask}.euaims.task)) = true;
            
        end

        if length(data) == 4
            ops.AllTasksPresent = true;
        else
            ops.AllTasksPresent = false;
        end
        
    otherwise %other data, read events, compare with sessionfiles, and semget
        dataorig = data{1};
        if ~isfield(dataorig,'urevent') || isempty(dataorig.urevent)
            dataorig.urevent = data{1}.event;
        end
        data= cell(1,length(tasks));
        
        
        % Load original EEG events 
        corrEvFilename = [corrEvPath, filesep, 'Events_',...
            dataorig.euaims.id, '.mat']; %DI: if event list is corrected, then re-uplaoded 
        if exist(corrEvFilename,'file')==2
            corrected_event = load(corrEvFilename);
            myevent = corrected_event.event;
            if corrected_event.Fs ~= dataorig.srate
                for iev = 1:length(myevent)
                   myevent(iev).latency = myevent(iev).latency * ...
                       (dataorig.srate / corrected_event.Fs); 
                end
                
            end
            dataorig.euaims.comments{end+1}='using manually corrected events';
        else
            myevent = dataorig.event;
        end
        
        % check for missing events
        if isempty(myevent), return, end
        
        % Load event offset - DI: whats the difference here? 
        event_offset = [];
        switch dataorig.euaims.site
            case 'UMCU'
                event_offset.mean = -0;
                event_offset.std  = 0;
            otherwise
                event_offset.mean = -0;
                event_offset.std  = 0;
        end
        event_offset.info = sprintf('%i sec were added to event latencies to correct for stimuli delays',event_offset.mean);
        
        % Get EEG events for all tasks
        eegev = euaims_get_eegevent(myevent,dataorig.srate,dataorig.euaims.site, ...
            [tasks, {'SCREENFLASH'}],event_offset.mean); %DI: discuss spurious events and discuss this one 

        
       
        aux = strfind(dataorig.euaims.rawpath,'raw_files');
        tempdatafile = fullfile(dataorig.euaims.rawpath(1:aux-1),'session_files/session1','tempData.mat');
        %tempdatafile = fullfile(dataorig.euaims.rawpath,'session_files/session1','tempData.mat');
        if exist(tempdatafile,'file')==2
            sesev = euaims_get_sessionevent(tempdatafile,tasks);
        else
            for itask = 1:length(tasks)
                sesev.(tasks{itask})=[];
            end
        end
        
        % Compare events from raw eeg and from session files event to buid
        % a corrected eegevent file if needed
        % eegev2 = eveeg;
        taskpresent = false(1,length(tasks));
        for itask = 1: length(tasks)
           if ~isempty(eegev.(tasks{itask})) || ~isempty(sesev.(tasks{itask}))
               taskpresent(itask)=true;
           end
        end
        
        timetasks = nan(length(tasks),2);
        for itask = find(taskpresent)
            eegevt = eegev.(tasks{itask});
            sesevt = sesev.(tasks{itask});
            commentst = dataorig.euaims.comments;

            % if this is the face ERP task, the fixation stimuli are not
            % recorded in the trial log data, which means the session
            % events don't have accurate information on the type of
            % fixation (FLAG = 221, ICON = 222). This will always cause the
            % comparison between EEG and session events to fail,
            % erroneously. To fix this, remove 221/222 events from both EEG
            % and session events before doing the comparison. 
            if strcmpi(tasks{itask}, 'FACE_ERP')
                idx_fixation_eeg = eegevt(:, 1) == 221 | eegevt(:, 1) == 222;
                eegevt(idx_fixation_eeg, :) = [];
                idx_fixation_ses = sesevt(:, 1) == 221 | sesevt(:, 1) == 222;
                sesevt(idx_fixation_ses, :) = [];
            end

            if isempty(sesevt)
               commentst{end+1}='no session events';
               evcor = eegevt;
            elseif isempty(eegevt)
               commentst{end+1}='no EEG events';
               evcor = [];
            elseif size(eegevt,1)==size(sesevt,1) && all(eegevt(:,1)==sesevt(:,1))
                % if raw eeg and session events coincide in code ordering, 
                % keep the raw eeg events
                evcor = eegevt;
                commentst{end+1} = ...
                        'EEG and session events match';
            else
                % raw eeg events are different than session events.
                % go back to the full list of eeg events, assume that codes 
                % are wrong but times are correct. 
                 
                % assuming eeg events have good timing but wrong code, find
                % what initial event will make the timings in eeg and in
                % session files match
                goodbegin=[];
                for ibeg = 1:size(eegev.all,1)-size(sesevt,1)+1
                    timeerr = eegev.all(ibeg+1:ibeg+size(sesevt,1)-1,3) - sesevt(2:end,3);
                      % timer{ibeg}=timeerr';
                    if strcmpi(tasks{itask},'FACE_ERP') && mean(abs(timeerr))<0.15
                        % For FACE_ERP use a more relaxed threshold of 15
                        % ms because the timing of the session file is not
                        % that precise (no timing info for begin of face
                        % and blank
                        goodbegin = [goodbegin ibeg];
                    elseif strcmpi(tasks{itask},'SOCIAL_NONSOCIAL_VIDEOS') && ... 
                            strcmpi(dataorig.euaims.site,'RUNMC') ...
                            && all(abs(timeerr)<0.08) %criteria a little more relaxed here too because for some reason there is more delay between timings in RUNMC social videos
                        goodbegin = [goodbegin ibeg];
                    elseif all(abs(timeerr)<0.06)
                        goodbegin = [goodbegin ibeg];
                    end
                end
                
                if size(goodbegin,1)==1
                    evcor=[];
                    evcor(:,1)= sesevt(:,1); % take the code from session file
                    evcor(:,2:4)= eegev.all(goodbegin:goodbegin+size(sesevt,1)-1,2:4); %take the timing from EEG file
                    commentst{end+1} = ...
                        'Event codes corrected from session files';
                else
                    % Events cannot be corrected. Keep the original EEG
                    % events, save also session events in case somebody
                    % wants to look at them
                    evcor = eegevt;
                    evcomment = ...
                        sprintf('Event list differs from session files ');
                    sessioncodes = unique(sesevt(:,1));
                    for icode = 1:length(sessioncodes)
                        if sum(evcor(:,1)==sessioncodes(icode)) ~= ...
                                sum(sesevt(:,1)==sessioncodes(icode))
                            evcomment = [ ...
                                evcomment ...
                                sprintf(' %i: %i/%i events.', ...
                                sessioncodes(icode), ...
                                sum(evcor(:,1)==sessioncodes(icode)), ...
                                sum(sesevt(:,1)==sessioncodes(icode)))];
                            
                        end
                        
                    end
                    commentst{end+1}=evcomment;
                    
                end
                
                if isempty(evcor)
                    % if eeg events cannot be corrected and we cannot
                    % find any event code for this task, assume the
                    % task is not present and do not write file (this
                    % can happen for instance when subjects performed
                    % the task (session event present), but EEG data
                    % was not recoded during this time
                    taskpresent(itask)=false;
                end                
                
            end
            
            if taskpresent(itask) && ~isempty(evcor)
   
                % Add corrected events
                dataorig.event = struct('type', ...
                    num2cell(evcor(:,1)), 'value','EEGcode',...
                    'latency',num2cell(evcor(:,2)*dataorig.srate),...
                    'duration',num2cell(ones(size(evcor,1),1)),'urevent',num2cell(evcor(:,4)));
                
                switch tasks{itask}
                    
                    case 'SOCIAL_NONSOCIAL_VIDEOS'
                        
                        % we don't have an offset marker here, so we take
                        % onset + 60s (the duration of the videos)
                        rawfiletime = [min(evcor(:,2))-10 ...
                            max(evcor(:,2))+70];   
                        
                    case 'RESTING_STATE'
                        
                        % detect whether this is LEAP 1/2 resting state (30s
                        % EO/EC, multiple trials of each), or LEAP 3 resting
                        % state (one single trial, EC, 120s) and determine the
                        % timestamps to segment around accordingly
                        isLEAP3 = evcor(1) == 215;

                        if isLEAP3
                            
                            % find row indices for 1) first 215 (trial
                            % onset) marker, and 2) last 213 OR 214
                            % (valid/invalid marker)
                            idx_onset = find(eegev.allofficial(:, 1) == 215, 1, 'first');
                            idx_offset = find(eegev.allofficial(:, 1) == 213 |...
                                eegev.allofficial(:, 1) == 214, 1, 'last');

                            % check that there was at least one onset and
                            % offset marker
                            if isempty(idx_onset) || isempty(idx_offset)
                                % todo - figure out what to do if not
                                % trials found
                                error('Either the onset (215) or offset (213/214) markers were not found -- debug!')
                            end
                            
                            % find the latency of the first and last
                            % markers
                            lat_onset = eegev.allofficial(idx_onset, 2);
                            lat_offset = eegev.allofficial(idx_offset, 2);
                            rawfiletime = [lat_onset - 10, lat_offset + 10];
                            
%                             % the segmentation is trying to chop out the
%                             % entire resting state task, from the onset of
%                             % the first trial to the offset of the last
%                             % trial. We can normally assume that each trial
%                             % is exactly 120s long, but because trials can
%                             % be skipped, they can be shorter. We need to
%                             % find the onset of the first trial, then find
%                             % the last trial and calculate whether it was
%                             % skipped. If it was, the offset is the
%                             % val/inval (213/214) marker, if it wasn't, th
%                             % eoffset is 120s
% 
%                             % we need to find the valid/invalid (213/214)
%                             % markers. If the trial was skipped, these will
%                             % occur before the planned 120s trial length.
%                             % First, find the onset event we're segmenting
%                             % around in all events, then check if the next
%                             % event is a valid/invalid
%                             idx_thisEvent = find(eegev.allofficial(:, 4) ==...
%                                 evcor(:, 4));
%                             idx_nextEvent = idx_thisEvent + 1;
%                             ev_val = eegev.allofficial(idx_nextEvent, :);
% 
%                             % check that this event is actually 213/214
%                             if ismember(ev_val(1), [213, 214])
% 
%                                 % we now take the offset time as 120s OR the
%                                 % latency of the val/inval marker, whichever is
%                                 % lowest
%                                 valMarkerOffsetTime = ev_val(3);
%                                 if valMarkerOffsetTime < 120
%                                     offsetTime = valMarkerOffsetTime;
%                                 else
%                                     offsetTime = min(evcor(:,2)) + 120;
%                                 end
% 
%                                 % note that we extend the segment length at
%                                 % start and end by 10s to avoid edge artefacts
%                                 % when filtering later on (during the
%                                 % task-specific analysis)
%                                 rawfiletime = [min(evcor(:,2))-10, offsetTime + 10];
% 
%                             else
% 
%                                 % if we don't find the val/inval event, then
%                                 % just segment to 120s
%                                 offsetTime = min(evcor(:,2)) + 120;
%                                 rawfiletime = [min(evcor(:,2))-10, offsetTime + 10];
% 
%                             end

                        else

                            % assume this is LEAP 1/2
                            rawfiletime = [min(evcor(:,2))-10 ...
                                max(evcor(:,2))+10];

                        end

                    otherwise
                        
                        rawfiletime = [min(evcor(:,2))-10 ...
                        max(evcor(:,2))+10];
                    
                end                        
                        
%                 if strcmpi(tasks{itask},'SOCIAL_NONSOCIAL_VIDEOS')
%                     
%                     
%                 else
%                     rawfiletime = [min(evcor(:,2))-10 ...
%                         max(evcor(:,2))+10];
%                 end
                data{itask} = pop_select( dataorig,'time',rawfiletime);
                data{itask}.euaims.rawfiletime = rawfiletime;

                data{itask}.euaims.task = tasks{itask};
                data{itask}.euaims.comments = commentst;
                if ~isempty(sesevt)
                    data{itask}.euaims.sessionevent = struct('type', ...
                        num2cell(sesevt(:,1)), ...
                        'CompTime',num2cell(sesevt(:,2)));
                end
                
                timetasks(itask,1)=evcor(1,2);
                timetasks(itask,2)=evcor(end,2);
                
                ops.(sprintf('TaskPresent_%s', tasks{itask})) = true;
                
            else
                
                ops.(sprintf('TaskPresent_%s', tasks{itask})) = false;
                
            end
            
        end
        data = data(taskpresent);
        
        
        % Extract screenflash timing
        ScreenFlash = [];
        if ~isempty(eegev.SCREENFLASH)
            for iev = 1:size(eegev.SCREENFLASH,1)
                if eegev.SCREENFLASH(iev,1)==114 && ...
                        eegev.SCREENFLASH(iev,2) < nanmin(timetasks(:))
                    ScreenFlash.InitFlash_tonset = eegev.SCREENFLASH(iev,2);
                elseif eegev.SCREENFLASH(iev,1)==115 && ...
                        eegev.SCREENFLASH(iev,2) < nanmin(timetasks(:))
                    ScreenFlash.InitFlash_toffset = eegev.SCREENFLASH(iev,2);
                elseif eegev.SCREENFLASH(iev,1)==114 && ...
                        eegev.SCREENFLASH(iev,2) > nanmax(timetasks(:))
                    ScreenFlash.EndFlash_tonset = eegev.SCREENFLASH(iev,2);
                elseif eegev.SCREENFLASH(iev,1)==115 && ...
                        eegev.SCREENFLASH(iev,2) > nanmax(timetasks(:))
                    ScreenFlash.EndFlash_toffset = eegev.SCREENFLASH(iev,2);
                end 
            end
        end
        %         if ~isfield(ScreenFlash,'InitFlash_tonset') % if the correct values for InitFlash cannot be found store the first event
        %             isEEGcode = find( strcmpi({myevent.value},'Stimulus') | ...
        %                 strcmpi({myevent.value},'Toggle'));
        %             if ~isempty(isEEGcode)
        %             auxt = myevent(isEEGcode(1)).latency / dataorig.srate + event_offset.mean;
        %             if auxt < nanmin(timetasks(:))
        %                 ScreenFlash.FirstEEGCode_tonset = auxt;
        %                 ScreenFlash.FirstEEGCode_type = myevent(isEEGcode(1)).type;
        %             end
        %             end
        %         end
        fieldnames = {'InitFlash_tonset','InitFlash_toffset','EndFlash_tonset', ...
            'EndFlash_toffset'};
        for itask = 1:length(data)
            for ifield = 1:length(fieldnames)
                if isfield(ScreenFlash,fieldnames{ifield})
                    data{itask}.euaims.ScreenFlash.(fieldnames{ifield}) = ...
                        ScreenFlash.(fieldnames{ifield}) ...
                        - data{itask}.euaims.rawfiletime(1);
                end
            end
        end
        
        
        if ~any(taskpresent)
            ops.AllTasksPresent = false;
            ops.TaskPresenceError =...
                sprintf('no task data (EEGfile %.1f min - %i raw events)',...
                range(dataorig.times)/1000/60,length(dataorig.urevent));
        else
            ops.AllTasksPresent = true;
        end
        
end

ops.LEAP_EEG_TaskSegment = true;

end