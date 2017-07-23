function rejected = reject_channels(data, varargin)
% reject_channels   reject bad channels based on defined criterias
%   rejected = reject_channels(data, params)
%   where rejected is a list of channels that must be removed. data is a
%   EEGLAB data structure. params is an optional argument with optional
%   fields 'kurt_thresh', 'prob_thresh', 'spec_thresh' and 
%   'interpolation_params'. First three are to specify thresholds for three
%   different measures to compute probability, kurtosis and spectrum for 
%   each channel. 'interpolation_params' is the parameter to determine the 
%   mode of the interpolation for flatchannels. Note that an interpolation
%   of the flatchannels is already performed here so that next steps of 
%   pop_rejchans perform with no error, but the interpolated result is not 
%   returned. These flaatchannels are returned alongside other bad channels 
%   to be interpolated at the end of the preprocessing all together. 
%   When params is ommited default values are used. When a field of params 
%   is ommited, default value for that field is used. If any of the fields 
%   is -1, that measure is not computed for channel rejection.
%   Default values: params.kurt_thresh = 3
%                   params.prob_thresh = 4
%                   params.spec_thresh = 4
%                   params.interpolation_params.method = 'spherical'
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

defaults = DefaultParameters.channel_rejection_params;
p = inputParser;
addParameter(p,'kurt_thresh', defaults.kurt_thresh, @isnumeric);
addParameter(p,'prob_thresh', defaults.prob_thresh, @isnumeric);
addParameter(p,'spec_thresh', defaults.prob_thresh, @isnumeric);
addParameter(p,'interpolation_params', ...
                    struct('method', ...
                    DefaultParameters.interpolation_params.method), ...
                    @isstruct);
parse(p, varargin{:});


kurt_thresh = p.Results.kurt_thresh;
prob_thresh = p.Results.prob_thresh;
spec_thresh = p.Results.spec_thresh;
interpolation_params = p.Results.interpolation_params;

display(defaults.run_message);

% Detect the reference channel to exclude it from interpolation
refs = find(sum(data.data==0,2)==size(data.data, 2));
if( length(refs) == 1 && refs == size(data.data, 1))
    reference_idx = refs;
elseif(length(refs) == 1)
    reference_idx = refs;
    warning(['Reference channel is not properly found. The only channel (='...
        num2str(reference_idx) ') having all values equal to zero is chosen to'...
        ' be the reference channel.']);
else
    error(['Reference channel is not found. Please put a reference channel'... 
        ' in the last channel of your dataset.']);
    return;
end

flatchans = find(std(data.data, 0, 2) < 0.01);
flatchans = setdiff(flatchans, reference_idx);
if ~isempty(flatchans)
    [~, data] = evalc('eeg_interp(data ,flatchans , interpolation_params.method)');
end

chans = 1:data.nbchan;
chans = setdiff(chans, reference_idx);

indelec_kurt = [];
if( kurt_thresh ~= -1 )
    [~, ~, indelec_kurt , ~] = ...
        evalc('pop_rejchan( data, ''elec'', chans, ''threshold'', kurt_thresh, ''measure'' , ''kurt'',  ''norm'' , ''on'')');
end

indelec_prob= [];
if( prob_thresh ~= -1 )
    [~, ~, indelec_prob ,~] = ...
        evalc('pop_rejchan(data, ''elec'', chans, ''threshold'', prob_thresh, ''measure'' , ''prob'', ''norm'' , ''on'')');
end

indelec_spec = [];
if( spec_thresh ~= -1 )
    [~, ~, indelec_spec , ~] = ...
        evalc('pop_rejchan(data, ''elec'', chans, ''threshold'', spec_thresh, ''measure'' , ''spec'', ''norm'' , ''on'')');
end

rejected = unique([indelec_kurt indelec_prob indelec_spec flatchans]); 
end