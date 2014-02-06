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
        
        Filename    = '';
    end
    
    %% properties
    properties ( Dependent = true )
        isStarted
        isFinished
    end
    
    methods
        function result = get.isStarted(this)
            if ( isempty( this.experiment.CurrentRun ) || isempty(this.experiment.CurrentRun.pastConditions) )
                result = 0;
            else
                result = 1;
            end
        end
        
        function result = get.isFinished(this)
            if ( ~isempty( this.experiment.CurrentRun ) && isempty(this.experiment.CurrentRun.futureConditions) )
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
            switch(this.experimentName)
                case 'torsion'
                    this.experiment     = ExperimentDesigns.OptokineticTorsionExperimentDesign();
            end

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
            
            this.experiment.init();
        end
        
        function initExisting( this, project, data )
            
            this.init( project, data.experimentName, data.subjectCode, data.sessionCode  );
            
            this.experiment.CurrentRun = data.CurrentRun;
            this.experiment.PastRuns = data.PastRuns;
            this.Filename = data.Filename;
            this.experiment.Config = data.Config;
            
        end
        
        function data = save( this )
            data = [];
            
            data.experimentName = this.experimentName;
            data.subjectCode = this.subjectCode;
            data.sessionCode = this.sessionCode;
            data.experiment.CurrentRun = this.experiment.CurrentRun;
            data.experiment.PastRuns = this.experiment.PastRuns;
            data.Filename = this.Filename;
            data.experiment.Config = this.experiment.Config;
            
        end
        
        %% RUNING METHODS
        function start( this )
            this.experiment.run();
        end
        
        function resume( this )
            %-- save the status of the current run in  the past runs
            if ( isempty( this.experiment.PastRuns) )
                this.experiment.PastRuns = this.experiment.CurrentRun;
            else
                this.experiment.PastRuns( length(this.experiment.PastRuns) + 1 ) = this.experiment.CurrentRun;
            end
            this.run();
        end
        
        function restart( this )
            % save the status of the current run in  the past runs
            if ( isempty( this.PastRuns) )
                this.experiment.PastRuns    = this.experiment.CurrentRun;
            else
                this.experiment.PastRuns( length(this.experiment.PastRuns) + 1 ) = this.experiment.CurrentRun;
            end
            % generate new sequence of trials
            this.experiment.CurrentRun = this.experiment.setUpNewRun( );
            this.Experiment.run();
        end
        
        
        %% ANALYSIS METHODS
        function prepareForAnalysis( this )
            
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

