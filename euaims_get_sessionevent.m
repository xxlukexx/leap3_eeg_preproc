function sesev = euaims_get_sessionevent(tempdatafile,tasks)

load(tempdatafile)
sesev = []; % Struct with a field for each task, matrices Nevents x 3 [code time time_diff_to_previous_event]

for itask = 1:length(tasks)
    
    switch tasks{itask}
        case 'RESTING_STATE'
            nametask2 = 'restingstate_trial';
        case 'MMN'
            nametask2 = 'mmn_trial';
        case 'FACE_ERP',
            nametask2 = 'faces_trial';
        case 'SOCIAL_NONSOCIAL_VIDEOS'
            nametask2 = 'restingvideos_trial';
    end
    idt = find(strcmpi(tempData.FunName,nametask2));
    
    if ~isempty(idt)
        idEEGcode = find(ismember(tempData.Headings{idt},{'StimEEGCode','EEGCode','FaceEEGCode'}));
        if isnumeric(tempData.Data{idt}{1,idEEGcode})
            auxEEGcode = [tempData.Data{idt}{:,idEEGcode}];
        else
            auxEEGcode = cellfun( @(x) str2double(x),tempData.Data{idt}(:,idEEGcode));
        end
        idonsettime   = strcmpi(tempData.Headings{idt},'TrialOnsetTime');
        onsettime = cellfun( @(x) str2double(x),tempData.Data{idt}(:,idonsettime));
        
        switch tasks{itask}
            case 'RESTING_STATE'
                %if resting add 213 triggers at the end of each listed trial to be able to compare to EEG codes
                idoffsettime = strcmpi(tempData.Headings{idt},'TrialOffsetTime');
                auxoffsettime = cellfun( @(x) str2double(x),tempData.Data{idt}(:,idoffsettime));
                sesev.(tasks{itask}) = nan(2*length(auxEEGcode),3);
                sesev.(tasks{itask})(1:2:end,1) = auxEEGcode;
                sesev.(tasks{itask})(1:2:end,2)= onsettime(:);
                sesev.(tasks{itask})(2:2:end,1) = 213;
                sesev.(tasks{itask})(2:2:end,2)= auxoffsettime(:);
                
            case 'FACE_ERP'
                idoffsettime = strcmpi(tempData.Headings{idt},'TrialOffsetTime');
                auxoffsettime = cellfun( @(x) str2double(x),tempData.Data{idt}(:,idoffsettime));
                
                idfixEEGcode = ismember(tempData.Headings{idt},'FixEEGCode');
                auxfixEEGcode = [tempData.Data{idt}{:,idfixEEGcode}];
                
                % each row in the table corresponds to 3 events: fixation + face + blank
                % the time of the face and blank event have not been stored
                sesev.(tasks{itask}) = nan(3*length(auxEEGcode),3);
                sesev.(tasks{itask})(1:3:end,1) = auxfixEEGcode;
                sesev.(tasks{itask})(1:3:end,2)= onsettime(:);
                sesev.(tasks{itask})(2:3:end,1) = auxEEGcode;
                sesev.(tasks{itask})(2:3:end,2)= onsettime(:)+0.6; % approximate time because jittering
                sesev.(tasks{itask})(3:3:end,1) = 229;
                sesev.(tasks{itask})(3:3:end,2)= auxoffsettime(:)-0.5; %approximate time because jittering
                  
            otherwise
                sesev.(tasks{itask})(:,1) = auxEEGcode;
                sesev.(tasks{itask})(:,2)= onsettime(:);
                    
        end

        sesev.(tasks{itask})(2:end,3)= sesev.(tasks{itask})(2:end,2)-sesev.(tasks{itask})(1:end-1,2);
        sesev.(tasks{itask})(1,3) = nan;
    else
        sesev.(tasks{itask})=nan(0,3);
    end
    
end