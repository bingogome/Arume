classdef Project < handle
    %PROJECT Class handingling Arume projects
    %   
    
    properties( SetAccess = private)
        name        % Name of the project
        path        % Working path of the uncompressed project (typically the temp folder)
        
        defaultExperiment % default experiment for this project
                
        sessions    % Sessions that belong to this project
    end
        
    methods
        %
        % Initialization methods
        %
        function init ( this, path, name, defaultExperiment )
            this.name               = name;
            this.path               = path;
            this.defaultExperiment  = defaultExperiment;
            this.sessions           = [];
        end
        
        function initNew( this, parentPath, projectName, defaultExperiment )
        % Initializes a new project
            
            if ( exist( fullfile(parentPath, projectName), 'dir' ) )
                error( 'Arume: project file already exists' );
            end
            
            % initialize the project
            this.init( fullfile(parentPath, projectName), projectName, defaultExperiment );
            
            % prepare folder structure
            mkdir( parentPath, projectName );
            
            % save the project
            this.save();
        end
        
        function initExisting( this, path )
        % Initializes a project loading from a folder
        
            [~, projectName] = fileparts(path);
            projectMatFile = fullfile(path, [projectName '_ArumeProject.mat']);
                        
            % load project data
            data = load( projectMatFile, 'data' );
            data = data.data;
            
            % initialize the project
            this.init( path, projectName, data.defaultExperiment );
            
            % load sessions
            for session = data.sessions
                ArumeCore.Session.LoadSession( this, session );
            end
        end
        
        function updateFileStructure(this, path, projectName)
            
            if ( exist(fullfile(path, 'project.mat'),'file') )
                movefile(fullfile(path, 'project.mat'), fullfile(path, [projectName '_ArumeProject.mat']),'f');
                movefile(fullfile(fullfile(path,'dataAnalysis'),'*'), path,'f');
                movefile(fullfile(fullfile(path,'dataRaw'),'*'), path,'f');
                
                
                if ( exist( fullfile(path, 'analysis'),'dir') )
                    rmdir(fullfile(path, 'analysis'),'s');
                end
                if ( exist( fullfile(path, 'dataAnalysis'),'dir') )
                    rmdir(fullfile(path, 'dataAnalysis'),'s');
                end
                if ( exist( fullfile(path, 'dataRaw'),'dir') )
                    rmdir(fullfile(path, 'dataRaw'),'s');
                end
                if ( exist( fullfile(path, 'figures'),'dir') )
                    rmdir(fullfile(path, 'figures'),'s');
                end
                if ( exist( fullfile(path, 'stimuli'),'dir') )
                    rmdir(fullfile(path, 'stimuli'),'s');
                end
                
            end
        end
            
        %
        % Save project object to file
        %   
        function save( this )
            % for safer storage do not save the actual matlab Project
            % object. Instead create a struct and save that. It will be
            % more robust to version changes.
            data = [];
            data.defaultExperiment = this.defaultExperiment; 
            
            data.sessions = [];
            for session = this.sessions
                if isempty( data.sessions )   
                    data.sessions = session.save();
                else
                    data.sessions(end+1) = session.save();
                end
            end
            
            % Save the data structure
            filename = fullfile( this.path, [this.name '_ArumeProject.mat']);
            save( filename, 'data' );
            
            disp('======= ARUME PROJECT SAVED TO DISK REMEMBER TO BACKUP ==============================')
            try
                tbl = this.GetDataTable;
                if (~isempty(tbl) )
                    writetable(tbl,fullfile(this.path, [this.name '_ArumeSessionTable.xlsx']))
                end
                
                disp('======= ARUME EXCEL DATA SAVED TO DISK ==============================')
            catch err
                disp('ERROR saving excel data');
                disp(err.getReport);
            end
        end
        
        function backup(this, file)
            if (~isempty(file) )
                % create a backup of the last project file before
                % overriding it
                if ( exist(file,'file') )
                    copyfile(file, [file '.aruback']);
                end
                
                % compress project file and keep temp folder
                zip(file , this.path);
            end
        end
                
        %
        % Other methods
        %
        function addSession( this, session)
            if ( isempty( this.sessions ) )
                this.sessions = session;
            else
                this.sessions(end+1) = session;
            end
        end
        
        function deleteSession( this, session )
            session.deleteFolders();
            this.sessions( this.sessions == session ) = [];
        end
        
        function [session, i] = findSession( this, experimentName, subjectCode, sessionCode)
            
            for i=1:length(this.sessions)
                if ( exist('sessionCode','var') )
                    if ( strcmpi(this.sessions(i).experiment.Name, upper(experimentName)) &&  ...
                        strcmpi(this.sessions(i).subjectCode, upper(subjectCode)) &&  ...
                           strcmpi(this.sessions(i).sessionCode, upper(sessionCode)))
                       session = this.sessions(i);
                       return;
                    end
                else
                    if ( strcmpi(this.sessions(i).experiment.Name, upper(experimentName)) &&  ...
                        strcmpi([upper(this.sessions(i).subjectCode) upper(this.sessions(i).sessionCode),], subjectCode))
                       session = this.sessions(i);
                       return;
                    end
                end
            end
            
            % if not found
            session = [];
            i = 0;
        end
        
        function sortSessions(this)
            
            sessionNames = cell(length(this.sessions),1);
            for i=1:length(this.sessions)
                sessionNames{i} = [this.sessions(i).subjectCode this.sessions(i).sessionCode];
            end
            [~, i] = sort(sessionNames);
            this.sessions = this.sessions(i);
        end
        
        function mergeProject(this, projectPath)
            p2 = ArumeCore.Project.LoadProject(projectPath);
            
            for session = p2.sessions
                repeated = false;
                for session1 = this.sessions
                    if ( strcmp( session.name, session1.name) )
                        repeated = true;
                    end
                end
                
                if ( ~repeated)
                    d = session.save();
                    s = ArumeCore.Session.LoadSession(this,d);
                    this.addSession(s);
                end
            end
        
        end
        
        %
        % Analysis methods
        % 
        function dataTable = GetDataTable(this, subjectSelection, sessionSelection)
            allSubjects = {};
            allSessionCodes = {};
            for session=this.sessions
                allSubjects{end+1} = session.subjectCode;
                allSessionCodes{end+1} = session.sessionCode;
            end
            if ( ~exist( 'subjectSelection', 'var' ) && ~exist( 'sessionSelection', 'var' ))
                subjectSelection = unique(allSubjects);
                sessionSelection = unique(allSessionCodes);
            end
            
                dataTable = table();
                for isess=1:length(this.sessions)
                    session=this.sessions(isess);
                    % if this is one of the sessions we want
                    if ( any(categorical(subjectSelection) == session.subjectCode) && any(categorical(sessionSelection)==session.sessionCode))
                        if ( isempty(dataTable) )
                            dataTable = session.sessionDataTable;
                        else
