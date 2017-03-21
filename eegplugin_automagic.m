function eegplugin_automagic(fig, try_strings, catch_strings)

if nargin < 3
    error('eegplugin_microstate requires 3 arguments');
end


matlab_paths = genpath('.');
if(ispc)
    parts = strsplit(matlab_paths, ';');
else
    parts = strsplit(matlab_paths, ':');
end
IndexC = strfind(parts, 'compat');
Index = not(cellfun('isempty', IndexC));
parts(Index) = [];
IndexC = strfind(parts, 'neuroscope');
Index = not(cellfun('isempty', IndexC));
parts(Index) = [];
if(ispc)
    matlab_paths = strjoin(parts, ';');
else
    matlab_paths = strjoin(parts, ':');
end
addpath(matlab_paths);


processing_command = ...
    [ try_strings.check_chanlocs '[EEG, com] = pop_parameters(EEG);' catch_strings.store_and_hist ];
rating_command = ...
    [ try_strings.no_check '[ALLEEG, com] = pop_rating(ALLEEG);' catch_strings.store_and_hist ];
interpolate_command = ...
    [ try_strings.check_chanlocs '[ALLEEG, com] = pop_interpolate(ALLEEG);' catch_strings.store_and_hist ];

main = uimenu( fig, 'label', 'Automagic');
uimenu( main, 'label', 'Start preprocessing...', 'callback', processing_command);
uimenu( main, 'label', 'Start manual rating...', 'callback', rating_command);
uimenu( main, 'label', 'Start interpolation...', 'callback', interpolate_command);