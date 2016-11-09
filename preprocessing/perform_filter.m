function filtered = perform_filter(data, varargin)
% perform_filter  perform a high pass filter followed by a notch filter
%   filtered = perform_filter(data, varargin)
%   where data is the data loaded by popfileio of eeglab. varargin is an
%   optional structure contating parameters: two optional fields are 
%   possible: filter_params.filter_mode which is a char that can be either 
%   'EU' or 'US' determining the frequency for the Notch filter. 
%   Filter_params.freq which must be a numeric used for the high pass 
%   filter. Any of the fields could be ommited. No additional field must 
%   exist. filtered = perform_filter(data) where the default parameters 
%   are used: filter_params.filter_mode = 'EU' and filter_params.freq =
%   1/sampling-rate/2


p = inputParser;
addParameter(p,'filter_mode', 'EU', @ischar);
addParameter(p,'freq', 1/(data.srate/2), @isnumeric);
parse(p, varargin{:});


filter_mode = p.Results.filter_mode;
freq = p.Results.freq;




display('Perform Filtering...');
eeg = data.data;
[bhp,ahp] = butter(3, freq,'high'); % Highpass
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