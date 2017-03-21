classdef EEGLabBlock < handle
     %% Properties
    properties
        EEG
    end
    properties(SetAccess=private)
        % Index of this block in the block list of the project.
        index
        
        % Unique_name of this block. It has the form
        % subjectName_rawFileName (ie. subject1_001).
        unique_name
        
        % Name of the raw file of this block
        file_name
        
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
    
    %% Constructor
    methods   
        function self = EEGLabBlock(file_name, index, EEG)
  
            % Fixed ones are initialised in the constructor
            self.index = index;
            self.EEG = EEG;
            self.file_name = file_name;
            self.unique_name = strcat(int2str(index), '_',file_name);

            self = self.update_rating_info_from_file_if_any();
        end
    end
    
    %% Public Methods
    methods 
        function self = update_rating_info_from_file_if_any(self)
            % If the prefix indicates that the block has been already rated
            if( ~ isfield(self.EEG, 'rate'))
                self.EEG.rate = 'Not Rated';
                self.EEG.tobe_interpolated = [];
                self.EEG.auto_badchans = [];
                self.EEG.man_badchans = [];
                self.EEG.is_interpolated = false;
            end
            
            self.rate = self.EEG.rate;
            self.tobe_interpolated = self.EEG.tobe_interpolated;
            self.is_interpolated = self.EEG.is_interpolated;
            self.auto_badchans = self.EEG.auto_badchans;
            self.man_badchans = self.EEG.man_badchans;
        end
        
        function self = setRatingInfoAndUpdate(self, rate, list, man_badchans, is_interpolated)
            % Set the new rating information            
            self.rate = rate;
            self.tobe_interpolated = list;
            self.man_badchans = man_badchans;
            self.is_interpolated = is_interpolated;
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
        
        function reduced = get_reduced(self)  
            reduced.data = self.EEG.data;
        end
        
        function self = saveRatingsToFile(self)
            self.EEG.tobe_interpolated = self.tobe_interpolated;
            self.EEG.rate = self.rate;
            self.EEG.auto_badchans = self.auto_badchans;
            self.EEG.is_interpolated = self.is_interpolated;
            
            % It keeps track of the history of all interpolations.
            self.EEG.man_badchans = self.man_badchans;
        end
        
        function self = update_addresses(self, new_data_path, new_project_path)

        end
    end
end