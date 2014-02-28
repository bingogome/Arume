classdef Session < ArumeCore.DataDB
    %SESSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
    end
    
    %% properties
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
    
    %% dependent properties... see the related get.property method
    properties ( Dependent = true )
        isStarted
        isFinished
        
        isReadyForAnalysis
    end
    
    %% properties from analysis
    properties( Dependent = true ) % not stored in the object (memory) BIG VARIABLES
        
        trialDataSet
        
        samplesDataSet
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
        
        function result = get.isReadyForAnalysis(this)
            if ( this.IsVariableInDB( 'trialDataSet' ) )
                result = 1;
            else
                result = 0;
            end
        end
        
        function trialDataSet = get.trialDataSet(this)
            trialDataSet = this.ReadVariable('trialDataSet');
        end
        
        function samplesDataSet = get.samplesDataSet(this)
            samplesDataSet = this.ReadVariable('samplesDataSet');
        end
    end
    
    
    
    %% methods
    methods
        %% INIT METHODS
        function init( this, project, experimentName, subjectCode, sessionCode )
            this.project        = project;
            this.experimentName = experimentName;
            this.experiment     = ArumeCore.ExperimentDesign.Create( this, this.experimentName );

            this.name           = [subjectCode sessionCode];
            this.subjectCode    = subjectCode;
            this.sessionCode    = sessionCode;
            
            this.dataRawPath        = fullfile( this.project.dataRawPath, this.name);
            this.dataAnalysisPath	= fullfile( this.project.dataAnalysisPath, this.name);
            
            this.InitDB( this.project.dataAnalysisPath, this.name );
            
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
        end
        
        function initExisting( this, project, data )
            
            this.init( project, data.experimentName, data.subjectCode, data.sessionCode  );
            if (~isempty( data.CurrentRun ))
                this.CurrentRun  = ArumeCore.ExperimentRun.LoadRunData( data.CurrentRun, this.experiment );
            end
            if (~isempty( data.PastRuns ))
                this.PastRuns  = ArumeCore.ExperimentRun.LoadRunDataArray( data.PastRuns, this.experiment );
            end
        end
        
        function importData( this, trialDataSet, samplesDataSet )
            this.WriteVariable(trialDataSet,'trialDataSet');
            this.WriteVariable(samplesDataSet,'samplesDataSet');
        end
        
        function data = save( this )
            data = [];
            
            data.experimentName = this.experimentName;
            data.subjectCode = this.subjectCode;
            data.sessionCode = this.sessionCode;
            
            if (~isempty( this.CurrentRun ))
                data.CurrentRun = ArumeCore.ExperimentRun.SaveRunData(this.CurrentRun);
            else
                data.CurrentRun = [];
            end
            if (~isempty( this.CurrentRun ))
                data.PastRuns = ArumeCore.ExperimentRun.SaveRunDataArray(this.PastRuns);
            else
                data.PastRuns = [];
            end
        end
        
        %% RUNING METHODS
        function start( this )
            if ( this.isFinished )
                error( 'This is session is finished it cannot be run' )
            end
            this.CurrentRun = ArumeCore.ExperimentRun.SetUpNewRun( this.experiment );
            this.experiment.run();
        end
        
        function resume( this )
            
            if ( this.isFinished )
                error( 'This is session is finished it cannot be run' )
            end
            
            %-- save the status of the current run in  the past runs
            if ( isempty( this.PastRuns) )
                this.PastRuns = this.CurrentRun.Copy();
            else
                this.PastRuns( length(this.PastRuns) + 1 ) = this.CurrentRun;
            end
            this.experiment.run();
        end
        
        function restart( this )
            
            if ( this.isFinished )
                error( 'This is session is finished it cannot be run' )
            end
            
            % save the status of the current run in  the past runs
            if ( isempty( this.PastRuns) )
                this.PastRuns    = this.CurrentRun.Copy();
            else
                this.PastRuns( length(this.PastRuns) + 1 ) = this.CurrentRun;
            end
            % generate new sequence of trials
            this.CurrentRun = ArumeCore.ExperimentRun.SetUpNewRun( this.experiment );
            this.experiment.run();
        end
        
        %% ANALYSIS METHODS
        function prepareForAnalysis( this )
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            trialConditionVars = this.experiment.ConditionMatrix( this.CurrentRun.pastConditions(:,1),:);
            
            ds = dataset;
            ds.TrialNumber = (1:length(this.CurrentRun.pastConditions(:,1)))';
            ds.ConditionNumber = this.CurrentRun.pastConditions(:,Enum.pastConditions.condition);
            ds.TrialResult = this.CurrentRun.pastConditions(:,Enum.pastConditions.trialResult);
            ds.BlockNumber = this.CurrentRun.pastConditions(:,Enum.pastConditions.blocknumber);
            ds.BlockID = this.CurrentRun.pastConditions(:,Enum.pastConditions.blockid);
            ds.Session = this.CurrentRun.pastConditions(:,Enum.pastConditions.session);

            for i=1:length(this.experiment.ConditionVars)
               ds.(this.experiment.ConditionVars(i).name)  = this.experiment.ConditionVars(i).values(trialConditionVars(:,i))';
            end
            
            % find all the possible output variables
            outputVars = {};
            for i=1:length(this.CurrentRun.Data)
                fields = fieldnames(this.CurrentRun.Data{i}.trialOutput);
                outputVars = union(outputVars,fields);
            end
            
            % collect the actual values
            output = [];
            for i=1:length(this.CurrentRun.Data)
                for j=1:length(outputVars)
                    field = outputVars{j};
                    if isfield( this.CurrentRun.Data{i}.trialOutput, field)
                        if ( isempty(output) || ~isfield(output, field) )
                            output.(field) = this.CurrentRun.Data{i}.trialOutput.(field);
                        else
                            output.(field)(i) = this.CurrentRun.Data{i}.trialOutput.(field);
                        end
                    end
                end
            end
            
            % add the output variables to the dataset
            fields = fieldnames(output);
            for j=1:length(fields)
                field = fields{j};
                ds.(field)  = output.(field)';
            end
            % save the dataset
            this.WriteVariable(ds,'trialDataSet');
        %%
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

