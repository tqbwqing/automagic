function [result, fig] = pre_process(data, varargin)
% pre_process  preprocess the data 
%   [result, fig] = pre_process(data, varargin)
%   where data is the EEGLAB data structure and varargin is an 
%   optional parameter which must be a structure with optional fields 
%   'filter_params', 'channel_rejection_params', 'pca_params', 'ica_params'
%   'interpolation_params', 'perform_eog_regression', 'eeg_system', 
%   'perform_reduce_channels' and 'original_file' to specify parameters for 
%   filtering, channel rejection, pca, ica, interpolation, EOG regression, 
%   channel locations, reducing channels and original file address 
%   respectively. This latter one is needed only if a .fif file is used,
%   otherwise it can be omitted.
%   
%   To learn more about 'filter_params', 'channel_rejection_params', 
%   ica_params and 'pca_params' please see their corresponding functions 
%   perform_filter.m, reject_channels.m, perform_ica.m and perform_pca.m.
%   
%   'interpolation_params' is an optional structure with an optional field
%   'method' which can be on of the following chars: 'spherical',
%   'invdist' and 'spacetime'. The default value is
%   interpolation_params.method = 'spherical'. To learn more about these
%   three methods please see eeg_interp.m of EEGLAB.
%   
%   'perform_eog_regression' must be a boolean indication whether to
%   perform EOG Regression or not. The default value is
%   perform_eog_regression = 1.
%   
%   'perform_reduce_channels' must be a boolean indication whether to
%   reduce the number of channels or not. The default value is
%   'perform_reduce_channels' = 1.
%
%   'original_file' is necassary only in case of .fif files. In that case,
%   this should be the address of the file where this EEG data is loaded
%   from.
%   
%   eeg_system must be a structure with fields name, eog_chan, loc_file and
%   file_loc_type. eeg_system.name can be either 'EGI' or 'Others'. In the
%   former case none of the other fields are used and they can be empty.
%   In the latter case eeg_system.eog_chan must be an array of numbers
%   indicating indices of the EOG channels in the data, eeg_system.loc_file
%   must be the name of the file located in 'matlab_scripts' folder that 
%   can be used by pop_chanedit to find channel locations and finally 
%   eeg_system.file_loc_type must be the type of that file. Please see 
%   pop_chanedit for more information. Obviously only types supported by 
%   pop_chanedit are supported.
%   
%   If varargin is ommited, default values are used. If any of the fields
%   of varargin are ommited, corresponsing default values are used. Please
%   note that there is no default value for eeg_system.
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

result = [];
fig = [];

p = inputParser;
addParameter(p,'eeg_system', @isstruct);
addParameter(p,'filter_params', struct, @isstruct);
addParameter(p,'channel_rejection_params', struct, @isstruct);
addParameter(p,'pca_params', struct, @isstruct);
addParameter(p,'ica_params', struct, @isstruct);
addParameter(p,'interpolation_params', struct('method', 'spherical'), @isstruct);
addParameter(p,'perform_eog_regression', 1, @isnumeric);
addParameter(p,'perform_reduce_channels', 1, @isnumeric);
addParameter(p,'original_file', '', @ischar);
parse(p, varargin{:});
eeg_system = p.Results.eeg_system;
filter_params = p.Results.filter_params;
channel_rejection_params = p.Results.channel_rejection_params;
pca_params = p.Results.pca_params;
ica_params = p.Results.ica_params;
interpolation_params = p.Results.interpolation_params;
perform_eog_regression = p.Results.perform_eog_regression;
perform_reduce_channels = p.Results.perform_reduce_channels;
original_file_address = p.Results.original_file;

assert( ( ~ isempty(pca_params.lambda) && pca_params.lambda == -1) ...
         || ica_params.bool == 0);

pca_url = 'http://perception.csl.illinois.edu/matrix-rank/Files/inexact_alm_rpca.zip';
if(ispc)
    slash = '\';
else
    slash = '/';
end
%% Add path if not added before
if(~exist('pop_fileio', 'file'))
    matlab_paths = genpath(['..' slash 'matlab_scripts' slash]);
    if(ispc)
        parts = strsplit(matlab_paths, ';');
    else
        parts = strsplit(matlab_paths, ':');
    end
    IndexC = strfind(parts, 'compat');
    Index = not(cellfun('isempty', IndexC));
    parts(Index) = [];
    IndexC = strfind(parts, 'neuroscope');
    Index = not(cellfun('isempty', IndexC));
    parts(Index) = [];
    if(ispc)
        matlab_paths = strjoin(parts, ';');
    else
        matlab_paths = strjoin(parts, ':');
    end
    addpath(matlab_paths);
end