%                             t1 = dataTable;
%                             t2 = session.sessionDataTable;
%                             if ( ~isempty(t2) )
%                                 t1colmissing = setdiff(t2.Properties.VariableNames, t1.Properties.VariableNames);
%                                 t2colmissing = setdiff(t1.Properties.VariableNames, t2.Properties.VariableNames);
%                                 t1 = [t1 array2table(nan(height(t1), numel(t1colmissing)), 'VariableNames', t1colmissing)];
%                                 t2 = [t2 array2table(nan(height(t2), numel(t2colmissing)), 'VariableNames', t2colmissing)];
%                                 for colname = t1colmissing
%                                     if iscell(t2.(colname{1}))
%                                         t1.(colname{1}) = cell(height(t1), 1);
%                                     end
%                                 end
%                                 for colname = t2colmissing
%                                     if iscell(t1.(colname{1}))
%                                         t2.(colname{1}) = cell(height(t2), 1);
%                                     end
%                                 end
%                                 dataTable = [t1; t2]
%                             end

                            dataTable = [dataTable;session.sessionDataTable]
                        end
                    end
                end
        end
    end
    
    
    methods ( Static = true )
        
        %
        % Factory methods
        %
        function project = NewProject( parentPath, projectName, defaultExperiment)            
            
            % check if parentFolder exists
            if ( ~exist( parentPath, 'dir' ) )
                error('Arume: parent folder does not exist');
            end
            
            % check if name is a valid name
            if ( ~ArumeCore.Project.IsValidProjectName( projectName ) )
                error('Arume: project name is not valid');
            end
            
            % create project object
            project = ArumeCore.Project();
            project.initNew( parentPath, projectName, defaultExperiment );
        end
        
        function project = LoadProject( projectPath )
            % read project info
            project = ArumeCore.Project();
            project.initExisting( projectPath );
        end
        
        function project = LoadProjectBackup(file, parentPath)
            
            project = ArumeCore.Project();
            
            [~, projectName, ext] = fileparts(file);
            
            projectPath = fullfile(parentPath, projectName);
            
            mkdir(projectPath);
            
            % uncompress project file into temp folder
            if ( strcmp(ext, '.aruprj' ) )
                untar(file, parentPath);
            else
                unzip(file, parentPath);
            end
            project.updateFileStructure(projectPath, projectName);
            project.initExisting(projectPath);
        end
        
        %
        % Other methods
        %
        function result = IsValidProjectName( name )
            result = 1;
        end
    end
end

