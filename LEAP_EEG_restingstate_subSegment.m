function LEAP_EEG_restingstate_subSegment(file_in, path_out)

    % load EEGLab data
    eeg = pop_loadset(file_in);
    
    % extract urevents (all events from original session)
    ev = struct2table(eeg.urevent);
    numUREvents = size(ev, 1);
    
    % loop through all resting state events (in .events structure)
    numEvents = length(eeg.event);
    lat = [];                       % storage for on/offset latencies
    idx_lat = 1;                    % row of lat to write to
    for e = 1:numEvents
       
        % find corresponding event in urevent (all original events from the
        % full session)
        ur = eeg.event(e).urevent + 1;
        offsetFound = false;
        while ur <= numUREvents && ~offsetFound
            
            if ismember(eeg.urevent(ur).type, {'T213', 'T214'})
                
                % calculate duration s2-s1
                dur = ev.latency(ur) - ev.latency(eeg.event(e).urevent);

                % if duration > 120s, clamp to 120s
                if dur > 120000
                    dur = 120000;
                end
                    
                % start of segment is 215 onset event
                lat(idx_lat, 1) = eeg.event(e).latency - 5;                 % start 5 samples earlier, to include 215 event
                
                % end of event is start + duration
                lat(idx_lat, 2) = eeg.event(e).latency + dur;
                
                % next result will be written to new row in lat
                idx_lat = idx_lat + 1;
                
                % set found flag to exit while loop 
                offsetFound = true;
                
            end
            
        end
            
    end
    
    numSegs = size(lat, 1);               
    eeg_seg = cell(numSegs, 1);
    for s = 1:numSegs
        
        % segment around latencies
        eeg_seg{s} = pop_select(eeg, 'time', lat(s, :) / 1000);
        
        % write segment as EEGLAb file
        [pth, filename, ext] = fileparts(file_in);
        file_out = fullfile(path_out, 'resting_state', sprintf('%s_seg%02d%s', filename, s, ext));
        pop_saveset(eeg_seg{s}, file_out);
        fprintf('\n<strong>Wrote segment %02d to %s</strong>\n\n\n\n', s, file_out);
        
    end
        
end
                    