%% Check if PCA exists
if((isempty(pca_params.lambda) || pca_params.lambda ~= -1) && (~exist('inexact_alm_rpca.m', 'file')))
    ques = 'inexact_alm_rpca is necessary for PCA. Do you want to download it now?';
    ques_title = 'PCA Requirement installation';
    if(exist('questdlg2', 'file'))
        res = questdlg2( ques , ques_title, 'No', 'Yes', 'Yes' );
    else
        res = questdlg( ques , ques_title, 'No', 'Yes', 'Yes' );
    end
    
    if(strcmp(res, 'No'))
       msg = 'Preprocessing failed as PCA package is not yet installed. Please either isntall it or choose not to use PCA.';
        if(exist('warndlg2', 'file'))
            warndlg2(msg);
        else
            warndlg(msg);
        end
        return; 
    end
    
    folder = pwd;
    if(regexp(folder, 'gui'))
        folder = ['..' slash 'matlab_scripts' slash];
    elseif(regexp(folder, 'eeglab'))
        folder = ['plugins' slash 'automagic' slash 'matlab_scripts' slash];
    else
      while(isempty(regexp(folder, 'gui', 'once')) || ...
            isempty(regexp(folder, 'eeg_lab', 'once')))
        
        msg = ['For the installation, please choose the root folder of the EEGLAB: your_path/eeglab or',...
            ' the gui folder of the automagic: your_path/automagic/gui/'];
        waitfor(msgbox(msg));
        folder = uigetdir(pwd, msg);
        
        if(isempty(folder))
            return;
        end
        
      end
    end
    zip_name = [folder 'inexact_alm_rpca.zip'];  
    
    outfilename = websave(zip_name,pca_url);
    unzip(outfilename,folder);
    addpath(genpath([folder 'inexact_alm_rpca' slash]));
    delete(zip_name);
    display('PCA package successfully installed. Continuing preprocessing....');
end

%% Determine the eeg system
% Case of others where the location file must have been provided
if (~isempty(eeg_system.name) && strcmp(eeg_system.name, 'Others'))
    assert(~ perform_reduce_channels);
    ica_params.chanloc_map = containers.Map; % Map is empty. 
    
    all_chans = 1:data.nbchan;
    eog_channels = eeg_system.eog_chans;
    channels = setdiff(all_chans, eog_channels);
    
    if( mod(data.nbchan, 2) == 0)
        data.data(end+1,:) = 0;
        data.nbchan = data.nbchan + 1; 
    end
    data = pop_chanedit(data,  ...
        'load',{ eeg_system.loc_file , 'filetype', eeg_system.file_loc_type});

