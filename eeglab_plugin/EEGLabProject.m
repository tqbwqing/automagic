classdef EEGLabProject < handle
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
        
        data_folder
        
        result_folder
    end
    
    properties(SetAccess=private)
        ALLEEG
        
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
        function self = EEGLabProject(ALLEEG)
            self.ALLEEG = ALLEEG;
            self.data_folder = '';
            self.result_folder = '';
            self = self.create_rating_structure();

        end
    end
    
    %% Public Methods
    methods

        function self = interpolate_selected(self)


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
                
                display(['Processing file ', block.unique_name ,' ...', '(file ', ...
                    int2str(i), ' out of ', int2str(length(int_list)), ')']); 
                assert(strcmp(block.rate, 'Interpolate') == 1);


                interpolate_chans = block.tobe_interpolated;
                if(isempty(interpolate_chans))
                    waitfor(msgbox(['The subject is rated to be interpolated but no',...
                        'channels has been chosen.'], 'Error','error'));
                    continue;
                end
                
                block.EEG = eeg_interp(block.EEG , interpolate_chans ,'spherical');

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

        end
        
        function self = update_rating_structures(self)
           %TODO: Throw an exception
        end
        
        function self = update_addresses_form_state_file(self, project_folder, data_folder)
            %TODO: Throw an exception
        end
        
        function modified = folders_are_changed(self)
            %TODO: Throw an exception
        end
        
        function self = save_project(self)

        end
        
        function list = list_subject_files(self)
           %TODO: Throw an exception
        end
        
        function list = list_preprocessed_subjects(self)
            %TODO: Throw an exception
        end
        
    end
    
    %% Private Methods
    methods(Access=private)
        function self = create_rating_structure(self)

            map = containers.Map;
            list = {};
            self.maxX = 0;
            p_list = {};
            i_list = [];
            g_list = [];
            b_list = [];
            o_list = [];
            n_list = [];

            files_count = 0;
            preprocessed_file_count = 0;
            preprocessed_subject_count = 0;
            for i = 1:length(self.ALLEEG)
                files_count = files_count + 1;
                EEG = self.ALLEEG(i);
                file_name = EEG.filename;

                % Block creation extracts and updates automatically the rating 
                % information from the existing files, if any.
                block = EEGLabBlock(file_name, files_count, self.ALLEEG(files_count));         
                map(block.unique_name) = block;
                list{files_count} = block.unique_name;

                if ( ~ isempty(block.rate))       

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
                end
            end

            self.processed_list = p_list;
            self.processed_files = preprocessed_file_count;
            self.processed_subjects = preprocessed_subject_count; 
            self.file_count = files_count;
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
        
        function self = setData_folder(self, data_folder)
            %TODO: Throw an exception
        end
        
        function self = setResult_folder(self, result_folder)
            %TODO: Throw an exception
        end

    end  
end