function varargout = rating_gui(varargin)
% RATING_GUI MATLAB code for rating_gui.fig
%      RATING_GUI is called by the main_gui. A user must not call this gui 
%      directly. Howerver, for test reasons, one can call RATING_GUI if an 
%      instance of the class Project is given as argument.
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

% Last Modified by GUIDE v2.5 28-Oct-2016 14:42:23

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @rating_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @rating_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before rating_gui is made visible.
function rating_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to rating_gui (see VARARGIN)

if( nargin - 3 ~= 1 )
    error('wrong number of arguments. Project must be given as argument.')
end

project = varargin{1};
assert(isa(project, 'Project') || isa(project, 'EEGLabProject'));
handles.project = project;

set(handles.rating_gui, 'units', 'normalized', 'position', [0.05 0.3 0.8 0.8])
% set checkboxes to be all selected on startup
set(handles.interpolatecheckbox,'Value', 1)
set(handles.badcheckbox,'Value', 1)
set(handles.okcheckbox,'Value', 1)
set(handles.goodcheckbox,'Value', 1)
set(handles.notratedcheckbox,'Value', 1)

% Allows to select channels for interpolation if it's set to true.
handles.selection_mode = false;

handles = load_project(handles);

% Choose default command line output for rating_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes rating_gui wait for user response (see UIRESUME)
% uiwait(handles.rating_gui);


% --- Outputs from this function are returned to the command line.
function varargout = rating_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Set the gui components according to this project's properties
function handles = load_project(handles)
% handles       structure with handles of the gui

handles = set_gui_subjects_list(handles);
set_gui_rating(handles);
handles = update_next_and_previous_button(handles);

% Load and show the first image
[handles, data] = load_current(handles);
handles = show_current(data, handles);
clear data;


% --- Set the gui menu to show all avaiable files that are not filtered by 
% the gui
function handles = set_gui_subjects_list(handles)
% handles  structure with handles of the gui

project = handles.project;
processed_list = project.processed_list;
list = {};
for i = 1:length(processed_list)
    unique_name = processed_list{i};
    if( ~ is_filtered(handles, unique_name) )
        list{end + 1} = unique_name;
    end
end

if( isempty(list))
    list{end + 1} = '';
end

set(handles.subjectsmenu,'String',list);
handles = update_gui_selected_subject(handles);

% --- Set the rating of the gui based on the current project
function handles = set_gui_rating(handles)
% handles  structure with handles of the gui

project = handles.project;
if( project.current == - 1 || is_filtered(handles, project.current))
    set(handles.rategroup,'selectedobject',[]);
    return
end
block = get_current_block(handles);

set(handles.turnonbutton,'Enable', 'off')
set(handles.turnoffbutton,'Enable', 'off')
switch block.rate
    case 'Good'
       set(handles.rategroup,'selectedobject',handles.goodrate)
    case 'OK'
        set(handles.rategroup,'selectedobject',handles.okrate)
    case 'Bad'
        set(handles.rategroup,'selectedobject',handles.badrate)
    case 'Interpolate'
        set(handles.rategroup,'selectedobject',handles.interpolaterate)
        set(handles.turnonbutton,'Enable', 'on')
        set(handles.turnoffbutton,'Enable', 'on')
    case 'Not Rated'
        set(handles.rategroup,'selectedobject',handles.notrate)
end


% --- Load the current "reduced" file to the work space (The file is 
% downsampled to speed up the loading)
function [handles, reduced] = load_current(handles) %#ok<STOUT>
% handles   structure with handles of the gui

project = handles.project;
if ( project.current == - 1 || is_filtered(handles, project.current))
    reduced = [];
else
    block = get_current_block(handles);
    if(isa(block, 'Block'))
        block.update_addresses(project.data_folder, project.result_folder);
        load(block.reduced_address); 
    elseif(isa(block, 'EEGLabBlock'))
        reduced = block.get_reduced();
    end
    handles.project.maxX = max(project.maxX, size(reduced.data, 2));% fot the plot
end

% --- Make the plot of the current file
function handles = show_current(reduced, handles)
% handles  structure with handles of the gui
% reduced  data file to be plotted

if isfield(reduced, 'data')
    data = reduced.data;
    project = handles.project;
    unique_name = project.processed_list{project.current};
else
    data = [];
    unique_name = 'no image';
end


axe = handles.axes;
cla(axe);

