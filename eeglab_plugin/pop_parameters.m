function [EEG, com] = pop_parameters(EEG)
% Pops-up a window that takes required parameters and then runs pre_process()
% function. 
%
% Usage:
%   >> EEG = pop_parameters ( EEG ); % pop up window
%
% Inputs:
%   EEG     - EEGLab EEG structure.
%
% Outputs:
%   EEG     -  EEGLab EEG structure where the data is preprocessed with 
%   given arguments from the pop-up window. A new field
%   EEG.automagic will contain information about parameters used
%   and the channels that have been interpolated during the
%   automatic detection of bad channels.
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

com = ''; 

% display help if not enough arguments
% ------------------------------------
if nargin < 1
	help pop_parameters;
	return;
end;	



%--------------------------Set default parameters
%-----------------------------------------------------------
default_params.Default = 'Default';
default_params.filter_params.high_freq = 0.5;
default_params.filter_params.high_order = [];
default_params.filter_params.low_freq = -1;
default_params.filter_params.low_order = [];
default_params.perform_reduce_channels = 1;
default_params.channel_rejection_params.kurt_thresh = 3;
default_params.channel_rejection_params.prob_thresh = 4;
default_params.channel_rejection_params.spec_thresh = 4;
default_params.perform_eog_regression = 1;
default_params.pca_params.lambda = [];
default_params.pca_params.tol = 1e-7;
default_params.pca_params.maxIter = 1000;
default_params.ica_params.bool = 0;
default_params.interpolation_params.method = 'spherical';
default_params.eeg_system.name = 'EGI';
default_params.eeg_system.file_loc_type = '';
default_params.eeg_system.loc_file = '';
default_params.eeg_system.eog_chans = '';


%--------------------------Create Gui
%-----------------------------------------------------------
[uilist, positions, verpos] = getUIControls();
[~, ~, allhandlers] = ...
    supergui('geomhoriz', positions, 'geomvert', verpos,'uilist', uilist, ...
    'title', 'Preprocessing inputs');


%--------------------------Set call backs
%-----------------------------------------------------------
params = struct;
euradio = findHandlerFromList(allhandlers, 'notcheu');
usradio = findHandlerFromList(allhandlers, 'notchus');
lowcheck = findHandlerFromList(allhandlers, 'lowcheckin');
lowfreq = findHandlerFromList(allhandlers, 'lowfreqin');
loworder = findHandlerFromList(allhandlers, 'loworderin');
highcheck = findHandlerFromList(allhandlers, 'highcheckin');
highfreq = findHandlerFromList(allhandlers, 'highfreqin');
highorder = findHandlerFromList(allhandlers, 'highorderin');
kurtcheck = findHandlerFromList(allhandlers, 'kurtcheck');
kurtin = findHandlerFromList(allhandlers, 'kurtin');
probcheck = findHandlerFromList(allhandlers, 'probcheck');
probin = findHandlerFromList(allhandlers, 'probin');
speccheck = findHandlerFromList(allhandlers, 'speccheck');
specin = findHandlerFromList(allhandlers, 'specin');
icacheck = findHandlerFromList(allhandlers, 'icacheck');
pcacheck = findHandlerFromList(allhandlers, 'pcacheck');
lambdain = findHandlerFromList(allhandlers, 'lambdain');
tolin = findHandlerFromList(allhandlers, 'tolerancein');
maxiterin = findHandlerFromList(allhandlers, 'maxiterin');
ok = findHandlerFromList(allhandlers, 'ok');
interpol = findHandlerFromList(allhandlers, 'interpolpopup');
reduce_chans = findHandlerFromList(allhandlers, 'reducechancheck');
eog_chans = findHandlerFromList(allhandlers, 'eogchans');
eog_chans_check = findHandlerFromList(allhandlers, 'eogchanscheck');
default = findHandlerFromList(allhandlers, 'default_butt');

euradio.set('callback', @euradiocallback);
usradio.set('callback', @usradiocallback);
lowcheck.set('callback', @lowcheckcallback);
highcheck.set('callback', @highcheckcallback);
kurtcheck.set('callback', @kurtcheckcallback);
probcheck.set('callback', @probcheckcallback);
speccheck.set('callback', @speccheckcallback);
icacheck.set('callback', @icacheckcallback);
pcacheck.set('callback', @pcacheckcallback);
ok.set('callback', @okcallback);
default.set('callback', @defaultcallback);
    
