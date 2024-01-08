function [siteCodes, siteLabels,  doesEEG, doesET] = LEAPGetSiteCodes

    sites = {...
    %   Site code  Site Label        EEG?    ET?
        'CIMH',    'MANNHEIM',       true,   true    ;...
        'KCL',     'KINGS_COLLEGE',  true,   true    ;... 
        'RUNMC',   'NIJMEGEN',       true,   true    ;...
        'UCBM',    'ROME',           true,   true    ;...
        'UMCU',    'UTRECHT',        true,   true,   ;...
        'KI',      'KAROLINSKA',     false,  true,   ;...
        'UCAM',    'CAMBRIDGE',      false,  true,   };
    
    siteCodes = sites(:, 1);
    siteLabels = sites(:, 2);
    doesEEG = cell2mat(sites(:, 3));
    doesET = cell2mat(sites(:, 4));

end  