% Case of EGI
elseif(~isempty(eeg_system.name) && strcmp(eeg_system.name, 'EGI'))
    
    if( perform_reduce_channels )
        chan128 = [2 3 4 5 6 7 9 10 11 12 13 15 16 18 19 20 22 23 24 26 27 ...
            28 29 30 31 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 50 51 ...
            52 53 54 55 57 58 59 60 61 62 64 65 66 67 69 70 71 72 74 75 76 ...
            77 78 79 80 82 83 84 85 86 87 89 90 91 92 93 95 96 97 98 100 ...
            101 102 103 104 105 106 108 109 110 111 112 114 115 116 117 ...
            118 120 121 122 123 124 129];

        chan256  = [2 3 4 5 6 7 8 9 11 12 13 14 15 16 17 19 20 21 22 ...
            23 24 26 27 28 29 30 33 34 35 36 38 39 40 41 42 43 44 45 ...
            47 48 49 50 51 52 53 55 56 57 58 59 60 61 62 63 64 65 66 ...
            68 69 70 71 72 74 75 76 77 78 79 80 81 83 84 85 86 87 88 ...
            89 90 93 94 95 96 97 98 99 100 101 103 104 105 106 107 108 ...
            109 110 112 113 114 115 116 117 118 119 121 122 123 124 125 ...
            126 127 128 129 130 131 132 134 135 136 137 138 139 140 141 ...
            142 143 144 146 147 148 149 150 151 152 153 154 155 156 157 ...
            158 159 160 161 162 163 164 166 167 168 169 170 171 172 173 ...
            175 176 177 178 179 180 181 182 183 184 185 186 188 189 190 ...
            191 192 193 194 195 196 197 198 200 201 202 203 204 205 206 ...
            207 210 211 212 213 214 215 220 221 222 223 224 257];
    else
        chan128 = 1:129;
        chan256 = 1:257;
    end

    switch data.nbchan
        case 128
            eog_channels = sort([1 32 8 14 17 21 25 125 126 127 128]);
            channels = setdiff(chan128, eog_channels);
            data.data(end+1,:) = 0;
            data.nbchan = data.nbchan + 1;
            data = pop_chanedit(data,  ...
                'load',{ 'GSN-HydroCel-129.sfp', 'filetype', 'sfp'});
        case (128 + 1)
            eog_channels = sort([1 32 8 14 17 21 25 125 126 127 128]);
            channels = setdiff(chan128, eog_channels);
            data = pop_chanedit(data, ...
                'load',{ 'GSN-HydroCel-129.sfp', 'filetype', 'sfp'});
        case 256
            eog_channels = sort([31 32 37 46 54 252 248 244 241 25 18 10 1 226 ...
                230 234 238]);
            channels = setdiff(chan256, eog_channels);
            data.data(end+1,:) = 0;
            data.nbchan = data.nbchan + 1;
            data = pop_chanedit(data, ...
                'load',{ 'GSN-HydroCel-257_be.sfp', 'filetype', 'sfp'});
        case (256 + 1)
            eog_channels = sort([31 32 37 46 54 252 248 244 241 25 18 10 1 226 ...
                230 234 238]);
            channels = setdiff(chan256, eog_channels);
            data = pop_chanedit(data, ...
                'load',{ 'GSN-HydroCel-257_be.sfp', 'filetype', 'sfp'});
        case 395  %% .fif files
            addpath('../fieldtrip-20160630/'); 
            % Get rid of two wrong channels 63 and 64
            eegs = arrayfun(@(x) strncmp('EEG',x.labels, length('EEG')), data.chanlocs, 'UniformOutput', false);
            not_ecg = arrayfun(@(x) ~ strncmp('EEG063',x.labels, length('EEG063')), data.chanlocs, 'UniformOutput', false);
            not_wrong = arrayfun(@(x) ~ strncmp('EEG064',x.labels, length('EEG064')), data.chanlocs, 'UniformOutput', false);
            channels = find(cell2mat(eegs) & cell2mat(not_ecg) & cell2mat(not_wrong));
            [~, data] = evalc('pop_select( data , ''channel'', channels)');
            data.data = data.data * 1e6;% Change from volt to microvolt
            % Convert channel positions to EEG_lab format 
            [~, hd] = evalc('ft_read_header(original_file_address)');
            hd_idx = true(1,74);
            hd_idx(63:64) = false;
            positions = hd.elec.chanpos(hd_idx,:);
            fid = fopen( 'pos_temp.txt', 'wt' );
            fprintf( fid, 'NumberPositions=	72\n');
            fprintf( fid, 'UnitPosition	cm\n');
            fprintf( fid, 'Positions\n');
            for pos = 1:length(positions)
              fprintf( fid, '%.8f %.8f %.8f\n', positions(pos,:));
            end
            fprintf( fid, 'Labels\n');
            fprintf( fid, ['EEG01	EEG02	EEG03	EEG04	EEG05	EEG06	EEG07	EEG08	EEG09	EEG010	EEG011	EEG012 '...
                          'EEG013	EEG014	EEG015	EEG016	EEG017	EEG018	EEG019	EEG020	EEG021	EEG022	EEG023	EEG024 '...
                          'EEG025	EEG026	EEG027	EEG028	EEG029	EEG030	EEG031	EEG032	EEG033	EEG034	EEG035	EEG036 '...
                          'EEG037	EEG038	EEG039	EEG040	EEG041	EEG042	EEG043	EEG044	EEG045	EEG046	EEG047	EEG048 '...
                          'EEG049	EEG050	EEG051	EEG052	EEG053	EEG054	EEG055	EEG056	EEG057	EEG058	EEG059	EEG060 '...
                          'EEG061	EEG062 EEG065	EEG066	EEG067	EEG068	EEG069	EEG070	EEG071	EEG072 '...
                          'EEG073	EEG074']);
            fprintf( fid, '\n');
            fclose(fid);
            eeglab_pos = readeetraklocs('pos_temp.txt');
            delete('pos_temp.txt');
            data.chanlocs = eeglab_pos;

            % Distinguish EOGs(61 & 62) from EEGs
            eegs = arrayfun(@(x) strncmp('EEG',x.labels, length('EEG')), data.chanlocs, 'UniformOutput', false);
            eog1 = arrayfun(@(x) strncmp('EEG061',x.labels, length('EEG061')), data.chanlocs, 'UniformOutput', false);
            eog2 = arrayfun(@(x) strncmp('EEG062',x.labels, length('EEG062')), data.chanlocs, 'UniformOutput', false); 

            channels = find((cellfun(@(x) x == 1, eegs)));
            channel1 = find((cellfun(@(x) x == 1, eog1)));
            channel2 = find((cellfun(@(x) x == 1, eog2)));
            eog_channels = [channel1 channel2];
            channels = setdiff(channels, eog_channels); 
        otherwise
            error('This number of channel is not supported.')

    end

    %% Make ICA map of channels
    switch data.nbchan
        case 129
            % Make the map for ICA
            keySet = {'E17', 'E22', 'E9', 'E11', 'E24', 'E124', 'E33', 'E122', ...
                'E129', 'E36', 'E104', 'E45', 'E108', 'E52', 'E92', 'E57', 'E100', ...
                'E58', 'EE96', 'E70', 'E75', 'E83', 'E62'};
            valueSet =   {'NAS', 'Fp1', 'Fp2', 'Fz', 'F3', 'F4', 'F7', 'F8', 'Cz', ...
                'C3', 'C4', 'T7', 'T8', 'P3', 'P4', 'LM', 'RM', 'P7', 'P8', 'O1', ...
                'Oz', 'O2', 'Pz'};
            ica_params.chanloc_map = containers.Map(keySet,valueSet);
        case 257
            keySet = {'E31', 'E37', 'E18', 'E21', 'E36', 'E224', 'E47', ...
                'E2', 'E257', 'E59', 'E183', 'E69', 'E202', 'E87', 'E153', ...
                'E94', 'E190', 'E96', 'E170', 'E116', 'E126', 'E150', 'E101'};
            valueSet =   {'NAS', 'Fp1', 'Fp2', 'Fz', 'F3', 'F4', 'F7', 'F8', 'Cz', ...
                'C3', 'C4', 'T7', 'T8', 'P3', 'P4', 'LM', 'RM', 'P7', 'P8', 'O1', ...
                'Oz', 'O2', 'Pz'};
            ica_params.chanloc_map = containers.Map(keySet,valueSet);
    end
