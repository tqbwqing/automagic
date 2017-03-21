classdef EEGLabBlock < handle
%EEGLabBlock is a class representing each EEG file in ALLEEG. EEGLabBlock
%is closely related to src/Block.m
%   A Block contains relevant information of each EEG structure. For more
%   information please see src/Block.m
%
%   Block is a subclass of handle, meaning it's a refrence to an
%   object. Use accordingly.
%
%Block Methods:
%   EEGLabBlock - To create a project following arguments must be given:
%   myBlock = EEGLabBlock(file_name, index, EEG)
%   where file_name is a char defining the block name, index is its index
%   in the corresponding list of the EEGLabProject. This index is important
%   for ordering the files and plotting them in order. EEG is the EEGLab
%   data structure to which this block belongs.
%
%   update_rating_info_from_file_if_any - Check if any corresponding the
%   EEG is already preprocessed and imports the information. Otherwise it
%   initialises data.
%
%   setRatingInfoAndUpdate - This method must be called to set and
%   update the new rating information of this block (For example when 
%   user changes the rating within the rating_gui).
%
%   saveRatingsToFile - Save all rating information to the
%   corresponding EEG data structure
%
%   interpolate_channels - interpolates the selected channels during the
%   manual rating.
%
%   get_reduced - returns the EEG data structure to be plotted by
%   rating_gui
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
properties(SetAccess=private)
    % The EEGLab data structure that this block represents.
    EEG

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
        if( ~ isfield(self.EEG.automagic, 'rate'))
            self.EEG.automagic.rate = 'Not Rated';
            self.EEG.automagic.tobe_interpolated = [];
            self.EEG.automagic.auto_badchans = [];
            self.EEG.automagic.man_badchans = [];
            self.EEG.automagic.is_interpolated = false;
        end

        self.rate = self.EEG.automagic.rate;
        self.tobe_interpolated = self.EEG.automagic.tobe_interpolated;
        self.is_interpolated = self.EEG.automagic.is_interpolated;
        self.auto_badchans = self.EEG.automagic.auto_badchans;
        self.man_badchans = self.EEG.automagic.man_badchans;
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
        % Save information to the automagic field of EEG structure
        
        self.EEG.automagic.tobe_interpolated = self.tobe_interpolated;
        self.EEG.automagic.rate = self.rate;
        self.EEG.automagic.auto_badchans = self.auto_badchans;
        self.EEG.automagic.is_interpolated = self.is_interpolated;

        % It keeps track of the history of all interpolations.
        self.EEG.automagic.man_badchans = self.man_badchans;
    end

    function self = interpolate_channels(self, mode)
        % Interpolates selected channels during the manual rating.
        % mode - The mode of interpolation. Please see eeg_interp
        
        interpolate_chans = self.tobe_interpolated;
        if(isempty(interpolate_chans))
            waitfor(msgbox(['The subject is rated to be interpolated but no',...
                'channels has been chosen.'], 'Error','error'));
            return;
        end

        self.EEG = eeg_interp(self.EEG , interpolate_chans , mode);

        % Setting the new information
        self.setRatingInfoAndUpdate('Not Rated', [], [self.man_badchans interpolate_chans], true);
        self.saveRatingsToFile();
    end
end

end

