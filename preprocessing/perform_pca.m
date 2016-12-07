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

[~ , m] = size(data.data);

p = inputParser;
addParameter(p,'lambda', 1 / sqrt(m), @isnumeric);
addParameter(p,'tol', 1e-7, @isnumeric);
addParameter(p,'maxIter', 1000, @isnumeric);
parse(p, varargin{:});

lambda = p.Results.lambda;
tol = p.Results.tol;
maxIter = p.Results.maxIter;

eeg = double(data.data)';
% Run robust PCA
noise = [];
if( lambda ~= -1)
    display('Performing PCA  (this may take a while...)');
    [~, A_hat, E_hat, ~] = evalc('inexact_alm_rpca(eeg, lambda, tol, maxIter)');
    sig  = A_hat'; % data
    data.data = sig;
    noise = E_hat';  % noise
end

end