% Notch Filter callback
% -------------------------------------------
function euradiocallback(PushButton, EventData)
    if(get(euradio, 'Value'))
        set(usradio, 'Value', 0);
    end
end

function usradiocallback(PushButton, EventData)
    if(get(usradio, 'Value'))
        set(euradio, 'Value', 0);
    end
end

% Low pass callback
% -------------------------------------------
function lowcheckcallback(PushButton, EventData)
    switch_components();
end

% High pass callback
% -------------------------------------------
function highcheckcallback(PushButton, EventData)
    switch_components();
end

% Channel Rejection criterias callback
% -------------------------------------------
function kurtcheckcallback(PushButton, EventData)
    switch_components();
end
function probcheckcallback(PushButton, EventData)
    switch_components();
end
function speccheckcallback(PushButton, EventData)
    switch_components();
end

% ICA and PCA callback
% -------------------------------------------
function icacheckcallback(PushButton, EventData)
    if(get(icacheck, 'Value'))
        set(pcacheck, 'value', 0)
        set(lambdain, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.Default)));
        set(tolin, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.pca_params.tol)));
        set(maxiterin, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.pca_params.maxIter)));
    end
end

function pcacheckcallback(PushButton, EventData)
    if( get(pcacheck, 'Value') )
        set(lambdain, 'enable', 'on');
        set(tolin, 'enable', 'on');
        set(maxiterin, 'enable', 'on');
        set(icacheck, 'value', 0)
    else
        set(lambdain, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.Default)));
        set(tolin, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.pca_params.tol)));
        set(maxiterin, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.pca_params.maxIter)));
    end
end

% OK button callback. It gathers input and start preprocessing
% -------------------------------------------
function okcallback(PushButton, EventData)
    perform_reduce_channels = ...
        get(reduce_chans, 'Value');

    ica_bool = get(icacheck, 'Value');

    high_order = [];
    if( get(highcheck, 'Value') )
        high_order = str2double(get(highorder, 'String'));
    end
    if(isnan(high_order) )
        high_order = default_params.filter_params.high_order;
    end


    low_order = [];
    if( get(lowcheck, 'Value') )
        low_order = str2double(get(loworder, 'String'));
    end
    if(isnan(low_order))
        low_order = default_params.filter_params.high_order;
    end

    if( get(kurtcheck, 'Value') )
        kurt_val = str2double(get(kurtin, 'String'));
    else
        kurt_val = -1;
    end
    if( isempty(kurt_val) || isnan(kurt_val))
       kurt_val = default_params.channel_rejection_params.kurt_thresh;
    end

    if( get(speccheck, 'Value') )
        spec_val = str2double(get(specin, 'String'));
    else
        spec_val = -1;
    end
    if( isempty(spec_val) || isnan(spec_val))
       spec_val = default_params.channel_rejection_params.spec_thresh; ;
    end


    if( get(probcheck, 'Value') )
        prob_val = str2double(get(probin, 'String'));
    else
        prob_val = -1;
    end
    if( isempty(prob_val) || isnan(prob_val))
       prob_val = default_params.channel_rejection_params.prob_thresh;
    end


    if( get(pcacheck, 'Value') )
        lambda = str2double(get(lambdain, 'String'));
        tol = str2double(get(tolin, 'String'));
        maxIter = str2double(get(maxiterin, 'String'));
        if(isnan(lambda) )
            lambda = default_params.pca_params.lambda; 
        end
    else
        lambda = -1;
        tol = -1;
        maxIter = -1;
    end

    if(isempty(tol) || isnan(tol))
        tol = default_params.pca_params.tol;
    end

    if( isempty(maxIter) || isnan(maxIter)) 
        maxIter = default_params.pca_params.maxIter;
    end


    idx = get(interpol, 'Value');
    methods = get(interpol, 'String');
    method = methods{idx};

    perform_eog_regression = get(eog_chans_check, 'Value');
    eog_channels = str2num(get(eog_chans, 'String'));
    if( perform_eog_regression && isempty(eog_channels))
        waitfor(msgbox(['A list of channel indices seperated by space or',...
            ' comma must be given to determine EOG channels'],...
            'Error','error'));
        return;
    end
    eeg_system.eog_chans = eog_channels;
    eeg_system.name = '';
    
    if(get(euradio, 'Value'))
        notch_filter = 'EU';
    elseif(get(usradio, 'Value'))
        notch_filter = 'US';
    else
        notch_filter = 'None';
    end
    params.eeg_system = eeg_system;
    params.perform_eog_regression = perform_eog_regression;
    params.perform_reduce_channels = perform_reduce_channels;
    params.filter_params.high_order = high_order;
    params.filter_params.low_order = low_order;
    params.filter_params.filter_mode = notch_filter;
    params.channel_rejection_params.kurt_thresh = kurt_val;
    params.channel_rejection_params.spec_thresh = spec_val;
    params.channel_rejection_params.prob_thresh = prob_val;
    params.pca_params.lambda = lambda;
    params.pca_params.tol = tol;
    params.pca_params.maxIter = maxIter;
    params.ica_params.bool = ica_bool;
    params.interpolation_params.method = method;
    close gcbf
