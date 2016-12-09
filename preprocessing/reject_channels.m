function rejected = reject_channels(data, varargin)
% reject_channels   reject bad channels based on defined criterias
%   rejected = reject_channels(data, params)
%   where rejected is a list of channels that must be removed. data is a
%   EEGLAB data structure. params is an optional argument with optional
%   fields 'kurt_thresh', 'prob_thresh', 'spec_thresh' and 
%   'interpolation_params'. First three are to specify thresholds for three
%   different measures to compute probability, kurtosis and spectrum for 
%   each channel. 'interpolation_params' is the parameter to determine the 
%   mode of the interpolation for flatchannels. Note that the interpolation
%   of the flatchannels is already performed here, otherwise there will be 
%   some issues with flatchannels in the pop_rejchan.m. When params is 
%   ommited default values are used. When a field of params is ommited, 
%   default value for that %field is used. If any of the fields is -1, 
%   that measure is not computed for channel rejection.
%   Default values: params.kurt_thresh = 3
%                   params.prob_thresh = 4
%                   params.spec_thresh = 4
%                   params.interpolation_params.method = 'spherical'

p = inputParser;
addParameter(p,'kurt_thresh', 3, @isnumeric);
addParameter(p,'prob_thresh', 4, @isnumeric);
addParameter(p,'spec_thresh', 4, @isnumeric);
addParameter(p,'interpolation_params', struct('method', 'spherical'), @isstruct);
parse(p, varargin{:});


kurt_thresh = p.Results.kurt_thresh;
prob_thresh = p.Results.prob_thresh;
spec_thresh = p.Results.spec_thresh;
interpolation_params = p.Results.interpolation_params;

display('Finding bad channels...');

chans = 1:data.nbchan;
flatchans_idx = std(data.data, 0, 2) < 0.01;
flatchans = chans(flatchans_idx);

if ~isempty(flatchans)
    [~, data] = evalc('eeg_interp(data ,flatchans , interpolation_params.method)');
end

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