classdef ConstantGlobalValues
    properties(Constant)
        version = '1.3.0';
            
        DEFAULT_keyword = 'Default';
                
        NONE_keyword = 'None';
        
        new_project = struct('LIST_NAME', 'Create New Project...', ...
            'NAME', 'Type the name of your new project...', ...
            'DATA_FOLDER', 'Choose where your raw data is...', ...
            'FOLDER', 'Choose where you want the results to be saved...');
        
        state_file = struct('NAME', 'state.mat', ...
            'PROJECT_NAME', 'project_state.mat', ...
            'FOLDER', '~/methlab_pipeline/', ...
            'ADDRESS', '~/methlab_pipeline/state.mat');
        
        load_selected_project = struct('LIST_NAME', 'Load an existing project...');
        
        default_params = DefaultParameters
        
        ratings = struct('Good', 'Good', ...
                        'Bad', 'Bad', ...
                        'OK', 'OK', ...
                        'Interpolate', 'Interpolate', ...
                        'NotRated', 'Not Rated');
    end
    
    methods
        function self = ConstantGlobalValues
            addpath('../preprocessing/');
        end
    end
end