end

% Default button callback. It sets all values of the gui to default
% -------------------------------------------
function defaultcallback(PushButton, EventData)
    
    % Filterings
    set(euradio, 'Value', 1);
    set(usradio, 'Value', 0);
   
    set(highcheck, 'Value', 1);
    set(lowcheck, 'Value', 0);
    set(highorder, 'String', ...
        format_default(default_params.Default));
    set(highfreq, 'String', ...
        format_default(default_params.filter_params.high_freq));

    % Channel rejection
    if( default_params.channel_rejection_params.kurt_thresh ~= -1)
        set(kurtcheck, 'Value', 1);       
    else
        set(kurtcheck, 'Value', 0);
    end
    set(kurtin, 'String', ...
            format_default(default_params.channel_rejection_params.kurt_thresh));

    if( default_params.channel_rejection_params.spec_thresh ~= -1)
        set(speccheck, 'Value', 1);
    else
        set(speccheck, 'Value', 0);
    end
    set(specin, 'String', ...
        format_default(default_params.channel_rejection_params.spec_thresh));

    if( default_params.channel_rejection_params.prob_thresh ~= -1)
        set(probcheck, 'Value', 1);
    else
        set(probcheck, 'Value', 0);
    end
    format_default(set(probin, 'String', ...
            default_params.channel_rejection_params.prob_thresh));

    % ICA
    set(icacheck, 'Value', default_params.ica_params.bool);
        
    % PCA
    if( isempty(default_params.pca_params.lambda) || default_params.pca_params.lambda ~= -1)
        set(pcacheck, 'Value', 1);
        format_default(set(lambdain, 'String', ...
            default_params.Default));
        set(tolin, 'String', ...
            format_default(default_params.pca_params.tol));
        set(maxiterin, 'String', ...
            format_default(default_params.pca_params.maxIter));
    else
        set(pcacheck, 'Value', 0);
        set(lambdain, 'String', '');
        set(tolin, 'String', '');
        set(maxiterin, 'String', '');
    end

    % Reduce channels
    set(reduce_chans, 'Value', default_params.perform_reduce_channels);
        
    % EOG channels
    set(eog_chans, 'String', '');
    set(eog_chans_check, 'Value', 1);
    
    % Interpolation
    IndexC = strfind(interpol.String, ...
        default_params.interpolation_params.method);
    index = find(not(cellfun('isempty', IndexC)));
    set(interpol, 'Value', index);

    switch_components();
end

% Activate or desactivate ui elements accordingly
% ----------------------------------------------------
function switch_components()
    if(get(euradio, 'Value'))
        set(usradio, 'Value', 0);
    end
    if(get(usradio, 'Value'))
        set(euradio, 'Value', 0);
    end

    if( get(highcheck, 'Value') )
        set(highorder, 'enable', 'on');
        set(highfreq, 'enable', 'on');
    else
        set(highorder, 'enable', 'off', 'String', ...
            format_default(default_params.Default));
        set(highfreq, 'enable', 'off', 'String', ...
            format_default(default_params.filter_params.high_freq));
    end

    if( get(lowcheck, 'Value') )
        set(loworder, 'enable', 'on');
        set(lowfreq, 'enable', 'on');
    else
        set(loworder, 'enable', 'off', 'String', ...
            format_default(default_params.filter_params.low_order));
        set(lowfreq, 'enable', 'off', 'String', ...
           format_default(default_params.filter_params.low_freq));
    end

    if( get(kurtcheck, 'Value') )
        set(kurtin, 'enable', 'on');
    else
        set(kurtin, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.channel_rejection_params.kurt_thresh)));
    end

    if( get(speccheck, 'Value') )
        set(specin, 'enable', 'on');
    else
        set(specin, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.channel_rejection_params.spec_thresh)));
    end

    if( get(probcheck, 'Value') )
        set(probin, 'enable', 'on');
    else
        set(probin, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.channel_rejection_params.prob_thresh)));
    end

    if( get(pcacheck, 'Value') )
        set(lambdain, 'enable', 'on');
        set(tolin, 'enable', 'on');
        set(maxiterin, 'enable', 'on');
        set(icacheck, 'value', 0)
    else
        set(lambdain, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.Default)));
        set(tolin, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.pca_params.tol)));
        set(maxiterin, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.pca_params.maxIter)));
    end

    if(get(icacheck, 'Value'))
        set(pcacheck, 'value', 0)
        set(lambdain, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.Default)));
        set(tolin, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.pca_params.tol)));
        set(maxiterin, 'enable', 'off', 'String', ...
            format_default(num2str(default_params.pca_params.maxIter)));
    end
