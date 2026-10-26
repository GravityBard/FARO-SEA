function setup_FARO
% SETUP_FARO Add active project folders to the MATLAB path.

project_root = fileparts(mfilename('fullpath'));

addpath(project_root);
addpath(fullfile(project_root, 'functions'));
addpath(fullfile(project_root, 'models'));
addpath(fullfile(project_root, 'tests'));
addpath(fullfile(project_root, 'requirements'));

fprintf('FARO project paths configured.\n');

end