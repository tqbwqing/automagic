function varargout = settings(varargin)
% SETTINGS MATLAB code for settings.fig
%      SETTINGS, by itself, creates a new SETTINGS or raises the existing
%      singleton*.
%
%      H = SETTINGS returns the handle to a new SETTINGS or the handle to
%      the existing singleton*.
%
%      SETTINGS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SETTINGS.M with the given input arguments.
%
%      SETTINGS('Property','Value',...) creates a new SETTINGS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before settings_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to settings_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help settings

% Last Modified by GUIDE v2.5 16-Nov-2016 14:31:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @settings_OpeningFcn, ...
                   'gui_OutputFcn',  @settings_OutputFcn, ...
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


% --- Executes just before settings is made visible.
function settings_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to settings (see VARARGIN)

if( nargin - 3 ~= 2 )
    error('wrong number of arguments. Project must be given as argument.')
end

set(handles.settingsfigure, 'units', 'normalized')
children = handles.settingsfigure.Children;
for child_idx = 1:length(children)
    child = children(child_idx);
    set(child, 'units', 'normalized')
    for grandchild_idx = 1:length(child.Children)
       grandchild = child.Children(grandchild_idx);
       set(grandchild, 'units', 'normalized')
    end
end

params = varargin{1};
default_params = varargin{2};
assert(isa(params, 'struct'));
assert(isa(default_params, 'struct'));
handles.params = params;
handles.default_params = default_params;

set(handles.channelreductioncheckbox, 'Value', params.perform_reduce_channels);
set(handles.highpasspopupmenu, 'Value', params.filter_params.high_order);
set(handles.lowpasspopupmenu, 'Value', params.filter_params.low_order);

if( params.channel_rejection_params.kurt_thresh ~= -1)
    set(handles.kurtcheckbox, 'Value', 1);
    set(handles.kurtthreshedit, 'String', params.channel_rejection_params.kurt_thresh);
else
    set(handles.kurtcheckbox, 'Value', 0);
    set(handles.kurtthreshedit, 'String', default_params.channel_rejection_params.kurt_thresh);
end

if( params.channel_rejection_params.spec_thresh ~= -1)
    set(handles.speccheckbox, 'Value', 1);
    set(handles.specthreshedit, 'String', params.channel_rejection_params.spec_thresh);
    
else
    set(handles.speccheckbox, 'Value', 0);
    set(handles.specthreshedit, 'String', default_params.channel_rejection_params.spec_thresh);
end

if( params.channel_rejection_params.prob_thresh ~= -1)
    set(handles.probcheckbox, 'Value', 1);
    set(handles.probthreshedit, 'String', params.channel_rejection_params.prob_thresh);
else
    set(handles.probcheckbox, 'Value', 0);
    set(handles.probthreshedit, 'String', default_params.channel_rejection_params.prob_thresh);
end

set(handles.eogregressioncheckbox, 'Value', params.perform_eog_regression);

if( params.pca_params.lambda ~= -1)
    set(handles.pcacheckbox, 'Value', 1);
    set(handles.lambdaedit, 'String', params.pca_params.lambda);
    set(handles.toledit, 'String', params.pca_params.tol);
    set(handles.maxIteredit, 'String', params.pca_params.maxIter);
else
    set(handles.pcacheckbox, 'Value', 0);
    set(handles.lambdaedit, 'String', default_params.pca_params.lambda);
    set(handles.toledit, 'String', default_params.pca_params.tol);
    set(handles.maxIteredit, 'String', default_params.pca_params.maxIter);
end

IndexC = strcmp(handles.interpolationpopupmenu.String, params.interpolation_params.method);
Index = find(IndexC == 1);
set(handles.interpolationpopupmenu,...
    'String',handles.interpolationpopupmenu.String,...
    'Value', Index);
        
handles = switch_components(handles);


% Choose default command line output for settings
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes settings wait for user response (see UIRESUME)
% uiwait(handles.settingsfigure);


