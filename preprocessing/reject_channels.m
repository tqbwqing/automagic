function rejected = reject_channels(data)
display('Finding bad channels...');

chans_idx = logical(1:data.nbchan);
flatchan_idx = std(data.data, 0, 2) == 0;
chans_idx = chans_idx(~flatchan_idx);

[~, ~, indelec_kurt , ~] = evalc('pop_rejchan( data, ''elec'', chans_idx, ''threshold'', 3, ''measure'' , ''kurt'',  ''norm'' , ''on'')');


[~, ~, indelec_prob ,~] = ...
    evalc('pop_rejchan(data, ''elec'', chans_idx, ''threshold'', 4, ''measure'' , ''prob'', ''norm'' , ''on'')');

% TODO: Check commented lines specified in the original code
[~, ~, indelec_spec , ~] = ...
    evalc('pop_rejchan_spec(data, ''elec'', chans_idx, ''threshold'', 4, ''measure'' , ''spec'', ''norm'' , ''on'')');

flatchan = find(flatchan_idx == 1);
rejected = unique([indelec_kurt indelec_prob indelec_spec flatchan']); 
end