function filtered = old_perform_filter(data)

eeg = data.data;
fs = data.srate;

[bhp,ahp] = butter(3,1/(fs/2),'high'); % order of the filt, then cutoff freq
[b50,a50] = butter(4,[47 53]./(fs/2),'stop');

eeg = eeg - repmat(eeg(:,1),[1 length(eeg)]);

eeg = filter(bhp,ahp,eeg')';
eeg = filter(b50,a50,eeg')';

data.data = eeg;
filtered = data;
end