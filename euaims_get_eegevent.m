function eveeg = euaims_get_eegevent(myevent,Fs,site,tasks,offset)


if nargin < 5
   offset = 0; 
end

valid_EEGcodes.RESTING_STATE =  [211 212 213 214 215];
valid_EEGcodes.MMN = [201 202 203 204];
valid_EEGcodes.FACE_ERP = [223 224 225 226 227 228 221 222 229 21 22 23];
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
    bad_events = [48 49 208 53 54 85];
    idx_bad_events = ~ismember(eveeg.all(:,1),bad_events);
    eveeg.all = eveeg.all(idx_bad_events,:);
end
eveeg.all(2:end,3)= diff(eveeg.all(:, 2)); % time to previous event

% Discard all events that are not in the official list
eveeg.allofficial = eveeg.all(ismember(eveeg.all(:,1),valid_EEGcodes.all),:);
eveeg.allofficial(2:end,3)= diff(eveeg.allofficial(:, 2));

for itask = 1:length(tasks)

    current_task = tasks{itask};

    switch current_task
        case 'RESTING_STATE'
    
            % temp store events into a table
            tab_rs = array2table(eveeg.allofficial, 'VariableNames', {'event', 'latency', 'delta', 'idx'});
        
            % find onset of each rs trial (211 = EO, 212 = EC, 215 = LEAP3 2min EC onset)
            idx_rs_onset = ismember(tab_rs.event, [211, 212, 213, 214, 215]);
            tab_rs = tab_rs(idx_rs_onset, :);

            % loop through and check that each onset event has a valid
            % marker afterwards
            tab_rs.valid = false(size(tab_rs, 1), 1);
            for e = 1:height(tab_rs)
                
                % is this an onset event for an rs trial?
                if ismember(tab_rs.event(e), [211, 212, 215])               % todo does 215 have valid/invalid after it in LEAP3?
                    
                    % if so, is the next event a valid marker (213)
                    idx_next_event = e + 1;

                    % ensure that there is an event after this one
                    if idx_next_event > height(tab_rs)
                        continue
                    end

                    tab_rs.valid(e) = tab_rs.event(idx_next_event) == 213;

                end

            end

            % filter table for only valid onset events
            tab_rs = tab_rs(tab_rs.valid, :);

            % recalculate event onset delta
            tab_rs.delta = nan(height(tab_rs), 1);
            tab_rs.delta(2:end) = diff(tab_rs.latency);
            num_rs_onset_events = length(idx_rs_onset);

            % convert table back to matrix
            eveeg.RESTING_STATE = table2array(tab_rs);

%             % for resting select relevant codes and eliminate all bad trials
%             % (which are not recorded in session file)
%             idbegin = find (ismember(eveeg.allofficial(:,1),[211 212 215])); %codes of begin resting
% %             goodtrial = eveeg.allofficial( min(idbegin+1,size(eveeg.allofficial,1)),1) == 213; %good trial if followed by 213
%             goodtrial = true(size(idbegin));
%             discardevents = idbegin(~goodtrial);
%             eveeg.RESTING_STATE = eveeg.allofficial(setdiff(1:size(eveeg.allofficial,1),discardevents),:);
%             eveeg.RESTING_STATE = eveeg.RESTING_STATE(ismember(eveeg.RESTING_STATE(:,1),[211 212 215]),:);
%             eveeg.RESTING_STATE(2:end,3)= eveeg.RESTING_STATE(2:end,2)-eveeg.RESTING_STATE(1:end-1,2); % time to previous event
            
        case {'MMN','FACE_ERP','SOCIAL_NONSOCIAL_VIDEOS','SCREENFLASH'}

            valid_codes_this_task = valid_EEGcodes.(current_task);
            idx_valid_codes_this_task = ismember(eveeg.allofficial(:, 1), valid_codes_this_task);
            eveeg.(current_task) = eveeg.allofficial(idx_valid_codes_this_task, :);

            % eveeg.(tasks{itask}) = eveeg.allofficial(ismember(eveeg.allofficial(:,1),valid_EEGcodes.(tasks{itask})),:);
        
        otherwise
            error('using an unknown task')
               
    end
    eveeg.(current_task)(:,3) = nan; %time after previous event
    eveeg.(current_task)(2:end,3)= eveeg.(tasks{itask})(2:end,2)-eveeg.(tasks{itask})(1:end-1,2);
    
    
end


%% Search for spurious events in the overall list (only will be used if eeg and session events do not match
% for the overall eeg events, in case needed for later, eliminate events
% that are < 5ms closer to other events, because these are not true event
% but spurious 

presentcode = unique(eveeg.all(:,1));
countcode = hist(eveeg.all(:,1),presentcode)';

% whilst it's possible for spurious events to appear far too close to other
% events, there are some genuine events that may also meet the <5ms
% criterion. These are:
%
%   112 - face ERP event marker to indicate screen refresh after a stimulus
%   is drawn
%
% find all events that are potentially too close (<5ms delta) but which ARE
% NOT in the list above
genuine_events = [112];
idx_event_too_close = eveeg.all(:, 3) < 0.005 &...
    ~ismember(eveeg.all(:, 1), genuine_events);

event_too_close = find(idx_event_too_close); %if distance between events < 5ms
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


