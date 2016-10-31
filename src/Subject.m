classdef Subject
    %SUBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(SetAccess=private)
        name
    end
    properties(SetAccess=private, GetAccess=private)
        data_folder
        result_folder
        data_folder_win
        result_folder_win
    end
    properties
        block_list
    end
    
    methods
        function self = Subject(data_folder, result_folder)
            self = self.setResult_folder(result_folder);
            self = self. setData_folder(data_folder);
            self.name = self.extract_name(data_folder);
        end
        
        
        function self = setData_folder(self, address)
            if(ismac)
                self.data_folder = address;
            elseif(ispc)
                self.data_folder_win = address;
            end
        end

        function self = setResult_folder(self, address)
            if(ismac)
                self.result_folder = address;
            elseif(ispc)
                self.result_folder_win = address;
            end
        end
        
        function data_folder = getData_folder(self)
            if(ismac)
                data_folder = self.data_folder;
            elseif(ispc)
                data_folder = self.data_folder_win;
            end
        end
        function result_folder = getResult_folder(self)
            if(ismac)
                result_folder = self.result_folder;
            elseif(ispc)
                result_folder = self.result_folder_win;
            end
        end

        
    end
    
    methods(Static, Access=private)
        function name = extract_name(address)
            if(ismac)
                splits = strsplit(address, '/');
            elseif(ispc)
                splits = strsplit(address, '\');
            end
            name = splits{end};
        end
    end
end

