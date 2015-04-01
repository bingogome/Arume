classdef Session < ArumeCore.DataDB
    %SESSION Encapsulates an experimental session
    %  links to the corresponding experiment design and contains all the
    %  data obtained when running the experiment or analyzing it.
    properties( SetAccess = private)
        project
        experiment
        
        subjectCode = '000';
        sessionCode = 'Z';
        comment = '';
        
        currentRun  = [];
        pastRuns    = [];
    end
    
    %% dependent properties... see the related get.property method
    properties ( Dependent = true )
        
        name
        
        isStarted
        isFinished
        
        isReadyForAnalysis
        
        dataRawPath
        dataAnalysisPath
    end
    
    %% properties from analysis
    properties( Dependent = true ) % not stored in the object (memory) BIG VARIABLES
        
        % Dataset with all the trial information (one row per trial)
        %
        % Most of is created automatically for all the experiments using the 
        % experiment design and the experiment run information.
        % Each experiment can add extra information in the method prepareTrialDataSet.
        trialDataSet
            
        % Dataset with all the sample data (one row per sample) :
        % 
        % Different experiments can load different columns.
        % Each experiment has to take care of preparing the dataset
        %
        % TimeStamp
        % LeftHorizontal
        % LeftVertical
        % LeftTorsion
        % RightHorizontal
        % RightVertical
        % RightTorsion
        % HeadRollTilt
        samplesDataSet
        
        % Results of the experiment specific analysis
        analysisResults 
    end
    
    %
    % Methods for dependent variables
    %
    methods
        
        function name = get.name(this)
            name = [this.experiment.Name '_' this.subjectCode this.sessionCode];
        end
        
        function name = get.dataRawPath(this)
            name = fullfile( this.project.dataRawPath, this.name);
        end
        
        function name = get.dataAnalysisPath(this)
            name = fullfile( this.project.dataAnalysisPath, this.name);
        end
        
        function result = get.isStarted(this)
            if ( isempty( this.currentRun ) || isempty(this.currentRun.pastConditions) )
                result = 0;
            else
                result = 1;
            end
        end
        
        function result = get.isFinished(this)
            if ( ~isempty( this.currentRun ) && isempty(this.currentRun.futureConditions) )
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
        %
        % INIT METHODS
        %
        function init( this, project, experimentName, subjectCode, sessionCode, experimentOptions )
            
            this.project        = project;
            this.subjectCode    = subjectCode;
            this.sessionCode    = sessionCode;
            
            this.experiment = ArumeCore.ExperimentDesign.Create( this, experimentName );
            this.experiment.init(this, experimentOptions);
            
            % to create stand alone sessions that do not belong to a
            % project and don't save data
            if ( ~isempty( this.project) ) 
                
                % Analysis folders
                
                if ( ~exist(fullfile(this.project.dataAnalysisPath,this.name), 'dir') )
                    
                    % fix for backwards compatibility, convert session
                    % folders to full name including experiment
                    oldStyleFolder = fullfile(this.project.dataAnalysisPath,strrep(this.name, [this.experiment.Name '_'],''));
                    newStyleFolder = fullfile(this.project.dataAnalysisPath,this.name);
                    if ( exist(oldStyleFolder, 'dir') )
                        movefile(oldStyleFolder, newStyleFolder);
                    end
                end
                
                this.InitDB( this.project.dataAnalysisPath, this.name );
                
                % Raw data folders
                
                if ( ~exist(fullfile(this.project.dataRawPath,this.name), 'dir') )
                    
                    % fix for backwards compatibility, convert session
                    % folders to full name including experiment
                    oldStyleFolder = fullfile(this.project.dataRawPath,strrep(this.name, [this.experiment.Name '_'],''));
                    newStyleFolder = fullfile(this.project.dataRawPath,this.name);
                    if ( exist(oldStyleFolder, 'dir') )
                        movefile(oldStyleFolder, newStyleFolder);
                    else
                        mkdir( project.dataRawPath, this.name );
                    end
                end
            end
        end
        
        function initExisting( this, project, data )
             
            this.init( project, data.experimentName, data.subjectCode, data.sessionCode, data.experimentOptions );
            
            if (isfield(data, 'currentRun') && ~isempty( data.currentRun ))
                this.currentRun  = ArumeCore.ExperimentRun.LoadRunData( data.currentRun, this.experiment );
            end
            
            if (isfield(data, 'pastRuns') && ~isempty( data.pastRuns ))
                this.pastRuns  = ArumeCore.ExperimentRun.LoadRunDataArray( data.pastRuns, this.experiment );
            end
            
            if (isfield(data, 'comment') && ~isempty( data.comment ))
                this.comment  = data.comment;
            end
        end
        
        function rename( this, subjectCode, sessionCode)
            oldname = this.name;
            this.subjectCode = subjectCode;
            this.sessionCode = sessionCode;
            this.RenameDB( this.name );
            
            if ( ~strcmp(fullfile(this.project.dataRawPath, oldname),  fullfile(this.project.dataRawPath , this.name) ))
                movefile( fullfile(this.project.dataRawPath, oldname), fullfile(this.project.dataRawPath , this.name));
            end
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
            
            data.experimentName     = this.experiment.Name;
            data.subjectCode        = this.subjectCode;
            data.sessionCode        = this.sessionCode;
            data.comment        = this.comment;
            data.experimentOptions  = this.experiment.ExperimentOptions;
            
            if (~isempty( this.currentRun ))
                data.currentRun = ArumeCore.ExperimentRun.SaveRunData(this.currentRun);
                data.pastRuns = ArumeCore.ExperimentRun.SaveRunDataArray(this.pastRuns);
            else
                data.currentRun = [];
                data.pastRuns = [];
            end
        end
        
        function updateComment( this, comment)
            this.comment = comment;
        end
        
        function updateExperimentOptions( this, newExperimentOptions)
            
            if ( ~this.isStarted )
                this.init( this.project, this.experiment.Name, this.subjectCode, this.sessionCode, newExperimentOptions );
            else
                error('This is session is already started, cannot change settings.');
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
            this.currentRun = ArumeCore.ExperimentRun.SetUpNewRun( this.experiment );
            
            % Start the experiment
            this.experiment.run();
        end
        
        function simulate( this )
            
            % Set up the new run: trial sequence, etc ...
            this.currentRun = ArumeCore.ExperimentRun.SetUpNewRun( this.experiment );
            
            % Start the experiment
            this.experiment.runSimulation();
        end
        
        function resume( this )
            
            if ( this.isFinished )
                error( 'This is session is finished it cannot be run' )
            end
            
            % Save the status of the current run in  the past runs, useful
            % to restart from a past point
            if ( isempty( this.pastRuns) )
                this.pastRuns = this.currentRun.Copy();
            else
                this.pastRuns( length(this.pastRuns) + 1 ) = this.currentRun;
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
            if ( isempty( this.pastRuns) )
                this.pastRuns    = this.currentRun.Copy();
            else
                this.pastRuns( length(this.pastRuns) + 1 ) = this.currentRun;
            end
            
            % Set up the new run: trial sequence, etc ...
            this.currentRun = ArumeCore.ExperimentRun.SetUpNewRun( this.experiment );
            
            % Start the experiment
            this.experiment.run();
        end
        
        %
        %% ANALYSIS METHODS
        %
        function prepareForAnalysis( this )
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            if ( isempty( this.currentRun) )
                return;
            end
            
            ds = dataset;
            ds.TrialNumber = (1:length(this.currentRun.pastConditions(:,1)))';
            ds.ConditionNumber = this.currentRun.pastConditions(:,Enum.pastConditions.condition);
            ds.TrialResult = this.currentRun.pastConditions(:,Enum.pastConditions.trialResult);
            ds.BlockNumber = this.currentRun.pastConditions(:,Enum.pastConditions.blocknumber);
            ds.BlockID = this.currentRun.pastConditions(:,Enum.pastConditions.blockid);
            ds.Session = this.currentRun.pastConditions(:,Enum.pastConditions.session);

            % find all the possible output variables
            outputVars = {};
            for i=1:length(this.currentRun.Data)
                if ( isfield( this.currentRun.Data{i}, 'trialOutput' ) && ~isempty( this.currentRun.Data{i}.trialOutput ) )
                    fields = fieldnames(this.currentRun.Data{i}.trialOutput);
                    outputVars = union(outputVars,fields);
                end
            end
            
            % collect the actual values
            output = [];
            for i=1:length(this.currentRun.Data)
                for j=1:length(outputVars)
                    field = outputVars{j};
                    if ( isfield( this.currentRun.Data{i}, 'trialOutput' ) && isfield( this.currentRun.Data{i}.trialOutput, field))
                        if ( isempty(output) || ~isfield(output, field) )
                            output.(field) = this.currentRun.Data{i}.trialOutput.(field);
                        else
                            output.(field)(i) = this.currentRun.Data{i}.trialOutput.(field);
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
            for i=1:length(this.currentRun.Data)
                if ( ~isempty( this.currentRun.Data{i}.variables ) )
                    fields = fieldnames(this.currentRun.Data{i}.variables);
                    trialVars = union(trialVars,fields);
                end
            end
            
            
            % collect the actual values
            var = [];
            for i=1:length(this.currentRun.Data)
                for j=1:length(trialVars)
                    field = trialVars{j};
                    if isfield( this.currentRun.Data{i}.variables, field)
                        if ( isempty(var) || ~isfield(var, field) )
                            var.(field) = {this.currentRun.Data{i}.variables.(field)};
                        else
                            var.(field){i} = this.currentRun.Data{i}.variables.(field);
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
        
        %
        % Factory methods
        %
        function session = NewSession( project, experimentName, subjectCode, sessionCode, experimentOptions )
            % TODO add factory for multiple types of experimentNames
            session = ArumeCore.Session();
            session.init(project, experimentName, subjectCode, sessionCode, experimentOptions);
        end
        
        function session = LoadSession( project, data )
            % TODO add factory for multiple types of experimentNames
            
            session = ArumeCore.Session();
            
            session.initExisting( project, data );
        end
        
        function session = CopySession( sourceSession, newSubjectCode, newSessionCode)
            data = sourceSession.save();
            
            newData = [];
            
            newData.subjectCode = newSubjectCode;
            newData.sessionCode = newSessionCode;
            newData.experimentName = data.experimentName;
            newData.experimentOptions = data.experimentOptions;
            
            session = ArumeCore.Session();
            session.initExisting( sourceSession.project, newData );
        end
    end
    
    
    
   
    
    
end

