classdef Block < handle
    %BLOCK Summary of this class goes here
    %   Detailed explanation goes here
    
    %% Properties
    properties
        % Only so that the filtering shows everything in the same order as in the files
        index 
    end

   properties(SetAccess=private, GetAccess=private)
        source_address
        result_address
        reduced_address
        
        source_address_win
        result_address_win
        reduced_address_win
   end
    
    properties(SetAccess=private)
        % Fixed
        subject
        unique_name
        file_name
        file_extension
        dsrate
        prefix
        
        % Rating info
        tobe_interpolated
        rate
        man_badchans
        auto_badchans
        is_interpolated
    end
    
    properties(Dependent)
        image_address
    end
    
    %% Constructor
    methods   
        function self = Block(subject, file_name, ext, dsrate)
            % Fixed ones are initialised in the constructor
            self.subject = subject;
            self.file_name = file_name;
            self.file_extension = ext;
            self.dsrate = dsrate;
            self.unique_name = self.extract_unique_name(subject, file_name);
            self = self.setSource_address(self.extract_source_address(subject, file_name, ext));
            % Modifiables
            self = self.update_rating_info_from_file_if_any();
        end
    end
    
    %% Public Methods
    methods
        % Only in case it was loaded from another OS
        function self = update_addresses(self, new_data_path, new_project_path)
            self.subject.setResult_folder(new_project_path);
            self.subject.setData_folder(new_data_path);
            self = self.setSource_address(self.extract_source_address(self.subject, self.file_name, self.file_extension));
            self = self.update_prefix_and_result_address();
        end
        function self = setSource_address(self, address)
            if(ismac)
                self.source_address = address;
            elseif(ispc)
                self.source_address_win = address;
            end
        end
        function self = setResult_address(self, address)
            if(ismac)
                self.result_address = address;
            elseif(ispc)
                self.result_address_win = address;
            end
        end
        function self = setReduced_address(self, address)
            if(ismac)
                self.reduced_address = address;
            elseif(ispc)
                self.reduced_address_win = address;
            end
        end
        function reduced_address = getReduced_address(self)
            if(ismac)
                reduced_address = self.reduced_address;
            elseif(ispc)
                reduced_address = self.reduced_address_win;
            end
        end
        function source_address = getSource_address(self)
            if(ismac)
                source_address = self.source_address;
            elseif(ispc)
                source_address = self.source_address_win;
            end
        end
        
        function result_address = getResult_address(self)
            if(ismac)
                result_address = self.result_address;
            elseif(ispc)
                result_address = self.result_address_win;
            end
        end
        function self = update_rating_info_from_file_if_any(self)
            extracted_prefix = self.extract_prefix(self.potential_result_address());
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
        
        % Looks in the result folder to find a match for the raw data.
        function result_address = potential_result_address(self)
            if(ismac)
                slash = '/';
            elseif(ispc)
                slash = '\';
            end
            pattern = '^[gobni]i?p_';
            fileData = dir(strcat(self.subject.getResult_folder, slash));                                        
            fileNames = {fileData.name};  
            idx = regexp(fileNames, strcat(pattern, self.file_name, '.mat')); 
            inFiles = fileNames(~cellfun(@isempty,idx));
            assert(length(inFiles) <= 1);
            if(~ isempty(inFiles))
                result_address = strcat(self.subject.getResult_folder, slash, inFiles{1});
            else
                result_address = '';
            end
        end
        function img_address = get.image_address(self)
            if(ismac)
                slash = '/';
            elseif(ispc)
                slash = '\';
            end
            
           img_address = [self.subject.getResult_folder slash self.file_name];
        end
        
        function self = setRatingInfoAndUpdate(self, rate, list, man_badchans, is_interpolated)
            self.rate = rate;
            self.tobe_interpolated = list;
            self.man_badchans = man_badchans;
            self.is_interpolated = is_interpolated;
            % Update the result address and rename if if necessary
            self = self.update_prefix_and_result_address();
        end
        
        function saveRatingsToFile(self)
            % Save them to corresponding result file
            preprocessed = matfile(self.getResult_address,'Writable',true);
            preprocessed.tobe_interpolated = self.tobe_interpolated;
            preprocessed.rate = self.rate;
            preprocessed.auto_badchans = self.auto_badchans;
            preprocessed.is_interpolated = self.is_interpolated;
            % It keeps track of the history of all interpolations.
            preprocessed.man_badchans = self.man_badchans;
        end
        
        function bool = is_interpolate(self)
            bool = strcmp(self.rate, 'Interpolate');
            bool = bool &&  (~ self.is_null);
        end
        
        function bool = is_good(self)
            bool = strcmp(self.rate, 'Good');
            bool = bool &&  (~ self.is_null);
        end
        
        function bool = is_ok(self)
            bool = strcmp(self.rate, 'OK');
            bool = bool &&  (~ self.is_null);
        end
        
        function bool = is_bad(self)
            bool = strcmp(self.rate, 'Bad');
            bool = bool &&  (~ self.is_null);
        end
        
        function bool = is_not_rated(self)
            bool = strcmp(self.rate, 'Not Rated');
            bool = bool &&  (~ self.is_null);
        end
        
        function bool = is_null(self)
            bool = (self.index == -1);
        end
    end
    
    %% Private Methods
    methods(Access=private)
        % This must be set after rating info are set. See below function.
        function self = update_prefix(self)
            p = 'p';
            if (self.is_interpolated)
                i = 'i';
            else
                i = '';
            end
            r = lower(self.rate(1));
            self.prefix = strcat(r, i, p);
        end
        % This must be called once rating info are set. Then the address
        % and prefix are set based on rating info.
        function self = update_prefix_and_result_address(self)
            if(ismac)
                slash = '/';
            elseif(ispc)
                slash = '\';
            end
            
            self = self.update_prefix();
            self = self.setResult_address(strcat(self.subject.getResult_folder, ...
                slash, self.prefix, '_', self.file_name, '.mat'));
            self = self.setReduced_address(self.extract_reduced_address(self.getResult_address, self.dsrate));
            
            % Rename the file if it doesn't correspond to the actual rating
            if( ~ strcmp(self.getResult_address, self.potential_result_address) )
                if( ~ isempty(self.potential_result_address) )
                    movefile(self.potential_result_address, self.getResult_address);
                end
            end
        end
    end
    
    %% Private utility static methods
    methods(Static, Access=private)
        function source_address = extract_source_address(subject, file_name, ext)
            if(ismac)
                slash = '/';
            elseif(ispc)
                slash = '\';
            end
            
            source_address = [subject.getData_folder slash file_name, ext];
        end
        
        function reduced_address = extract_reduced_address(result_address, dsrate)
            pattern = '[gobni]i?p_';
            reduced_address = regexprep(result_address,pattern,...
                strcat('reduced', int2str(dsrate), '_'));
        end
        
        function unique_name = extract_unique_name(subject, file_name)
            unique_name = strcat(subject.name, '_', file_name);
        end

        function bool = has_information(prefix)
            bool = true;
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
            pattern = '^[gobni]i?p$';
            reg = regexp(prefix, pattern, 'match');
            bool = ~ isempty(reg) || strcmp(prefix, '');
        end
        
        function prefix = extract_prefix(result_address)
            if(ismac)
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

