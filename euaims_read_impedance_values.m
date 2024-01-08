function data = euaims_read_impedance_values(file, data)

% Reads impedance values from vhdr files (values recorded in CIMH and KCL)

% INPUTS:
%   file = vhdr file (full path) where the impedance values are stored
%   data = eeglab data structure 

% OUTPUTS:
%   data - also eeglab data structure, a new field called "impedance" is added 
%          in data.chanlocs


% Last change. 1 March 2016. P.Garces


fid=fopen( file );
% if isoctave
%     hdrtxt={};
%     keepreading=true;
%     while keepreading
%         newline=fgetl(file);
%         if newline == -1
%             keepreading=false;
%         else
%             hdrtxt{end+1}=newline;
%         end
%     end
% else 
    hdrtxt = textscan(fid, '%s', 'Delimiter', '\n');
    hdrtxt=hdrtxt{1};
% end
fclose(fid);


beginline = find( ~cellfun('isempty', strfind(hdrtxt, 'Impedance ')));
if ~isempty(beginline)
beginline = beginline(end); % if impedances read more than once, take latest version
for ich=1: min([ data.nbchan length(hdrtxt)-beginline])
    charendlabel=strfind(hdrtxt{beginline+ich},':');
    chlabel=hdrtxt{beginline+ich}(1:charendlabel-1);
    if ~isempty(regexp( hdrtxt{beginline+ich}(charendlabel+1:end),'\s+\d+', 'once'))
        idch= find(strcmpi( {data.chanlocs.labels}, chlabel) );
        if ~isempty(idch)
            data.chanlocs(idch).impedance = str2double(hdrtxt{beginline+ich}(charendlabel+1:end));
        end
    elseif ~isempty(strfind( hdrtxt{beginline+ich}(charendlabel+1:end),'Out of Range'))
        idch= find(strcmpi( {data.chanlocs.labels}, chlabel) );
        if ~isempty(idch)
            data.chanlocs(idch).impedance = inf;
        end
    end
end
end

end