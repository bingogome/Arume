classdef DataDB < handle
    %DATADB Database access class
    %   Reads and saves matlab variables to .mat files on disk. Simple
    %   cache implemented
    %
    %Jorge Otero-Millan, jorgeoteromillan@gmail.com 00/00/00
    %
    %This code is provided "as is". Enjoy and feel free to modify it.
    %Needless to say, the correctness of the code is not guarantied.
    
    properties (SetAccess = private)
        folder = '';
    end
    
    properties (Access = private)
        cache
        USECACHE = 1;
        
        READONLY = 0;
    end
    
    methods (Access = protected)
        
        function InitDB( this, folder)
            
            if ( ~ischar(folder) )
                error( 'Folder should be a string' );
            end
            
            this.folder = folder;
            
            if ( ~exist(this.folder,'dir') )
                mkdir(this.folder);
            end
        end
                
        function result = IsVariableInDB( this, variableName )
            d = dir( fullfile( this.folder, [variableName '.mat'] ) );
            if isempty(d)
                result = 0;
                return
            else
                result = 1;
                return
            end
        end
        
        function var = ReadVariable( this, variableName )
            var = [];
            
            try
                d = dir( fullfile( this.folder, [variableName '.mat'] ) );
                if isempty(d)
                    return
                end
                
                % if variable is in cache
                if ( isfield( this.cache, variableName ) ...
                        && isfield(this.cache, 'TIMESTAMPS') ...
                        && isfield(this.cache.TIMESTAMPS, variableName) ...
                        && d.datenum <= this.cache.TIMESTAMPS.(variableName))
                    % return variable from cache
                    var = this.cache.(variableName);
                    return
                else
                    % if variable is not in cache
                    try
                        % read variable
                        dat = load(fullfile( this.folder, d(1).name));
                    catch me
                        % if memory error
                        if ( isequal(me.identifier, 'MATLAB:nomem') )
                            % empty cache
                            this.cache = struct();
                            % read variable again
                            dat = load(fullfile( this.folder, d(1).name));
                        else
                            rethrow(me)
                        end
                    end
                    
                    var = dat.(variableName); % TODO, change!!
                    
                    if ( this.USECACHE )
                        
                        % add variable to cache
                        this.cache.(variableName) = var;
                        this.cache.TIMESTAMPS.(variableName) = d.datenum;
                    end
                end
            catch me
                rethrow(me);
            end
        end
        
        function WriteVariable( this, variable, variableName )
            if ( ~this.READONLY )
                try
                    fullname = [variableName '.mat'];
                    eval([variableName ' =  variable ;']);
                    
                    save(fullfile(this.folder , fullname), variableName);
                catch me
                    rethrow(me);
                end
            else
                disp('ClusterDetection.DataDB: cannot write to the database, it is set as read only');
            end
        end
        
        function RemoveVariable( this, variableName )
            if ( ~this.READONLY )
                try
                    delete(fullfile(this.folder , [variableName '.mat']));
                catch me
                    rethrow(me);
                end
            else
                disp('ClusterDetection.DataDB: cannot write to the database, it is set as read only');
            end
        end

        function ClearCache( this )
            this.cache = struct();
        end 
    end
end

