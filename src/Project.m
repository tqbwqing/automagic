classdef Project < handle
    %Project is a class representing a project created in the main_gui
    %   Each instance of Project corresponds to a data_folder in which raw
    %   data is placed and a result_folder where the preprocessing results
    %   and plots are saved. Each instance Project keeps track of the list
    %   of all blocks, list of different five ratings, the current block
    %   which is shown in the rating_gui, etc. For more information look at
    %   the properties of this class.
    %   Project is a subclass of handle, meaning it's a refrence to an
    %   object. Use accordingly.
    %
    %Project Methods:
    %   Project - To create a project following arguments must be given:
    %   myProject = Project(name, d_folder, p_folder, ext, ds, filter_mode)
    %   where name is a char specifying the desired project name, d_folder
    %   is the address of the folder where raw data is placed, p_folder is
    %   the address of the folder where you want the results to be saved,
    %   ext is the file_extension of raw files, ds is the downsampling rate
    %   that will be used to create smaller versions of raw data in order
    %   to plot faster and filter_mode is a char that can be either 'US' or
    %   'EU' depending where the raw EEG data are recorded.
    %   update_rating_structures - 
    %
    %   update_addresses_form_state_file - Hoy
    properties
        filter_mode
        current
        maxX
        block_list
        interpolate_list
        good_list
        bad_list
        ok_list
        not_rated_list
    end
    
    properties(SetAccess=private, GetAccess=private)
        data_folder
        result_folder
        state_address
        
        
        data_folder_win
        result_folder_win
        state_address_win
    end
    
    properties(SetAccess=private)
        name
        ds_rate
        file_extension
        
        processed_list
        processed_files
        processed_subjects
        file_count
        subject_count
        block_map
    end
    
    %% Constructor
    methods
        function self = Project(name, d_folder, p_folder, ext, ds, ...
                filter_mode)
            self.name = name;
            self = self.setData_folder(d_folder);
            self = self.setResult_folder(p_folder);
            self = self.setState_address(self.make_state_address(self.getResult_folder));
            self.file_extension = ext;
            self.ds_rate = ds;
            self.filter_mode = filter_mode;
            self = self.create_rating_structure();
            self.save_project();
        end
    end
    
    %% Public Methods
    methods
        function self = update_rating_structures(self)
            
            if(ismac)
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
                raw_files = dir([self.getData_folder subject_name slash '*' ext]);
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
                            end
                        else
                            % In any case, no file exists, so resets the rating info
                            block.update_rating_info_from_file_if_any();
                        end
                    else                                        % File is new
                        % Block creation extracts and updates automatically the rating 
                        % information from the existing files, if any.
                        block = Block(subject, file_name, ext);
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
            % test comment
            self = self.setData_folder(data_folder);
            self = self.setResult_folder(project_folder);
            self = self.setState_address(self.make_state_address(project_folder));
        end
        
        function save_project(self)
            save(self.getState_address, 'self');
        end
        
        function list = list_subject_files(self)
           list = self.list_subjects(self.getData_folder);
        end
        
        function list = list_preprocessed_subjects(self)
            list = self.list_subjects(self.getResult_folder);
        end
        
        function self = set.name(self, name)
            % Name must be a valid file name
            if (~isempty(regexp(name, '[/\*:?"<>|]', 'once')))
                waitfor(msgbox(['Please enter a valid name not containing any of the following: '...
                       '/ \ * : ? " < > |'], 'Error','error'));
                return;
            end
            self.name = name;
        end
        
        function self = setData_folder(self, data_folder)
            if(ismac)
                self.data_folder = data_folder;
            elseif(ispc)
                self.data_folder_win = data_folder;
            end
        end
        
        function self = set.data_folder(self, data_folder)
            if(~ exist(data_folder, 'dir') && ismac)
                waitfor(msgbox(strcat('This data folder does not exist: ', data_folder),...
                    'Error','error'));
                return;
            end
            self.data_folder = self.add_slash(data_folder);
        end
        
        function self = setResult_folder(self, result_folder)
            
            if(~ exist(result_folder, 'dir'))
                mkdir(result_folder);
            end

            if(ismac)
                self.result_folder = self.add_slash(result_folder);
            elseif(ispc)
                self.result_folder_win = self.add_slash(result_folder);
            end
        end
        
        function self = setState_address(self, address)
            if(ismac)
                self.state_address = address;
            elseif(ispc)
                self.state_address_win = address;
            end
        end
        
        
        function data_folder = getData_folder(self)
            if(ismac)
                data_folder = self.data_folder;
            elseif(ispc)
                data_folder = self.data_folder_win;
            end
        end
        
        function result_folder = getResult_folder(self)
            if(ismac)
                result_folder = self.result_folder;
            elseif(ispc)
                result_folder = self.result_folder_win;
            end
        end
        
        function address = getState_address(self)
            if(ismac)
                address = self.state_address;
            elseif(ispc)
                address = self.state_address_win;
            end
        end
        
        
        % --- Count number of files that has been already rated
        function rated_count = get_rated_numbers(self)
            rated_count = length(self.processed_list) - length(self.not_rated_list);
        end
        
        % --- Count the number of files that are rated as interpolate
        function count = to_be_interpolated_count(self)
            count = length(self.interpolate_list);
        end
        
        function modified = folders_are_changed(self)
            data_changed = self.folder_is_changed(self.getData_folder, ...
                self.subject_count, self.file_count, self.file_extension);
            result_changed = self.folder_is_changed(self.getResult_folder, []...
                , self.processed_files, '.mat');
            modified = data_changed || result_changed;
        end
        
    end
    
    %% Private Methods
    methods(Access=private)
        function self = create_rating_structure(self)
            if(ismac)
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
                subject = Subject([self.getData_folder subject_name], ...
                                    [self.getResult_folder subject_name]);

                raw_files = dir([self.getData_folder subject_name slash '*' ext]);
                temp = 0; 
                for j = 1:length(raw_files)
                    files_count = files_count + 1;
                    file = raw_files(j);
                    name_temp = file.name;
                    splits = strsplit(name_temp, ext);
                    file_name = splits{1};

                    % Block creation extracts and updates automatically the rating 
                    % information from the existing files, if any.
                    block = Block(subject, file_name, ext, self.ds_rate);
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
    end
    
    %% Public static methods
    methods(Static)
        function address = make_state_address(p_folder)
            address = strcat(p_folder, 'project_state.mat');
        end 
    end
    %% Private utility static methods
    methods(Static, Access=private)
        % --- Add "\" is not exists already
        function folder = add_slash(folder)
            if(ismac)
                if( ~ isempty(folder) && isempty(regexp( folder ,'\/$','match')))
                    folder = strcat(folder,'/');
                end
            elseif(ispc)
                if( ~ isempty(folder) && isempty(regexp( folder ,'\\$','match')))
                    folder = strcat(folder,'\');
                end
            end
        end
        
        % --- return the list of subjects in the folder
        function subjects = list_subjects(root_folder)
            % root_folder       the folder in which subjects are looked for
            subs = dir(root_folder);
            isub = [subs(:).isdir];
            subjects = {subs(isub).name}';
            subjects(ismember(subjects,{'.','..'})) = [];
        end
        
        function modified = folder_is_changed(folder, folder_counts, ...
                file_counts, ext)
            
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

