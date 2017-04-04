function [data, noise] = perform_pca(data, varargin)
% perform_pca  perform pca on the data 
%   [data, noise] = perform_pca(data, params) where data is the EEGLAB data
%   structure. params is an optional parameter which must be a structure
%   with optional fields 'lambda', 'tol', and 'maxIter' to specify
%   corresponding parameters in inexact_alm_rpca.m. To learn more about
%   these three parameters please see inexact_alm_rpca.m.
%
%   If varargin is ommited, default values are used. If any fields of
%   varargin is ommited, corresponsing default value is used. If
%   params.lambda = -1, PCA is not performed. Note that if 'maxIter' or 
%   'tol' are given as arguments, then 'lambda' must be given as well.
%
%   Default values: params.lambda = 1/sqrt(m) where m is number of channels
%                   params.tol = 1e-7
%                   params.maxIter = 1000
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

[~ , m] = size(data.data);

defaults = DefaultParameters.pca_params;
p = inputParser;
addParameter(p,'lambda', 1 / sqrt(m), @isnumeric);
addParameter(p,'tol', defaults.tol, @isnumeric);
addParameter(p,'maxIter', defaults.maxIter, @isnumeric);
parse(p, varargin{:});

lambda = p.Results.lambda;
tol = p.Results.tol;
maxIter = p.Results.maxIter;


if( isempty( lambda) )
    lambda = 1 / sqrt(m);
end

noise = [];
if( lambda == -1)
    return;
end

eeg = double(data.data)';
% Run robust PCA
display(defaults.run_message);
[~, A_hat, E_hat, ~] = evalc('inexact_alm_rpca(eeg, lambda, tol, maxIter)');
sig  = A_hat'; % data
data.data = sig;
noise = E_hat';  % noise

end