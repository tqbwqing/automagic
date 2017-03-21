function [EEG, com] = pop_interpolate(ALLEEG)
% Starts interpolation of all the EEG files that have been rated to be
% interpolated during the rating step.
%
% Usage:
%   >> EEG = pop_interpolate ( EEG );
%
% Inputs:
%   EEG     - EEGLab EEG structure where the data has been already
%   preprocessed and rated.
%
% Outputs:
%   EEG     -  EEGLab EEG structure where the channels chosen to be
%   interpolated during the rating step are interpolated. In addition, the
%   EEG.automagic field is modified: the EEG.automagic.rate = NotRated as
%   the file needs to be re-rated after interpolation. The information
%   about interpolated channels will be updated accordingly.
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

% Check if there is already any preprocessed EEG files for interpolation.
% Note that the preprocessed files may not have been rated to be
% interpolated yet. This error will be detected in project.interpolate_selected()
% ------------------------------------
processed = [];
for i = 1:length(ALLEEG)
    if(isfield(ALLEEG(i), 'automagic') && ~ isempty(ALLEEG(i).automagic))
        processed = [processed, ALLEEG(i)];
    end
end

if(length(processed) < 1)
    error(['No preprocessed file. Please first click on ''Start ',...
    'preprocessing...''']);
end

% Create an instance of EEGLabProject and start interpolation
% ------------------------------------
project = EEGLabProject(processed, processed(1).automagic.params);
project.interpolate_selected();

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
com = sprintf('[EEG] = pop_interpolate(ALLEEG)');