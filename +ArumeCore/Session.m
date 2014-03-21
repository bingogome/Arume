classdef Session < ArumeCore.DataDB
    %SESSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant)
    end
    
    %% properties
    properties( SetAccess = private)
        project
        
        
        experiment
        
        subjectCode = '000';
        sessionCode = 'Z';
        
        CurrentRun  = [];
        PastRuns    = [];
    end
    
    %% dependent properties... see the related get.property method
    properties ( Dependent = true )
        experimentName
        
        name
        isStarted
        isFinished
        
        isReadyForAnalysis
        
        dataRawPath
        dataAnalysisPath
    end
    
    %% properties from analysis
    properties( Dependent = true ) % not stored in the object (memory) BIG VARIABLES
        
        trialDataSet
        
        samplesDataSet
    end
    
    methods
        function name = get.experimentName(this)
            name = strrep(class(this.experiment), 'ExperimentDesigns.','');
        end
        
        function name = get.name(this)
            name = [this.subjectCode this.sessionCode];
        end
        
        function name = get.dataRawPath(this)
            name = fullfile( this.project.dataRawPath, this.name);
        end
        
        function name = get.dataAnalysisPath(this)
            name = fullfile( this.project.dataAnalysisPath, this.name);
        end
        
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
        function init( this, project, experimentName, subjectCode, sessionCode, experimentOptions )
            this.project        = project;
            this.experiment     = ArumeCore.ExperimentDesign.Create( this, experimentName, experimentOptions );

            this.subjectCode    = subjectCode;
            this.sessionCode    = sessionCode;
            
            
            this.InitDB( this.project.dataAnalysisPath, this.name );
            
            if ( isempty( project.sessions ) )
                project.sessions = this;
            else
                project.sessions(end+1) = this;
            end
        end
        
        function initNew( this, project, experimentName, subjectCode, sessionCode, experimentOptions )
            
            % check if session already exists with that subjectCode and
            % sessionCode
            for session = project.sessions
                if ( isequal(subjectCode, session.subjectCode) && isequal( sessionCode, session.sessionCode) )
                    error( 'Arume: session already exists use a diferent name' );
                end
            end
            
            this.init( project, experimentName, subjectCode, sessionCode, experimentOptions );
            
            % create the new folders
            mkdir( project.dataRawPath, this.name );
        end
        
        function initExisting( this, project, data )
             
            this.init( project, data.experimentName, data.subjectCode, data.sessionCode, data.experimentOptions  );
            if (~isempty( data.CurrentRun ))
                this.CurrentRun  = ArumeCore.ExperimentRun.LoadRunData( data.CurrentRun, this.experiment );
            end
            if (~isempty( data.PastRuns ))
                this.PastRuns  = ArumeCore.ExperimentRun.LoadRunDataArray( data.PastRuns, this.experiment );
            end
        end
        
        function rename( this, subjectCode, sessionCode)
            oldname = this.name;
            this.subjectCode = subjectCode;
            this.sessionCode = sessionCode;
            this.RenameDB( this.name );
            movefile([this.project.dataRawPath '\' oldname], [this.project.dataRawPath '\' this.name]);
        end
        
        function deleteFolders( this )
            rmdir(this.dataRawPath,'s');
            rmdir(this.dataAnalysisPath,'s');
        end
        
        function importData( this, trialDataSet, samplesDataSet )
            this.WriteVariable(trialDataSet,'trialDataSet');
            this.WriteVariable(samplesDataSet,'samplesDataSet');
        end
        
        function data = save( this )
            data = [];
            
            data.experimentName     = this.experimentName;
            data.subjectCode        = this.subjectCode;
            data.sessionCode        = this.sessionCode;
            data.experimentOptions  = this.experiment.ExperimentOptions;
            
            if (~isempty( this.CurrentRun ))
                data.CurrentRun = ArumeCore.ExperimentRun.SaveRunData(this.CurrentRun);
                data.PastRuns = ArumeCore.ExperimentRun.SaveRunDataArray(this.PastRuns);
            else
                data.CurrentRun = [];
                data.PastRuns = [];
            end
        end
        
        %
        %% RUNING METHODS
        %
        function start( this )
            if ( this.isFinished )
                error( 'This is session is finished it cannot be run' )
            end
            
            % Set up the new run: trial sequence, etc ...
            this.CurrentRun = ArumeCore.ExperimentRun.SetUpNewRun( this.experiment );
            
            % Start the experiment
            this.experiment.run();
        end
        
        function resume( this )
            
            if ( this.isFinished )
                error( 'This is session is finished it cannot be run' )
            end
            
            % Save the status of the current run in  the past runs, useful
            % to restart from a past point
            if ( isempty( this.PastRuns) )
                this.PastRuns = this.CurrentRun.Copy();
            else
                this.PastRuns( length(this.PastRuns) + 1 ) = this.CurrentRun;
            end
            
            % Start the experiment
            this.experiment.run();
        end
        
        function restart( this )
            
            if ( this.isFinished )
                error( 'This is session is finished it cannot be run' )
            end
            
            % Save the status of the current run in  the past runs, useful
            % to restart from a past point
            if ( isempty( this.PastRuns) )
                this.PastRuns    = this.CurrentRun.Copy();
            else
                this.PastRuns( length(this.PastRuns) + 1 ) = this.CurrentRun;
            end
            
            % Set up the new run: trial sequence, etc ...
            this.CurrentRun = ArumeCore.ExperimentRun.SetUpNewRun( this.experiment );
            
            % Start the experiment
            this.experiment.run();
        end
        
        %
        %% ANALYSIS METHODS
        %
        function prepareForAnalysis( this )
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
%             trialConditionVars = this.experiment.ConditionMatrix( this.CurrentRun.pastConditions(:,1),:);
            
            ds = dataset;
            ds.TrialNumber = (1:length(this.CurrentRun.pastConditions(:,1)))';
            ds.ConditionNumber = this.CurrentRun.pastConditions(:,Enum.pastConditions.condition);
            ds.TrialResult = this.CurrentRun.pastConditions(:,Enum.pastConditions.trialResult);
            ds.BlockNumber = this.CurrentRun.pastConditions(:,Enum.pastConditions.blocknumber);
            ds.BlockID = this.CurrentRun.pastConditions(:,Enum.pastConditions.blockid);
            ds.Session = this.CurrentRun.pastConditions(:,Enum.pastConditions.session);

%             for i=1:length(this.experiment.ConditionVars)
%                ds.(this.experiment.ConditionVars(i).name)  = this.experiment.ConditionVars(i).values(trialConditionVars(:,i))';
%             end
            
            % find all the possible output variables
            outputVars = {};
            for i=1:length(this.CurrentRun.Data)
                if ( isfield( this.CurrentRun.Data{i}, 'trialOutput' ) && ~isempty( this.CurrentRun.Data{i}.trialOutput ) )
                    fields = fieldnames(this.CurrentRun.Data{i}.trialOutput);
                    outputVars = union(outputVars,fields);
                end
            end
            
            
            % collect the actual values
            output = [];
            for i=1:length(this.CurrentRun.Data)
                for j=1:length(outputVars)
                    field = outputVars{j};
                    if ( isfield( this.CurrentRun.Data{i}, 'trialOutput' ) && isfield( this.CurrentRun.Data{i}.trialOutput, field))
                        if ( isempty(output) || ~isfield(output, field) )
                            output.(field) = this.CurrentRun.Data{i}.trialOutput.(field);
                        else
                            output.(field)(i) = this.CurrentRun.Data{i}.trialOutput.(field);
                        end
                    end
                end
            end
            
            % add the output variables to the dataset
            if ( ~isempty( output) )
                fields = fieldnames(output);
                for j=1:length(fields)
                    field = fields{j};
                    ds.(field)  = output.(field)';
                end
            end
            
            
            trialVars = {};
            for i=1:length(this.CurrentRun.Data)
                if ( ~isempty( this.CurrentRun.Data{i}.variables ) )
                    fields = fieldnames(this.CurrentRun.Data{i}.variables);
                    trialVars = union(trialVars,fields);
                end
            end
            
            
            % collect the actual values
            var = [];
            for i=1:length(this.CurrentRun.Data)
                for j=1:length(trialVars)
                    field = trialVars{j};
                    if isfield( this.CurrentRun.Data{i}.variables, field)
                        if ( isempty(var) || ~isfield(var, field) )
                            var.(field) = {this.CurrentRun.Data{i}.variables.(field)};
                        else
                            var.(field){i} = this.CurrentRun.Data{i}.variables.(field);
                        end
                    end
                end
            end
            
            % add the output variables to the dataset
            if ( ~isempty( var) )
                fields = fieldnames(var);
                for j=1:length(fields)
                    field = fields{j};
                    if ( ischar(var.(field){1} ))
                        ds.(field)  = var.(field)';
                    else
                        ds.(field)  = cell2mat(var.(field)');
                    end
                end
            end
            
            % save the dataset
            trialDataSet = this.experiment.PrepareTrialDataSet(ds);
            this.WriteVariable(trialDataSet,'trialDataSet');
            
            samplesDataSet = this.experiment.PrepareSamplesDataSet(trialDataSet);
            this.WriteVariable(samplesDataSet,'samplesDataSet');
        end
        
    end
    
    methods (Static = true )
        
        function session = NewSession( project, experimentName, subjectCode, sessionCode, experimentOptions )
            % TODO add factory for multiple types of experimentNames
            session = ArumeCore.Session();
            session.initNew( project, experimentName, subjectCode, sessionCode, experimentOptions );
        end
        
        function session = LoadSession( project, data )
            % TODO add factory for multiple types of experimentNames
            
            session = ArumeCore.Session();
            
            session.initExisting( project, data );
        end
    end
    
    
    
   
    
    
end