end

% This makes the code stop until we make sure the pop up window is closed
waitfor(allhandlers{1})

% If cancel was clicked on
if( isempty(fieldnames(params)) ||  isempty(EEG.data))
    disp('Cannot preprocess without parameters or dataset.');
    return
end

% Preprocess EEG with given parameters. Keep all information in a field
% called 'EEG.automagic'
% -------------------------
[EEG, ~] = pre_process(EEG, [], params);
auto_badchans =  EEG.auto_badchans;
EEG = rmfield(EEG, 'auto_badchans');
EEG.automagic.params = params;
EEG.automagic.auto_badchans = auto_badchans;

% return the string command
% -------------------------
com = sprintf('[EEG] = pop_parameters(EEG)');

end


function [uilist, uipositions, verpos] = getUIControls()
% Create uiconstrols for each line

% Notch Filter
% ---------------------------------------
notch_text.style = { {'Style','text',...
            'String','Notch Filter:'} };
notch_text.pos = 1;

notch_input.style = { {} {'Style','radio',...
            'String','Europe (50Hz)', 'tag', 'notcheu', 'Value', 1}  {'Style','radio',...
            'String','US (60Hz)', 'tag', 'notchus'}};
notch_input.pos = [1 1 1];

% High pass filter
% ---------------------------------------
high_text.style = {{'Style','text',...
            'String','High Pass Filter:'}};
high_text.pos = 1;

high_label.style = {{} {'Style','text',...
            'String','Frequency'} {'Style','text',...
            'String','Order'}};
high_label.pos = [1 1 1];

high_inputs.style = { {'Style','checkbox',...
            'String','(Recommended)', 'tag', 'highcheckin', 'Value', 1} {'Style','edit',...
            'String','0.5', 'tag', 'highfreqin'} {'Style','edit',...
            'String','Default', 'tag', 'highorderin'} };
high_inputs.pos = [1 1 1];
 
% Low pass filter
% ---------------------------------------
low_text.style = { {'Style','text',...
            'String','Low Pass Filter:'} };
low_text.pos = 1;

low_label.style = {{} {'Style','text',...
            'String','Frequency'} {'Style','text',...
            'String','Order'}};
low_label.pos = [1 1 1];

low_inputs.style = { {'Style','checkbox',...
            'String','None', 'Value', 0, 'tag', 'lowcheckin'} {'Style','edit',...
            'String','', 'tag', 'lowfreqin', 'Enable', 'off'} {'Style','edit',...
            'String','', 'tag', 'loworderin', 'Enable', 'off'} };
low_inputs.pos = [1 1 1];

% Channel rejection criterias
% ---------------------------------------
channel_rejection_text.style = { {'Style','text',...
            'String','Channel rejection criterias:'} };
channel_rejection_text.pos = 1;

channel_rejection_label.style = {{} {'Style','text',...
            'String','Threshold'}};
channel_rejection_label.pos = [1 1];

channel_rejection_input_kur.style = { {'Style','checkbox',...
            'String','Kurtosis', 'tag', 'kurtcheck', 'Value', 1} {'Style','edit',...
            'String','3', 'tag', 'kurtin'}};
channel_rejection_input_kur.pos = [1 1];        

channel_rejection_input_prob.style = { {'Style','checkbox',...
            'String','Probability', 'tag', 'probcheck', 'Value', 1} {'Style','edit',...
            'String','4', 'tag', 'probin'}};
