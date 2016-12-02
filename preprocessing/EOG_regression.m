function regressed = EOG_regression(EEG, EOG)
% EOG_regression  perform EOG regression from EOG channels
%   Both EEG and EOG are EEGLAB data structure.

display('Perform EOG Regression...');

eeg = EEG.data';
eog = EOG.data';

eegclean =  eeg - eog * (eog \ eeg);


regressed = EEG;
regressed.data = eegclean';

end