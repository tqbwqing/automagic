function filtered = perform_filter(data, filter_mode)

display('Perform Filtering...');
fs = data.srate;

eeg = data.data;
[bhp,ahp] = butter(3,1/(fs/2),'high'); % Highpass
eeg = filter(bhp,ahp,eeg')';
data.data = eeg;
switch filter_mode
    case 'US'
        [~, filtered] = evalc('pop_eegfiltnew(data, 57, 63, [], 1)'); % Band-stop filter
    case 'EU'
        [~, filtered] = evalc('pop_eegfiltnew(data, 47, 53, [], 1)'); % Band-stop filter
    otherwise
        waitfor(msgbox('Please choose an appropriate filtering mode!', ...
        'Error','error'));
end

end