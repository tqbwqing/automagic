function [result, fig] = pre_process(data, raw_file_address, varargin)
% pre_process  preprocess the data 
%   [result, fig] = pre_process(data, raw_file_address, varargin)
%   where data is the EEGLAB data structure, raw_file_address is the 
%   address of the location where this file is located and varargin is an 
%   optional parameter which must be a structure with optional fields 
%   'filter_params', 'channel_rejection_params', 'pca_params', 
%   'interpolation_params', 'perform_eog_regression' and 
%   'perform_reduce_channels' to specify parameters for filtering, channel
%   rejection, pca, interpolation, EOG regression and reducing channels
%   respectively. 
%   
%   To learn more about 'filter_params', 'channel_rejection_params' and
%   'pca_params' please see their corresponding functions perform_filter.m,
%   reject_channels.m and perform_pca.m.
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
%   If varargin is ommited, default values are used. If any of the fields
%   of varargin are ommited, corresponsing default values are used.


p = inputParser;
addParameter(p,'filter_params', struct, @isstruct);
addParameter(p,'channel_rejection_params', struct, @isstruct);
addParameter(p,'pca_params', struct, @isstruct);
addParameter(p,'interpolation_params', struct('method', 'spherical'), @isstruct);
addParameter(p,'perform_eog_regression', 1, @isnumeric);
addParameter(p,'perform_reduce_channels', 1, @isnumeric);
parse(p, varargin{:});
filter_params = p.Results.filter_params;
channel_rejection_params = p.Results.channel_rejection_params;
pca_params = p.Results.pca_params;
interpolation_params = p.Results.interpolation_params;
perform_eog_regression = p.Results.perform_eog_regression;
perform_reduce_channels = p.Results.perform_reduce_channels;

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
    if(ispc)
        matlab_paths = strjoin(parts, ';');
    else
        matlab_paths = strjoin(parts, ':');
    end
    addpath(matlab_paths);
end
   
%% Determine number of channels
if( perform_reduce_channels )
    chan128 = [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 18 19 20 21 22 23 ...
        24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 ...
        45 46 47 50 51 52 53 54 55 57 58 59 60 61 62 64 65 66 67 69 70 ...
        71 72 74 75 76 77 78 79 80 82 83 84 85 86 87 89 90 91 92 93 95 ...
        96 97 98 100 101 102 103 104 105 106 108 109 110 111 112 114 115 ...
        116 117 118 120 121 122 123 124 129];
    
    chan_excl256  = [31 67 73 82 91 92 102 111 120 133 145 165 174 187 199 208 ... 
    209 216 217 218 219 225 226 227 228 229 230 231 232 233 234 235 236 ...
    237 238 239 240 241 242 243 244 245 246 247 248 249 250 251 252 253 ...
    254 255 256];
else
    chan128 = 1:129;
    chan_excl256 = double.empty(1,0);
end

switch data.nbchan
    case 128
        channels = chan128;
        eog_channels = sort([1 32 8 14 17 21 25 125 126 127 128]);
        data.data(end+1,:) = 0;
        data.nbchan = data.nbchan + 1;
        data = pop_chanedit(data,  ...
            'load',{ ['GSN-HydroCel-129.sfp'], 'filetype', 'sfp'});
    case (128 + 1)
        channels = chan128;
        eog_channels = sort([1 32 8 14 17 21 25 125 126 127 128]);
        data = pop_chanedit(data, ...
            'load',{ 'GSN-HydroCel-129.sfp', 'filetype', 'sfp'});
    case 256
        channels = setxor(1:257, chan_excl256);
        eog_channels = sort([31 32 37 46 54 252 248 244 241 25 18 10 1 226 ...
            230 234 238]);
        data.data(end+1,:) = 0;
        data.nbchan = data.nbchan + 1;
        data = pop_chanedit(data, ...
            'load',{ 'GSN-HydroCel-257_be.sfp', 'filetype', 'sfp'});
    case (256 + 1)
        channels = setxor(1:257, chan_excl256);
        eog_channels = sort([31 32 37 46 54 252 248 244 241 25 18 10 1 226 ...
            230 234 238]);
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
        [~, hd] = evalc('ft_read_header(raw_file_address)');
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
    otherwise
        error('This number of channel is not supported.')

end
s = size(data.data);
assert(data.nbchan == s(1)); clear s;

%% Preprocess data
% filtering on the whole dataset
filtered_data = perform_filter(data, filter_params);

% seperate EEG channels from EOG ones
unique_chans = setdiff(channels, eog_channels);
[~, EEG] = evalc('pop_select( filtered_data , ''channel'', channels)');
[~, EOG] = evalc('pop_select( filtered_data , ''channel'', eog_channels)');
[~, EEG_unique] = evalc('pop_select( filtered_data , ''channel'', unique_chans)');

% Detect artifact channels
rejected_chans = reject_channels(EEG, channel_rejection_params);

% Remove effect of EOG
if( perform_eog_regression )
    EEG_regressed = EOG_regression(EEG_unique, EOG);
else
    EEG_regressed = EEG_unique;
end

% PCA
if( ~ strcmp(pca_params.lambda, 'Default'))
    [EEG_cleared, noise] = perform_pca(EEG_regressed, pca_params);
else
    [EEG_cleared, noise] = perform_pca(EEG_regressed);
end
% Replace common channels of eeg and eog by zeros and put together with
% unique eeg channels
eeg_cleaned = zeros(size(filtered_data.data));
eeg_cleaned(unique_chans,:) = EEG_cleared.data;
EEG_cleaned = EEG;
EEG_cleaned.data = eeg_cleaned(channels,:);

% interpolate zero and artifact channels:
display('Interpolating...');
if ~isempty(rejected_chans)
    [~, interpolated] = evalc('eeg_interp(EEG_cleaned ,rejected_chans , interpolation_params.method)');
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
subplot(4,1,1)
imagesc(filtered_data.data);
colormap jet
caxis([-100 100])
XTicks = 0:length(filtered_data.data)/5:length(filtered_data.data) ;
XTicketLabels = round(0:length(filtered_data.data)/filtered_data.srate/5:length(filtered_data.data)/filtered_data.srate);
set(gca,'XTick', XTicks)
set(gca,'XTickLabel', XTicketLabels)
title('Filtered data')
subplot(4,1,2)
% figure;
imagesc(EEG_regressed.data);
colormap jet
caxis([-100 100])
set(gca,'XTick',XTicks)
set(gca,'XTickLabel',XTicketLabels)
title('EOG regressed out')
subplot(4,1,3)
%figure;
imagesc(EEG_cleared.data);
colormap jet
caxis([-100 100])
set(gca,'XTick',XTicks)
set(gca,'XTickLabel',XTicketLabels)
title('PCA corrected clean data')
subplot(4,1,4)
%figure;
imagesc(noise);
colormap jet
caxis([-100 100])
set(gca,'XTick',XTicks)
set(gca,'XTickLabel',XTicketLabels)
title('PCA noise')