im = imagesc(data);
set(im, 'ButtonDownFcn', {@on_selection,handles})
set(gcf, 'Color', [1,1,1])
colormap jet
caxis([-100 100])
title(unique_name, 'Interpreter','none')
handles.im = im;

draw_lines(handles);
mark_interpolated_chans(handles)

% --- Show the current ptoject as the selected one in the menu
function handles = update_gui_selected_subject(handles)
% handles  structure with handles of the gui

project = handles.project;
if( project.current == -1)
    return;
end
unique_name = project.processed_list{project.current};
IndexC = strfind(handles.subjectsmenu.String, unique_name);
Index = find(not(cellfun('isempty', IndexC)));
if(isempty(Index))
    Index = 1;
end
set(handles.subjectsmenu,'Value',Index);

% Returns the block pointed by the current index. If current = -1, a mock
% block is returned.
function block = get_current_block(handles)
project = handles.project;

if( project.current == -1)
    subject = Subject('','');
    block = Block(subject, '', '', 0, []);
    block.index = -1;
    return;
end
unique_name = project.processed_list{project.current};
block = project.block_map(unique_name);



% --- Get the index of the next available file.
% There are five different lists corresponding to different ratings. The
% first possible block from each list is first chosen, and finally the one
% which precedes all others in the main list is chosen. For more info 
% on why these lists please read Project docs.
function next = get_next_index(handles)
% handles  structure with handles of the gui

block = get_current_block(handles);
unique_name = block.unique_name;
current_index = block.index;
project = handles.project;

good_bool = get(handles.goodcheckbox,'Value');
ok_bool = get(handles.okcheckbox,'Value');
bad_bool = get(handles.badcheckbox,'Value');
interpolate_bool = get(handles.interpolatecheckbox,'Value');
notrated_bool = get(handles.notratedcheckbox,'Value');

% If no rating is filtered, simply return the next one in the list.
if( good_bool && ok_bool && bad_bool && interpolate_bool && notrated_bool)
    next = min(project.current + 1, length(project.processed_list));
    if( next == 0)
        next = next + 1;
    end
else
    next_good = [];
    next_ok = [];
    next_bad = [];
    next_interpolate = [];
    next_notrated = [];
    if(good_bool)
        possible_goods = find(project.good_list > current_index, 1);
        if( ~ isempty(possible_goods))
            next_good = project.good_list(possible_goods(1));
        end
    end
    if(ok_bool)
       possible_oks = find(project.ok_list > current_index, 1);
        if( ~ isempty(possible_oks))
            next_ok = project.ok_list(possible_oks(1));
        end
    end
    if(bad_bool)
       possible_bads = find(project.bad_list > current_index, 1);
        if( ~ isempty(possible_bads))
            next_bad = project.bad_list(possible_bads(1));
        end
    end
    if(interpolate_bool)
       possible_interpolates = find(project.interpolate_list > current_index, 1);
        if( ~ isempty(possible_interpolates))
            next_interpolate = project.interpolate_list(possible_interpolates(1));
        end
    end
    if(notrated_bool)
       possible_notrateds = find(project.not_rated_list > current_index, 1);
        if( ~ isempty(possible_notrateds))
            next_notrated = project.not_rated_list(possible_notrateds(1));
        end
    end
    next = min([next_good next_ok next_bad next_interpolate next_notrated]);
    if( isempty(next))
        if( ~ is_filtered(handles, unique_name ))
            next = project.current;
        else
            next = -1;
        end
    end
end


% --- Get the index of the previous file if any.
% There are five different lists corresponding to different ratings. The
% first possible block from each list is first chosen, and finally the one
% which follows all others in the main list is chosen. For more info 
% please read the docs.
function previous = get_previous_index(handles)
% handles  structure with handles of the gui

% Get the current project and file
block = get_current_block(handles);
unique_name = block.unique_name;
current_index = block.index;
project = handles.project;

% Check which ratings are filtered and which are not
good_bool = get(handles.goodcheckbox,'Value');
ok_bool = get(handles.okcheckbox,'Value');
bad_bool = get(handles.badcheckbox,'Value');
interpolate_bool = get(handles.interpolatecheckbox,'Value');
notrated_bool = get(handles.notratedcheckbox,'Value');

% If nothing is filtered the previous one is simply the one before the
% current one in the list
if( good_bool && ok_bool && bad_bool && interpolate_bool && notrated_bool)
    previous = max(project.current - 1, 1);
    return;
end

