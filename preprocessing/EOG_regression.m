function regressed = EOG_regression(EEG, EOG)
display('Perform EOG Regression...');

eeg = EEG.data';
eog = EOG.data';

eegclean =  eeg - eog * (eog \ eeg);


regressed = EEG;
regressed.data = eegclean';

end