else
   if(isempty(data.chanlocs))
       disp('data.chanlocs is necessary for interpolation.');
       return;
   end
    all_chans = 1:data.nbchan;
    eog_channels = eeg_system.eog_chans;
    channels = setdiff(all_chans, eog_channels);
end
s = size(data.data);
assert(data.nbchan == s(1)); clear s;

%% Preprocess data
% filtering on the whole dataset
filtered_data = perform_filter(data, filter_params);

% seperate EEG channels from EOG ones
[~, EOG] = evalc('pop_select( filtered_data , ''channel'', eog_channels)');
[~, EEG] = evalc('pop_select( filtered_data , ''channel'', channels)');

% Detect artifact channels
rejected_chans = reject_channels(EEG, channel_rejection_params);
eeg_size = size(EEG.data);
if( length(rejected_chans) > eeg_size(1) / 2)
    result = [];
    fig = [];
   return; 
end

% Remove effect of EOG
if( perform_eog_regression )
    EEG_regressed = EOG_regression(EEG, EOG);
else
    EEG_regressed = EEG;
end

% PCA or ICA
if (ica_params.bool ) % If ICA is checked
    EEG_cleared = perform_ica(EEG_regressed, ica_params);
else % If PCA is not checked either, the EEG_cleared will remain unchanged
    [EEG_cleared, noise] = perform_pca(EEG_regressed, pca_params);
end

% interpolate zero and artifact channels:
display('Interpolating...');
if ~isempty(rejected_chans)
    [~, interpolated] = evalc('eeg_interp(EEG_cleared ,rejected_chans , interpolation_params.method)');
else
    interpolated = EEG_cleared;
end
interpolated.auto_badchans = rejected_chans;
% detrending
res = bsxfun(@minus, interpolated.data, mean(interpolated.data,2));
result = interpolated;
result.data = res;

%% Creating the final figure to save
fig = figure;
set(gcf, 'Color', [1,1,1])
hold on
% eog figure
subplot(9,1,1)
imagesc(EOG.data);
colormap jet
caxis([-100 100])
XTicks = [] ;
XTicketLabels = [];
set(gca,'XTick', XTicks)
set(gca,'XTickLabel', XTicketLabels)
title('Filtered EOG data');
%eeg figure
subplot(9,1,2:3)
imagesc(EEG.data);
colormap jet
caxis([-100 100])
set(gca,'XTick', XTicks)
set(gca,'XTickLabel', XTicketLabels)
title('Filtered EEG data')
% figure;
subplot(9,1,4:5)
imagesc(EEG_regressed.data);
colormap jet
caxis([-100 100])
set(gca,'XTick',XTicks)
set(gca,'XTickLabel',XTicketLabels)
title('EOG regressed out');
%figure;
subplot(9,1,6:7)
imagesc(EEG_cleared.data);
colormap jet
caxis([-100 100])
set(gca,'XTick',XTicks)
set(gca,'XTickLabel',XTicketLabels)
title('PCA corrected clean data')
%figure;
if( isempty(pca_params.lambda) || pca_params.lambda ~= -1)
    subplot(9,1,8:9)
    imagesc(noise);
    colormap jet
    caxis([-100 100])
    XTicks = 0:length(EEG.data)/5:length(EEG.data) ;
    XTicketLabels = round(0:length(EEG.data)/EEG.srate/5:length(EEG.data)/EEG.srate);
    set(gca,'XTick',XTicks)
    set(gca,'XTickLabel',XTicketLabels)
    title('PCA noise')
end
