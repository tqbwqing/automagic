function eegplugin_automagic(fig, try_strings, catch_strings)

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
                
main = uimenu( fig, 'label', 'Automagic');
uimenu( main, 'label', 'Launch Automagic...', 'callback', 'main_gui');