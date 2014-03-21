classdef Project < handle
    %PROJECT Class handingling Arume projects
    %   Detailed explanation goes here
    
    properties( SetAccess = private)
        name        % Name of the project
        projectFile % Actual location of the compressed project file
        path        % Working path of the uncompressed project (typically the temp folder)
        
        defaultExperiment % default experiment for this project
                
        sessions 
        
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
        function init ( this, path, name, defaultExperiment )
            this.name               = name;
            this.path               = path;
            this.defaultExperiment  = defaultExperiment;
            this.sessions           = [];
        end
        
        function initNew( this, parentFolder, name, defaultExperiment )
            
            this.projectFile = [parentFolder '\' name '.aruprj'];
            
            if ( exist( this.projectFile, 'file' ) )
                error( 'Arume: project file already exists' );
            end
            
            % initialize the project
            this.init( [Arume.tempFolder '\' name], name, defaultExperiment );
            
            % prepare folder structure
            mkdir( Arume.tempFolder, name );
            mkdir( this.path, 'dataRaw' );
            mkdir( this.path, 'dataAnalysis' );
            mkdir( this.path, 'stimuli' );
            mkdir( this.path, 'figures' );
            mkdir( this.path, 'analysis' );
            
            % save the project
            this.save();
        end
        
        function initExisting( this, file )
            [filePath, projectName] = fileparts(file);
            
            this.projectFile = file;
            
            % clean the temp folder
            rmdir(Arume.tempFolder,'s');
            mkdir(Arume.tempFolder);
            
            % uncompress project file into temp folder
            untar(file, Arume.tempFolder);
            
            projectPath = fullfile(Arume.tempFolder, projectName);
            projectMatFile = fullfile(Arume.tempFolder, projectName, 'project.mat');
            
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
            
            % compress project file and keep temp folder
            tempPath = Arume.tempFolder;
            tar(this.projectFile , fullfile(tempPath, this.name));
            movefile([this.projectFile '.tar'], this.projectFile);
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
    end
    
    
    methods ( Static = true )
        
        %
        % Factory methods
        %
        function project = NewProject( parentFolder, name, defaultExperiment)            
            
            % check if parentFolder exists
            if ( ~exist( parentFolder, 'dir' ) )
                error('Arume: parent folder does not exist');
            end
            
            % check if name is a valid name
            if ( ~ArumeCore.Project.IsValidProjectName( name ) )
                error('Arume: project name is not valid');
            end
            
            % create project object
            project = ArumeCore.Project();
            project.initNew( parentFolder, name, defaultExperiment );
        end
        
        function this = LoadProject( file )
            % read project info
            this = ArumeCore.Project();
            this.initExisting( file );
        end
        
        %
        % Other methods
        %
        function result = IsValidProjectName( name )
            result = 1;
        end
    end
    
end

