classdef Project < handle
    %PROJECT Class handingling Arume projects
    %   
    
    properties( SetAccess = private)
        name        % Name of the project
        projectFile % Actual location of the compressed project file
        path        % Working path of the uncompressed project (typically the temp folder)
        
        defaultExperiment % default experiment for this project
                
        sessions    % Sessions that belong to this project
        
        analysis
        figures
        reports
    end
    
    properties(Dependent=true)
        % relative paths inside the project
        dataRawPath
        dataAnalysisPath
        figuresPath
        stimuliPath
    end
    
    %
    % Get methods for dependent variables
    %
    methods
        function out = get.dataRawPath( this )
            out = fullfile( this.path, 'dataRaw');
        end
        
        function out = get.dataAnalysisPath( this )
            out = fullfile( this.path, 'dataAnalysis');
        end
        
        function out = get.figuresPath( this )
            out = fullfile( this.path, 'figures');
        end
        
        function out = get.stimuliPath( this )
            out = fullfile( this.path, 'stimuli');
        end
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
            
            this.projectFile = fullfile(projectFilePath, [projectName '.aruprj']);
            
            if ( exist( this.projectFile, 'file' ) )
                error( 'Arume: project file already exists' );
            end
            
            % initialize the project
            this.init( fullfile(tempPath, projectName),projectName, defaultExperiment );
            
            % prepare folder structure
            mkdir( tempPath, projectName );
            mkdir( this.path, 'dataRaw' );
            mkdir( this.path, 'dataAnalysis' );
            mkdir( this.path, 'stimuli' );
            mkdir( this.path, 'figures' );
            mkdir( this.path, 'analysis' );
            
            % save the project
            this.save();
        end
        
        function initExisting( this, file, tempPath )
        % Initializes a project loading from a file
        
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
            projectMatFile = fullfile(tempPath, projectName, 'project.mat');
            
            % load project data
            data = load( projectMatFile, 'data' );
            data = data.data;
            
            % initialize the project
            this.init( projectPath, data.name, data.defaultExperiment );
            
            % load sessions
            for session = data.sessions
                s = ArumeCore.Session.LoadSession( this, session );
            end
        end
            
        %
        % Save project object to file
        %   
        function save( this )
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
            
            filename = fullfile( this.path, 'project.mat');
            save( filename, 'data' );
            
            % create a backup of the last project file before overriding it
            if ( exist(this.projectFile,'file') )
                copyfile(this.projectFile, [this.projectFile '.aruback']);
            end
            
            % compress project file and keep temp folder
            tar(this.projectFile , this.path);
            movefile([this.projectFile '.tar'], this.projectFile,'f');
            
            % send session variables to workspace
            arumeData = [];
            for session = this.sessions
                arumeData.(session.name).trialDataSet = session.trialDataSet;
                arumeData.(session.name).analysisResults = session.analysisResults;
            end
            
            assignin ('base','arumeData',arumeData);
            
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
            sessidx = find( this.sessions == session );
            this.sessions(sessidx) = [];
        end
        
        function [session i] = findSession( this, experimentName, subjectCode, sessionCode)
            
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
            
            sessionNames = {};
            for i=1:length(this.sessions)
                sessionNames{i} = [this.sessions(i).subjectCode this.sessions(i).sessionCode];
            end
            [b i] = sort(sessionNames);
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

