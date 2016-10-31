function interpolate_selected(project)
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

if( ~exist('eeg_interp', 'file'))
    addpath(genpath(['..' slash 'matlab_scripts'])); % project code
end

if( ~exist('main_gui','file'))
    addpath(['..' slash 'gui'])
end

if(isempty(project.interpolate_list))
    waitfor(msgbox('No subjects to interpolate. Please first rate.',...
        'Error','error'));
    return;
end

display('*******Start Interpolation**************');
start_time = cputime;
int_list = project.interpolate_list;
for i = 1:length(int_list)
    index = int_list(i);
    unique_name = project.block_list{index};
    block = project.block_map(unique_name);
    block.update_addresses(project.getData_folder, project.getResult_folder);

    display(['Processing file ', block.unique_name ,' ...', '(file ', ...
        int2str(i), ' out of ', int2str(length(int_list)), ')']); 
    assert(strcmp(block.rate, 'Interpolate') == 1);
    
    % Interpolate and save to results
    preprocessed = matfile(block.getResult_address,'Writable',true);
    EEG = preprocessed.EEG;
    interpolate_chans = block.tobe_interpolated;
    if(isempty(interpolate_chans))
        waitfor(msgbox(['The subject is rated to be interpolated but no',...
            'channels has been chosen.'], 'Error','error'));
        continue;
    end
    preprocessed.EEG = eeg_interp(EEG ,...
        interpolate_chans ,'spherical');
    EEG = preprocessed.EEG;
    % Downsample the new file and save it
    reduced.data = (downsample(EEG.data', project.ds_rate))';
    save(block.getReduced_address, 'reduced', '-v6');
    
    % Setting the new information
    block.setRatingInfoAndUpdate('Not Rated', [], [block.man_badchans interpolate_chans], true);
    project.interpolate_list(project.interpolate_list == block.index) = [];
    project.not_rated_list = ...
            [project.not_rated_list block.index];
    project.not_rated_list = sort(project.not_rated_list);
    block.saveRatingsToFile();
    project.save_project();
    cleanupObj = onCleanup({@cleanMeUp, project});
end
end_time = cputime - start_time;
disp(['Interpolation finished. Total elapsed time: ', num2str(end_time)])

% Update the main gui's data after rating processing
h = findobj(allchild(0), 'flat', 'Tag', 'main_gui');
if( isempty(h))
    h = main_gui;
end
handle = guidata(h);
handle.project_list(project.name) = project;
guidata(handle.main_gui, handle);
main_gui('load_selected_project', handle);
    
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
    main_gui('load_selected_project', handle);
end
