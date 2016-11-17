function rejected = reject_channels(data, varargin)
% reject_channels   reject bad channels based on defined criterias
%   rejected = reject_channels(data, params)
%   where rejected is a list of channels that must be removed. data is a
%   EEGLAB data structure. params is an optional argument with optional
%   fields 'kurt_thresh', 'prob_thresh' and 'spec_thresh' to specify
%   thresholds for three different measures to compute probability, kurtosis
%   and spectrum for each channel. When params is ommited default values
%   are used. When a field of params is ommited, default value for that
%   field is used. If any of the fields is -1, that measure is not computed
%   for channel rejection.
%   Default values: params.kurt_thresh = 3
%                   params.prob_thresh = 4
%                   params.spec_thresh = 4

p = inputParser;
addParameter(p,'kurt_thresh', 3, @isnumeric);
addParameter(p,'prob_thresh', 4, @isnumeric);
addParameter(p,'spec_thresh', 4, @isnumeric);
parse(p, varargin{:});


kurt_thresh = p.Results.kurt_thresh;
prob_thresh = p.Results.prob_thresh;
spec_thresh = p.Results.spec_thresh;


display('Finding bad channels...');

chans_idx = logical(1:data.nbchan);
flatchan_idx = std(data.data, 0, 2) == 0;
chans_idx = chans_idx(~flatchan_idx);

indelec_kurt = [];
if( kurt_thresh ~= -1 )
    [~, ~, indelec_kurt , ~] = ...
        evalc('pop_rejchan( data, ''elec'', chans_idx, ''threshold'', kurt_thresh, ''measure'' , ''kurt'',  ''norm'' , ''on'')');
end

indelec_prob= [];
if( prob_thresh ~= -1 )
    [~, ~, indelec_prob ,~] = ...
        evalc('pop_rejchan(data, ''elec'', chans_idx, ''threshold'', prob_thresh, ''measure'' , ''prob'', ''norm'' , ''on'')');
end

indelec_spec = [];
if( spec_thresh ~= -1 )
    [~, ~, indelec_spec , ~] = ...
        evalc('pop_rejchan(data, ''elec'', chans_idx, ''threshold'', spec_thresh, ''measure'' , ''spec'', ''norm'' , ''on'')');
end

flatchan = find(flatchan_idx == 1);
rejected = unique([indelec_kurt indelec_prob indelec_spec flatchan']); 
end