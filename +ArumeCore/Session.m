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
        
        dataPath
    end
    
    %% properties from analysis
    properties( Dependent = true ) % not stored in the object (memory) BIG VARIABLES
        
        % Dataset with all the trial information (one row per trial)
        %
        % Most of is created automatically for all the experiments using the 
        % experiment design and the experiment run information.
        % Each experiment can add extra information in the method prepareTrialDataSet.
        %
        %
        
        trialDataSet
            
        % Dataset with all the sample data (one row per sample) :
        % 
        % Different experiments can load different columns.
        % Each experiment has to take care of preparing the dataset
        %
        rawDataSet
        samplesDataSet
        
        % Dataset with all the events data
        % 
        % Different experiments can load different columns.
        % Each experiment has to take care of preparing the dataset
        %
        % Basic type of events will be Saccades, blinks, slow phases
        %
        eventsDataSet
        
        % Results of the experiment specific analysis
        analysisResults 
        
        % single row data table that will be used to create a multisession
        % table
        sessionDataTable
    end
    
    %
    % Methods for dependent variables
    %
    methods
        
        function name = get.name(this)
            name = [this.experiment.Name '_' this.subjectCode this.sessionCode];
        end
        
        function name = get.dataPath(this)
            name = fullfile( this.project.path, this.name);
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
        
        function rawDataSet = get.rawDataSet(this)
            rawDataSet = this.ReadVariable('rawDataSet');
        end
        
        function samplesDataSet = get.samplesDataSet(this)
            samplesDataSet = this.ReadVariable('samplesDataSet');
        end
        
        function eventsDataSet = get.eventsDataSet(this)
            eventsDataSet = this.ReadVariable('eventsDataSet');
        end
        
        function analysisResults = get.analysisResults(this)
            analysisList = {};
            methodList = meta.class.fromName(class(this.experiment)).MethodList;
            for i=1:length(methodList)
                if ( strfind( methodList(i).Name, 'Analysis_') )
                    analysisList{end+1} = strrep( methodList(i).Name, 'Analysis_' ,'');
                end
            end
            analysisResults = [];
            for i=1:length(analysisList)
                var = this.ReadVariable(analysisList{i});
                if ( ~isempty(var) )
                    analysisResults.(analysisList{i}) = var;
                end
            end
        end
        
        function sessionDataTable = get.sessionDataTable(this)
            sessionDataTable = this.ReadVariable('sessionDataTable');
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
                this.InitDB( this.project.path, this.name );
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
            
            if ( ~strcmp(fullfile(this.project.path, oldname),  fullfile(this.project.path , this.name) ))
                movefile( fullfile(this.project.path, oldname), fullfile(this.project.path , this.name));
            end
        end
        
        function deleteFolders( this )
            if ( exist(this.dataPath, 'dir') )
                rmdir(this.dataPath,'s');
            end
        end
        
        function importData( this, trialDataSet, samplesDataSet )
            this.WriteVariable(trialDataSet,'trialDataSet');
            this.WriteVariable(samplesDataSet,'samplesDataSet');
        end
        
        function importSampleData(this, sampleDataSet)
            this.WriteVariable(samplesDataSet,'samplesDataSet');
        end
        
        function data = save( this )
            data = [];
            
            data.experimentName     = this.experiment.Name;
            data.subjectCode        = this.subjectCode;
            data.sessionCode        = this.sessionCode;
            data.comment            = this.comment;
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
        
        function addFile(this, fileTag, filePath)
            
            [~,fileName, ext] = fileparts(filePath);
            copyfile(filePath, fullfile(this.dataRawPath, [fileName ext] ));
                
            if ( ~isfield(this.currentRun.LinkedFiles, fileTag) )
                this.currentRun.LinkedFiles.(fileTag) = [fileName ext];
            else
                if ~iscell(this.currentRun.LinkedFiles.(fileTag))
                    this.currentRun.LinkedFiles.(fileTag) = {this.currentRun.LinkedFiles.(fileTag)};
                end
                this.currentRun.LinkedFiles.(fileTag) = cat(1, this.currentRun.LinkedFiles.(fileTag), [fileName ext] );
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
            
            %% 0) Create the basic trial dataaset (without custom experiment stuff)
            newTrialsDataTable = this.GetBasicTrialsDataTable();
            if ( ~isempty(newTrialsDataTable) )
                this.WriteVariable(newTrialsDataTable,'trialDataSet');
            end
            
            %% 1) Prepare the sample dataset
            [samples, rawData] = this.experiment.PrepareSamplesDataSet(table());
            
            if ( ~isempty(samples) )
                this.WriteVariable(samples,'samplesDataSet');
            end
            
            if ( ~isempty(rawData) )
                this.WriteVariable(rawData,'rawDataSet');
            end
            
            %% 2) Prepare the trial dataset
            newTrialsDataTable = this.experiment.PrepareTrialDataSet(newTrialsDataTable);
            if ( ~isempty(newTrialsDataTable) )
                this.WriteVariable(newTrialsDataTable,'trialDataSet');
            end
            
            %% 3) Prepare events datasets
            events = this.experiment.PrepareTrialDataSet([]);
            if ( ~isempty(events) )
                this.WriteVariable(events,'eventsDataSet');
            end
            
            %% 4) Prepare session dataTable
            newSessionDataTable = this.GetBasicSessionDataTable();
            newSessionDataTable = this.experiment.PrepareSessionDataTable(newSessionDataTable);
            if ( ~isempty(newSessionDataTable) )
                this.WriteVariable(newSessionDataTable,'sessionDataTable');
            end
        end
        
        function newTrialsDataTable = GetBasicTrialsDataTable(this)
             Enum = ArumeCore.ExperimentDesign.getEnum();
            
            trials = dataset;
            if ( ~isempty( this.currentRun) )
                
                trials.TrialNumber = (1:length(this.currentRun.pastConditions(:,1)))';
                trials.ConditionNumber = this.currentRun.pastConditions(:,Enum.pastConditions.condition);
                trials.TrialResult = this.currentRun.pastConditions(:,Enum.pastConditions.trialResult);
                trials.BlockNumber = this.currentRun.pastConditions(:,Enum.pastConditions.blocknumber);
                trials.BlockID = this.currentRun.pastConditions(:,Enum.pastConditions.blockid);
                trials.Session = this.currentRun.pastConditions(:,Enum.pastConditions.session);
                
                trials.TimeStartTrial = this.currentRun.Events(this.currentRun.Events(:,3)==Enum.Events.TRIAL_START,1);
                trials.TimeStopTrial = this.currentRun.Events(this.currentRun.Events(:,3)==Enum.Events.TRIAL_STOP,1);
                
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
                            trials.(field)  = var.(field)';
                        else
                            trials.(field)  = cell2mat(var.(field)');
                        end
                    end
                end
            else
                trials = dataset();
            end
            newTrialsDataTable = trials;
        end
        
        function newSessionDataTable = GetBasicSessionDataTable(this)
            
            newSessionDataTable = table();
            newSessionDataTable.Subject = categorical(cellstr(this.subjectCode));
            newSessionDataTable.SessionCode = categorical(cellstr(this.sessionCode));
            newSessionDataTable.Experiment = categorical(cellstr(this.experiment.Name));
            
            NoYes = {'No' 'Yes'};
            newSessionDataTable.Started = NoYes{this.isStarted+1};
            newSessionDataTable.Finished = NoYes{this.isFinished+1};
            if (~isempty(this.currentRun) && ~isempty(this.currentRun.Events))
                newSessionDataTable.TimeFirstTrial = datestr(this.currentRun.Events(1,2));
                newSessionDataTable.TimeLastTrial = datestr(this.currentRun.Events(end,2));
            else
                newSessionDataTable.TimeLastTrial = '-';
                newSessionDataTable.TimeFirstTrial = '-';
            end
            if (~isempty(this.currentRun) && ~isempty(this.currentRun.pastConditions) && ~isempty(this.currentRun.futureConditions))
                newSessionDataTable.NumberOfTrialsCompleted = sum(this.currentRun.pastConditions(:,2)==0);
                newSessionDataTable.NumberOfTrialsAborted   = sum(this.currentRun.pastConditions(:,2)~=0);
                newSessionDataTable.NumberOfTrialsPending   = length(this.currentRun.futureConditions(:,1));
            end
            
            opts = fieldnames(this.experiment.ExperimentOptions);
            for i=1:length(opts)
                newSessionDataTable.(['Option_' opts{i}]) = this.experiment.ExperimentOptions.(opts{i});
            end
        end
    end
    
    methods (Static = true )
        
        %
        % Factory methods
        %
        function session = NewSession( project, experimentName, subjectCode, sessionCode, experimentOptions )
            
            session = project.findSession( experimentName, subjectCode, sessionCode);
            
            if ( isempty(session) )
                
                % TODO add factory for multiple types of experimentNames
                session = ArumeCore.Session();
                session.init(project, experimentName, subjectCode, sessionCode, experimentOptions);
                project.addSession(session);
            else
                warning('Session already exists ... overriding');
                session.init(project, experimentName, subjectCode, sessionCode, experimentOptions);
            end
        end
        
        function session = LoadSession( project, data )
            % TODO add factory for multiple types of experimentNames
            
            session = ArumeCore.Session();
            session.initExisting( project, data );
            project.addSession(session);
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
            sourceSession.project.addSession(session);
            
            % JORGE 4/25/2018 Decided to not copy data because it was being
            % too confusing.
%             if ( length(dir(sourceSession.dataAnalysisPath)) > 2 )
%                 copyfile(fullfile(sourceSession.dataAnalysisPath,'*'),fullfile(session.dataAnalysisPath));
%             end
%             if ( length(dir(sourceSession.dataRawPath)) > 2 )
%                 copyfile(fullfile(sourceSession.dataRawPath,'*'),fullfile(session.dataRawPath));
%             end
        end
        
        function session = CopySessionToDifferentProject( sourceSession, destinationProject, newSubjectCode, newSessionCode)
            data = sourceSession.save();
            
            newData = data;
            
            newData.subjectCode = newSubjectCode;
            newData.sessionCode = newSessionCode;
            
            session = ArumeCore.Session();
            session.initExisting( destinationProject, newData );
            
            destinationProject.addSession(session);
            
            if ( length(dir(sourceSession.dataPath)) > 2 )
                copyfile(fullfile(sourceSession.dataPath,'*'),fullfile(session.dataPath));
            end
        end
    end
    
    
    
   
    
    
end

