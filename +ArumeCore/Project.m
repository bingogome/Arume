classdef Project < handle
    %PROJECT Class handingling Arume projects
    %   
    
    properties( SetAccess = private)
        name        % Name of the project
        projectFile % Actual location of the compressed project file, will be empty for folder projects  
        path        % Working path of the uncompressed project (typically the temp folder)
        
        defaultExperiment % default experiment for this project
                
        sessions    % Sessions that belong to this project
    end
        
    methods
        %
        % Initialization methods
        %
        function init ( this, tempPath, name, defaultExperiment )
            this.name               = name;
            this.path               = tempPath;
            this.defaultExperiment  = defaultExperiment;
            this.sessions           = [];
        end
        
        function initNew( this, projectFilePath, projectName, tempPath, defaultExperiment )
        % Initializes a new project
            
            if ( ~strcmp(projectFilePath, tempPath) )
                this.projectFile = fullfile(projectFilePath, [projectName '.aruprj']);
            else
                % for project folders. There is no project file and the
                % temp folder if the same folder containing the project
                this.projectFile = [];
            end
            
            if ( exist( this.projectFile, 'file' ) )
                error( 'Arume: project file already exists' );
            end
            
            % initialize the project
            this.init( fullfile(tempPath, projectName), projectName, defaultExperiment );
            
            % prepare folder structure
            mkdir( tempPath, projectName );
            
            % save the project
            this.save();
        end
        
        function initExisting( this, file, tempPath )
        % Initializes a project loading from a file
        
            if ( ~strcmp(file, tempPath) )
                this.projectFile = file;
                
                [filePath, projectName] = fileparts(file);
                
                % clean the temp folder
                if(  exist(tempPath,'dir') )
                    try
                        rmdir(tempPath,'s');
                    catch(error)
                        disp('ERRO: temp folder could not be removed');
                    end
                end
                mkdir(tempPath);
                
                % uncompress project file into temp folder
                untar(file, tempPath);
                projectPath = fullfile(tempPath, projectName);
                projectMatFile = fullfile(tempPath, projectName, [projectName '_ArumeProject.mat']);
                
            else
                % TODO: this must not work for folders. How does it get
                % projectName??
                
                % for project folders. There is no project file and the
                % temp folder is the same folder containing the project
                this.projectFile = [];
                projectPath = file;
                projectMatFile = fullfile(projectPath, [projectName '_ArumeProject.mat']);
            end
            
            this.updateFileStructure(projectPath, projectName);
            
            % load project data
            data = load( projectMatFile, 'data' );
            data = data.data;
            
            % initialize the project
            this.init( projectPath, data.name, data.defaultExperiment );
            
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
            data.name = this.name;
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
            
            % If project file (not folder) compress the folder structure
            % into a single file and save it.
            if (~isempty(this.projectFile) ) 
                % create a backup of the last project file before
                % overriding it
                if ( exist(this.projectFile,'file') )
                    copyfile(this.projectFile, [this.projectFile '.aruback']);
                end
                
                % compress project file and keep temp folder
                tar(this.projectFile , this.path);
                movefile([this.projectFile '.tar'], this.projectFile,'f');
            end
                        
            disp('========== ARUME PROJECT SAVED TO DISK =================================')
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
            this.sessions(find( this.sessions == session )) = [];
        end
        
        function [session, i] = findSession( this, experimentName, subjectCode, sessionCode)
            
            for i=1:length(this.sessions)
                if ( exist('sessionCode','var') )
                    if ( strcmp(upper(this.sessions(i).experiment.Name), upper(experimentName)) &&  ...
                        strcmp(upper(this.sessions(i).subjectCode), upper(subjectCode)) &&  ...
                           strcmp(upper(this.sessions(i).sessionCode), upper(sessionCode)))
                       session = this.sessions(i);
                       return;
                    end
                else
                    if ( strcmp(upper(this.sessions(i).experiment.Name), upper(experimentName)) &&  ...
                        strcmp([upper(this.sessions(i).subjectCode) upper(this.sessions(i).sessionCode),], upper(subjectCode)))
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
        
        function mergeProject(this, projectFile)
            tempPath2 = fullfile(this.path, 'TEMPMERGE');
            p2 = ArumeCore.Project.LoadProject(projectFile, tempPath2);
            
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
            for session=this.sessions
                % if this is one of the sessions we want
                if ( any(categorical(subjectSelection) == session.subjectCode) && any(categorical(sessionSelection)==session.sessionCode))
                    if ( isempty(dataTable) )
                        dataTable = session.sessionDataTable;
                    else
                        % TODO: need to deal with sessions from different
                        % experiments. May need to add additional columns
                        % to either table before merging
                        dataTable = [dataTable;session.sessionDataTable];
                    end
                end
            end
        end
    end
    
    
    methods ( Static = true )
        
        %
        % Factory methods
        %
        function project = NewProject( projectFilePath, projectName, tempPath, defaultExperiment)            
            
            % check if parentFolder exists
            if ( ~exist( projectFilePath, 'dir' ) )
                error('Arume: parent folder does not exist');
            end
            
            % check if name is a valid name
            if ( ~ArumeCore.Project.IsValidProjectName( projectName ) )
                error('Arume: project name is not valid');
            end
            
            % create project object
            project = ArumeCore.Project();
            project.initNew( projectFilePath, projectName, tempPath, defaultExperiment );
        end
        
        function project = LoadProject( projectFile, tempPath )
            % read project info
            project = ArumeCore.Project();
            project.initExisting( projectFile, tempPath );
        end
        
        %
        % Other methods
        %
        function result = IsValidProjectName( name )
            result = 1;
        end
    end
end

