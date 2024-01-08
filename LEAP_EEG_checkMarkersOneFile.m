function val = LEAP_EEG_checkMarkersOneFile(path_data)

    try
        eeg = pop_loadset(path_data);
        tab = struct2table(eeg.event);
        [~, uev] = extractNumeric(unique(tab.type));
        uev(isnan(uev)) = [];
        val = any(mod(uev, 2) ~= 0);
    catch ERR
        val = false;
    end

end