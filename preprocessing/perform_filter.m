function filtered = perform_filter(data, varargin)
% perform_filter  perform a high pass filter followed by a notch filter.
% Optionally, a low pass filter can be performed as well. See below.
%   filtered = perform_filter(data, params)
%   where data is the EEGLAB data structure. filtered is the resulting 
%   EEGLAB data structured after filtering. params is an optional
%   parameter which must be a structure with optional parameters
%   'filter_mode', 'high_freq', 'high_order', 'low_freq' and 'low_order'.
%   
%   'filter_mode' is a char that can be either  'EU' or 'US' determining 
%   the frequency for the Notch filter ([47, 53] or [57, 63] respectively). 
%
%   'high_freq' and 'low_freq' are the frequencies for high pass filter and
%   low pass filter respectively.
%
%   'high_order' and 'low_order' are orders of filtering for high pass
%   filter and low pass filter respectively.
%
%   If params is ommited default values are used. If any field of params
%   are ommited, corresponding default values are used. If 'high_freq' or
%   'low_freq' are -1, high pass filter or low pass filter are not
%   perfomed respectively.
%
%   Default values: by default there is no low_pass filter:
%                   params.filter_mode = 'EU'
%                   params.high_freq = 0.5
%                   params.high_order = 3
%                   params.low_freq = -1 % low pass filtering skipped
%                   params.low_order = 3

p = inputParser;
addParameter(p,'filter_mode', 'EU', @ischar);
addParameter(p,'high_freq', 0.5, @isnumeric);
addParameter(p,'high_order', 3, @isnumeric);
addParameter(p,'low_freq', -1, @isnumeric);
addParameter(p,'low_order', 3, @isnumeric);
parse(p, varargin{:});


filter_mode = p.Results.filter_mode;
high_freq = p.Results.high_freq;
high_order = p.Results.high_order;
low_freq = p.Results.low_freq;
low_order = p.Results.low_order;


display('Perform Filtering...');
eeg = data.data;

if( high_freq ~= -1 )
    [bhp,ahp] = butter(high_order, high_freq/(data.srate/2),'high'); % Highpass
    eeg = filter(bhp,ahp,eeg')';
end

if( low_freq ~= -1 )
    [bhp,ahp] = butter(low_order, low_freq/(data.srate/2),'low'); % Lowpass
    eeg = filter(bhp,ahp,eeg')';
end

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