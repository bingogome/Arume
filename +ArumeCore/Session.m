classdef Session < ArumeCore.DataDB
    %SESSION Encapsulates an experimental session
    %  links to the corresponding experiment design and contains all the
    %  data obtained when running the experiment or analyzing it.
    
    properties( SetAccess = private)
        experimentDesign        % Experiment design object associated with this session
        
        subjectCode = '000';    % Subject code for this session, for xample S01_BC
        sessionCode = 'Z';      % Session code
        sessionIDNumber = 0;    % Internal arume sessionIDnumber. To link with the UI.
        comment  	= '';       % Comment about the session
        
        currentRun  = [];       % current data for this session
        pastRuns    = [];       % data from every time experiment was started, resumed, or restarted
        
        dataPath    = [];       % path of the folder containing the session files
    end
    
    %% dependent properties... see the related get.property method
    properties ( Dependent = true )
        
        name
        isStarted
        isFinished
        
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
        
        % Single row data table that will be used to create a multisession
        % table
        sessionDataTable
        
        % DataTable with all the events data
        % 
        % Different experiments can load different columns.
        % Each experiment has to take care of preparing the dataset
        %
        % Basic type of events will be Saccades, blinks, slow phases
        %
        analysisResults
        
    end
    
    %
    %% Methods for dependent variables
    methods
        
        function name = get.name(this)
            name = [this.experimentDesign.Name '__' this.subjectCode '__' this.sessionCode];
        end
        
        function result = get.isStarted(this)
            result = ~isempty( this.currentRun );
        end
        
        function result = get.isFinished(this)
            result = ~isempty( this.currentRun ) && isempty(this.currentRun.futureTrialTable);
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
        
        function sessionDataTable = get.sessionDataTable(this)
            sessionDataTable = this.ReadVariable('sessionDataTable');
        end
        
        function analysisResults = get.analysisResults(this)
            d = struct2table(dir(fullfile(this.dataPath,'AnalysisResults_*')));
            analysisResults = [];
            for i=1:height(d)
                res = regexp(d.name,'^AnalysisResults_(?<name>[_a-zA-Z0-9]+)\.mat$','names');
                varName = res.name;
                analysisResults.(varName) = this.ReadVariable(['AnalysisResults_' varName]);
            end
        end
        
    end
    
    methods (Static)
        function newNumber = GetNewSessionNumber()
            persistent number;
            if isempty(number)
                number = 0;
                a = Arume();
                if( ~isempty( a.currentProject ) )
                    for i=1:length(a.currentProject.sessions)
                        number = max(number, a.currentProject.sessions(i).sessionIDNumber);
                    end
                end
            end
            number = number+1;
            
            newNumber = number;
        end
    end
    
    %% Main Session methods
    methods
        
        function this = Session()
            this.sessionIDNumber    = ArumeCore.Session.GetNewSessionNumber();
        end
        
        %
        % INIT METHODS
        %
        function init( this, projectPath, experimentName, subjectCode, sessionCode, experimentOptions )
            
            this.subjectCode        = subjectCode;
            this.sessionCode        = sessionCode;
            
            this.experimentDesign = ArumeCore.ExperimentDesign.Create( experimentName );
            this.experimentDesign.init(this, experimentOptions);
            
            % to create stand alone sessions that do not belong to a
            % project and don't save data
            if ( ~isempty( projectPath ) ) 
                this.dataPath  = fullfile(projectPath, this.name);
                this.InitDB( this.dataPath );
            end
        end
        
        function initExisting( this, sessionPath )
             
            [projectPath,sessionName] = fileparts(sessionPath);        
            parts = split(sessionName,'__');
            newExperimentName   = parts{1};
            newSubjectCode      = parts{2};
            newSessionCode      = parts{3};
            filename = fullfile( sessionPath, 'ArumeSession.mat');
            
            sessionData = load( filename, 'sessionData' );
            data = sessionData.sessionData;  
            this.init( projectPath, newExperimentName, newSubjectCode, newSessionCode, data.experimentOptions );
            
            if (isfield(data, 'currentRun') && ~isempty( data.currentRun ))
                this.currentRun  = ArumeCore.ExperimentRun.LoadRunData( data.currentRun );
            else
                this.currentRun = [];
            end
            
            if (isfield(data, 'pastRuns') && ~isempty( data.pastRuns ))
                this.pastRuns  = ArumeCore.ExperimentRun.LoadRunDataArray( data.pastRuns );
            else
                this.pastRuns = [];
            end
            
            if (isfield(data, 'comment') && ~isempty( data.comment ))
                this.comment  = data.comment;
            else
                this.comment  = '';
            end
        end
        
        function rename( this, newSubjectCode, newSessionCode)
            oldpath = this.dataPath;
            projectPath = fileparts(oldpath);        
            this.subjectCode = newSubjectCode;
            this.sessionCode = newSessionCode;
            newPath = fullfile(projectPath, this.name);
            
            if ( ~strcmp(oldpath, newPath ))
                movefile(oldpath, newPath);
            end
            
            this.initExisting(newPath);
        end
        
        function deleteFolders( this )
            if ( exist(this.dataPath, 'dir') )
                rmdir(this.dataPath,'s');
            end
        end
        
        function sessionData = save( this )
            sessionData = [];
            
            sessionData.comment            = this.comment;
            sessionData.experimentOptions  = this.experimentDesign.ExperimentOptions;
            
            if (~isempty( this.currentRun ))
                sessionData.currentRun = ArumeCore.ExperimentRun.SaveRunData(this.currentRun);
                sessionData.pastRuns = ArumeCore.ExperimentRun.SaveRunDataArray(this.pastRuns);
            else
                sessionData.currentRun = [];
                sessionData.pastRuns = [];
            end
            
            filename = fullfile( this.dataPath, 'ArumeSession.mat');
            save( filename, 'sessionData' );
        end
        
        function session = copy( this, newSubjectCode, newSessionCode)
            projectFolder = fileparts(this.dataPath);
            newSessionName = [this.experimentDesign.Name '__' newSubjectCode '__' newSessionCode];
            newSessionDataPath = fullfile(projectFolder, newSessionName);
            if ( exist( newSessionDataPath, 'dir') )
                error( 'There is already a session in the current project with the same name.');
            end
            
            sessionData = [];
            sessionData.experimentOptions = this.experimentDesign.ExperimentOptions;
            sessionData.currentRun = [];
            sessionData.pastRuns = [];
            
            mkdir(newSessionDataPath);
            filename = fullfile( newSessionDataPath, 'ArumeSession.mat');
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
                this.experimentDesign = ArumeCore.ExperimentDesign.Create( this.experimentDesign.Name );
                this.experimentDesign.init(this, newExperimentOptions);
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
            this.experimentDesign.ImportSession();
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
            this.currentRun = ArumeCore.ExperimentRun.SetUpNewRun( this.experimentDesign );
            
            % Start the experiment
            this.experimentDesign.run();
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
            this.experimentDesign.run();
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
            this.experimentDesign.run();
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
            this.currentRun = ArumeCore.ExperimentRun.SetUpNewRun( this.experimentDesign );
            
            % Start the experiment
            this.experimentDesign.run();
        end
    end
    
    %
    %% ANALYSIS METHODS
    methods
        function prepareForAnalysis( this )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            if ( isempty(  this.currentRun ) )
                return;
            end
            
            %% 0) Create the basic trial dataaset (without custom experiment stuff)
            trials = this.currentRun.pastTrialTable;
            % remove errors and aborts for analysis
            if (~isempty(trials))
                    % just in case for old data
                if ( ~iscategorical(trials.TrialResult) )
                    trials.TrialResult = Enum.trialResult.PossibleResults(trials.TrialResult+1);
                end
                if ( ~any(strcmp(trials.Properties.VariableNames,'TrialNumber')) )
                    tn = cumsum(trials.TrialResult ~= Enum.trialResult.CORRECT)+1;
                    trials.TrialNumber = [1 tn(1:end-1)];
                end
                trials(trials.TrialResult ~= Enum.trialResult.CORRECT ,:) = [];
            end
            this.WriteVariable(trials,'trialDataTable');
            
            %% 1) Prepare the sample dataset
            [samples, rawData] = this.experimentDesign.PrepareSamplesDataTable(options);
            
            if ( ~isempty(samples) )
                this.WriteVariable(samples,'samplesDataTable');
            end
            
            if ( ~isempty(rawData) )
                this.WriteVariable(rawData,'rawDataTable');
            end
            
            %% 2) Prepare the trial dataset
            trials = this.experimentDesign.PrepareTrialDataTable(trials,options);
            if ( ~isempty(trials) )
                this.WriteVariable(trials,'trialDataTable');
            end
            
            %% 3) Prepare session dataTable
            newSessionDataTable = this.GetBasicSessionDataTable();
            newSessionDataTable = this.experimentDesign.PrepareSessionDataTable(newSessionDataTable,options);
            if ( ~isempty(newSessionDataTable) )
                this.WriteVariable(newSessionDataTable,'sessionDataTable');
            end
        end
        
        function runAnalysis(this, options)
            
            %% 1) Prepare events datasets
            results = [];
            samplesIn = this.samplesDataTable;
            trialsIn = this.trialDataTable;
            [results, samples, trials]  = this.experimentDesign.RunDataAnalyses(results, samplesIn, trialsIn, options);
        
            if ( ~isempty(results) )
                if ( isstruct(results))
                    fields = fieldnames(results);
                    for i=1:length(fields)
                        result = results.(fields{i});
                        this.WriteVariable(result,['AnalysisResults_' fields{i}]);
                    end
                else
                    this.WriteVariable(results,'AnalysisResults');
                end
            end
            if ( ~isempty(samples) )
                this.WriteVariable(samples,'samplesDataTable');
            end
            if ( ~isempty(trials) )
                this.WriteVariable(trials,'trialDataTable');
            end
            
            %% 2) Prepare session dataTable
            newSessionDataTable = this.GetBasicSessionDataTable();
            newSessionDataTable = this.experimentDesign.PrepareSessionDataTable(newSessionDataTable);
            if ( ~isempty(newSessionDataTable) )
                this.WriteVariable(newSessionDataTable,'sessionDataTable');
            end
        end
                
        function newSessionDataTable = GetBasicSessionDataTable(this)
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            try 
                newSessionDataTable = table();
                newSessionDataTable.Subject = categorical(cellstr(this.subjectCode));
                newSessionDataTable.SessionCode = categorical(cellstr(this.sessionCode));
                newSessionDataTable.Experiment = categorical(cellstr(this.experimentDesign.Name));
                
                NoYes = {'No' 'Yes'};
                newSessionDataTable.Started = categorical(NoYes(this.isStarted+1));
                newSessionDataTable.Finished = categorical(NoYes(this.isFinished+1));
                if (~isempty(this.currentRun) && ~isempty(this.currentRun.pastTrialTable)...
                        && any(strcmp(this.currentRun.pastTrialTable.Properties.VariableNames,'DateTimeTrialStart'))...
                        && ~isempty(this.currentRun.pastTrialTable.DateTimeTrialStart(1,:)))
                    newSessionDataTable.TimeFirstTrial = string(this.currentRun.pastTrialTable.DateTimeTrialStart(1,:));
                else
                    newSessionDataTable.TimeFirstTrial = "-";
                end
                if (~isempty(this.currentRun) && ~isempty(this.currentRun.pastTrialTable)...
                        && any(strcmp(this.currentRun.pastTrialTable.Properties.VariableNames,'DateTimeTrialStart'))...
                        && ~isempty(this.currentRun.pastTrialTable.DateTimeTrialStart(end,:)))
                    newSessionDataTable.TimeLastTrial = string(this.currentRun.pastTrialTable.DateTimeTrialStart(end,:));
                else
                    newSessionDataTable.TimeLastTrial = "-";
                end
                if (~isempty(this.currentRun))
                    newSessionDataTable.NumberOfTrialsCompleted = 0;
                    newSessionDataTable.NumberOfTrialsAborted = 0;
                    newSessionDataTable.NumberOfTrialsPending = 0;
                    
                    if ( ~isempty(this.currentRun.pastTrialTable) )
                        if ( iscategorical(this.currentRun.pastTrialTable.TrialResult) )
                            newSessionDataTable.NumberOfTrialsCompleted = sum(this.currentRun.pastTrialTable.TrialResult == Enum.trialResult.CORRECT);
                            newSessionDataTable.NumberOfTrialsAborted   = sum(this.currentRun.pastTrialTable.TrialResult ~= Enum.trialResult.CORRECT);
                        end
                    end
                    
                    if ( ~isempty(this.currentRun.futureTrialTable) )
                        newSessionDataTable.NumberOfTrialsPending   = height(this.currentRun.futureTrialTable);
                    end
                end
                
                opts = fieldnames(this.experimentDesign.ExperimentOptions);
                s = this.experimentDesign.GetExperimentOptionsDialog(1);
                for i=1:length(opts)
                    if ( ~ischar( this.experimentDesign.ExperimentOptions.(opts{i})) && numel(this.experimentDesign.ExperimentOptions.(opts{i})) <= 1)
                        newSessionDataTable.(['Option_' opts{i}]) = this.experimentDesign.ExperimentOptions.(opts{i});
                    elseif (isfield( s, opts{i}) && iscell(s.(opts{i})) && iscell(s.(opts{i}){1}) && length(s.(opts{i}){1}) >1)
                        newSessionDataTable.(['Option_' opts{i}]) = categorical(cellstr(this.experimentDesign.ExperimentOptions.(opts{i})));
                    elseif (~ischar(this.experimentDesign.ExperimentOptions.(opts{i})) && numel(this.experimentDesign.ExperimentOptions.(opts{i})) > 1 )
                        newSessionDataTable.(['Option_' opts{i}]) = {this.experimentDesign.ExperimentOptions.(opts{i})};
                    else
                        newSessionDataTable.(['Option_' opts{i}]) = string(this.experimentDesign.ExperimentOptions.(opts{i}));
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
            
            if ( ~exist( 'experimentOptions', 'var') || isempty(experimentOptions) )
                exp = ArumeCore.ExperimentDesign.Create( experimentName );
                experimentOptions = exp.GetExperimentOptionsDialog( );
                if ( ~isempty( experimentOptions) )
                    experimentOptions = StructDlg(experimentOptions,'',[],[],'off');
                end
            end
                    
            session.init(projectPath, experimentName, subjectCode, sessionCode, experimentOptions);
        end
        
        function session = LoadSession( sessionPath )
            
            filename = fullfile( sessionPath, 'ArumeSession.mat');
            if  (~exist(filename,'file') )
                session = [];
                return 
            end
            
            session = ArumeCore.Session();
            session.initExisting( sessionPath );
            disp(['Loaded session ' session.name]);
        end
        
        
        %
        % Other methods
        %
        function result = IsValidSubjectCode( name )
            result = ~isempty(regexp(name,'^[_a-zA-Z0-9]+$','ONCE') );
            result = result && ~contains(name,'__');
        end
        
        %
        % Other methods
        %
        function result = IsValidSessionCode( name )
            result = ~isempty(regexp(name,'^[_a-zA-Z0-9]+$','ONCE') );
            result = result && ~contains(name,'__');
        end
    end
    
    
    
   
    
    
end