% --- Outputs from this function are returned to the command line.
function varargout = settings_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in channelreductioncheckbox.
function channelreductioncheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to channelreductioncheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of channelreductioncheckbox


% --- Executes on button press in kurtcheckbox.
function kurtcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to kurtcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = switch_components(handles);
% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of kurtcheckbox


% --- Executes on selection change in highpasspopupmenu.
function highpasspopupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to highpasspopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns highpasspopupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from highpasspopupmenu


% --- Executes during object creation, after setting all properties.
function highpasspopupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to highpasspopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in lowpasspopupmenu.
function lowpasspopupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to lowpasspopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lowpasspopupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lowpasspopupmenu


% --- Executes during object creation, after setting all properties.
function lowpasspopupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lowpasspopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in probcheckbox.
function probcheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to probcheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = switch_components(handles);
% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of probcheckbox


% --- Executes on button press in speccheckbox.
function speccheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to speccheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles = switch_components(handles);
% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of speccheckbox



function kurtthreshedit_Callback(hObject, eventdata, handles)
% hObject    handle to kurtthreshedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of kurtthreshedit as text
%        str2double(get(hObject,'String')) returns contents of kurtthreshedit as a double


% --- Executes during object creation, after setting all properties.
function kurtthreshedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to kurtthreshedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function probthreshedit_Callback(hObject, eventdata, handles)
% hObject    handle to probthreshedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of probthreshedit as text
%        str2double(get(hObject,'String')) returns contents of probthreshedit as a double


% --- Executes during object creation, after setting all properties.
function probthreshedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to probthreshedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function specthreshedit_Callback(hObject, eventdata, handles)
% hObject    handle to specthreshedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of specthreshedit as text
%        str2double(get(hObject,'String')) returns contents of specthreshedit as a double


% --- Executes during object creation, after setting all properties.
function specthreshedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to specthreshedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in eogregressioncheckbox.
function eogregressioncheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to eogregressioncheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of eogregressioncheckbox


% --- Executes on button press in pcacheckbox.
function pcacheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to pcacheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = switch_components(handles);
% Update handles structure
guidata(hObject, handles);
% Hint: get(hObject,'Value') returns toggle state of pcacheckbox



function lambdaedit_Callback(hObject, eventdata, handles)
% hObject    handle to lambdaedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of lambdaedit as text
%        str2double(get(hObject,'String')) returns contents of lambdaedit as a double


% --- Executes during object creation, after setting all properties.
function lambdaedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lambdaedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function toledit_Callback(hObject, eventdata, handles)
% hObject    handle to toledit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of toledit as text
%        str2double(get(hObject,'String')) returns contents of toledit as a double


% --- Executes during object creation, after setting all properties.
function toledit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to toledit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function maxIteredit_Callback(hObject, eventdata, handles)
% hObject    handle to maxIteredit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxIteredit as text
%        str2double(get(hObject,'String')) returns contents of maxIteredit as a double


% --- Executes during object creation, after setting all properties.
function maxIteredit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxIteredit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in interpolationpopupmenu.
function interpolationpopupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to interpolationpopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns interpolationpopupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from interpolationpopupmenu


% --- Executes during object creation, after setting all properties.
function interpolationpopupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to interpolationpopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in okpushbutton.
function okpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to okpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles = get_inputs(handles);
% Update handles structure
guidata(hObject, handles);

close('settings');

function handles = get_inputs(handles)

h = findobj(allchild(0), 'flat', 'Tag', 'main_gui');
main_gui_handle = guidata(h);
default_params = handles.default_params;

perform_reduce_channels = ...
    get(handles.channelreductioncheckbox, 'Value');

perform_eog_regression = ...
    get(handles.eogregressioncheckbox, 'Value');

high_order = 3;
if( get(main_gui_handle.highpasscheckbox, 'Value') )
    idx = get(handles.highpasspopupmenu, 'Value');
    orders = get(handles.highpasspopupmenu, 'String');
    high_order = str2double(orders{idx});
end
if( isempty(high_order) || isnan(high_order))
    high_order = default_params.filter_params.high_order;
end

