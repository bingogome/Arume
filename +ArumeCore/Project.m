classdef Project < handle
    %PROJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Name of the project
        name
        path
                
        sessions
        
        analysis
        figures
        reports
        
        dataRawPath = '';
        dataAnalysisPath = '';
        
        figuresPath = '';
        stimuliPath = '';
    end
    
    methods
        function init ( this, path, name )
            this.name = name;
            this.path = path;
            
            this.dataRawPath = [ this.path '\dataRaw'];
            this.dataAnalysisPath = [ this.path '\dataAnalysis'];
            this.figuresPath = [ this.path '\figures'];
            this.stimuliPath = [ this.path '\stimuli'];
            
            this.sessions = [];
        end
        
        function initNew( this, parentFolder, name )
            
            this.init( [parentFolder '\' name], name );
            
            if ( exist( this.path, 'dir' ) )
                error( 'Arume: project folder already exists, select empty folder' );
            end
            
            
            % prepare folder structure
            mkdir( parentFolder, name );
            mkdir( this.path, 'dataRaw' );
            mkdir( this.path, 'dataAnalysis' );
            mkdir( this.path, 'stimuli' );
            mkdir( this.path, 'figures' );
            mkdir( this.path, 'analysis' );
            mkdir( this.path, 'reports' );
            
            this.save();
        end
        
        function initFromPath( this, file )
            filePath = fileparts(file);
            data = load( file, 'data' );
            data = data.data;
            
            this.init( filePath, data.name );
            
            for session = data.sessions
                ArumeCore.Session.LoadSession( this, session );
            end
        end
            
        function save( this )
            data = [];
            data.name = this.name;
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
            
        end
        
    end
    
    
    methods ( Static = true )
        function project = New( parentFolder, name)
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
            project.initNew( parentFolder, name );
                
        end
        
        function this = Load( file )
            % read project info
            this = ArumeCore.Project();
            
            this.initFromPath( file );
            
        end
        
        function result = IsValidProjectName( name )
            result = 1;
        end
    end
    
end

