function varargout = main_gui(varargin)
% MAIN_GUI MATLAB code for main_gui.fig
%      MAIN_GUI is the main function of Automagic that must be called in
%      order to start the application. All other functions and guis are 
%      called from within the MAIN_GUI.
%      
%      No arguments is needed to start the application.
%
%      MAIN_GUI, by itself, creates a new MAIN_GUI or raises the existing
%      singleton*.
%
%      H = MAIN_GUI returns the handle to a new MAIN_GUI or the handle to
%      the existing singleton*.
%
%      MAIN_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MAIN_GUI.M with the given input arguments.
%
%      MAIN_GUI('Property','Value',...) creates a new MAIN_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before main_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to main_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help main_gui

% Last Modified by GUIDE v2.5 16-Nov-2016 15:54:35

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @main_gui_OpeningFcn, ...
    'gui_OutputFcn',  @main_gui_OutputFcn, ...
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


% --- Executes just before main_gui is made visible.
function main_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to main_gui (see VARARGIN)

% Choose default command line output for main_gui
handles.output = hObject;

% Position of the gui
set(handles.main_gui, 'units', 'normalized', 'position', [0.05 0.3 0.9 0.8])

handles.version = '1.2.0';

% Set constant values
handles.new_project.LIST_NAME = 'Create New Project...';
handles.new_project.NAME = 'Type the name of your new project...';
handles.new_project.DATA_FOLDER = 'Choose where your raw data is...';
handles.new_project.FOLDER = 'Choose where you want the results to be saved...';
handles.load_selected_project.LIST_NAME = 'Load an existing project...';
handles.state_file.NAME = 'state.mat';
handles.state_file.FOLDER = '~/methlab_pipeline/';
handles.state_file.ADDRESS = strcat(handles.state_file.FOLDER,...
    handles.state_file.NAME);


% Default Settings
handles.NONE = 'None';
handles.Default = 'Default';
handles.default_params.filter_params.high_freq = 0.5;
handles.default_params.filter_params.high_order = 3;
handles.default_params.filter_params.low_freq = -1;
handles.default_params.filter_params.low_order = 3;
handles.default_params.perform_reduce_channels = 1;
handles.default_params.channel_rejection_params.kurt_thresh = 3;
handles.default_params.channel_rejection_params.prob_thresh = 4;
handles.default_params.channel_rejection_params.spec_thresh = 4;
handles.default_params.perform_eog_regression = 1;
handles.default_params.pca_params.lambda = handles.Default;
handles.default_params.pca_params.tol = 1e-7;
handles.default_params.pca_params.maxIter = 1000;
handles.default_params.interpolation_params.method = 'spherical';

% Set settings to default
handles.params = handles.default_params;

% Add project paths
% Checks 'pre_process_all' as an example of a file in /src. Could be any other file
% in /src
if( ~exist('pre_process_all', 'file')) 
    addpath('../src/');
end