low_order = 3;
if( get(main_gui_handle.lowpasscheckbox, 'Value') )
    idx = get(handles.lowpasspopupmenu, 'Value');
    orders = get(handles.lowpasspopupmenu, 'String');
    low_order = str2double(orders{idx});
end
if( isempty(low_order) || isnan(low_order))
    low_order = default_params.filter_params.low_order;
end

if( get(handles.kurtcheckbox, 'Value') )
    kurt_val = str2double(get(handles.kurtthreshedit, 'String'));
else
    kurt_val = -1;
end
if( isempty(kurt_val) || isnan(kurt_val))
   kurt_val = default_params.channel_rejection_params.kurt_thresh; 
end

if( get(handles.speccheckbox, 'Value') )
    spec_val = str2double(get(handles.specthreshedit, 'String'));
else
    spec_val = -1;
end
if( isempty(spec_val) || isnan(spec_val))
   spec_val = default_params.channel_rejection_params.spec_thresh; 
end


if( get(handles.probcheckbox, 'Value') )
    prob_val = str2double(get(handles.probthreshedit, 'String'));
else
    prob_val = -1;
end
if( isempty(prob_val) || isnan(prob_val))
   prob_val = default_params.channel_rejection_params.prob_thresh; 
end


if( get(handles.pcacheckbox, 'Value') )
    lambda = str2double(get(handles.lambdaedit, 'String'));
    tol = str2double(get(handles.toledit, 'String'));
    maxIter = str2double(get(handles.maxIteredit, 'String'));
    if( isempty(lambda) )
        lambda = 'Default';
    end
else
    lambda = -1;
    tol = -1;
    maxIter = -1;
end

if( isempty(lambda) || isnan(lambda))
    lambda = default_params.pca_params.lambda;
end

if(isempty(tol) || isnan(tol))
    tol = default_params.pca_params.tol;
end

if( isempty(maxIter) || isnan(maxIter)) 
    maxIter = default_params.pca_params.maxIter;
end


idx = get(handles.interpolationpopupmenu, 'Value');
methods = get(handles.interpolationpopupmenu, 'String');
method = methods{idx};

handles.params.perform_reduce_channels = perform_reduce_channels;
handles.params.perform_eog_regression = perform_eog_regression;
handles.params.filter_params.high_order = high_order;
handles.params.filter_params.low_order = low_order;
handles.params.channel_rejection_params.kurt_thresh = kurt_val;
handles.params.channel_rejection_params.spec_thresh = spec_val;
handles.params.channel_rejection_params.prob_thresh = prob_val;
handles.params.pca_params.lambda = lambda;
handles.params.pca_params.tol = tol;
handles.params.pca_params.maxIter = maxIter;
handles.params.interpolation_params.method = method;

% --- Executes on button press in defaultpushbutton.
function defaultpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to defaultpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
default_params = handles.default_params;

set(handles.channelreductioncheckbox, 'Value', ...
    default_params.perform_reduce_channels);

set(handles.highpasspopupmenu, 'Value', ...
    default_params.filter_params.high_order);
set(handles.lowpasspopupmenu, 'Value', ...
    default_params.filter_params.low_order);

if( default_params.channel_rejection_params.kurt_thresh ~= -1)
    set(handles.kurtcheckbox, 'Value', 1);
    set(handles.kurtthreshedit, 'String', ...
        default_params.channel_rejection_params.kurt_thresh);
else
    set(handles.kurtcheckbox, 'Value', 0);
    set(handles.kurtthreshedit, 'String', '');
end

if( default_params.channel_rejection_params.spec_thresh ~= -1)
    set(handles.speccheckbox, 'Value', 1);
    set(handles.specthreshedit, 'String', ...
        default_params.channel_rejection_params.spec_thresh);
else
    set(handles.speccheckbox, 'Value', 0);
    set(handles.specthreshedit, 'String', '');
end
if( default_params.channel_rejection_params.prob_thresh ~= -1)
    set(handles.probcheckbox, 'Value', 1);
    set(handles.probthreshedit, 'String', ...
        default_params.channel_rejection_params.prob_thresh);
