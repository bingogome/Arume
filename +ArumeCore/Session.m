classdef Session < ArumeCore.DataDB
    %SESSION Encapsulates an experimental session
    %  links to the corresponding experiment design and contains all the
    %  data obtained when running the experiment or analyzing it.
    properties( SetAccess = private)
        experiment
        
        subjectCode = '000';
        sessionCode = 'Z';
        comment = '';
        
        currentRun  = [];
        pastRuns    = [];
        
        dataPath = [];
    end
    
    %% dependent properties... see the related get.property method
    properties ( Dependent = true )
        
        name
        
        isStarted
        isFinished
        
        isReadyForAnalysis
        
    end
    
    %% properties from analysis
    properties( Dependent = true ) % not stored in the object (memory) BIG VARIABLES
        
        % DataTable with all the trial information (one row per trial)
        %
        % Most of is created automatically for all the experiments using the 
        % experiment design and the experiment run information.
        % Each experiment can add extra information in the method prepareTrialDataTable.
        %
        %
        
        trialDataTable
            
        % DataTable with all the sample data (one row per sample) :
        % 
        % Different experiments can load different columns.
        % Each experiment has to take care of preparing the dataset
        %
        samplesDataTable
        rawDataTable
        
        % DataTable with all the events data
        % 
        % Different experiments can load different columns.
        % Each experiment has to take care of preparing the dataset
        %
        % Basic type of events will be Saccades, blinks, slow phases
        %
        eventsDataTable 
        
        % Single row data table that will be used to create a multisession
        % table
        sessionDataTable
    end
    
    %
    %% Methods for dependent variables
    methods
        
        function name = get.name(this)
            name = [this.experiment.Name '_' this.subjectCode this.sessionCode];
        end
        
        function result = get.isStarted(this)
            if ( isempty( this.currentRun ) || isempty(this.currentRun.pastTrialTable) )
                result = 0;
            else
                result = 1;
            end
        end
        
        function result = get.isFinished(this)
            if ( ~isempty( this.currentRun ) && isempty(this.currentRun.futureTrialTable) )
                result = 1;
            else
                result = 0;
            end
        end
        
        function result = get.isReadyForAnalysis(this)
            if ( this.IsVariableInDB( 'trialDataTable' ) )
                result = 1;
            else
                result = 0;
            end
        end
        
        function trialDataTable = get.trialDataTable(this)
            trialDataTable = this.ReadVariable('trialDataTable');
        end
        
        function rawDataTable = get.rawDataTable(this)
            rawDataTable = this.ReadVariable('rawDataTable');
        end
        
        function samplesDataTable = get.samplesDataTable(this)
            samplesDataTable = this.ReadVariable('samplesDataTable');
        end
        
        function eventsDataTable = get.eventsDataTable(this)
            eventsDataTable = this.ReadVariable('eventsDataTable');
        end
        
        function sessionDataTable = get.sessionDataTable(this)
            sessionDataTable = this.ReadVariable('sessionDataTable');
        end
    end
    
    %% Main Session methods
    methods
        %
        % INIT METHODS
        %
        function init( this, projectPath, experimentName, subjectCode, sessionCode, experimentOptions )
            this.subjectCode    = subjectCode;
            this.sessionCode    = sessionCode;
            
            this.experiment = ArumeCore.ExperimentDesign.Create( this, experimentName );
            this.experiment.init(this, experimentOptions);
            this.dataPath  = fullfile(projectPath, this.name);
            
            % to create stand alone sessions that do not belong to a
            % project and don't save data
            if ( ~isempty( projectPath ) ) 
                this.InitDB( projectPath, this.name );
            end
        end
        
        function initExisting( this, sessionPath )
             
            [projectPath,sessionName] = fileparts(sessionPath);
            filename = fullfile( sessionPath, [sessionName '_ArumeSession.mat']);
            
            sessionData = load( filename, 'sessionData' );
            data = sessionData.sessionData;          
            
            this.init( projectPath, data.experimentName, data.subjectCode, data.sessionCode, data.experimentOptions );
            
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
            
            if ( ~strcmp(fullfile(this.projectPath, oldname),  this.dataPath ))
                movefile( fullfile(this.projectPath, oldname), this.dataPath);
            end
        end
        
        function deleteFolders( this )
            if ( exist(this.dataPath, 'dir') )
                rmdir(this.dataPath,'s');
            end
        end
        
        function sessionData = save( this )
            sessionData = [];
            
            sessionData.experimentName     = this.experiment.Name;
            sessionData.subjectCode        = this.subjectCode;
            sessionData.sessionCode        = this.sessionCode;
            sessionData.comment            = this.comment;
            sessionData.experimentOptions  = this.experiment.ExperimentOptions;
            
            if (~isempty( this.currentRun ))
                sessionData.currentRun = ArumeCore.ExperimentRun.SaveRunData(this.currentRun);
                sessionData.pastRuns = ArumeCore.ExperimentRun.SaveRunDataArray(this.pastRuns);
            else
                sessionData.currentRun = [];
                sessionData.pastRuns = [];
            end
            
            filename = fullfile( this.dataPath, [this.name '_ArumeSession.mat']);
            save( filename, 'sessionData' );
        end
        
        function session = copy( this, newSubjectCode, newSessionCode)
            projectFolder = fileparts(this.dataPath);
            newSessionName = [this.experiment.Name '_' newSubjectCode newSessionCode];
            newSessionDataPath = fullfile(projectFolder, newSessionName);
            if ( exist( newSessionDataPath, 'dir') )
                error( 'There is already a session in the current project with the same name.');
            end
            
            mkdir(newSessionDataPath);
            
            sessionData = [];
            
            sessionData.subjectCode = newSubjectCode;
            sessionData.sessionCode = newSessionCode;
            sessionData.experimentName = this.experiment.Name;
            sessionData.experimentOptions = this.experiment.ExperimentOptions;
            sessionData.currentRun = [];
            sessionData.pastRuns = [];
            
            filename = fullfile( newSessionDataPath, [newSessionName '_ArumeSession.mat']);
            save( filename, 'sessionData' );
            
            session = ArumeCore.Session();
            session.initExisting( newSessionDataPath );
        end
        
        function updateComment( this, comment)
            this.comment = comment;
        end
        
        function updateExperimentOptions( this, newExperimentOptions)
            
            if ( ~this.isStarted )
               % re initialize the experiment with the new options 
                this.experiment = ArumeCore.ExperimentDesign.Create( this, this.experiment.Name );
                this.experiment.init(this, newExperimentOptions);
            else
                error('This is session is already started, cannot change settings.');
            end
            
        end
        
        function addFile(this, fileTag, filePath)
            
            [~,fileName, ext] = fileparts(filePath);
            copyfile(filePath, fullfile(this.dataPath, [fileName ext] ));
                
            if ( ~isfield(this.currentRun.LinkedFiles, fileTag) )
                this.currentRun.LinkedFiles.(fileTag) = [fileName ext];
            else
                if ~iscell(this.currentRun.LinkedFiles.(fileTag))
                    this.currentRun.LinkedFiles.(fileTag) = {this.currentRun.LinkedFiles.(fileTag)};
                end
                this.currentRun.LinkedFiles.(fileTag) = cat(1, this.currentRun.LinkedFiles.(fileTag), [fileName ext] );
            end               
        end
        
        function importSession(this)
            this.experiment.ImportSession();
        end

        function importCurrentRun(this, newRun)
            this.currentRun = newRun;
        end
    end
    
    %
    %% RUNING METHODS
    methods
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
        
        function resumeFrom( this, runNumber )
            
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
            
            this.currentRun = this.pastRuns(runNumber).Copy();
            
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
    end
    
    %
    %% ANALYSIS METHODS
    methods
        function prepareForAnalysis( this )
            if ( isempty(  this.currentRun ) )
                return;
            end
            
            SHOULD_DO_TRIALS = 1;
            SHOULD_DO_SAMPLES = 1;
            SHOULD_DO_EVENTS = 0;
            SHOULD_DO_SESSION = 1;
            
            %% 0) Create the basic trial dataaset (without custom experiment stuff)
            newTrialDataTable = this.currentRun.pastTrialTable;
            % remove errors and aborts for analysis
            newTrialDataTable(newTrialDataTable.TrialResult > 0 ,:) = [];
            this.WriteVariable(newTrialDataTable,'trialDataTable');
            
            if (SHOULD_DO_SAMPLES)
                %% 1) Prepare the sample dataset
                [samples, rawData] = this.experiment.PrepareSamplesDataTable();
                
                if ( ~isempty(samples) )
                    this.WriteVariable(samples,'samplesDataTable');
                end
                
                if ( ~isempty(rawData) )
                    this.WriteVariable(rawData,'rawDataSet');
                end
            end

            if (SHOULD_DO_TRIALS)
                %% 2) Prepare the trial dataset
                newTrialDataTable = this.experiment.PrepareTrialDataTable(newTrialDataTable);
                if ( ~isempty(newTrialDataTable) )
                    this.WriteVariable(newTrialDataTable,'trialDataTable');
                end
            end

            if (SHOULD_DO_EVENTS)
                %% 3) Prepare events datasets
                events = this.experiment.PrepareEventDataSet([]);
                if ( ~isempty(events) )
                    this.WriteVariable(events,'eventsDataTable');
                end
            end
            
            if (SHOULD_DO_SESSION)
                %% 4) Prepare session dataTable
                newSessionDataTable = this.GetBasicSessionDataTable();
                newSessionDataTable = this.experiment.PrepareSessionDataTable(newSessionDataTable);
                if ( ~isempty(newSessionDataTable) )
                    this.WriteVariable(newSessionDataTable,'sessionDataTable');
                end
            end
        end
                
        function newSessionDataTable = GetBasicSessionDataTable(this)
            
            try 
                newSessionDataTable = table();
                newSessionDataTable.Subject = categorical(cellstr(this.subjectCode));
                newSessionDataTable.SessionCode = categorical(cellstr(this.sessionCode));
                newSessionDataTable.Experiment = categorical(cellstr(this.experiment.Name));
                
                NoYes = {'No' 'Yes'};
                newSessionDataTable.Started = categorical(NoYes(this.isStarted+1));
                newSessionDataTable.Finished = categorical(NoYes(this.isFinished+1));
                if (~isempty(this.currentRun) && ~isempty(this.currentRun.pastTrialTable) && any(strcmp(this.currentRun.pastTrialTable.Properties.VariableNames,'DateTimeTrialStart')))
                    newSessionDataTable.TimeFirstTrial = string(this.currentRun.pastTrialTable.DateTimeTrialStart(1,:));
                    newSessionDataTable.TimeLastTrial = string(this.currentRun.pastTrialTable.DateTimeTrialStart(end,:));
                else
                    newSessionDataTable.TimeLastTrial = string('-');
                    newSessionDataTable.TimeFirstTrial = string('-');
                end
                if (~isempty(this.currentRun))
                    newSessionDataTable.NumberOfTrialsCompleted = 0;
                    newSessionDataTable.NumberOfTrialsAborted = 0;
                    newSessionDataTable.NumberOfTrialsPending = 0;
                    
                    if ( ~isempty(this.currentRun.pastTrialTable) )
                        newSessionDataTable.NumberOfTrialsCompleted = sum(this.currentRun.pastTrialTable.TrialResult == 0);
                        newSessionDataTable.NumberOfTrialsAborted   = sum(this.currentRun.pastTrialTable.TrialResult ~= 0);
                    end
                    
                    if ( ~isempty(this.currentRun.futureTrialTable) )
                        newSessionDataTable.NumberOfTrialsPending   = height(this.currentRun.futureTrialTable);
                    end
                end
                
                opts = fieldnames(this.experiment.ExperimentOptions);
                s = this.experiment.GetExperimentOptionsDialog(1);
                for i=1:length(opts)
                    if ( ~ischar( this.experiment.ExperimentOptions.(opts{i})) )
                        newSessionDataTable.(['Option_' opts{i}]) = this.experiment.ExperimentOptions.(opts{i});
                    elseif (isfield( s, opts{i}) && iscell(s.(opts{i})) && iscell(s.(opts{i}){1}) && length(s.(opts{i}){1}) >1)
                        newSessionDataTable.(['Option_' opts{i}]) = categorical(cellstr(this.experiment.ExperimentOptions.(opts{i})));
                    else
                        newSessionDataTable.(['Option_' opts{i}]) = string(this.experiment.ExperimentOptions.(opts{i}));
                    end
                end
            catch ex
                ex.getReport
            end
        end
    end
    
    %% SESSION FACTORY METHODS
    methods (Static = true )
        
        function session = NewSession( projectPath, experimentName, subjectCode, sessionCode, experimentOptions )
            session = ArumeCore.Session();
            session.init(projectPath, experimentName, subjectCode, sessionCode, experimentOptions);
        end
        
        function session = LoadSession( sessionPath )
            
            [~,sessionName] = fileparts(sessionPath);
            filename = fullfile( sessionPath, [sessionName '_ArumeSession.mat']);
            if  (~exist(filename,'file') )
                session = [];
                return 
            end
            
            session = ArumeCore.Session();
            session.initExisting( sessionPath );
        end
        
        
        %
        % Other methods
        %
        function result = IsValidSubjectCode( name )
            result = ~isempty(regexp(name,'^[_a-zA-Z0-9]+$','ONCE') );
        end
        
        %
        % Other methods
        %
        function result = IsValidSessionCode( name )
            result = ~isempty(regexp(name,'^[_a-zA-Z0-9]+$','ONCE') );
        end
    end
    
    
    
   
    
    
end

