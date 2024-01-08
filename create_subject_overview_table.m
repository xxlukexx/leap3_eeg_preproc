%% CREATE A TABLE WITH OVERVIEW OF PREPROCESSING OUTPUT AND CRF INFORMATION

clear all
close all

files.preproccomments = 'commentsmay19bis.mat';
files.CRFinfo = '/data64/clinbiomarkers/EEGEUAIMS/EEG/eCRF/20160511/all_items/Age gender IQ_EEG session.csv';
files.badsubjectinfo = 'badsubjects.xlsx';


%% 1 - LOAD PREPROCESSING COMMENTS
load(files.preproccomments)

for isub = 1:size(comments,1)
    for icol = 4:7
        aux = comments{isub,icol};
        if iscell(aux) && length(aux)>1
           if ~strcmpi(aux{1},'using manually corrected events')
              error('too many comments') 
           else
               aux = aux(2:end);
           end
        end
        if iscell(aux)
            switch aux{1}
                case 'Event codes corrected from session files'
                    comments{isub,icol}=2;
                case 'no session events'
                    comments{isub,icol}=3;
                case 'using manually corrected events'
                    comments{isub,icol}=4;
                otherwise
                    if ~isempty(strfind(aux{1},'Event list differs from session files'))
                        comments{isub,icol} = aux{1}(39:end);
                    end
            end
        elseif isempty(aux)
            comments{isub,icol}=0;
        end
    end
end


%% 2 - LOAD CRF INFORMATION

fid=fopen(files.CRFinfo);
hdrline=fgetl(fid);
columnhdrs=regexp(hdrline,'[^;]*;','match')';
Ncol = length(columnhdrs);
for icol=1:Ncol
    columnhdrs{icol}= columnhdrs{icol}(1:end-1);
end

CRFdata=cell(900,Ncol);
cont=0;
morelines=true;
while morelines
    newline=fgetl(fid);
    if  newline==-1
        morelines=false;
    else
        cont=cont+1;
        values=regexp(newline,'[^;]*;','match')';
        if length(values)~=Ncol
            fprintf('line with diff amount of columns \n');
        else
            for icol=1:Ncol
                aux = values{icol}(1:end-1);
                if ~ismember(aux,{'999','none','None'})
                    CRFdata{cont,icol}= aux;
                end
            end
        end
    end
    
end
fclose(fid);
CRFdata=CRFdata(1:cont,:);

CRFtable =[];
CRFtable.site            = cell(size(comments,1),1);
CRFtable.generalcomments = cell(size(comments,1),1);
CRFtable.rscomplete      = nan(size(comments,1),1);
CRFtable.mmncomplete     = nan(size(comments,1),1);
CRFtable.facescomplete   = nan(size(comments,1),1);
CRFtable.socialcomplete  = nan(size(comments,1),1);
CRFtable.rscomment       = cell(size(comments,1),1);
CRFtable.mmncomment      = cell(size(comments,1),1);
CRFtable.facescomment    = cell(size(comments,1),1);
CRFtable.socialcomment   = cell(size(comments,1),1);


