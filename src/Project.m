classdef Project < handle
    %Project is a class representing a project created in the main_gui.
    %   A Project contains the entire relevant information for each
    %   project. This information include the name of the project, address
    %   of the data_folder, result_folder, list of all exisiting blocks,
    %   list of all preprocessed blocks, five different list of ratings
    %   corresponding to each rate and more. Please see the properties for 
    %    more information.
    %
    %   Project is a subclass of handle, meaning it's a refrence to an
    %   object. Use accordingly.
    %
    %Project Methods:
    %   Project - To create a project following arguments must be given:
    %   myProject = Project(name, d_folder, p_folder, ext, ds, params)
    %   where name is a char specifying the desired project name, d_folder
    %   is the address of the folder where raw data is placed, p_folder is
    %   the address of the folder where you want the results to be saved,
    %   ext is the file_extension of raw files, ds is the downsampling rate
    %   that will be used to create smaller versions of raw data in order
    %   to plot faster and params is a struct that contains parameters for 
    %   preprocessing.
    %   This constructor calls create_rating_structures in order to create
    %   and initialise corresponding data structures.
    %
    %   preprocess_all - It is called from the main_gui to start
    %   preprocessing. It iterates on all the raw files in data_folder,
    %   preprocess them all and put the results in result_folder. 
    %   If some files have been already preprocessed, in the beginning the
    %   user is asked to whether overwrite the previous results or just
    %   skip them and continue with the rest of unpreprocessed files.
    %
    %   interpolate_selected - Called from the main_gui to interpolate all
    %   the selected channels during the manual rating in rating_gui.
    %   
    %   update_rating_structures - Whenever changes has been made to the
    %   data_folder or result_folder, this method must be called to update
    %   the data structures accordingly. The process may take long time
    %   depending on the number of existing files in each folder. See the
    %   method to learn more on how it works.
    %
    %   update_addresses_form_state_file - The method is to be called
    %   just after a project is "loaded" from a state file. The loaded project
    %   may have not been created from this operating system, thus addresses
    %   to the folders (which can be on the server as well) could be 
    %   different on this system, and they must be updated.
    %   
    %   get_rated_numbers - Return the number of rated blocks in this
    %   project.
    %   
    %   to_be_interpolated_count - Return number of blocks rated to be
    %   interpolated in this project.
    %   
    %   folders_are_changed - Return a boolean. It's true if any of the
    %   data_folder or result_folder has been changed since the last update.
    %   It can be used to decide whether to call
    %   update_rating_structures or not. Note that at this stage this
    %   method only returns based on the number of files in the folder.
    %   
    %   save_project - Save the entire project class in an m.file
    %   
    %   list_subject_files - List all folders in the data_folder
    %   
    %   list_preprocessed_subjects - List all folders in the result_folder
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
        
    properties
        
        % The index of the current block that must be shown in rating_gui.
        current
        
        % List of names of all existing blocks in the data_folder.
        block_list
        
        % List of indices of blocks that are rated as Interpolate.
        interpolate_list
        
        % List of indices of blocks that are rated as Good.
        good_list
        
        % List of indices of blocks that are rated as Bad.
        bad_list
        
        % List of indices of blocks that are rated as OK.
        ok_list
        
        % List of indices of blocks that are not rated (or rated as Not Rated).
        not_rated_list
        
        % Maximum value for the X-axis in the plot. Needed for the visual
        % aspects of the plot.
        maxX
        
        % Adress of the folder where raw data are stored.
        data_folder
        
        % Address of the folder where results are (to be) saved. 
        result_folder
        
        % Address of the state file corresponding to this project. By
        % default it's in the result_folder and is name project_state.mat.
        state_address
    end
    
    properties(SetAccess=private)
        
        % Name of this project.
        name
        
        % Sampling rate to crate reduced files.
        ds_rate
        
        % File extension of the raw files in this project. Can be .raw,
        % .RAW, .dat , .fif or even .mat if it's saved as a matlab file
        file_extension
        
        % Parameters of the preprocessing. To learn more please see
        % preprocessing/preprocess.m
        params
        
        % List of names of all preprocessed blocks so far.
        processed_list
         
        % Map each block name to the block itself.
        block_map
        
        % Number of all existing blocks.
        file_count
        
        % Number of all existing subjects.
        subject_count
        
        % Number of preprocessed blocks.
        processed_files
        
        % Number of preprocessed subjects.
        processed_subjects
    end
    
    %% Constructor
    methods
        function self = Project(name, d_folder, p_folder, ext, ds, ...
                params)
            self = self.setName(name);
            self = self.setData_folder(d_folder);
            self = self.setResult_folder(p_folder);
            self.state_address = self.make_state_address(self.result_folder);
            self.file_extension = ext;
            self.ds_rate = ds;
            self.params = params;
            self = self.create_rating_structure();
            self.save_project();
        end
    end
    
    %% Public Methods
    methods
        function self = preprocess_all(self)
            % preprocesses all the files in the data_folder of this project
            
            % Add paths
            if(isunix)
                slash = '/';
            elseif(ispc)
                slash = '\';
            end

            % preprocess is checked as an example of a file in preprocessing, it could
            % be any other file in that folder.
            if( ~exist('preprocess', 'file'))
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
                IndexC = strfind(parts, 'neuroscope');
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

            assert(exist(self.result_folder, 'dir') > 0 , ...
                'The project folder does not exist or is not reachable.' );

            % Ask the user whether to overwrite the existing preprocessed files, if any
            skip = self.check_existings();

            display('*******Start preprocessing all dataset**************');
            start_time = cputime;
            % Iterate on all subjects
            for i = 1:length(self.block_list)
                unique_name = self.block_list{i};
                block = self.block_map(unique_name);
                block.update_addresses(self.data_folder, self.result_folder);
                subject_name = block.subject.name;

                display(['Processing file ', block.unique_name ,' ...', '(file ', ...
                    int2str(i), ' out of ', int2str(length(self.block_list)), ')']); 

                % Create the subject folder if it doesn't exist yet
                if(~ exist([self.result_folder subject_name], 'dir'))
                    mkdir([self.result_folder subject_name]);
                end

                % Don't preprocess the file if user answered negatively to overwriting
                if skip && exist(block.potential_result_address, 'file')
                    display('Results already exits. Skipping prerocessing for this subject... ');
                    continue;
                else
                    % Load and preprocess
                    if( strcmp(block.file_extension, '.mat'))
                        data = load(block.source_address);
                        data = data.EEG;
                    else
                        [~ ,data] = evalc('pop_fileio(block.source_address)');
                    end
                    
                    if(strcmp('.fif', self.file_extension)) 
                        self.params.original_file = block.source_address;
                    end
                    
                    [EEG, fig] = preprocess(data, self.params);

                    if(strcmp('.fif', self.file_extension)) 
                        self.params = rmfield(self.params, 'original_file');
                    end
                    
                    if( isempty(EEG) )
                        self.write_to_log(block.source_address);
                       continue; 
                    end
                    figure(fig);
                    h = gcf;
                end
                
                % Delete old results
                if( exist(block.reduced_address, 'file' ))
                    delete(block.reduced_address);
                end
                if( exist(block.result_address, 'file' ))
                    delete(block.result_address);
                end
                if( exist([block.image_address, '.tif'], 'file' ))
                    delete([block.image_address, '.tif']);
                end
                block.setRatingInfoAndUpdate( 'Not Rated', [], [], false);
                
                % save results
                set(fig,'PaperUnits','inches','PaperPosition',[0 0 10 8])
                print(fig, block.image_address, '-djpeg', '-r100');
                close(fig);

                reduced.data = downsample(EEG.data',self.ds_rate)';
                rate = 'Not Rated';
                tobe_interpolated = [];
                auto_badchans =  EEG.auto_badchans;
                man_badchans = [];
                is_interpolated = false;
                EEG = rmfield(EEG, 'auto_badchans');
                params = self.params;
                
                display('Saving results...');
                save(block.reduced_address, 'reduced', '-v6');
                save(block.result_address, 'EEG', 'auto_badchans','man_badchans'...
                    , 'rate','tobe_interpolated', 'is_interpolated', ...
                    'params', '-v7.3');

                self.not_rated_list = ...
                    [self.not_rated_list block.index];
                self.not_rated_list = sort(unique(self.not_rated_list));
                if( self.current == -1)
                   self.current = 1; 
                end
                self.save_project();
            end
            end_time = cputime - start_time;
            disp(['*********Pre-processing finished. Total elapsed time: ', num2str(end_time),'***************'])

            % Update the main gui's data after rating processing
            h = findobj(allchild(0), 'flat', 'Tag', 'main_gui');
            if( isempty(h))
                h = main_gui;
            end
            handle = guidata(h);
            handle.project_list(self.name) = self;
            guidata(handle.main_gui, handle);
            main_gui();
        end
        
        function self = interpolate_selected(self)
            % Interpolates all the channels selected to be interpolated
            % during the manual rating in rating_gui.
            
            % Add paths
            if(isunix)
                slash = '/';
            elseif(ispc)
                slash = '\';
            end

            % eeg_interp is checked as an example of a file in matlab_scripts, it could
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
                IndexC = strfind(parts, 'neuroscope');
                Index = not(cellfun('isempty', IndexC));
                parts(Index) = [];
                if(ispc)
                    matlab_paths = strjoin(parts, ';');
                else
                    matlab_paths = strjoin(parts, ':');
                end
                addpath(matlab_paths);
            end

            if( ~exist('main_gui','file'))
                addpath(['..' slash 'gui'])
            end

            if(isempty(self.interpolate_list))
                waitfor(msgbox('No subjects to interpolate. Please first rate.',...
                    'Error','error'));
                return;
            end

            display('*******Start Interpolation**************');
            start_time = cputime;
            int_list = self.interpolate_list;
            for i = 1:length(int_list)
                index = int_list(i);
                unique_name = self.block_list{index};
                block = self.block_map(unique_name);
                block.update_addresses(self.data_folder, self.result_folder);

                display(['Processing file ', block.unique_name ,' ...', '(file ', ...
                    int2str(i), ' out of ', int2str(length(int_list)), ')']); 
                assert(strcmp(block.rate, 'Interpolate') == 1);

                % Interpolate and save to results
                preprocessed = matfile(block.result_address,'Writable',true);
                EEG = preprocessed.EEG;
                interpolate_chans = block.tobe_interpolated;
                if(isempty(interpolate_chans))
                    waitfor(msgbox(['The subject is rated to be interpolated but no',...
                        'channels has been chosen.'], 'Error','error'));
                    continue;
                end
                preprocessed.EEG = eeg_interp(EEG ,...
                    interpolate_chans , self.params.interpolation_params.method);
                EEG = preprocessed.EEG;
                % Downsample the new file and save it
                reduced.data = (downsample(EEG.data', self.ds_rate))';
                save(block.reduced_address, 'reduced', '-v6');

                % Setting the new information
                block.setRatingInfoAndUpdate('Not Rated', [], [block.man_badchans interpolate_chans], true);
                self.interpolate_list(self.interpolate_list == block.index) = [];
                self.not_rated_list = ...
                        [self.not_rated_list block.index];
                self.not_rated_list = sort(self.not_rated_list);
                block.saveRatingsToFile();
                self.save_project();
            end
            end_time = cputime - start_time;
            disp(['Interpolation finished. Total elapsed time: ', num2str(end_time)])

            % Update the main gui's data after rating processing
            h = findobj(allchild(0), 'flat', 'Tag', 'main_gui');
            if( isempty(h))
                h = main_gui;
            end
            handle = guidata(h);
            handle.project_list(self.name) = self;
            guidata(handle.main_gui, handle);
            main_gui();
        end
        
        function self = update_rating_structures(self)
            % Updates the data structures of this project. Look
            % create_rating_structure for more info.
            % This method may be time consuming depending on the number of 
            % files in both data_folder and result_folder as it goes 
            % through every block and fetches relevant information.
            %
            % This functionality helps to merge different projects
            % together. As it goes through all files in the data_folder and
            % result_folder, it finds out the new files that are added to
            % these folders, and updates the data correspondigly. If
            % there are raw files added to the data_folder only, it means some
            % new subjects are added. If there are raw files added to the
            % data_folder and they have also their corresponding new
            % preprocessed files in the result_folder, it means that some
            % data from another projects are added to this project. If
            % there are some new preprocessed files added to the
            % result_folder only , they will be considered only if a
            % corresponding raw_data in the data_folder exist. Else they
            % are ignored.
            % If on the other hand, any files is deleted from any of those
            % two folders, they are not copied to the new data structures
            % and considered as deleted files in the project.
            
            if(isunix)
                slash = '/';
            elseif(ispc)
                slash = '\';
            end
            % Load subject folders
            subjects = self.list_subject_files();
            s_count = length(subjects);
            preprocessed_subject_count = 0;
            ext = self.file_extension;
            map = containers.Map;
            list = {};
            p_list = {};
            i_list = [];
            g_list = [];
            b_list = [];
            o_list = [];
            n_list = [];

            files_count = 0;
            preprocessed_file_count = 0;
            for i = 1:length(subjects)
                subject_name = subjects{i};
                subject = Subject([self.data_folder subject_name], ...
                                    [self.result_folder subject_name]);
                
                raw_files = dir([self.data_folder subject_name slash '*' ext]);
                temp = 0;
                for j = 1:length(raw_files)
                    files_count = files_count + 1;
                    file = raw_files(j);
                    name_tmp = file.name;
                    splits = strsplit(name_tmp, ext);
                    file_name = splits{1};
                    unique_name = strcat(subject_name, '_', file_name);

                    % Merge data and update block_list
                    if isKey(self.block_map, unique_name) % File has been here
                        block = self.block_map(unique_name);
                        % Add it to the new list anyways. So that if anything has been
                        % deleted, it's not copied to this new list.
                        map(block.unique_name) = block; 
                        list{files_count} = block.unique_name;
                        block.index = files_count;
                        if (~ isempty(block.potential_result_address)) % Some results exist
                            IndexC = strfind(self.processed_list, unique_name);
                            Index = find(not(cellfun('isempty', IndexC)), 1);
                            if( ~isempty(Index))
                                % Currently a result file exists. There has been a
                                % result file before as well. So don't do anything.
                                % Here we don't check whether the rating info has been
                                % changed.
                            else % The result is new
                                % Update the rating info of the block
                                block.update_rating_info_from_file_if_any();
                                if( isempty(block.rate))
                                    list{files_count} = [];
                                    files_count = files_count - 1;
                                    remove(map, block.unique_name);
                                    continue;
                                end
                            end
                        else
                            % In any case, no file exists, so resets the rating info
                            block.update_rating_info_from_file_if_any();
                            if( isempty(block.rate))
                                list{files_count} = [];
                                files_count = files_count - 1;
                                remove(map, block.unique_name);
                                continue;
                            end
                        end
                    else                                        % File is new
                        % Block creation extracts and updates automatically the rating 
                        % information from the existing files, if any.
                        block = Block(subject, file_name, ext, self.ds_rate, self.params);
                        % If the block is not created due to unmatched
                        % parameters just skip it.
                        if( isempty(block.rate))
                            files_count = files_count - 1;
                            continue;
                        end
                        map(block.unique_name) = block;
                        list{files_count} = block.unique_name;
                        block.index = files_count;
                    end

                    % Update the processed_list 
                    if (~ isempty(block.potential_result_address))

                        switch block.rate
                        case 'Good'
                            g_list = [g_list block.index];
                        case 'OK'
                            o_list = [o_list block.index];
                        case 'Bad'
                            b_list = [b_list block.index];
                        case 'Interpolate'
                            i_list = [i_list block.index];
                        case 'Not Rated'
                            n_list = [n_list block.index];
                        end

                       p_list{end + 1} = block.unique_name;
                       preprocessed_file_count = preprocessed_file_count + 1;
                       temp = temp + 1;
                    end
                end
                if (~isempty(raw_files) && temp == length(raw_files))
                    preprocessed_subject_count = preprocessed_subject_count + 1; 
                end
            end
            
            % Inform user if result folder has been modified
            if( preprocessed_file_count > self.processed_files || preprocessed_subject_count > self.processed_subjects)
                if( preprocessed_subject_count > self.processed_subjects)
                    waitfor(msgbox('New preprocessed results have been added to the project folder.'));
                else
                    waitfor(msgbox('New preprocessed results have been added to the project folder.'));
                end
            end

            if( preprocessed_file_count < self.processed_files || preprocessed_subject_count < self.processed_subjects)
                if( preprocessed_subject_count < self.processed_subjects)
                    waitfor(msgbox('Some preprocessed results have been deleted from the project folder.'));
                else
                    waitfor(msgbox('Some preprocessed results have been deleted from the project folder.'));
                end
            end

            % Inform user if data folder has been modified
            if( files_count > self.file_count || s_count > self.subject_count)
                if( s_count > self.subject_count)
                    waitfor(msgbox('New subjects are added to data folder.'));
                else
                    waitfor(msgbox('New files are added to data folder.'));
                end
            end

            if( files_count < self.file_count || s_count < self.subject_count)
                if( s_count < self.subject_count)
                    waitfor(msgbox('You have lost some data files.'));
                else
                    waitfor(msgbox('You have lost some data cosubjects.'));
                end
            end
            self.processed_files = preprocessed_file_count;
            self.processed_subjects = preprocessed_subject_count;   
            self.processed_list = p_list;
            self.block_map = map;
            self.block_list = list;
            self.file_count = files_count;
            self.subject_count = s_count;
            self.interpolate_list = i_list;
            self.good_list = g_list;
            self.bad_list = b_list;
            self.ok_list = o_list;
            self.not_rated_list = n_list;

            % Assign current index
            if( isempty(self.processed_list))
                self.current = -1;
            else
                if( self.current == -1)
                    self.current = 1;
                end
            end
        end
        
        function self = update_addresses_form_state_file(self, project_folder, data_folder)
            % This method must be called only when this project is a new
            % project loaded from a state file. The loaded project
            % may have not been created from this operating system, thus addresses
            % to the folders (which can be on the server as well) could be 
            % different on this system, and they must be updated.
            % project_folder - the new address of the result_folder
            % data_folder - the new address of the data_folder
            self = self.setData_folder(data_folder);
            self = self.setResult_folder(project_folder);
            self.state_address = self.make_state_address(project_folder);
            self.save_project();
        end
        
        function rated_count = get_rated_numbers(self)
            % Return number of files that has been already rated
            rated_count = length(self.processed_list) - length(self.not_rated_list);
        end
        
        function count = to_be_interpolated_count(self)
            % Return the number of files that are rated as interpolate
            count = length(self.interpolate_list);
        end
        
        function modified = folders_are_changed(self)
            % Return True if any change has happended to data_folder or
            % result_folder since the last update. If it's true,
            % update_data_structures must be called.
            data_changed = self.folder_is_changed(self.data_folder, ...
                self.subject_count, self.file_count, self.file_extension);
            result_changed = self.folder_is_changed(self.result_folder, []...
                , self.processed_files, '.mat');
            modified = data_changed || result_changed;
        end
        
        function save_project(self)
            % Save this class to the state file
            save(self.state_address, 'self');
        end
        
        function list = list_subject_files(self)
           % List all folders in the data_folder
           list = self.list_subjects(self.data_folder);
        end
        
        function list = list_preprocessed_subjects(self)
            % List all folders in the result_folder
            list = self.list_subjects(self.result_folder);
        end
        
    end
    
    %% Private Methods
    methods(Access=private)
        function self = create_rating_structure(self)
            % This method is called from the constructor to create and
            % initialise all data structures based on the data on both
            % data_folder and result_folder. This method may be time
            % consuming depending on the number of files in both
            % data_folder and result_folder as it goes through every block
            % and fetches relevant information.
            % In case there are already preprocessed files in the
            % result_folder, the rating data structures are initialised
            % based on those preprocessed blocks and their corresponding
            % ratings.
            %
            % The following properties are created/updated:
            %   block_list
            %   processed_list
            %   block_map
            %   processed_subjects
            %   processed_files
            %   file_count
            %   current
            %   interpolate_list
            %   good_list
            %   bad_list
            %   ok_list
            %   not_rated_list
            %   (Look at their corresponding docs for more info)
            %
            % Why are there 5 lists for each rating ?
            % The rate of each block is not only saved in its corresponding
            % instance of the class Block, but there is also one list
            % corresponding to that rate which contains the list of
            % indices of all blocks that have this rate. This helps to
            % speed up the operations next and previous of the rating_gui
            % whenver a filter on ratings is applied.
            
            % How this works ?
            % The methods goes through every single exising block in the
            % data_folder, then tries to find the corresponding
            % preprocessed file in the result_folder, if any. Then updates
            % the data_structure based on the preprocessed result.
            
            
            if(isunix)
                slash = '/';
            elseif(ispc)
                slash = '\';
            end
            % Load subject folders
            subjects = self.list_subject_files();
            s_count = length(subjects);
            map = containers.Map;
            list = {};
            self.maxX = 0;
            ext = self.file_extension;
            p_list = {};
            i_list = [];
            g_list = [];
            b_list = [];
            o_list = [];
            n_list = [];

            files_count = 0;
            preprocessed_file_count = 0;
            preprocessed_subject_count = 0;
            for i = 1:length(subjects)
                subject_name = subjects{i};
                subject = Subject([self.data_folder subject_name], ...
                                    [self.result_folder subject_name]);

                raw_files = dir([self.data_folder subject_name slash '*' ext]);
                temp = 0; 
                for j = 1:length(raw_files)
                    files_count = files_count + 1;
                    file = raw_files(j);
                    name_temp = file.name;
                    splits = strsplit(name_temp, ext);
                    file_name = splits{1};

                    % Block creation extracts and updates automatically the rating 
                    % information from the existing files, if any.
                    block = Block(subject, file_name, ext, self.ds_rate, self.params);
                    % If the block is not created due to unmatched
                    % parameters just skip it.
                    if( isempty(block.rate))
                        files_count = files_count - 1;
                        continue;
                    end
                    
                    map(block.unique_name) = block;
                    list{files_count} = block.unique_name;
                    block.index = files_count;

                    if ( ~ isempty(block.potential_result_address))       

                        switch block.rate
                        case 'Good'
                            g_list = [g_list block.index];
                        case 'OK'
                            o_list = [o_list block.index];
                        case 'Bad'
                            b_list = [b_list block.index];
                        case 'Interpolate'
                            i_list = [i_list block.index];
                        case 'Not Rated'
                            n_list = [n_list block.index];
                        end

                       p_list{end + 1} = block.unique_name;      
                       preprocessed_file_count = preprocessed_file_count + 1;
                       temp = temp + 1;
                    end
                end
                if (~isempty(raw_files) && temp == length(raw_files))
                    preprocessed_subject_count = preprocessed_subject_count + 1; 
                end
            end

            self.processed_list = p_list;
            self.processed_files = preprocessed_file_count;
            self.processed_subjects = preprocessed_subject_count; 
            self.file_count = files_count;
            self.subject_count = s_count;
            self.block_map = map;
            self.block_list = list;
            self.interpolate_list = i_list;
            self.good_list = g_list;
            self.bad_list = b_list;
            self.ok_list = o_list;
            self.not_rated_list = n_list;
            % Assign current index
            if( ~ isempty(self.processed_list))
                self.current = 1;
            else
                self.current = -1;
            end
        end
        
        function self = setName(self, name)
            % Set the name of this project
            
            % Name must be a valid file name
            if (~isempty(regexp(name, '[/\*:?"<>|]', 'once')))
                waitfor(msgbox(['Please enter a valid name not containing any of the following: '...
                       '/ \ * : ? " < > |'], 'Error','error'));
                return;
            end
            self.name = name;
        end
        
        function self = setData_folder(self, data_folder)
            % Set the address of the data_folder
            
            if(~ exist(data_folder, 'dir') && isunix)
                waitfor(msgbox(strcat('This data folder does not exist: ', data_folder),...
                    'Error','error'));
                return;
            end
            
            self.data_folder = self.add_slash(data_folder);
        end
        
        function self = setResult_folder(self, result_folder)
            % Set the address of the result_folder
            
            if(~ exist(result_folder, 'dir'))
                mkdir(result_folder);
            end
            
            self.result_folder = self.add_slash(result_folder);
        end
        
        function skip = check_existings(self)
            % If there is already at least one preprocessed file in the
            % result_folder, ask the user whether to overwrite them or skip them

            skip = 1;
            if( self.processed_files > 0)
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
        
        function write_to_log(self, source_address)
            log_file_address = [self.result_folder 'preprocessing.log'];
            if( exist(log_file_address, 'file'))
                fileID = fopen(log_file_address,'a');
            else
                fileID = fopen(log_file_address,'w');
            end
            fprintf(fileID, ['The data file ' source_address ' could not be preprocessed due to a lot of noise.']);
            fclose(fileID);
        end
    end
    
    %% Public static methods
    methods(Static)
        function address = make_state_address(p_folder)
            % Return the address of the state file
            
            address = strcat(p_folder, 'project_state.mat');
        end 
    end
    
    %% Private utility static methods
    methods(Static, Access=private)
        function folder = add_slash(folder)
            % Add "\" is not exists already ("\" for windows)
            
            if(isunix)
                if( ~ isempty(folder) && isempty(regexp( folder ,'\/$','match')))
                    folder = strcat(folder,'/');
                end
            elseif(ispc)
                if( ~ isempty(folder) && isempty(regexp( folder ,'\\$','match')))
                    folder = strcat(folder,'\');
                end
            end
        end
        
        function subjects = list_subjects(root_folder)
            % Return the list of subjects in the folder
            % root_folder       the folder in which subjects are looked for
            
            subs = dir(root_folder);
            isub = [subs(:).isdir];
            subjects = {subs(isub).name}';
            subjects(ismember(subjects,{'.','..'})) = [];
        end
        
        function modified = folder_is_changed(folder, folder_counts, ...
                file_counts, ext)
            % Return true if the number of files or folders in the
            % root_folder are changed since the last update. 
            % NOTE: This is a very naive way of checking if changes
            % happened. There could be changes in files, but not number of 
            % files, which are not detected. Be careful when using this.
            
            modified = false;
            subjects = Project.list_subjects(folder);
            subject_count = length(subjects);

            if( ~ isempty(folder_counts) )
                if( subject_count ~= folder_counts )
                    modified = true;
                    return;
                end
            end

            file_count = 0;
            for i = 1:subject_count
                subject = subjects{i};

                files = dir([folder, subject ,'/*' ,ext]);
                file_count = file_count + length(files);
            end

            % NOTE: Very risky. The assumption is that for each result file, there is a
            % corresponding reduced file as well.
            if(file_count ~= file_counts && file_count / 2 ~= file_counts)
                modified = true;
            end
        end

    end
    
    
end

