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


run_command = [ try_strings.no_check '[EEG, com] = pop_parameters(EEG);' catch_strings.store_and_hist ];

main = uimenu( fig, 'label', 'Automagic');
uimenu( main, 'label', 'Start preprocessing...', 'callback', run_command);
uimenu( main, 'label', 'Start manual rating...', 'callback', 'pop_rating');
uimenu( main, 'label', 'Start interpolation...', 'callback', 'interpolate_all');