for isub = 1:size(comments,1)
    irowCRF = find(strcmpi(CRFdata(:,1),comments{isub,1}));
    if ~isempty(irowCRF)
        
        icolCRF = strcmpi(columnhdrs,'Centre');
        CRFtable.site{isub}=CRFdata{irowCRF,icolCRF};
        
        
        icolCRF = strcmpi(columnhdrs,'General Comments');
        CRFtable.generalcomments{isub}=CRFdata{irowCRF,icolCRF};
        
        % Resting complete
        icolCRF = cellfun(@(x) ~isempty(strfind(x,'Coding(Resting State Trial')),columnhdrs) & ...
            cellfun(@(x) ~isempty(strfind(x,'(Complete (Y/N))')),columnhdrs) ;
        if ~all(cellfun(@(x) isempty(x),CRFdata(irowCRF, icolCRF)))
        CRFtable.rscomplete(isub) = sum(strcmpi(CRFdata(irowCRF, icolCRF),'Y'));
        end
        
        % MMN complete
        icolCRF = cellfun(@(x) ~isempty(strfind(x,'Coding(Mismatch Negativity)(Complete (Y/N))')),columnhdrs);
        if ~all(cellfun(@(x) isempty(x),CRFdata(irowCRF, icolCRF)))
            CRFtable.mmncomplete(isub)  = sum(strcmpi(CRFdata(irowCRF, icolCRF),'Y'));
        end
        
        % Faces complete
        icolCRF = cellfun(@(x) ~isempty(strfind(x,'Coding(Faces')),columnhdrs) & ...
            cellfun(@(x) ~isempty(strfind(x,'(Complete (Y/N))')),columnhdrs) ;
        if ~all(cellfun(@(x) isempty(x),CRFdata(irowCRF, icolCRF)))
            CRFtable.facescomplete(isub)  = sum(strcmpi(CRFdata(irowCRF, icolCRF),'Y'));
        end
        
        % Social complete
        icolCRF = cellfun(@(x) ~isempty(strfind(x,'Coding')),columnhdrs) & ...
            cellfun(@(x) ~isempty(strfind(x,'Social')),columnhdrs) & ...
            cellfun(@(x) ~isempty(strfind(x,'(Complete (Y/N))')),columnhdrs) ;
        if ~all(cellfun(@(x) isempty(x),CRFdata(irowCRF, icolCRF)))
            
            CRFtable.socialcomplete(isub)  = sum(strcmpi(CRFdata(irowCRF, icolCRF),'Y'));
        end
        
        % Resting comment
        icolCRF = cellfun(@(x) ~isempty(strfind(x,'Coding(Resting State Trial')),columnhdrs) & ...
            cellfun(@(x) ~isempty(strfind(x,'(Comment)')),columnhdrs) ;
        aux = CRFdata(irowCRF,icolCRF);
        aux = unique( aux(cellfun(@(x) ~isempty(x),aux)) );
        CRFtable.rscomment{isub} = [aux{:}];
        
        % MMN comment
        icolCRF = cellfun(@(x) ~isempty(strfind(x,'Coding(Mismatch Negativity)(Comment)')),columnhdrs) ;
        CRFtable.mmncomment{isub} = CRFdata{irowCRF,icolCRF};
        
        % Faces comment
        icolCRF = cellfun(@(x) ~isempty(strfind(x,'Coding(Faces')),columnhdrs) & ...
            cellfun(@(x) ~isempty(strfind(x,'(Comment)')),columnhdrs) ;
        aux = CRFdata(irowCRF,icolCRF);
        aux = unique( aux(cellfun(@(x) ~isempty(x),aux)) );
        CRFtable.facescomment{isub} = [aux{:}];
        
        % Social comment
        icolCRF = cellfun(@(x) ~isempty(strfind(x,'Social')),columnhdrs) & ...
            cellfun(@(x) ~isempty(strfind(x,'(Comment)')),columnhdrs) ;
        aux = CRFdata(irowCRF,icolCRF);
        aux = unique( aux(cellfun(@(x) ~isempty(x),aux)) );
        CRFtable.socialcomment{isub} = [aux{:}];
        
        
    end
    % add crf information
    
end

%% 3 - ADD BADSUBJECT COMMENTS

generalcomments = cell(size(comments,1),1);
[badsubjects.num, badsubjects.txt] = xlsread(files.badsubjectinfo);
for isub = 1:length(badsubjects.num)
    isub2 = find(strcmpi(comments(:,1),num2str(badsubjects.num(isub))));
    if ~isempty(isub2)
        generalcomments{isub2}=badsubjects.txt{isub,2};
    end
end

%% 4 - WRITE EXCEL FILE

mytable = table(comments(:,1),CRFtable.site, ...
    comments(:,2),comments(:,3),comments(:,4),comments(:,5),comments(:,6),comments(:,7), generalcomments, ...
    CRFtable.generalcomments,CRFtable.rscomplete, CRFtable.mmncomplete, CRFtable.facescomplete, CRFtable.socialcomplete, ...
    CRFtable.rscomment, CRFtable.mmncomment, CRFtable.facescomment, CRFtable.socialcomment, ...
    'VariableNames',{'code','centre','success','outcome','rs','mmn','faces','social','Comments', ...
    'CRFcomments','rsblocks','mmnblocks','facesblock','socialblocks', ...
    'rscomment','mmncomment','facescomment','socialcomment'});

writetable(mytable,'subjectoverview.xls')



