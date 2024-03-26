function [data, ops] = euaims_channel_rearrange(data, site, ops)

% Rearrages EUAIMS eeglab data. This is done depending on the EEG system (centre)
% Details on the rearranging decisions can be found in the EUAIMS preprocessing document.  
% 
% Inputs
% data = eeglab-like data structure
% site = CIMH, KCL, RUNMC, UCBM or UMCU

% Outputs
% sucess = true or false
% outcome = in case of incident reports information in text
% data = rearranged data

% Last change. 1 March 2016 - P.Garces

ops.euaims_channel_rearrange = false;

Nchan=data.nbchan;
%data_s = cellfun(@(x) x, data); %Di tried smth


%% 1 - RELABEL TO MATCH COMMON MONTAGE LABEL, REMOVE UNNECESSARY CHANNELS AND ADD REFERENCE CHANNEL
switch site
    
    case 'KCL'
        
        % Add FCz channel used as reference with all 0 values
        data.nbchan                   = Nchan + 1;
        data.data(Nchan+1,:)          = zeros(1,length(data.times)); %zero at the end of 
        data.chanlocs(Nchan+1).labels = 'FCz';
        
    case 'RUNMC'
        
        % Relabel
        if length(data.chanlocs)~=64 %ask meaning of the 2 extra channels. 
            ops.RearrangeChannelsIssue =...
                sprintf('RUNMC has %i instead of 64 channels',length(data.chanlocs));
        elseif ~all( str2double({data.chanlocs(1:64).labels})==(1:1:64) )
            ops.RearrangeChannelsIssue =...
                'RUNMC data not in the expected numeric format';
        else
            RUNMClabel = {1,'FP1';2,'FP2';3,'F7';4,'F3';5,'FZ';6,'F4';7,'F8';...
                8,'FC5';9,'FC1';10,'FC2';11,'FC6';12,'T7';13,'C3';14,...
                'CZ';15,'C4';16,'T8';17,'TP9';18,'CP5';19,'CP1';20,'CP2';...
                21,'CP6';22,'TP10';23,'P7';24,'P3';25,'PZ';26,'P4';27,'P8';...
                28,'PO9';29,'O1';30,'OZ';31,'O2';32,'PO10';33,'AF7';34,'AF3';...
                35,'AF4';36,'AF8';37,'F5';38,'F1';39,'F2';40,'F6';41,'FT9';...
                42,'FT7';43,'FC3';44,'FC4';45,'FT8';46,'FT10';47,'C5';48,'C1';...
                49,'C2';50,'C6';51,'TP7';52,'CP3';53,'CPz';54,'CP4';55,'TP8';...
                56,'P5';57,'P1';58,'P2';59,'P6';60,'PO7';61,'PO3';62,'POz';...
                63,'PO4';64,'PO8'};
            for ich = 1:64
                data.chanlocs(ich).labels = RUNMClabel{ich, 2}; 
            end
            
            % add FCz channel used as reference with all 0 values
            data.nbchan                   = Nchan + 1;
            data.data(Nchan+1,:)          = zeros(1,length(data.times));
            data.chanlocs(Nchan+1).labels = 'FCz';
        end
    
        
    
    case 'UCBM'
        
        % Relabel electrodes to produce homogenous labels across centres
        oldlabel = {'T4','T6','T5','T3'};
        newlabel = {'T8','P8','P7','T7'};
        for ich = 1: length(oldlabel)
            ide = find(strcmpi( {data.chanlocs.labels}, oldlabel{ich}));
            if ~(isempty(ide))
                data.chanlocs(ide).labels = newlabel{ich};
            end
        end
        
        
        
    case 'UMCU'
        
        % Relabel electrodes to produce homogenous labels across centres
        selected_ind = {'185048685294','880258979280','308985002572', '347433880698', '406025860813', '498184660603', '592413773463', '599197502428', '602495883891', '713675032670', '713933341814', '714993068392', '869163187754', '881324181111', '955634127896'};
        if any(ismember(data.euaims.id, selected_ind))
           oldlabel = {  'HL',  'HR','S2/VO', 'VB','EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','Nose', 'S1'};
           newlabel = {'EOGL','EOGR','EOGA','EOGB','EOGA','EOGB','EOGL','EOGR',  'ML',  'MR', 'Not','Not-1'};

        else
            oldlabel = {  'HL',  'HR',  'VO',  'VB','EXG1','EXG2','EXG3','EXG4','EXG5','EXG6','EXG7', 'EXG8'};
            newlabel = {'EOGL','EOGR','EOGA','EOGB','EOGA','EOGB','EOGL','EOGR',  'ML',  'MR', 'Not','Not-1'};
        end
        
        for ich = 1: length(oldlabel)
            ide = find(strcmpi( {data.chanlocs.labels}, oldlabel{ich}));
            if ~(isempty(ide))
                data.chanlocs(ide).labels = newlabel{ich};
            end
        end
          
        
        % Remove channels Not and status
        labelremove = {'Not','Not-1','Status'};
        idch = [];
        for ich=1:length(labelremove)
            idch(end+1) = find( strcmpi( {data.chanlocs.labels} , labelremove{ich} ) ); 
        end
        data.nbchan   = Nchan - length(idch);
        idchremain    = setdiff(1:Nchan , idch );
        data.data     = data.data(idchremain , : );
        data.chanlocs = data.chanlocs(idchremain);
        
        
        
        
end


%% 2 - ADD EOG HORIZONTAL DIFF
% CIMH and UMCU: subtracting EOGR and EOGL
% Other centres: subtract AF7 and AF8 

switch site
    
    case {'CIMH','UMCU'}
        idEOGr =  find( strcmpi( {data.chanlocs.labels}, 'EOGR' ) );
        idEOGl =  find( strcmpi( {data.chanlocs.labels}, 'EOGL' ) );
        if or ( isempty(idEOGr), isempty(idEOGl) )
            data.euaims.comments{end+1}= 'Expected EOG channels not found';
        else
            
            data.nbchan                   = data.nbchan + 1;
            data.data(data.nbchan ,:)          = data.data(idEOGr,:) - data.data(idEOGl,:);
            data.chanlocs(data.nbchan).labels = 'EOGHdiff';
        end
        
        
    otherwise
        idEOGr =  find( strcmpi( {data.chanlocs.labels}, 'AF8' ) );
        idEOGl =  find( strcmpi( {data.chanlocs.labels}, 'AF7' ) );
        if or ( isempty(idEOGr), isempty(idEOGl) )
            data.euaims.comments{end+1}= 'Not producing EOGHdiff - AF7/AF8 not present';
        else
            data.nbchan                   = data.nbchan + 1;
            data.data(data.nbchan ,:)          = data.data(idEOGr,:) - data.data(idEOGl,:);
            data.chanlocs(data.nbchan).labels = 'EOGHdiff';
        end
        
end

ops.euaims_channel_rearrange = true;


end