channel_rejection_input_prob.pos = [1 1]; 

channel_rejection_input_spec.style = { {'Style','checkbox',...
            'String','Spectrum', 'tag', 'speccheck', 'Value', 1} {'Style','edit',...
            'String','4', 'tag', 'specin'}};
channel_rejection_input_spec.pos = [1 1]; 

% ICA
% ---------------------------------------
ica_checkbox.style = { {'Style','checkbox',...
            'String','ICA', 'tag', 'icacheck', 'Value', 0} };
ica_checkbox.pos = 1; 

% PCA
% ---------------------------------------
pca_checkbox.style = { {'Style','checkbox',...
            'String','PCA', 'tag', 'pcacheck', 'Value', 1} };
pca_checkbox.pos = 1; 

pca_lambda.style = { {} {'Style','text',...
            'String','lambda'} {'Style','edit',...
            'String','Default', 'tag', 'lambdain'} };
pca_lambda.pos = [1 1 1]; 

pca_tolerance.style = { {} {'Style','text',...
            'String','tolerance'} {'Style','edit',...
            'String','1e-07', 'tag', 'tolerancein'} };
pca_tolerance.pos = [1 1 1]; 

pca_maxiter.style = { {} {'Style','text',...
            'String','maxIter'} {'Style','edit',...
            'String','1000', 'tag', 'maxiterin'} };
pca_maxiter.pos = [1 1 1]; 

% Reduce number of channels
% ---------------------------------------
reduce_chan_chechbox.style = { {'Style','checkbox',...
            'String','Reduce Number of Channels (Only for EGI systems)', ...
            'tag', 'reducechancheck', 'Value', 1} };
reduce_chan_chechbox.pos = 1; 

interpolation_text.style = {{'Style','text',...
            'String','Interpolation'}  {'Style','popupmenu',...
            'String',{'spherical', 'invdist', 'spacetime'}, ...
            'tag', 'interpolpopup', 'Value', 1} };
interpolation_text.pos = [1 1];

% EOG channels
% ---------------------------------------
eog.style = {{'Style','checkbox',...
            'String','EOG Channels', ...
            'tag', 'eogchanscheck', 'Value', 1}  {'Style','edit',...
            'String','', 'tag', 'eogchans'} };
eog.pos = [1 2];

% OK, Default and Cancel button
% ---------------------------------------
okcancel.style = {{ 'width' 80 'align' 'left' 'Style', 'pushbutton', ...
    'string', 'Cancel', 'tag' 'cancel' 'callback', 'close gcbf' } ...
    { 'width' 120 'align' 'left' 'Style', 'pushbutton', ...
    'string', 'Set to Default', 'tag' 'default_butt' }...
    { 'width' 80 'align' 'right' 'stickto' 'on' ...
    'Style', 'pushbutton', 'tag', 'ok', 'string', 'OK' } };
okcancel.pos = [1 1 1];
            
% Return both lists of uis and their positions
% --------------------------------------------
verpos = [1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];
uipositions = {notch_text.pos notch_input.pos high_text.pos ...
    high_label.pos high_inputs.pos low_text.pos ...
    low_label.pos low_inputs.pos ...
    channel_rejection_text.pos channel_rejection_label.pos ...
    channel_rejection_input_kur.pos channel_rejection_input_prob.pos ...
    channel_rejection_input_spec.pos ica_checkbox.pos pca_checkbox.pos ...
    pca_lambda.pos pca_tolerance.pos pca_maxiter.pos reduce_chan_chechbox.pos ...
    interpolation_text.pos eog.pos okcancel.pos};
uilist = [notch_text.style notch_input.style high_text.style ...
    high_label.style high_inputs.style low_text.style ...
    low_label.style low_inputs.style channel_rejection_text.style ...
    channel_rejection_label.style channel_rejection_input_kur.style ...
    channel_rejection_input_prob.style channel_rejection_input_spec.style...
    ica_checkbox.style pca_checkbox.style pca_lambda.style pca_tolerance.style...
    pca_maxiter.style reduce_chan_chechbox.style interpolation_text.style ...
    eog.style okcancel.style];

end

function uielem = findHandlerFromList(allhandlers, tag)
indices = cellfun(@(x) isa(x, 'matlab.ui.control.UIControl') && ...
    strcmp(x.Tag, tag), allhandlers);
uielem = allhandlers{indices};
end

function val = format_default(val)
    if( val == -1)
        val = [];
    end
end