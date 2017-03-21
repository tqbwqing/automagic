function [EEG, com] = pop_rating(ALLEEG)
% Opens up the rating_gui.  After rating it saves all the information in the
% corresponding EEG structure in the field 'EEG.automagic'. This
% information can be later used for interpolation. To find out 
%
% Usage:
%   >> EEG = pop_rating ( EEG );
%
% Inputs:
%   EEG     - EEGLab EEG structure where the data has been already
%   preprocessed.
%
% Outputs:
%   EEG     -  EEGLab EEG structure where the field EEG.automagic is
%   modified to have new information about ratings.
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

% display help if not enough arguments
% ------------------------------------
if nargin < 1
	help pop_parameters;
	return;
end;	

% Check if there is already any preprocessed EEG files to plot for rating.
% ------------------------------------
processed = [];
for i = 1:length(ALLEEG)
    if(isfield(ALLEEG(i), 'automagic') && ~ isempty(ALLEEG(i).automagic))
        processed = [processed, ALLEEG(i)];
    end
end

if(length(processed) < 1)
    error(['No preprocessed file to show. Please first click on ''Start ',...
    'preprocessing...''']);
end

% rating-gui needs an object of the class EEGLabProject. Create it and open
% the rating-gui
% ------------------------------------
project = EEGLabProject(processed, processed(1).automagic.params);
waitfor(rating_gui(project));

% Put the result from the project to the EEG structure.
% ------------------------------------
val = values(project.block_map);
new_ALLEEG = val{1}.EEG;
for i = 2:length(val)
    new_ALLEEG = [new_ALLEEG, val{i}.EEG];
end
EEG = new_ALLEEG;

% return the string command
% -------------------------
com = sprintf('[EEG] = pop_rating(ALLEEG)');
