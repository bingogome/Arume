classdef Project < handle
    %PROJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        experiment
        path
        options
        
        sessions = [];
        analysis = [];
        figures = [];
        reports = [];
        
        sessionsPath = '';
        figuresPath = '';
    end
    
    methods
        function init ( this, experiment, path, name, options )
            this.name = name;
            this.experiment = experiment;
            this.path = path;
            this.sessionsPath = [ this.path '\sessions'];
            this.figuresPath = [ this.path '\figures'];
            this.options = options;
            
            this.sessions = [];
        end
        
        function initNew( this, experiment, parentFolder, name, options )
            
            this.init( experiment, [parentFolder '\' name], name, options );
            
            if ( exist( this.path, 'dir' ) )
                error( 'Arume: project folder already exists, select empty folder' );
            end
            
            
            % prepare folder structure
            mkdir( parentFolder, name );
            mkdir( this.path, 'data' );
            mkdir( this.path, 'sessions' );
            mkdir( this.path, 'figures' );
            mkdir( this.path, 'analysis' );
            mkdir( this.path, 'reports' );
            
            this.save();
        end
        
        function initFromPath( this, path )
            filename = fullfile( path, 'project.mat');
            data = load( filename, 'data' );
            data = data.data;
            
            this.init( data.experiment, path, data.name, data.options );
            
            this.loadSessions();
        end
            
        function save( this )
            data = [];
            data.name = this.name;
            data.experiment = this.experiment;
            data.options = this.options;
            
            filename = fullfile( this.path, 'project.mat');
            save( filename, 'data' );
            
            for session = this.sessions
                session.save();
            end
        end
        
    end
    
    % session management
    methods 
        function loadSessions( this )
            
            d = dir(this.sessionsPath);
            isub = [d(:).isdir];
            sessionNames = {d(isub).name}';
            sessionNames(ismember(sessionNames,{'.','..'})) = [];
            
            for i=1:length(sessionNames)
                ArumeCore.Session.LoadSession( this, sessionNames{i} );
            end
            
        end
        
    end
    
    methods ( Static = true )
        function project = New( experiment, parentFolder, name, options)
            import ArumeCore.Project;
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
            project.initNew( experiment, parentFolder, name, options );
                
        end
        
        function this = Load( path )
            % read project info
            this = ArumeCore.Project();
            
            this.initFromPath( path );
            
        end
        
        function result = IsValidProjectName( name )
            result = 1;
        end
    end
    
end

