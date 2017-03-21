classdef EEGLabProject < handle
%EEGLabProject is a class representing a project. EEGLabProject is closely
%related to the /src/Project but limited only to be used for the EEGLab
%plugin functionalities of Automagic. EEGLabProject is necassary because
%rating_gui requires a class Project or EEGLabProject in order to work
%properly. To understand better how this class works please see
%src/Project.m
%
%   EEGLabProject is a subclass of handle, meaning it's a refrence to an
%   object. Use accordingly.
%
%Project Methods:
%   EEGLabProject - To create a project following arguments must be given:
%   myProject = EEGLabProject(ALLEEG, params)
%   where ALLEEG is a the list of all EEG Lab data structures to be plotted
%   by rating_gui or interpolated. It's necessary that EEG files be already
%   preprocessed.
%   params is the structure containing preprocessing parameters. Plese see 
%   preprocessing/pre_process.m more information on params.
%   This constructor calls create_rating_structures in order to create
%   and initialise corresponding data structures.
%
%   interpolate_selected - Called from the main_gui/EEGLAB to interpolate all
%   the selected channels during the manual rating in rating_gui.

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
    % The index of the current block that must be shown in rating_gui.
    current
    
    % Maximum value for the X-axis in the plot. Needed for the visual
    % aspects of the plot.
    maxX 
    
    % List of names of all blocks in the ALLEEG given in the
    % constructor
    block_list

    % List of indices of blocks that are rated as Interpolate.
    interpolate_list

    % List of indices of blocks that are rated as Good.
    good_list

    % List of indices of blocks that are rated as Bad.
    bad_list

    % List of indices of blocks that are rated as OK.
    ok_list

    % List of indices of blocks that are not rated (or rated as NotRated).
    not_rated_list
end

properties(SetAccess=private)
    % Arrays of EEG Lab data structure. This list will be plotted using
    % rating_gui or will be used to interpolate files that have been marked
    % to be interpolated.
    ALLEEG

    % struct containing parameters of preprocessing. Please see 
    % preprocessing/pre_process.m
    params

    % List of names of all preprocessed blocks so far.
    processed_list

    % Map each block name to the block itself.
    block_map

    % Number of all existing blocks.
    file_count

    % Number of preprocessed blocks.
    processed_files
end

%% Constructor
methods
    function self = EEGLabProject(ALLEEG, params)
        self.ALLEEG = ALLEEG;
        self.params = params;
        self = self.create_rating_structure();

    end
end

%% Public Methods
methods
    function self = interpolate_selected(self)
        % Interpolates all the EEG files that have been rated as "Interpolate"
        
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
            
            block.interpolate_channels(self.params.interpolation_params.method);
            self.interpolate_list(self.interpolate_list == block.index) = [];
            self.not_rated_list = ...
                    [self.not_rated_list block.index];
            self.not_rated_list = sort(self.not_rated_list);
        end
        end_time = cputime - start_time;
        disp(['Interpolation finished. Total elapsed time: ', num2str(end_time)])

    end
end

%% Private Methods
methods(Access=private)
    function self = create_rating_structure(self)
        % Creates the necessary data structure for a project. Please see
        % src/Project.m for more information.
        
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
            end
        end

        self.processed_list = p_list; 
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
end  

end

