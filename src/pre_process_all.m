function pre_process_all(project)
% This function is called by the main_gui to preprocess all the blocks in
% the data_folder of the project. If some files have already preprocessed
% results in the result_folder, a pop out message asks the user whether to 
% overwrite them or just skip them.
%
%   project - An instance of the class Project

cleanupObj = onCleanup({@cleanMeUp, project});
if(isempty(project))
    return;
end

% Add paths
if(ismac)
    slash = '/';
elseif(ispc)
    slash = '\';
end

% pre_process is checked as an example of a file in preprocessing, it could
% be any other file in that folder.
if( ~exist('pre_process', 'file'))
    addpath(['..' slash 'preprocessing']);
end

% pop_fileio is checked as an example of a file in matlab_scripts, it could
% be any other file in that folder.
if(~exist('pop_fileio', 'file'))
    matlab_paths = genpath(['..' slash 'matlab_scripts' slash]);
    if(ispc)
        parts = strsplit(matlab_paths, ';');
    else
        parts = strsplit(matlab_paths, ':');
    end
    IndexC = strfind(parts, 'compat');
    Index = not(cellfun('isempty', IndexC));
    parts(Index) = [];
    if(ispc)
        matlab_paths = strjoin(parts, ';');
    else
        matlab_paths = strjoin(parts, ':');
    end
    addpath(matlab_paths);
end

if(~exist('main_gui', 'file'))
    addpath(genpath(['..' slash 'gui' slash]));
end

assert(exist(project.getResult_folder, 'dir') > 0 , ...
    'The project folder does not exist or is not reachable.' );

% Ask the user whether to overwrite the existing preprocessed files, if any
skip = check_existings(project);

display('*******Start preprocessing all dataset**************');
start_time = cputime;
% Iterate on all subjects
for i = 1:length(project.block_list)
    unique_name = project.block_list{i};
    block = project.block_map(unique_name);
    block.update_addresses(project.getData_folder, project.getResult_folder);
    subject_name = block.subject.name;

    display(['Processing file ', block.unique_name ,' ...', '(file ', ...
        int2str(i), ' out of ', int2str(length(project.block_list)), ')']); 
    
    % Create the subject folder if it doesn't exist yet
    if(~ exist([project.getResult_folder subject_name], 'dir'))
        mkdir([project.getResult_folder subject_name]);
    end

    % Don't preprocess the file if user answered negatively to overwriting
    if skip && exist(block.potential_result_address, 'file')
        display('Results already exits. Skipping prerocessing for this subject... ');
        continue;
    else
        % Load and preprocess
        [~ ,data] = evalc('pop_fileio(block.getSource_address)');
        [EEG, fig] = pre_process(data, block.getSource_address, project.params);
        figure(fig);
        h = gcf;

    end
    % Delete old results
    if( exist(block.getReduced_address, 'file' ))
        delete(block.getReduced_address);
    end
    if( exist(block.getResult_address, 'file' ))
    delete(block.getResult_address);
    end
    if( exist([block.image_address, '.tif'], 'file' ))
    delete([block.image_address, '.tif']);
    end
    block.setRatingInfoAndUpdate( 'Not Rated', [], [], false);
    % save results
    saveas(h, block.image_address, 'tif');
    close(fig);

    reduced.data = downsample(EEG.data',project.ds_rate)';
    rate = 'Not Rated';
    tobe_interpolated = [];
    auto_badchans =  EEG.auto_badchans;
    man_badchans = [];
    is_interpolated = false;
    EEG = rmfield(EEG, 'auto_badchans');
    display('Saving results...');
    save(block.getReduced_address, 'reduced', '-v6');
    save(block.getResult_address, 'EEG', 'auto_badchans','man_badchans'...
        , 'rate','tobe_interpolated', 'is_interpolated', '-v7.3');

    project.not_rated_list = ...
        [project.not_rated_list block.index];
    project.not_rated_list = sort(project.not_rated_list);
    if( project.current == -1)
       project.current = 1; 
    end
    project.save_project();
    cleanupObj = onCleanup({@cleanMeUp, project});
end

end_time = cputime - start_time;
disp(['*********Pre-processing finished. Total elapsed time: ', num2str(end_time),'***************'])

% Update the main gui's data after rating processing
h = findobj(allchild(0), 'flat', 'Tag', 'main_gui');
if( isempty(h))
    h = main_gui;
end
handle = guidata(h);
handle.project_list(project.name) = project;
guidata(handle.main_gui, handle);
main_gui();
end


function skip = check_existings(project)
    % If there is already at least one preprocessed file in the
    % result_folder, ask the user whether to overwrite them or skip them
    
    file_count = project.processed_files;
    skip = 1;
    if( file_count > 0)
        choice = questdlg(['Some files are already processed. Would ',... 
                           'you like to overwrite them or skip them ?'], ...
                           'Pre-existing files in the project folder.',...
                           'Over Write', 'Skip','Over Write');
        switch choice
            case 'Over Write'
                skip = 0;
            case 'Skip'
                skip = 1;
        end
    end
end

function cleanMeUp(project)
    % Update the main gui's data after rating processing
    h = findobj(allchild(0), 'flat', 'Tag', 'main_gui');
    if( isempty(h))
        h = main_gui;
    end
    handle = guidata(h);
    handle.project_list(project.name) = project;
    guidata(handle.main_gui, handle);
    main_gui();
end