% Now for each rating, find the possible choices, and then choose the
% closest one
previous_good = [];
previous_ok = [];
previous_bad = [];
previous_interpolate = [];
previous_notrated = [];
if(good_bool)
    possible_goods = find(project.good_list < current_index, 1, 'last');
    if( ~ isempty(possible_goods))
        previous_good = project.good_list(possible_goods(end));
    end
end
if(ok_bool)
   possible_oks = find(project.ok_list < current_index, 1, 'last');
    if( ~ isempty(possible_oks))
        previous_ok = project.ok_list(possible_oks(end));
    end
end
if(bad_bool)
   possible_bads = find(project.bad_list < current_index, 1, 'last');
    if( ~ isempty(possible_bads))
        previous_bad = project.bad_list(possible_bads(end));
    end
end
if(interpolate_bool)
   possible_interpolates = find(project.interpolate_list < current_index, 1, 'last');
    if( ~ isempty(possible_interpolates))
        previous_interpolate = project.interpolate_list(possible_interpolates(end));
    end
end
if(notrated_bool)
   possible_notrateds = find(project.not_rated_list < current_index, 1, 'last');
    if( ~ isempty(possible_notrateds))
        previous_notrated = project.not_rated_list(possible_notrateds(end));
    end
end
previous = max([previous_good previous_ok previous_bad previous_interpolate previous_notrated]);
if( isempty(previous))
    if( ~ is_filtered(handles, unique_name ))
        previous = project.current;
    else
        previous = -1;
    end
end

% --- Check whether this file is filtered by the user
function bool = is_filtered(handles, file)
% handles  structure with handles of the gui
% subj     could be a double indicating the index of the file or a char
%          indicating the name of it
project = handles.project;
if( project.current == -1)
    bool = true;
    return;
end

project = handles.project;
switch class(file)
    case 'double'
        unique_name = project.processed_list{file};
    case 'char'
        unique_name = file;
end

block = project.block_map(unique_name);
rate = block.rate;
switch rate
    case 'Good'
        bool = ~ get(handles.goodcheckbox,'Value');
    case 'OK'
        bool = ~ get(handles.okcheckbox,'Value');
    case 'Bad'
        bool = ~ get(handles.badcheckbox,'Value');
    case 'Interpolate'
        bool = ~ get(handles.interpolatecheckbox,'Value');
    case 'Not Rated'
        bool = ~ get(handles.notratedcheckbox,'Value');
    otherwise
        bool = false;
end

% --- Switch the gui to enable or disable
function switch_gui(mode, handles)
% handles  structure with handles of the gui
% mode     string that can be 'off' or 'on'

set(handles.nextbutton,'Enable', mode)
set(handles.previousbutton,'Enable', mode)
set(handles.interpolaterate,'Enable', mode)
set(handles.okrate,'Enable', mode)
set(handles.badrate,'Enable', mode)
set(handles.goodrate,'Enable', mode)
set(handles.notrate,'Enable', mode)
set(handles.goodcheckbox,'Enable', mode)
set(handles.okcheckbox,'Enable', mode)
set(handles.badcheckbox,'Enable', mode)
set(handles.interpolatecheckbox,'Enable', mode)
set(handles.notratedcheckbox,'Enable', mode)

% --- If there is no previous, desactivate the previous button, if there 
% is no next, desactivate the next button. And vice versa in order to 
% reset the action.
function handles = update_next_and_previous_button(handles)
% handles  structure with handles of the gui

if( handles.project.current == -1)
    set(handles.nextbutton,'Enable', 'off');
    set(handles.previousbutton,'Enable', 'off');
    return;
end
project = handles.project;
if( project.current == get_next_index(handles))
    set(handles.nextbutton,'Enable', 'off');
end

if( project.current ~= get_previous_index(handles))
    set(handles.previousbutton,'Enable', 'on');
end

if( project.current == get_previous_index(handles))
    set(handles.previousbutton,'Enable', 'off');
end

if( project.current ~= get_next_index(handles))
    set(handles.nextbutton,'Enable', 'on');
end

% --- Executes on button press in turnonbutton. Turn on the selection_mode
function turnonbutton_Callback(hObject, eventdata, handles)
% hObject    handle to turnonbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
project = handles.project;
if( project.current == -1)
    return;
end

