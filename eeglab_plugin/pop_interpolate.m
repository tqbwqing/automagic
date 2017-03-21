% Copyright (C) <2017>  <Amirreza Bahreini>
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
function [ALLEEG, com] = pop_interpolate(ALLEEG)

% display help if not enough arguments
% ------------------------------------
if nargin < 1
	help pop_parameters;
	return;
end;	

com = ''; 
ALLEEG = ALLEEG;

project = EEGLabProject(ALLEEG);
project.interpolate_selected();

val = values(project.block_map);
if(length(val) < 1)
    return
end

new_ALLEEG = val{1}.EEG;
for i = 2:length(val)
    new_ALLEEG = [new_ALLEEG, val{i}.EEG];
end
ALLEEG = new_ALLEEG;