function [data, noise] = perform_pca(data)
% perform_pca  perform pca on the data 

display('Performing PCA  (this may take a while...)');
eeg = double(data.data)'; 
% Run robust PCA
[~, A_hat, E_hat, ~] = evalc('inexact_alm_rpca(eeg)');
sig  = A_hat'; % data
data.data = sig;
noise = E_hat';  % noise
end