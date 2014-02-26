classdef Session < handle
    %SESSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        project
        
        experimentName
        
        experiment
        
        name
        dataRawPath
        dataAnalysisPath
        
        subjectCode = '000';
        sessionCode = 'Z';
        
        CurrentRun  = [];
        PastRuns    = [];
    end
    
    %% properties
    properties ( Dependent = true )
        isStarted
        isFinished
    end
    
    methods
        function result = get.isStarted(this)
            if ( isempty( this.CurrentRun ) || isempty(this.CurrentRun.pastConditions) )
                result = 0;
            else
                result = 1;
            end
        end
        
        function result = get.isFinished(this)
            if ( ~isempty( this.CurrentRun ) && isempty(this.CurrentRun.futureConditions) )
                result = 1;
            else
                result = 0;
            end
        end
    end
    
    %% methods
    methods
        function init( this, project, experimentName, subjectCode, sessionCode )
            this.project        = project;
            this.experimentName = experimentName;
            this.experiment     = ArumeCore.ExperimentDesign.Create( this, this.experimentName );

            this.name           = [subjectCode sessionCode];
            this.subjectCode    = subjectCode;
            this.sessionCode    = sessionCode;
            
            this.dataRawPath        = fullfile( this.project.dataRawPath, this.name);
            this.dataAnalysisPath	= fullfile( this.project.dataAnalysisPath, this.name);
            
            if ( isempty( project.sessions ) )
                project.sessions = this;
            else
                project.sessions(end+1) = this;
            end
        end
        
        function initNew( this, project, experimentName, subjectCode, sessionCode )
            
            % check if session already exists with that subjectCode and
            % sessionCode
            for session = project.sessions
                if ( isequal(subjectCode, session.subjectCode) && isequal( sessionCode, session.sessionCode) )
                    error( 'Arume: session already exists use a diferent name' );
                end
            end
            
            this.init( project, experimentName, subjectCode, sessionCode );
            
            % create the new folders
            mkdir( project.dataRawPath, this.name );
            mkdir( project.dataAnalysisPath, this.name );
            
            this.CurrentRun = ArumeCore.ExperimentRun.SetUpNewRun( this.experiment );
        end
        
        function initExisting( this, project, data )
            
            this.init( project, data.experimentName, data.subjectCode, data.sessionCode  );
            
            this.CurrentRun  = ArumeCore.ExperimentRun.LoadRunData( data.CurrentRun, this.experiment );
            this.PastRuns  = ArumeCore.ExperimentRun.LoadRunDataArray( data.PastRuns, this.experiment );
        end
        
        function data = save( this )
            data = [];
            
            data.experimentName = this.experimentName;
            data.subjectCode = this.subjectCode;
            data.sessionCode = this.sessionCode;
            
            data.CurrentRun = ArumeCore.ExperimentRun.SaveRunData(this.CurrentRun);
            data.PastRuns = ArumeCore.ExperimentRun.SaveRunDataArray(this.PastRuns);
        end
        
        %% RUNING METHODS
        function start( this )
            this.experiment.run();
        end
        
        function resume( this )
            %-- save the status of the current run in  the past runs
            if ( isempty( this.PastRuns) )
                this.PastRuns = this.CurrentRun;
            else
                this.PastRuns( length(this.PastRuns) + 1 ) = this.CurrentRun;
            end
            this.experiment.run();
        end
        
        function restart( this )
            % save the status of the current run in  the past runs
            if ( isempty( this.PastRuns) )
                this.PastRuns    = this.CurrentRun;
            else
                this.PastRuns( length(this.PastRuns) + 1 ) = this.CurrentRun;
            end
            % generate new sequence of trials
            this.CurrentRun = this.setUpNewRun( );
            this.experiment.run();
        end
        
        %% ANALYSIS METHODS
        function prepareForAnalysis( this )
            this.experiment.Analysis_getSigmoid();
        end
        
    end
    
    methods (Static = true )
        
        function session = NewSession( project, experimentName, subjectCode, sessionCode )
            % TODO add factory for multiple types of experimentNames
            session = ArumeCore.Session();
            session.initNew( project, experimentName, subjectCode, sessionCode );
        end
        
        function session = LoadSession( project, data )
            % TODO add factory for multiple types of experimentNames
            
            session = ArumeCore.Session();
            
            session.initExisting( project, data );
        end
        
    end
    
    
    
   
    
    
end

