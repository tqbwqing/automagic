classdef Block < handle
    %Block is a class representing each raw file and its corresponding
    %preprocessed file in data_folder and result_folder respectively.
    %   A Block contains the entire relevant information of each raw file
    %   and its corresponding preprocessed file.
    %   This information include a unique_name for each block, the name of
    %   the raw_file, its extension, its corresponding Subject, the prefix
    %   of the preprocessed file, parameters of preprocessing (for more 
    %   info on the prefix and the parameters of the preprocessing see docs) 
    %   , sampling rate of the corresponding project, list of channels
    %   that are chosen to be interpolated, rate of the preprocessed file
    %   given during the rating process in rating_gui, list of channels
    %   interpolated during the preprocessing, list of channels that are
    %   interpolated by manual inspection and a boolean stating whether
    %   this block has been already interpolated or not.
    %
    %   Block is a subclass of handle, meaning it's a refrence to an
    %   object. Use accordingly.
    %
    %Block Methods:
    %   Block - To create a project following arguments must be given:
    %   myBlock = Block(subject, file_name, ext, dsrate, params)
    %   where subject is an instance of class Subject which specifies the
    %   Subject to which this block belongs to, file_name is the name of 
    %   the raw_file corresponding to this block, dsrate is the sampling
    %   rate of the corresponding project with which a reduced file is
    %   obtained and params the parameters of the preprocessing used on
    %   this block.
    %
    %   update_rating_info_from_file_if_any - Check if any corresponding
    %   preprocessed file exists, if it's the case import the rating data
    %   to this block, initialise otherwise.
    %
    %   potential_result_address - Check in the result folder for a
    %   corresponding preprocessed file with any prefix that respects the
    %   standard pattern (See prefix).
    %   
    %   update_addresses - The method is to be called to update addresses
    %   in case the project is loaded from another operating system and may
    %   have a different path to the data_folder or result_folder. This can
    %   happen either because the data is on a server and the path to it is
    %   different on different systems, or simply if the project is loaded
    %   from a windows to an iOS or vice versa. The best practice is to call
    %   this method before accessing a block to make sure it's synchronised
    %   with its project.
    %
    %   setRatingInfoAndUpdate - This method must be called to set and
    %   update the new rating information of this block (For example when 
    %   user changes the rating within the rating_gui).
    %
    %   saveRatingsToFile - Save all rating information to the
    %   corresponding preprocessed file
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

    %% Properties
    properties
        
        % Index of this block in the block list of the project.
        index 
        
        % The address of the corresponding raw file
        source_address
        
        % The address of the corresponding preprocessed file. It has the
        % form /root/project/subject/prefix_unique_name.mat (ie. np_subject1_001).
        result_address
        
        % The address of the corresponding reduced file. The reduced file is
        % a downsampled file of the preprocessed file. Its use is only to be
        % plotted on the rating_gui. It is downsampled to speed up the
        % plotting in rating_gui
        reduced_address
    end

    properties(SetAccess=private)
        
        % Instance of the Subject. The corresponding subject that contains
        % this block.
        subject
        
        % Unique_name of this block. It has the form
        % subjectName_rawFileName (ie. subject1_001).
        unique_name
        
        % Name of the raw file of this block
        file_name
        
        % File extension of the raw file. Could be .raw, .RAW, .dat or .fif
        file_extension
        
        % Downsampling rate of the project. This is used to downsample and
        % obtain the reduced file.
        dsrate
        
        % Parameters of the preprocessing. To learn more please see
        % preprocessing/pre_process.m
        params

        % Prefix of the corresponding preprocessed file. Prefix has the
        % pattern '^[gobni]i?p': It could be any of the following:
        %   np - preprocessed file not rated
        %   gp - preprocessed file rated as Good
        %   op - preprocessed file rated as OK
        %   bp - preprocessed file rated as Bad
        %   ip - preprocessed file rated as Interpolate
        %   nip - preprocessed file not rated but interpoalted at least
        %   once
        %   gip - preprocessed file rated as Good and interpolated at least
        %   once
        %   oip - preprocessed file rated as OK and interpolated at least
        %   once
        %   bip - preprocessed file rated as Bad and interpolated at least
        %   once
        %   iip - preprocessed file rated as Interpolated and interpolated 
        %   at least once
        prefix
        
        % List of the channels chosen by the user in the gui to be 
        % interpolated.
        tobe_interpolated
        
        % rate of this block: Good, Bad, OK, Interpolate, Not Rated
        rate
        
        % List of the channels that have been interpolated by the manual
        % inspection in interpolate_selected. Note that this is not a set,
        % If a channel is interpolated n times, there will be n instances 
        % of this channel in the list.  
        man_badchans
        
        % List of the channels that have been interpolated during the
        % prerpocessing step.
        auto_badchans
        
        % is true if the block has been already interpolated at least once.
        is_interpolated
    end
    
    properties(Dependent)
        
        % The address of the plots obtained during the preprocessing
        image_address
    end
    
    %% Constructor
    methods   
        function self = Block(subject, file_name, ext, dsrate, params)
  
            % Fixed ones are initialised in the constructor
            self.subject = subject;
            self.file_name = file_name;
            self.file_extension = ext;
            self.dsrate = dsrate;
            self.params = params;
            self.unique_name = self.extract_unique_name(subject, file_name);
            self.source_address = self.extract_source_address(subject, file_name, ext);
            % Modifiables
            self = self.update_rating_info_from_file_if_any();
        end
    end
    
    %% Public Methods
    methods 
        function self = update_rating_info_from_file_if_any(self)
            % Check if any corresponding preprocessed file exists, if it's 
            % the case and that file has been already rated import the 
            % rating data to this block, initialise otherwise.
            
            if( exist(self.potential_result_address(), 'file'))
                preprocessed = matfile(self.potential_result_address());
                if( ~ isequal(preprocessed.params, self.params))
                    waitfor(msgbox(['Preprocessing parameters of the ',...
                        self.file_name, ' does not correspond to the ',...
                        'preprocessing parameters of this project. This ',...
                        'file can not be merged.'],'Error','error'));
                    self.rate = [];
                    return;
                end 
            end
            % Find the preprocessed file if any (Empty char if there is no
            % file).
            extracted_prefix = self.extract_prefix(self.potential_result_address());
            
            % If the prefix indicates that the block has been already rated
            if(self.has_information(extracted_prefix))
                preprocessed = matfile(self.potential_result_address());
                
                self.rate = preprocessed.rate;
                self.tobe_interpolated = preprocessed.tobe_interpolated;
                self.is_interpolated = (length(extracted_prefix) == 3);
                self.auto_badchans = preprocessed.auto_badchans;
                self.man_badchans = preprocessed.man_badchans;
            else
                self.rate = 'Not Rated';
                self.tobe_interpolated = [];
                self.auto_badchans = [];
                self.man_badchans = [];
                self.is_interpolated = false;
            end
            
            % Build prefix and adress based on ratings
            self = self.update_prefix_and_result_address();
        end
        
        function result_address = potential_result_address(self)
            % Check in the result folder for a
            % corresponding preprocessed file with any prefix that respects the
            % standard pattern (See prefix).
    
            if(isunix)
                slash = '/';
            elseif(ispc)
                slash = '\';
            end
            pattern = '^[gobni]i?p_';
            fileData = dir(strcat(self.subject.result_folder, slash));                                        
            fileNames = {fileData.name};  
            idx = regexp(fileNames, strcat(pattern, self.file_name, '.mat')); 
            inFiles = fileNames(~cellfun(@isempty,idx));
            assert(length(inFiles) <= 1);
            if(~ isempty(inFiles))
                result_address = strcat(self.subject.result_folder, slash, inFiles{1});
            else
                result_address = '';
            end
        end
       
        function self = update_addresses(self, new_data_path, new_project_path)
            % The method is to be called to update addresses
            % in case the project is loaded from another operating system and may
            % have a different path to the data_folder or result_folder. This can
            % happen either because the data is on a server and the path to it is
            % different on different systems, or simply if the project is loaded
            % from a windows to a iOS or vice versa. 

            self.subject = self.subject.update_addresses(new_data_path, new_project_path);
            self.source_address = ...
                self.extract_source_address(self.subject, self.file_name, self.file_extension);
            self = self.update_prefix_and_result_address();
        end
        
        function self = setRatingInfoAndUpdate(self, rate, list, man_badchans, is_interpolated)
            % Set the new rating information
            
            self.rate = rate;
            self.tobe_interpolated = list;
            self.man_badchans = man_badchans;
            self.is_interpolated = is_interpolated;
            
            % Update the result address and rename if necessary
            self = self.update_prefix_and_result_address();
        end
        
        function saveRatingsToFile(self)
            % Save all rating information to the corresponding preprocessed 
            % file
            
            preprocessed = matfile(self.result_address,'Writable',true);
            preprocessed.tobe_interpolated = self.tobe_interpolated;
            preprocessed.rate = self.rate;
            preprocessed.auto_badchans = self.auto_badchans;
            preprocessed.is_interpolated = self.is_interpolated;
            
            % It keeps track of the history of all interpolations.
            preprocessed.man_badchans = self.man_badchans;
        end
        
        function img_address = get.image_address(self)
            % The name and address of the obtained plots during
            % preprocessing
            
            if(isunix)
                slash = '/';
            elseif(ispc)
                slash = '\';
            end
            
           img_address = [self.subject.result_folder slash self.file_name];
        end
        
        function bool = is_interpolate(self)
            % Return to true if this block is rated as Interpolate
            bool = strcmp(self.rate, 'Interpolate');
            bool = bool &&  (~ self.is_null);
        end
        
        function bool = is_good(self)
            % Return to true if this block is rated as Good
            bool = strcmp(self.rate, 'Good');
            bool = bool &&  (~ self.is_null);
        end
        
        function bool = is_ok(self)
            % Return to true if this block is rated as OK
            bool = strcmp(self.rate, 'OK');
            bool = bool &&  (~ self.is_null);
        end
        
        function bool = is_bad(self)
            % Return to true if this block is rated as Bad
            bool = strcmp(self.rate, 'Bad');
            bool = bool &&  (~ self.is_null);
        end
        
        function bool = is_not_rated(self)
            % Return to true if this block is rated as Not Rated
            bool = strcmp(self.rate, 'Not Rated');
            bool = bool &&  (~ self.is_null);
        end
        
        function bool = is_null(self)
            % Return true if this block is a mock block
            bool = (self.index == -1);
        end
    end
    
    %% Private Methods
    methods(Access=private)

        function self = update_prefix(self)
            % Update the prefix based in the rating information. This must 
            % be set after rating info are set. See the below function.
            p = 'p';
            if (self.is_interpolated)
                i = 'i';
            else
                i = '';
            end
            r = lower(self.rate(1));
            self.prefix = strcat(r, i, p);
        end

        function self = update_prefix_and_result_address(self)
            % Update prefix and thus addresses based on the rating
            % information. This must be called once rating info are set. 
            % Then the address and prefix are set based on rating info.
            
            if(isunix)
                slash = '/';
            elseif(ispc)
                slash = '\';
            end
            
            self = self.update_prefix();
            self.result_address = strcat(self.subject.result_folder, ...
                slash, self.prefix, '_', self.file_name, '.mat');
            self.reduced_address = self.extract_reduced_address(self.result_address, self.dsrate);
            
            % Rename the file if it doesn't correspond to the actual rating
            if( ~ strcmp(self.result_address, self.potential_result_address) )
                if( ~ isempty(self.potential_result_address) )
                    movefile(self.potential_result_address, self.result_address);
                end
            end
        end
    end
    
    %% Private utility static methods
    methods(Static, Access=private)
        function source_address = extract_source_address(subject, file_name, ext)
            % Return the address of the raw file
            
            if(isunix)
                slash = '/';
            elseif(ispc)
                slash = '\';
            end
            
            source_address = [subject.data_folder slash file_name, ext];
        end
        
        function reduced_address = extract_reduced_address(result_address, dsrate)
            % Return the address of the reduced file
            
            pattern = '[gobni]i?p_';
            reduced_address = regexprep(result_address,pattern,...
                strcat('reduced', int2str(dsrate), '_'));
        end
        
        function unique_name = extract_unique_name(subject, file_name)
            % Return the unique_name of this block. The unique_name is the
            % concatenation of the subject's name and this raw file's name
            
            unique_name = strcat(subject.name, '_', file_name);
        end

        function bool = has_information(prefix)
            % Return true if the prefix indicates that this preprocessed
            % file has been already rated.
            
            bool = true;
            
            % If the length is 3, there must be an "i" in it, which
            % indicates it's already been rated and interpolated.
            if(length(prefix) == 3)
                return;
            end
            
            switch Block.get_rate_from_prefix(prefix)
                case 'Not Rated'
                    bool = false;
                case ''
                    bool = false;
            end
        end
        
        function type = get_rate_from_prefix(prefix)
            % Extract the rating information from the prefix. The first
            % character of the prefix indicates the rating. 
            
            if( strcmp(prefix, ''))
                type = 'Not Rated';
                return;
            end
            
            type = '';
            switch prefix(1)
                case 'g'
                    type = 'Good';
                case 'o'
                    type = 'OK';
                case 'b'
                    type = 'Bad';
                case 'i'
                    type = 'Interpolate';
                case 'n'
                    type = 'Not Rated';
            end
        end

        function bool = is_valid_prefix(prefix)
            % Return true if the prefix respects the standard pattern
            
            pattern = '^[gobni]i?p$';
            reg = regexp(prefix, pattern, 'match');
            bool = ~ isempty(reg) || strcmp(prefix, '');
        end
        
        function prefix = extract_prefix(result_address)
            % Given the result_address, take the prefix out of it and
            % return
            
            if(isunix)
                slash = '/';
            elseif(ispc)
                slash = '\';
            end
            
            splits = strsplit(result_address, slash);
            name_with_ext = splits{end};
            splits = strsplit(name_with_ext, '.');
            prefixed_name = splits{1};
            splits = strsplit(prefixed_name, '_');
            prefix = splits{1};
            
            if( ~ Block.is_valid_prefix(prefix) )
                waitfor(msgbox('Not a valid prefix.','Error','error'));
                return;
            end
        end
        

    end
    
end