else
    set(handles.probcheckbox, 'Value', 0);
    set(handles.probthreshedit, 'String', '');
end

set(handles.eogregressioncheckbox, 'Value', ...
    default_params.perform_eog_regression);
if( default_params.pca_params.lambda ~= -1)
    set(handles.pcacheckbox, 'Value', 1);
    set(handles.lambdaedit, 'String', ...
        default_params.pca_params.lambda);
    set(handles.toledit, 'String', ...
        default_params.pca_params.tol);
    set(handles.maxIteredit, 'String', ...
        default_params.pca_params.maxIter);
else
    set(handles.pcacheckbox, 'Value', 0);
    set(handles.lambdaedit, 'String', '');
    set(handles.toledit, 'String', '');
    set(handles.maxIteredit, 'String', '');
end

IndexC = strfind(handles.interpolationpopupmenu.String, ...
    default_params.interpolation_params.method);
index = find(not(cellfun('isempty', IndexC)));
set(handles.interpolationpopupmenu, 'Value', index);

handles = switch_components(handles);

% Update handles structure
guidata(hObject, handles);

function handles = switch_components(handles)

h = findobj(allchild(0), 'flat', 'Tag', 'main_gui');
main_gui_handle = guidata(h);
default_params = handles.default_params;

if( get(main_gui_handle.highpasscheckbox, 'Value') )
    set(handles.highpasspopupmenu, 'enable', 'on');
else
    set(handles.highpasspopupmenu, 'enable', 'off');
    set(handles.highpasspopupmenu, 'Value', ...
        default_params.filter_params.high_order);
end

if( get(main_gui_handle.lowpasscheckbox, 'Value') )
    set(handles.lowpasspopupmenu, 'enable', 'on');
else
    set(handles.lowpasspopupmenu, 'enable', 'off');
    set(handles.lowpasspopupmenu, 'Value', ...
        default_params.filter_params.low_order);
end

if( get(handles.kurtcheckbox, 'Value') )
    set(handles.kurtthreshedit, 'enable', 'on');
else
    set(handles.kurtthreshedit, 'enable', 'off');
    set(handles.kurtthreshedit, 'String', ...
        num2str(default_params.channel_rejection_params.kurt_thresh));
end

if( get(handles.speccheckbox, 'Value') )
    set(handles.specthreshedit, 'enable', 'on');
else
    set(handles.specthreshedit, 'enable', 'off');
    set(handles.specthreshedit, 'String', ...
        num2str(default_params.channel_rejection_params.spec_thresh));
end

if( get(handles.probcheckbox, 'Value') )
    set(handles.probthreshedit, 'enable', 'on');
else
    set(handles.probthreshedit, 'enable', 'off');
    set(handles.probthreshedit, 'String', ...
        num2str(default_params.channel_rejection_params.prob_thresh));
end

if( get(handles.pcacheckbox, 'Value') )
    set(handles.lambdaedit, 'enable', 'on');
    set(handles.toledit, 'enable', 'on');
    set(handles.maxIteredit, 'enable', 'on');
else
    set(handles.lambdaedit, 'enable', 'off');
    set(handles.toledit, 'enable', 'off');
    set(handles.maxIteredit, 'enable', 'off');
    set(handles.lambdaedit, 'String', ...
        num2str(default_params.pca_params.lambda));
    set(handles.toledit, 'String', ...
        num2str(default_params.pca_params.tol));
    set(handles.maxIteredit, 'String', ...
        num2str(default_params.pca_params.maxIter));
end

% --- Executes on button press in cancelpushbutton.
function cancelpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to cancelpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

close('settings')

% --- Executes when user attempts to close settingsfigure.
function settingsfigure_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to settingsfigure (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

h = findobj(allchild(0), 'flat', 'Tag', 'main_gui');
if( isempty(h))
    h = main_gui;
end
handle = guidata(h);
handle.params = handles.params;
guidata(handle.main_gui, handle);

delete(hObject);
