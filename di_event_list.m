
list = dir('*_face_erp.set');
comments_face = cell(size(list, 1), 2);

% Display the names of the files that match the criteria
for i=1:size(list,1)
data= pop_loadset(list(i).name);

 comments_face{i,1}=data.filename;

    if isfield(data, 'euaims') && isfield(data.euaims, 'comments')
        comments_face{i, 2} = data.euaims.comments;
    else
        comments_face{i, 2} = []; % Set to [] if 'comments' field is empty or not present
    end

end

list = dir('*_mmn.set');
comments_mmn = cell(size(list, 1), 2);

% Display the names of the files that match the criteria
for i=1:size(list,1)
data= pop_loadset(list(i).name);

 comments_mmn{i,1}=data.filename;


    if isfield(data, 'euaims') && isfield(data.euaims, 'comments')
        comments_mmn{i, 2} = data.euaims.comments;
    else
        comments_mmn{i, 2} = []; % Set to [] if 'comments' field is empty or not present
    end

end

list = dir('*_resting_state.set');
comments_rs = cell(size(list, 1), 2);

% Display the names of the files that match the criteria
for i=1:size(list,1)
data= pop_loadset(list(i).name);

 comments_rs{i,1}=data.filename;


    if isfield(data, 'euaims') && isfield(data.euaims, 'comments')
        comments_rs{i, 2} = data.euaims.comments;
    else
        comments_rs{i, 2} = []; % Set to [] if 'comments' field is empty or not present
    end

end


list = dir('*_social_nonsocial_videos.set');
comments_soc = cell(size(list, 1), 2);

% Display the names of the files that match the criteria
for i=1:size(list,1)
data= pop_loadset(list(i).name);

 comments_soc{i,1}=data.filename;


    if isfield(data, 'euaims') && isfield(data.euaims, 'comments')
        comments_soc{i, 2} = data.euaims.comments;
    else
        comments_soc{i, 2} = []; % Set to [] if 'comments' field is empty or not present
    end

end



%convert to table 
comments_soc=cell2table(comments_soc,'VariableNames',{'id','comments_soc'})
comments_rs=cell2table(comments_rs,'VariableNames',{'id','comments_rs'})
comments_mmn=cell2table(comments_mmn,'VariableNames',{'id','comments_mmn'})
comments_face=cell2table(comments_face,'VariableNames',{'id','comments_face'})


comments_soc.id = cellfun(@(x) x(1:12), comments_soc.id, 'UniformOutput', false);
comments_rs.id = cellfun(@(x) x(1:12), comments_rs.id, 'UniformOutput', false);
comments_mmn.id = cellfun(@(x) x(1:12), comments_mmn.id, 'UniformOutput', false);
comments_face.id = cellfun(@(x) x(1:12), comments_face.id, 'UniformOutput', false);

combinedTable = outerjoin(comments_soc, comments_rs, 'MergeKeys', true, 'Keys', 'id');
combinedTable = outerjoin(combinedTable, comments_mmn, 'MergeKeys', true, 'Keys', 'id');
combinedTable = outerjoin(combinedTable, comments_face, 'MergeKeys', true, 'Keys', 'id');

writetable(combinedTable, 'session_events_Mar5.xlsx')
