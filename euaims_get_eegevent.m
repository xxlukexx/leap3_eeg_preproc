function eveeg = euaims_get_eegevent(myevent,Fs,site,tasks,offset)


if nargin < 5
   offset = 0; 
end

valid_EEGcodes.RESTING_STATE =  [211 212 213 214 215];
valid_EEGcodes.MMN = [201 202 203 204];
valid_EEGcodes.FACE_ERP = [223 224 225 226 227 228 221 222 229 ];
valid_EEGcodes.SOCIAL_NONSOCIAL_VIDEOS = [10 11 12 13 14];
valid_EEGcodes.SCREENFLASH =  [114 115];

valid_EEGcodes.all = [valid_EEGcodes.RESTING_STATE valid_EEGcodes.MMN valid_EEGcodes.FACE_ERP valid_EEGcodes.SOCIAL_NONSOCIAL_VIDEOS valid_EEGcodes.SCREENFLASH];


eveeg = []; %Creates list of event.
eveeg.all = nan(length(myevent),3); % [type latency(sec) time_after_previous_event urevent]
isnumerictype = any(cellfun(@(x) ischar(x), {myevent.type}));
for iev = 1:size(eveeg.all,1)
    if isnumerictype
        numEv = str2double(myevent(iev).type(2:end));
        if any(~isnan(numEv)), eveeg.all(iev,1) = numEv; end
    else
        eveeg.all(iev,1) = myevent(iev).type;
    end
    eveeg.all(iev,2) = myevent(iev).latency/Fs + offset; % latency in seconds
    eveeg.all(iev,4)= myevent(iev).urevent;
end

% Discard all nans and bad triggers
eveeg.all = eveeg.all(~isnan(eveeg.all(:,1)),:);
if strcmpi(site,'CIMH')
    eveeg.all = eveeg.all(~ismember(eveeg.all(:,1),[48 49 208 53 54 21 85]),:);
end
eveeg.all(2:end,3)= eveeg.all(2:end,2)-eveeg.all(1:end-1,2); % time to previous event

% Discard all events that are not in the official list
eveeg.allofficial = eveeg.all(ismember(eveeg.all(:,1),valid_EEGcodes.all),:);
eveeg.allofficial(2:end,3)= eveeg.allofficial(2:end,2)-eveeg.allofficial(1:end-1,2);

for itask = 1:length(tasks)
    switch tasks{itask}
        case 'RESTING_STATE'
            % for resting select relevant codes and eliminate all bad trials
            % (which are not recorded in session file)
            idbegin = find (ismember(eveeg.allofficial(:,1),[211 212 215])); %codes of begin resting
%             goodtrial = eveeg.allofficial( min(idbegin+1,size(eveeg.allofficial,1)),1) == 213; %good trial if followed by 213
            goodtrial = true(size(idbegin));
            discardevents = idbegin(~goodtrial);
            eveeg.RESTING_STATE = eveeg.allofficial(setdiff(1:size(eveeg.allofficial,1),discardevents),:);
            eveeg.RESTING_STATE = eveeg.RESTING_STATE(ismember(eveeg.RESTING_STATE(:,1),[211 212 215]),:);
            eveeg.RESTING_STATE(2:end,3)= eveeg.RESTING_STATE(2:end,2)-eveeg.RESTING_STATE(1:end-1,2); % time to previous event
            
        case {'MMN','FACE_ERP','SOCIAL_NONSOCIAL_VIDEOS','SCREENFLASH'}
            eveeg.(tasks{itask}) = eveeg.allofficial(ismember(eveeg.allofficial(:,1),valid_EEGcodes.(tasks{itask})),:);
        
        otherwise
            error('using an unknown task')
               
    end
    eveeg.(tasks{itask})(:,3) = nan; %time after previous event
    eveeg.(tasks{itask})(2:end,3)= eveeg.(tasks{itask})(2:end,2)-eveeg.(tasks{itask})(1:end-1,2);
    
    
end


%% Search for spurious events in the overall list (only will be used if eeg and session events do not match
% for the overall eeg events, in case needed for later, eliminate events
% that are < 5ms closer to other events, because these are not true event
% but spurious 

presentcode = unique(eveeg.all(:,1));
countcode = hist(eveeg.all(:,1),presentcode)';
event_too_close = find(eveeg.all(:,3) < 0.05 ); %if distance between events < 5ms
% spurious code either just before or just after real code.
goodevent = true(1,size(eveeg.all,1));
for iev = 1:length(event_too_close)
    
    % if two events too close, one of them is spurious, need to figure out
    % which one
    id_candidate_bad = [event_too_close(iev), event_too_close(iev)-1];
    if any(~goodevent(id_candidate_bad))
        % if one of them has been found to be bad already, then it is the
        % other one (can happen when >=3 events too close)
        goodevent(id_candidate_bad) = false;
    elseif sum(ismember( eveeg.all(id_candidate_bad,1),valid_EEGcodes.all ))==1
        % If only one of the events has an official code, then discard the
        % other one
        id_candidate_bad = id_candidate_bad( ...
            ~ismember( eveeg.all(id_candidate_bad,1),valid_EEGcodes.all ) );
        goodevent(id_candidate_bad) = false;
    else
        % if none of the codes are in the official list, eliminate the one 
        % that has the lowest count
        if any(~goodevent(id_candidate_bad))
            goodevent(id_candidate_bad)=false;
        else
            aux1 = countcode(presentcode == eveeg.all(id_candidate_bad(1),1));
            aux2 = countcode(presentcode == eveeg.all(id_candidate_bad(2),1));
            [~,imin] = min([ aux1 aux2]);
            goodevent(id_candidate_bad(imin))=false;
        end
    end
end
eveeg.all = eveeg.all(goodevent,:);
eveeg.all(2:end,3)= eveeg.all(2:end,2)-eveeg.all(1:end-1,2);


