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
            
            d = struct2table(dir(path));
            d = d(d.isdir & ~strcmp(d.name,'.') & ~strcmp(d.name,'..'),:);
            
            % load sessions
            for i=1:length(d.name)
                sessionName = d.name{i};
                filename = fullfile( fullfile(path, sessionName), [sessionName '_ArumeSession.mat']);
                
                if ( exist(filename, 'file') )
                    session = load( filename, 'sessionData' );
                    session = session.sessionData;
            
                    ArumeCore.Session.LoadSession( this, session );
                else
                    disp(['WARNING: session ' sessionName ' could not be loaded. May be an old result of corruption.']);
                end
            end
        end
        
        function updateFileStructure(this, path, projectName)
            
            if ( exist(fullfile(path, 'project.mat'),'file') )
                disp('Updated file structure to new version of Arume ...');
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
                
                
                projectMatFile = fullfile(path, [projectName '_ArumeProject.mat']);
                
                % load project data
                data = load( projectMatFile, 'data' );
                data = data.data;
                
                for sessionData = data.sessions
                    sessionName = [sessionData.experimentName '_' sessionData.subjectCode sessionData.sessionCode];
                    filename = fullfile( fullfile(path, sessionName), [sessionName '_ArumeSession.mat']);
                    save( filename, 'sessionData' );
                end
                data = rmfield(data,'sessions');
                % TODO: maybe save the updated data without sessions.
                
                disp('... Done updating file structure.');
            end
        end
            
        %
        % Save project
        %   
        function save( this )
            % for safer storage do not save the actual matlab Project
            % object. Instead create a struct and save that. It will be
            % more robust to version changes.
            data = [];
            data.defaultExperiment = this.defaultExperiment; 
            
            for session = this.sessions
                sessionData = session.save();
                filename = fullfile( session.dataPath, [session.name '_ArumeSession.mat']);
                save( filename, 'sessionData' );
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
                        if ( isempty(dataTable) && ~isempty(session.sessionDataTable))
                            dataTable = session.sessionDataTable;
                        elseif ( ~isempty(session.sessionDataTable))
                            dataTable = [dataTable;session.sessionDataTable];
                        end
                    end
                end
                dataTable
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
            result = ~isempty(regexp(name,'^[_a-zA-Z0-9]+$','ONCE') );
        end
    end
end

