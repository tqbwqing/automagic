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
%                   params.high_order = []  (Default value of pop_eegfiltnew)
%                   params.low_freq = -1 % low pass filtering skipped
%                   params.low_order = [] (Default value of pop_eegfiltnew)
%
% Copyright (C) 2017  Amirreza Bahreini, amirreza.bahreini@uzh.ch
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

p = inputParser;
addParameter(p,'filter_mode', 'EU', @ischar);
addParameter(p,'high_freq', 0.5, @isnumeric);
addParameter(p,'high_order', [], @isnumeric);
addParameter(p,'low_freq', -1, @isnumeric);
addParameter(p,'low_order', [], @isnumeric);
parse(p, varargin{:});


filter_mode = p.Results.filter_mode;
high_freq = p.Results.high_freq;
high_order = p.Results.high_order;
low_freq = p.Results.low_freq;
low_order = p.Results.low_order;


display('Perform Filtering...');

if( high_freq ~= -1 )
    [~, data] = evalc('pop_eegfiltnew(data, high_freq, 0, high_order)');
end


if( low_freq ~= -1 )
    [~, data] = evalc('pop_eegfiltnew(data, 0, low_freq, low_order)');
end

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