block = get_current_block(handles);
assert(block.is_interpolate())
handles = turn_on_selection(handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in turnoffbutton. Turn off the
% selection_mode
function turnoffbutton_Callback(hObject, eventdata, handles)
% hObject    handle to turnoffbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
project = handles.project;
if( project.current == -1)
    return;
end

block = get_current_block(handles);
assert(block.is_interpolate())
handles = turn_off_selection(handles);

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in goodcheckbox. If the checkbox is
% unchecked, the blocks with this rating are filtered and can not be shown.
% It processes as explaind below:
% If the filter is turned on and the current block has the same rating , it 
% should be changed to the next not-filtered block. If there is no next
% possible block, a previous not-filtered block is chosen. 
%
% If no image was possible to be shown because of the filterings, and if this
% filtering is finally removed, choose the first possible block to be shown
function goodcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to goodcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = save_state(handles);
project = handles.project;

next_idx = handles.project.current;
val = get(handles.goodcheckbox, 'Value');
block = get_current_block(handles);

% If it's to be filtered and current must be changed
if( ~ val && block.is_good() )
    next_idx = get_next_index(handles);
    if(next_idx == -1)
        next_idx = get_previous_index(handles);
    end
end

% When nothing is shown and filter is off
if((val && is_filtered(handles, project.current)) || ...
        (val && block.is_good() ))
    if(block.is_good()  && ...
            ~ is_filtered(handles, project.current))
        next_idx = handles.project.current;
    else
        next_idx = get_next_index(handles);
        if(next_idx == -1)
            next_idx = get_previous_index(handles);
        end
    end
end

handles.project.current = next_idx;
handles = load_project(handles);
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in okcheckbox. If the checkbox is
% unchecked, the blocks with this rating are filtered and can not be shown.
% It processes as explaind below:
% If the filter is turned on and the current block has the same rating , it 
% should be changed to the next not-filtered block. If there is no next
% possible block, a previous not-filtered block is chosen. 
%
% If no image was possible to be shown because of the filterings, and if this
% filtering is finally removed, choose the first possible block to be shown
function okcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to okcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = save_state(handles);
project = handles.project;
next_idx = handles.project.current;
val = get(handles.okcheckbox, 'Value');
block = get_current_block(handles);
if( ~ val && block.is_ok() )
    next_idx = get_next_index(handles);
    if(next_idx == -1)
        next_idx = get_previous_index(handles);
    end
end

% When nothing is shown
if((val && is_filtered(handles, project.current)) || ...
        (val && block.is_ok() ))
    if(block.is_ok()  && ...
            ~ is_filtered(handles, project.current))
        next_idx = handles.project.current;
    else
        next_idx = get_next_index(handles);
        if(next_idx == -1)
            next_idx = get_previous_index(handles);
        end
    end
end
handles.project.current = next_idx;
handles = load_project(handles);
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in badcheckbox. If the checkbox is
% unchecked, the blocks with this rating are filtered and can not be shown.
% It processes as explaind below:
% If the filter is turned on and the current block has the same rating , it 
% should be changed to the next not-filtered block. If there is no next
% possible block, a previous not-filtered block is chosen. 
%
% If no image was possible to be shown because of the filterings, and if this
% filtering is finally removed, choose the first possible block to be shown
function badcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to badcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = save_state(handles);
project = handles.project;
next_idx = handles.project.current;
val = get(handles.badcheckbox, 'Value');
block = get_current_block(handles);
if( ~ val && block.is_bad() )
    next_idx = get_next_index(handles);
    if(next_idx == -1)
        next_idx = get_previous_index(handles);
    end
end

% When nothing is shown
if((val && is_filtered(handles, project.current)) || ...
        (val && block.is_bad() ))
    if(block.is_bad()  && ...
            ~ is_filtered(handles, project.current))
        next_idx = handles.project.current;
    else
        next_idx = get_next_index(handles);
        if(next_idx == -1)
            next_idx = get_previous_index(handles);
        end
    end
end
handles.project.current = next_idx;
handles = load_project(handles);
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in interpolatecheckbox. If the checkbox is
% unchecked, the blocks with this rating are filtered and can not be shown.
% It processes as explaind below:
% If the filter is turned on and the current block has the same rating , it 
% should be changed to the next not-filtered block. If there is no next
% possible block, a previous not-filtered block is chosen. 
%
% If no image was possible to be shown because of the filterings, and if this
% filtering is finally removed, choose the first possible block to be shown
function interpolatecheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to interpolatecheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = save_state(handles);
project = handles.project;
next_idx = handles.project.current;
val = get(handles.interpolatecheckbox, 'Value');
block = get_current_block(handles);
if( ~ val && block.is_interpolate() )
    next_idx = get_next_index(handles);
    if(next_idx == -1)
        next_idx = get_previous_index(handles);
    end
end

% When nothing is shown
if((val && is_filtered(handles, project.current)) || ...
        (val && block.is_interpolate() ))
    if(block.is_interpolate()  && ...
            ~ is_filtered(handles, project.current))
        next_idx = handles.project.current;
    else
        next_idx = get_next_index(handles);
        if(next_idx == -1)
            next_idx = get_previous_index(handles);
        end
    end
end
handles.project.current = next_idx;
handles = load_project(handles);
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in notratedcheckbox. If the checkbox is
% unchecked, the blocks with this rating are filtered and can not be shown.
% It processes as explaind below:
% If the filter is turned on and the current block has the same rating , it 
% should be changed to the next not-filtered block. If there is no next
% possible block, a previous not-filtered block is chosen. 
%
% If no image was possible to be shown because of the filterings, and if this
% filtering is finally removed, choose the first possible block to be shown
function notratedcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to notratedcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = save_state(handles);
project = handles.project;
next_idx = handles.project.current;
val = get(handles.notratedcheckbox, 'Value');
block = get_current_block(handles);
if( ~ val && block.is_not_rated() )
    next_idx = get_next_index(handles);
    if(next_idx == -1)
        next_idx = get_previous_index(handles);
    end
end

% When nothing is shown
if((val && is_filtered(handles, project.current)) || ...
        (val && block.is_not_rated() ))
    if(block.is_not_rated()  && ...
            ~ is_filtered(handles, project.current))
        next_idx = handles.project.current;
    else
        next_idx = get_next_index(handles);
        if(next_idx == -1)
            next_idx = get_previous_index(handles);
        end
    end
end
handles.project.current = next_idx;
handles = load_project(handles);
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in previousbutton.
function previousbutton_Callback(hObject, eventdata, handles)
% hObject    handle to previousbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = previous(handles);

% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in nextbutton.
function nextbutton_Callback(hObject, eventdata, handles)
% hObject    handle to nextbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = next(handles);

% Update handles structure
guidata(hObject, handles);

% --- Executes when selected object is changed in rategroup.
function rategroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in rategroup 
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
project = handles.project;
if(project.current == -1)
    return;
end
handles = get_rating_from_gui(handles);
block = get_current_block(handles);
if( block.is_interpolate() )
   handles = turn_on_selection(handles);
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on selection change in channellistbox. If a channel from the
% channel list is chosen, it will be drawn with 'red' color. Just a visual
% effect.
function channellistbox_Callback(hObject, eventdata, handles)
% hObject    handle to channellistbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if( handles.project.current == -1)
    return;
end
index_selected = get(handles.channellistbox,'Value');

if( isempty(index_selected))
    return;
end

channels = cellstr(get(handles.channellistbox,'String'));
channel = channels{index_selected};
channel = str2num(channel);

update_lines(handles);
lines = findall(gcf,'Type','Line');
for i = 1:length(lines)
   if (lines(i).YData(1) == channel)
       break;
   end
end
delete(lines(i));
draw_line(channel, project.maxX, handles, 'r')


% --- Executes on selection change in subjectsmenu. It selects the block
% chosen by the user in the subjects menu list
function subjectsmenu_Callback(hObject, eventdata, handles)
% hObject    handle to subjectsmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Determine the selected data set.
handles = save_state(handles);

project = handles.project;
list = get(hObject, 'String');
idx = get(hObject,'Value');
unique_name = list{idx};
IndexC = strfind(project.processed_list, unique_name);
Index = find(not(cellfun('isempty', IndexC)));
if( isempty(Index) )
    Index = -1;
end
project.current = Index;
handles.project = project;
handles = load_project(handles);

% Update handles structure
guidata(hObject, handles);

% --- Show the next file in the list
function handles = next(handles)
% handles  structure with handles of the gui

handles = save_state(handles);
handles.project.current = get_next_index(handles);
handles = load_project(handles);

% --- Show the previous file in the list
function handles = previous(handles)
% handles  structure with handles of the gui

handles = save_state(handles);
handles.project.current = get_previous_index(handles);
handles = load_project(handles);


% --- Get the selected rating from the gui for this current file. It does
% not save the result in the corresponsing file yet, but it does rename the
% result file immediately.
function handles = get_rating_from_gui(handles)
% handles  structure with handles of the gui

project = handles.project;
if ( ~ isa(handles,'struct') || project.current == -1)
    return
end

if( isempty(handles.rategroup.SelectedObject))
    return;
else
    block = get_current_block(handles);
    new_rate = handles.rategroup.SelectedObject.String;
    switch new_rate
        case {'Good', 'OK', 'Bad', 'Not Rated'}
            block.setRatingInfoAndUpdate(new_rate, [], block.man_badchans, block.is_interpolated);
        case 'Interpolate'
            % The interpolate_list is untouched at this step. There maybe even
            % conflicts in it which are not checked.
            block.setRatingInfoAndUpdate(new_rate, block.tobe_interpolated, block.man_badchans, block.is_interpolated);
    end
end

% --- Draw all the channels that has been previously selected to be
% interpolated
function draw_lines(handles)
% handles  structure with handles of the gui

project = handles.project;
if(project.current == -1)
    return;
end
block = get_current_block(handles);
list = block.tobe_interpolated;
for chan = 1:length(list)
    draw_line(list(chan), project.maxX, handles, 'b');
end
set(handles.channellistbox,'String',list)

% --- Draw a horizontal line on the channel selected by y to mark it on the
% plot
function draw_line(y, maxX, handles, color)
% handles  structure with handles of the gui
% y        the y-coordinate of the selected point to be drawn
% maxX     the maximum x-coordinate until which the line must be drawn in
%          the x-axis
% color    color of the line

axe = handles.axes;
axes(axe);
hold on;
p1 = [0, maxX];
p2 = [y, y];
p = plot(axe, p1, p2, color ,'LineWidth', 3);
set(p, 'ButtonDownFcn', {@delete_line, p, y, handles})
hold off;

% --- Draw a star * on the plot to show the channels that have been
% interpolated automatically during the preprocessing step
function mark_interpolated_chans(handles)
% handles  structure with handles of the gui

project = handles.project;
if(project.current == -1)
    return;
end
block = get_current_block(handles);
badchans = block.auto_badchans;
axe = handles.axes;
axes(axe);
hold on;
for i = 1:length(badchans)
    plot(0 , badchans(i),'r*')
end
hold off;

% --- Turn on the selection mode to choose channels that should be
% interpolated
function handles = turn_on_selection(handles)
% handles  structure with handles of the gui
set(handles.turnoffbutton,'Enable', 'on')
set(handles.turnonbutton,'Enable', 'off')
handles.selection_mode = true;

% To update both oncall functions with new handles where the selection is
% changed
set(handles.im, 'ButtonDownFcn', {@on_selection,handles})
update_lines(handles)

set(gcf,'Pointer','crosshair');
switch_gui('off', handles);

% --- Turn of the slesction mode of channels
function handles = turn_off_selection(handles)
% handles  structure with handles of the gui
set(handles.turnoffbutton,'Enable', 'off')
set(handles.turnonbutton,'Enable', 'on')
handles.selection_mode = false;

% To update both oncall functions with new handles where the selection is
% changed
set(handles.im, 'ButtonDownFcn', {@on_selection,handles})
update_lines(handles)

set(gcf,'Pointer','arrow');
switch_gui('on', handles);

% --- Event handler for the selection
function on_selection(source, event, handles)
% handles  structure with handles of the gui
% event    the event object

if( handles.selection_mode )
    y = event.IntersectionPoint(2);
    process_input(y, handles);
end

% --- Save the selected channel to the interpolation list and draw a line
% to mark it on the plot
function process_input(y, handles)
% handles  structure with handles of the gui
% y        the y coordinate of the selected point
block = get_current_block(handles);
list = block.tobe_interpolated;
y = int64(y);
if( ismember(y, list ) )
    error('No way the callback function is called here !')
else
    list = [list y];
    draw_line(y, handles.project.maxX, handles, 'b');
end
block.setRatingInfoAndUpdate('Interpolate', list, block.man_badchans, block.is_interpolated);
set(handles.channellistbox,'String',list)

% --- Redraw all lines
function update_lines(handles)
% handles  structure with handles of the gui

lines = findall(gcf,'Type','Line');
for i = 1:length(lines)
   delete(lines(i)); 
end
draw_lines(handles);
mark_interpolated_chans(handles);

% --- Delete the line selected by y and remove it from the interpolation
% list 
function delete_line(source, event, p, y, handles)
% handles  structure with handles of the gui
% y        the y-coordinate of the line to be deleted (number of the channel)
% p        the plot handler of the line (this is the plot seperated from the main plot)
% event    the event object

if( ~ handles.selection_mode )
    return;
end
axes(handles.axes);
delete(p);
block = get_current_block(handles);
list = block.tobe_interpolated;
list = list(list ~= y);
block.setRatingInfoAndUpdate('Interpolate', list, block.man_badchans, block.is_interpolated);
set(handles.channellistbox,'String',list)

% --- Save the state of the project
function handles = save_state(handles)
% handles  structure with handles of the gui

if ( ~ isa(handles,'struct') || handles.project.current == -1)
    return

end

% Save the rating data into the preprocessing file
block = get_current_block(handles);
block.saveRatingsToFile();
% Now we should update five lists of ratings which are used to speed up the
% filtering pocess.
switch block.rate
    case 'Good'
        if( ~ ismember(block.index, handles.project.good_list ) )
            handles.project.good_list = ...
                [handles.project.good_list block.index];
            handles.project.not_rated_list(handles.project.not_rated_list == block.index) = [];
            handles.project.ok_list(handles.project.ok_list == block.index) = [];
            handles.project.bad_list(handles.project.bad_list == block.index) = [];
            handles.project.interpolate_list(handles.project.interpolate_list == block.index) = [];
            handles.project.good_list = sort(handles.project.good_list);

        end
    case 'OK'
        if( ~ ismember(block.index, handles.project.ok_list ) )
            handles.project.ok_list = ...
                [handles.project.ok_list block.index];
            handles.project.not_rated_list(handles.project.not_rated_list == block.index) = [];
            handles.project.good_list(handles.project.good_list == block.index) = [];
            handles.project.bad_list(handles.project.bad_list == block.index) = [];
            handles.project.interpolate_list(handles.project.interpolate_list == block.index) = [];
            handles.project.ok_list = sort(handles.project.ok_list);
        end
    case 'Bad'
        if( ~ ismember(block.index, handles.project.bad_list ) )
            handles.project.bad_list = ...
                [handles.project.bad_list block.index];
            handles.project.not_rated_list(handles.project.not_rated_list == block.index) = [];
            handles.project.ok_list(handles.project.ok_list == block.index) = [];
            handles.project.good_list(handles.project.good_list == block.index) = [];
            handles.project.interpolate_list(handles.project.interpolate_list == block.index) = [];
            handles.project.bad_list = sort(handles.project.bad_list);
        end
    case 'Interpolate'
        if( ~ ismember(block.index, handles.project.interpolate_list ) )
            handles.project.interpolate_list = ...
                [handles.project.interpolate_list block.index];
            handles.project.not_rated_list(handles.project.not_rated_list == block.index) = [];
            handles.project.ok_list(handles.project.ok_list == block.index) = [];
            handles.project.bad_list(handles.project.bad_list == block.index) = [];
            handles.project.good_list(handles.project.good_list == block.index) = [];
            handles.project.interpolate_list = sort(handles.project.interpolate_list);
        end
    case 'Not Rated'
        if( ~ ismember(block.index, handles.project.not_rated_list ) )
            handles.project.not_rated_list = ...
                [handles.project.not_rated_list block.index];
            handles.project.good_list(handles.project.good_list == block.index) = [];
            handles.project.ok_list(handles.project.ok_list == block.index) = [];
            handles.project.bad_list(handles.project.bad_list == block.index) = [];
            handles.project.interpolate_list(handles.project.interpolate_list == block.index) = [];
            handles.project.not_rated_list = sort(handles.project.not_rated_list);
        end
end
        
% Save the stateS
if(isa(handles.project, 'Project'))
    handles.project.save_project();
end

% --- Executes when user attempts to close rating_gui.
function rating_gui_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to rating_gui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
save_state(handles);

if(isa(handles.project, 'EEGLabProject'))
    delete(hObject);
    return;
end

% Update the main gui's data after rating processing
h = findobj(allchild(0), 'flat', 'Tag', 'main_gui');
if( isempty(h))
    h = main_gui;
end
handle = guidata(h);
handle.project_list(handles.project.name) = handles.project;
guidata(handle.main_gui, handle);
main_gui();

% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Executes during object creation, after setting all properties.
function subjectsmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subjectsmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function channellistbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to channellistbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