% Load the state and then the current project
handles = load_state(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes main_gui wait for user response (see UIRESUME)
% uiwait(handles.main_gui);


% --- Outputs from this function are returned to the command line.
function varargout = main_gui_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Load the current state of the main gui from file and load the current
% project
function handles = load_state(handles)
% handles       main handles of this gui

if exist(handles.state_file.ADDRESS, 'file')
    load(handles.state_file.ADDRESS);
    if( isfield(state, 'version') && strcmp(state.version, handles.version))
        handles.project_list = state.project_list;
        handles.current_project = state.current_project;
    else % initialise everything if versioning doesn't correspond
        handles.project_list = containers.Map;
        handles.project_list(handles.new_project.LIST_NAME) = [];
        handles.project_list(handles.load_selected_project.LIST_NAME) = [];
        handles.current_project = 1;
    end
else % initialise everything if main state file does not exist
    handles.project_list = containers.Map;
    handles.project_list(handles.new_project.LIST_NAME) = [];
    handles.project_list(handles.load_selected_project.LIST_NAME) = [];
    handles.current_project = 1;
end

% For each existing project, update them from their state file.
% (Synchronisation)
k = handles.project_list.keys;
v = handles.project_list.values;
for i = 1:handles.project_list.Count
    if( ~ strcmp(k(i), handles.new_project.LIST_NAME) && ...
            ~ strcmp(k(i), handles.load_selected_project.LIST_NAME) )
        name = k{i};
        old_project = v{i};
        if( exist(old_project.getState_address, 'file') )
            load(old_project.getState_address);
            handles.project_list(name) = self;
        end
    end
end

set(handles.existingpopupmenu,...
    'String',handles.project_list.keys, ...
    'Value', handles.current_project);

% Update and load project
handles = update_and_load(handles);


% --- First update if any change has happenend since last time and then
% load the project to the gui
function handles = update_and_load(handles)
% handles       main handles of this gui

% Update the project
handles = update_selected_project(handles);

% Load the project
handles = load_selected_project(handles);


% --- Check if data structures are changed since last time and updates the
% structure accordingly
function handles = update_selected_project(handles)
% handles           main handle of this gui

% Find the selected project
idx = get(handles.existingpopupmenu, 'Value');
names = handles.project_list.keys;
name = names{idx};

% First update the project from the file (Synchronization with other users)
% (This is redundant if the gui is just started.)
project = handles.project_list(name);
if isempty(project) || ~ exist(project.getState_address, 'file')
    return;
else
    load(project.getState_address);
    handles.project_list(name) = self;
    project = self;
end

% Then update the rating structure of the project
if( exist( project.getResult_folder, 'dir'))
    if(project.folders_are_changed())
        
        % Change the cursor to a watch while updating...
        set(handles.main_gui, 'pointer', 'watch')
        drawnow;
        
        % Update the structure and save results in file
        project.update_rating_structures();
        project.save_project();
        
        % Change back the cursor to an arrow
        set(handles.main_gui, 'pointer', 'arrow')
    end
else
    waitfor(msgbox('The project folder does not exists or is not reachable.'...
        , 'Error', 'error'));
end

% --- Loads the current project selected by gui and set the gui accordingly
function handles = load_selected_project(handles)
% handles           main handles of this gui

% Find the selected project
Index = get(handles.existingpopupmenu, 'Value');
names = handles.project_list.keys;
name = names{Index};

% Special case of New Project
if(strcmp(name, handles.new_project.LIST_NAME))
    set(handles.projectname, 'String', handles.new_project.NAME);
    set(handles.datafoldershow, 'String', handles.new_project.DATA_FOLDER);
    set(handles.projectfoldershow, 'String', handles.new_project.FOLDER);
    
    set(handles.highpasscheckbox, 'Value', 1);
    set(handles.highfreqedit, 'String', handles.default_params.filter_params.high_freq)
    set(handles.highfreqedit, 'enable', 'on');
    
    set(handles.lowfreqedit, 'enable', 'off');
    set(handles.lowpasscheckbox, 'Value', 0);
    set(handles.lowfreqedit, 'String', handles.NONE)
    
    set(handles.subjectnumber, 'String', '')
    set(handles.filenumber, 'String', '')
    set(handles.preprocessednumber, 'String', '')
    set(handles.fpreprocessednumber, 'String', '')
    set(handles.ratednumber, 'String', '')
    set(handles.interpolatenumber, 'String', '')
    handles.current_project = Index;
    handles.params = handles.default_params;
    % Enable modifications
    switch_gui('on', 'off', handles);
    return;
end

% Special case of Load Project
if(strcmp(name, handles.load_selected_project.LIST_NAME))
    [name, project_path, ~] = uigetfile('load');
    
    % If user cancelled the process, choose the previous project
    if( name == 0 )
        set(handles.existingpopupmenu,...
            'String',handles.project_list.keys,...
            'Value', handles.current_project);
        load_selected_project(handles);
        return;
    end
    
    data_path = uigetdir('', 'Please choose the folder where the raw data is...');
    
    % If user cancelled the process, choose the previous project
    if( data_path == 0 )
        set(handles.existingpopupmenu,...
            'String',handles.project_list.keys,...
            'Value', handles.current_project);
        load_selected_project(handles);
        return;
    end
    
    load(strcat(project_path, name));
    if(exist('self', 'var') && isdir(data_path))
        name = self.name;
        
        if( ~ isKey(handles.project_list, name))
            % After load addresses must be updated as this system may have
            % a diferent adsresses than the system where project has been
            % created.
            self.update_addresses_form_state_file(project_path, data_path);
            handles.project_list(name) = self;
        else
            waitfor(msgbox(['This project already exists. You can not ',...
                'reload it unless it is deleted.'], 'Error','error'));
        end
        
        % Set the gui to this project and load this project
        IndexC = strcmp(handles.project_list.keys, name);
        Index = find(IndexC == 1);
        set(handles.existingpopupmenu,...
            'String',handles.project_list.keys,...
            'Value', Index);
    else
        % The selected state file is not a correct state file. So
        % load the previously loaded project.
        set(handles.existingpopupmenu,...
            'String',handles.project_list.keys,...
            'Value', handles.current_project);
        load_selected_project(handles);
        return;
    end
end

% Load the project:
project = handles.project_list(name);
% Set the current_project to the selected project
handles.current_project = Index;
if ~ exist(project.getState_address, 'file')
    if(  ~ exist(project.getResult_folder, 'dir') )
        % This can happen when data is on a server and connecton is lost
        waitfor(msgbox('The project folder is unreachable or deleted.',...
            'Error','error'));
        
        set(handles.projectname, 'String', name);
        set(handles.datafoldershow, 'String', '');
        set(handles.projectfoldershow, 'String', '');
        set(handles.subjectnumber, 'String', '')
        set(handles.filenumber, 'String', '')
        set(handles.preprocessednumber, 'String', '')
        set(handles.fpreprocessednumber, 'String', '')
        set(handles.ratednumber, 'String', '')
        set(handles.interpolatenumber, 'String', '')
        set(handles.highfreqedit, 'String', '')
        % Disable modifications from gui
        switch_gui('off', 'on', handles);
        return;
    else
        % If the state of is deleted, remove this project
        waitfor(msgbox(['The state file does not exist anymore.',...
            'You must create a new project.'], 'Error','error'));
        remove(handles.project_list, name);
        handles.current_project = 1;
        set(handles.existingpopupmenu,...
            'String',handles.project_list.keys,...
            'Value', handles.current_project);
        update_and_load(handles);
        save_state(handles);
        return;
    end
end
% Disable modifications from gui
switch_gui('off', 'on', handles);

% Set properties of the project:
set(handles.projectname, 'String', name);
set(handles.datafoldershow, 'String', project.getData_folder);
set(handles.projectfoldershow, 'String', project.getResult_folder);
set(handles.subjectnumber, 'String', [num2str(project.subject_count) ' subjects...'])
set(handles.filenumber, 'String', [num2str(project.file_count) ' files...'])
set(handles.preprocessednumber, 'String', ...
    [num2str(project.processed_subjects), ' subjects already done'])
set(handles.fpreprocessednumber, 'String', ...
    [num2str(project.processed_files), ' files already done'])

if(project.params.filter_params.high_freq ~= -1)
    set(handles.highfreqedit, 'String', num2str(project.params.filter_params.high_freq));
    set(handles.highpasscheckbox, 'Value', 1);
else
    set(handles.highfreqedit, 'String', handles.NONE);
    set(handles.highpasscheckbox, 'Value', 0);
end

if(project.params.filter_params.low_freq ~= -1)
    set(handles.lowfreqedit, 'String', num2str(project.params.filter_params.low_freq));
    set(handles.lowpasscheckbox, 'Value', 1);
else
    set(handles.lowfreqedit, 'String', handles.NONE);
    set(handles.lowpasscheckbox, 'Value', 0);
end
% Set the file extension
IndexC = strfind(handles.fileextension.String, project.file_extension);
index = find(not(cellfun('isempty', IndexC)));
set(handles.fileextension, 'Value', index);

% Set the downsampling rate
IndexC = strfind(handles.dsrate.String, int2str(handles.dsrate.Value));
index = find(not(cellfun('isempty', IndexC)));
set(handles.dsrate, 'Value', index);


% Set number of rated files
rated_count = project.get_rated_numbers();
set(handles.ratednumber, 'String', ...
    [num2str(rated_count), ' files already rated'])

% Set number of files to be interpolated
interpolate_count = project.to_be_interpolated_count();
set(handles.interpolatenumber, 'String', ...
    [num2str(interpolate_count), ' subjects to interpolate'])

save_state(handles);

% --- Enable or Disable the modifiable gui elements
function switch_gui(mode, visibility ,handles)
% handles    main handles of the gui
% mode       string that can be either 'off' (to disable) or 'on' (to enable)
% visibility the visibility of the delete button. It can be wither 'on' or
% 'off'. This is seperated as for different cases different functionality
% is needed.
set(handles.projectname, 'enable', mode);
set(handles.datafoldershow, 'enable', mode);
set(handles.projectfoldershow, 'enable', mode);
set(handles.fileextension, 'enable', mode);
set(handles.dsrate, 'enable', mode);
set(handles.choosedata, 'enable', mode);
set(handles.chooseproject, 'enable', mode);
set(handles.filteringbuttongroup.Children(1), 'enable', mode);
set(handles.filteringbuttongroup.Children(2), 'enable', mode);
set(handles.highpasscheckbox, 'enable', mode);
set(handles.lowpasscheckbox, 'enable', mode);
set(handles.configbutton, 'enable', mode)
set(handles.createbutton, 'visible', mode)
set(handles.deleteprojectbutton, 'visible', visibility)

if( strcmp(mode, 'off'))
    set(handles.highfreqedit, 'enable', mode);
    set(handles.lowfreqedit, 'enable', mode);
end

% --- Save the gui state
function save_state(handles)
% handles       main handles of this gui

if(isa(handles, 'struct'))
    state.project_list = handles.project_list;
    state.current_project = handles.current_project;
    state.version = handles.version;
    
    if(~ exist(handles.state_file.FOLDER, 'dir'))
        mkdir(handles.state_file.FOLDER);
    end
    save(handles.state_file.ADDRESS, 'state');
end


% --- Count the number of subjects and files in the folder given by
% argument
function [subject_count, file_count] = get_subject_and_file_numbers( ...
    handles, folder, ext)
% handles   the main handles of this gui
% folder    the folder to look into
% ext       determines the extension of files

% Change the cursor to a watch while updating...
set(handles.main_gui, 'pointer', 'watch')
drawnow;

if(ismac)
    slash = '/';
elseif(ispc)
    slash = '\';
end

subjects = list_subjects(folder);
subject_count = length(subjects);
file_count = 0;
for i = 1:subject_count
    subject = subjects{i};
    raw_files = dir([folder subject slash '*' ext]);
    file_count = file_count + length(raw_files);
end

% Change the cursor to normal
set(handles.main_gui, 'pointer', 'arrow')

% --- return the list of subjects in the folder
function subjects = list_subjects(root_folder)
% root_folder       the folder in which subjects are looked for
subs = dir(root_folder);
isub = [subs(:).isdir];
subjects = {subs(isub).name}';
subjects(ismember(subjects,{'.','..'})) = [];


% --- Get the file extension from the gui and calculate number of files and
% subjects in the datafolder with this extension and set the gui
function fileextension_Callback(hObject, eventdata, handles)
% hObject    handle to fileextension (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns fileextension contents as cell array
%        contents{get(hObject,'Value')} returns selected item from fileextension
if( strcmp(get(handles.datafoldershow, 'String'), handles.new_project.DATA_FOLDER))
    return
end

folder = get(handles.datafoldershow, 'String');
idx = get(handles.fileextension, 'Value');
exts = get(handles.fileextension, 'String');
ext = exts{idx};
[subject_count, file_count] = ...
    get_subject_and_file_numbers(handles, folder, ext);

set(handles.subjectnumber, 'String', ...
    [num2str(subject_count) ' subjects...'])
set(handles.filenumber, 'String', [num2str(file_count) ' files...'])

% Update handles structure
guidata(hObject, handles);


% --- Get the adress of the data folder from the gui, suggest a default
% project folder and set both to on the gui. Set the number of existing
% subjects and files as well
function choosedata_Callback(hObject, eventdata, handles)
% hObject    handle to choosedata (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
folder = uigetdir();
if(folder ~= 0)
    if(ismac)
        slash = '/';
    elseif(ispc)
        slash = '\';
    end
    folder = strcat(folder,slash);
    set(handles.datafoldershow, 'String', folder)
    
    split = strsplit(folder, slash);
    parent_folder = split(1:end - 2);
    data_folder = split{end - 1};
    parent_folder = strjoin(parent_folder, slash);
    project_folder = strcat(parent_folder, slash ,data_folder ,'_results', slash);
    set(handles.projectfoldershow, 'String', project_folder)
    
    idx = get(handles.fileextension, 'Value');
    exts = get(handles.fileextension, 'String');
    ext = exts{idx};
    [subject_count, file_count] = ...
        get_subject_and_file_numbers(handles, folder, ext);
    
    set(handles.subjectnumber, 'String', ...
        [num2str(subject_count) ' subjects...'])
    set(handles.filenumber, 'String', [num2str(file_count) ' files...'])
end


% Update handles structure
guidata(hObject, handles);


% --- Get the adress of project folder and set the gui
function chooseproject_Callback(hObject, eventdata, handles)
% hObject    handle to chooseproject (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
folder = uigetdir();
if(folder ~= 0)
    if(ismac)
        folder = strcat(folder,'/');
    elseif(ispc)
        folder = strcat(folder,'\');
    end
    set(handles.projectfoldershow, 'String', folder)
end
% Update handles structure
guidata(hObject, handles);

% --- Start the rating gui on the current project
function manualratingbutton_Callback(hObject, eventdata, handles)
% hObject    handle to manualratingbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
idx = get(handles.existingpopupmenu, 'Value');
projects = get(handles.existingpopupmenu, 'String');
name = projects{idx};
project = handles.project_list(name);

rating_gui(project);

% --- Start interpolation on selected files
function interpolatebutton_Callback(hObject, eventdata, handles)
% hObject    handle to interpolatebutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
idx = get(handles.existingpopupmenu, 'Value');
projects = get(handles.existingpopupmenu, 'String');
name = projects{idx};
project = handles.project_list(name);

interpolate_selected(project);


% --- Run preprocessing on all subjects
function runpreprocessbutton_Callback(hObject, eventdata, handles)
% hObject    handle to runpreprocessbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
idx = get(handles.existingpopupmenu, 'Value');
projects = get(handles.existingpopupmenu, 'String');
name = projects{idx};
project = handles.project_list(name);

pre_process_all(project);


% --- Load the selected project by gui
function existingpopupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to existingpopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns existingpopupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from existingpopupmenu
handles = update_and_load(handles);
% Update handles structure
guidata(hObject, handles);

% --- Get the selected info and create a new project with them
function createbutton_Callback(hObject, eventdata, handles)
% hObject    handle to createbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

name = get(handles.projectname, 'String');
project_folder = get(handles.projectfoldershow, 'String');
data_folder = get(handles.datafoldershow, 'String');

% Data folder and project folder must be at least modified !
if( strcmp(data_folder, handles.new_project.DATA_FOLDER) || ...
        strcmp(project_folder, handles.new_project.FOLDER) || ...
        strcmp(name, handles.new_project.NAME))
    waitfor(msgbox('You must choose a name, project folder and data folder.',...
        'Error','error'));
    return;
end

% Get the file extension
idx = get(handles.fileextension, 'Value');
exts = get(handles.fileextension, 'String');
ext = exts{idx};

% Get the downsampling rate
idx = get(handles.dsrate, 'Value');
dsrates = get(handles.dsrate, 'String');
ds = str2double(dsrates{idx});

% Get filter_params params
filter_params = handles.params.filter_params;
filter_params.filter_mode = upper(handles.filteringbuttongroup.SelectedObject.String(1:2));
if ( get(handles.highpasscheckbox, 'Value') == 1)
    high_freq = str2double(get(handles.highfreqedit, 'String'));
    if( ~isempty(high_freq) && ~isnan(high_freq))
        filter_params.high_freq = high_freq;
    end
else
    filter_params.high_freq = -1;
    filter_params.high_order = -1;
end
if( get(handles.lowpasscheckbox, 'Value') == 1)
    low_freq = str2double(get(handles.lowfreqedit, 'String'));
    if( ~isempty(low_freq) && ~isnan(low_freq) )
        filter_params.low_freq = low_freq;
    end
else
    filter_params.low_freq = -1;
    filter_params.low_order = -1;
end

handles.params.filter_params = filter_params;
params = handles.params;
% Change the cursor to a watch while updating...
set(handles.main_gui, 'pointer', 'watch')
drawnow;

choice = 'Over Write';
if( exist(Project.make_state_address(project_folder), 'file'))
    choice = questdlg(['Another project in this folder already ',...
        'exist. Do you want to load it or overwrite it ?'], ...
        'Pre-existing project in the project folder.',...
        'Over Write', 'Load','Over Write');
end

switch choice
    case 'Load'
        load(Project.make_state_address(project_folder));
        project = self;
        project.update_addresses_form_state_file(project_folder, self.data_folder);
    case 'Over Write'
        if( exist(Project.make_state_address(project_folder), 'file'))
            load(Project.make_state_address(project_folder));
            if( isKey(handles.project_list, self.name))
                project = handles.project_list(self.name);
                delete(project.getState_address);
                remove(handles.project_list, self.name);
            else
                delete(Project.make_state_address(project_folder));
            end
        end
        project = Project(name, data_folder, project_folder, ext, ds, params);
end
name = project.name; % Overwrite the name in case the project is loaded.

% Change back the cursor to an arrow
set(handles.main_gui, 'pointer', 'arrow')

% Set the gui to this project and load this project
handles.project_list(name) = project;
IndexC = strcmp(handles.project_list.keys, name);
Index = find(IndexC == 1);
handles.current_project = Index;
set(handles.existingpopupmenu,...
    'String',handles.project_list.keys,...
    'Value', handles.current_project);

switch choice
    case 'Load'
        handles = update_and_load(handles);
    case 'Over Write'
        handles = load_selected_project(handles);
end

save_state(handles);
waitfor(msgbox({'The project is successfully created.' ...
    'Now you can start pre-processing.'}));
% Update handles structure
guidata(hObject, handles);


% --- Save the main gui's state and close the gui
function main_gui_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to main_gui (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
save_state(handles);
% Hint: delete(hObject) closes the figure
delete(hObject);


% --- Delete the selected project by gui
function deleteprojectbutton_Callback(hObject, eventdata, handles)
% hObject    handle to deleteprojectbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

choice = questdlg(['Are you really sure to delete this project? The ',...
    'project will be deleted for all other users. NOTE: The ',...
    'data files and result files will not be deleted.'], ...
    'Take responsibility!',...
    'Cancel', 'Delete','Cancel');

switch choice
    case 'Cancel'
        % Do nothing
    case 'Delete'
        name = get(handles.projectname, 'String');
        project = handles.project_list(name);
        delete(project.getState_address);
        
        remove(handles.project_list, name);
        handles.current_project = 1;
        set(handles.existingpopupmenu,...
            'String',handles.project_list.keys, ...
            'Value', handles.current_project);
        handles = update_and_load(handles);
        save_state(handles);
end


% Update handles structure
guidata(hObject, handles);

% --- Get the filter_params mode (US or EU) and save it to the project state
function filter_paramsbuttongroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in filter_paramsbuttongroup
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
name = get(handles.projectname, 'String');
if( isKey(handles.project_list, name))
    project = handles.project_list(name);
    if (exist(project.getState_address, 'file'))
        project.params.filter_params.filter_mode = handles.filteringbuttongroup.SelectedObject.String;
    end
end

% --- Executes on button press in lowpasscheckbox.
function lowpasscheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to lowpasscheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if (get(hObject,'Value') == get(hObject,'Max'))
	set(handles.lowfreqedit, 'enable', 'on');
    set(handles.lowfreqedit, 'String', handles.default_params.filter_params.low_freq)
else
	set(handles.lowfreqedit, 'enable', 'off');
    set(handles.lowfreqedit, 'String', handles.NONE)
end



% --- Executes on button press in highpasscheckbox.
function highpasscheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to highpasscheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if (get(hObject,'Value') == get(hObject,'Max'))
	set(handles.highfreqedit, 'enable', 'on');
    set(handles.highfreqedit, 'String', handles.default_params.filter_params.high_freq)
else
	set(handles.highfreqedit, 'enable', 'off');
    set(handles.highfreqedit, 'String', handles.NONE)
end


% --- Executes on button press in configbutton.
function configbutton_Callback(hObject, eventdata, handles)
% hObject    handle to configbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

h = settings(handles.params, handles.default_params);
switch_gui('off', 'off', handles);
set(handles.runpreprocessbutton, 'enable', 'off');
set(handles.manualratingbutton, 'enable', 'off');
set(handles.interpolatebutton, 'enable', 'off');
set(handles.existingpopupmenu, 'enable', 'off');
waitfor(h);
h = findobj(allchild(0), 'flat', 'Tag', 'main_gui');
handles = guidata(h);
switch_gui('on', 'on', handles);
set(handles.runpreprocessbutton, 'enable', 'on');
set(handles.manualratingbutton, 'enable', 'on');
set(handles.interpolatebutton, 'enable', 'on');
set(handles.existingpopupmenu, 'enable', 'on');


function projectname_Callback(hObject, eventdata, handles)
% hObject    handle to projectname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of projectname as text
%        str2double(get(hObject,'String')) returns contents of projectname as a double


% --- Executes during object creation, after setting all properties.
function projectname_CreateFcn(hObject, eventdata, handles)
% hObject    handle to projectname (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function fileextension_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fileextension (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in dsrate.
function dsrate_Callback(hObject, eventdata, handles)
% hObject    handle to dsrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns dsrate contents as cell array
%        contents{get(hObject,'Value')} returns selected item from dsrate


% --- Executes during object creation, after setting all properties.
function dsrate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dsrate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function datafoldershow_Callback(hObject, eventdata, handles)
% hObject    handle to datafoldershow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of datafoldershow as text
%        str2double(get(hObject,'String')) returns contents of datafoldershow as a double


% --- Executes during object creation, after setting all properties.
function datafoldershow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to datafoldershow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function projectfoldershow_Callback(hObject, eventdata, handles)
% hObject    handle to projectfoldershow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of projectfoldershow as text
%        str2double(get(hObject,'String')) returns contents of projectfoldershow as a double


% --- Executes during object creation, after setting all properties.
function projectfoldershow_CreateFcn(hObject, eventdata, handles)
% hObject    handle to projectfoldershow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function existingpopupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to existingpopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function highfreqedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to highfreqedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function highfreqedit_Callback(hObject, eventdata, handles)
% hObject    handle to projectfoldershow (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of projectfoldershow as text
%        str2double(get(hObject,'String')) returns contents of projectfoldershow as a double



function lowfreqedit_Callback(hObject, eventdata, handles)
% hObject    handle to lowfreqedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lowfreqedit as text
%        str2double(get(hObject,'String')) returns contents of lowfreqedit as a double


% --- Executes during object creation, after setting all properties.
function lowfreqedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lowfreqedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
