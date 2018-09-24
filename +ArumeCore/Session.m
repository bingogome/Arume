classdef Session < ArumeCore.DataDB
    %SESSION Encapsulates an experimental session
    %  links to the corresponding experiment design and contains all the
    %  data obtained when running the experiment or analyzing it.
    
    properties( SetAccess = private)
        experimentDesign            % Experiment design object associated with this session
        
        subjectCode = '000';        % Subject code for this session. Good 
                                    % practice is to combine a unique serial 
                                    % number for a guiven project with initials 
                                    % of subject (or coded initials). 
                                    % For example: S03_JO
        
        sessionCode = 'Z';          % Session code. Good practice is to use 
                                    % a letter to indicate order of sessions 
                                    % and after an underscore some indication 
                                    % of what the session is about.
                                    % For example: A_LeftTilt
        
        sessionIDNumber = 0;        % Internal arume sessionIDnumber. To  
                                    % link with the UI. It will not be 
                                    % permanentely unique. Just while the 
                                    % project is open. The IDs are given to
                                    % sessions when the project starts.
                                    
        comment         = '';       % Comment about the session. All notes 
                                    % related to the session. They can easily 
                                    % be edited int he Arume UI.
        
        currentRun      = [];       % current data for this session
        
        pastRuns        = [];       % data from every time experiment was started, resumed, or restarted
        
        dataPath        = [];       % path of the folder containing the session files
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
        % table within the project
        sessionDataTable
        
        % Struct with all the output of analyses
        analysisResults
        
    end
    
    %
    %% Methods for dependent variables
    methods
        
        function name = get.name(this)
            name = ArumeCore.Session.SessionPartsToName(this.experimentDesign.Name, this.subjectCode, this.sessionCode);
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
            d = struct2table(dir(fullfile(this.dataPath,'AnalysisResults_*')),'asarray',1);
            analysisResults = [];
            for i=1:height(d)
                res = regexp(d.name{i},'^AnalysisResults_(?<name>[_a-zA-Z0-9]+)\.mat$','names');
                varName = res.name;
                analysisResults.(varName) = this.ReadVariable(['AnalysisResults_' varName]);
            end
        end
        
    end
    
    %% Main Session methods
    methods
        function init( this, projectPath, experimentName, subjectCode, sessionCode, experimentOptions )
            
            this.subjectCode        = subjectCode;
            this.sessionCode        = sessionCode;
            this.sessionIDNumber    = ArumeCore.Session.GetNewSessionNumber();
            this.experimentDesign   = ArumeCore.ExperimentDesign.Create( experimentName );
            this.experimentDesign.init(this, experimentOptions);
            
            % to create stand alone sessions that do not belong to a
            % project and don't save data
            if ( ~isempty( projectPath ) ) 
                this.dataPath  = fullfile(projectPath, this.name);
                this.InitDB( this.dataPath );
            end
        end
                
        function rename( this, newSubjectCode, newSessionCode)
            projectPath = fileparts(this.dataPath);    
            newName = ArumeCore.Session.SessionPartsToName(this.experimentDesign.Name, newSubjectCode, newSessionCode);
            newPath = fullfile(projectPath, newName);
            
            % rename the folder
            if ( ~strcmpi(this.dataPath, newPath ))
                this.subjectCode = newSubjectCode;
                this.sessionCode = newSessionCode;
                
                % TODO: it is tricky to rename when only changing
                % capitalization of names. Because for windows they are
                % the same files and it does not alow. One option would be
                % to do a double change. 
                movefile(this.dataPath, newPath);
                
                this.dataPath  = newPath;
                this.InitDB( this.dataPath );
            end
            
        end
        
        function deleteFolders( this )
            if ( exist(this.dataPath, 'dir') )
                rmdir(this.dataPath,'s');
            end
        end
        
        function sessionData = save( this )
            sessionData = [];
            
            sessionData.comment             = this.comment;
            sessionData.experimentOptions   = this.experimentDesign.ExperimentOptions;
            sessionData.currentRun          = [];
            sessionData.pastRuns            = [];
            
            if (~isempty( this.currentRun ))
                sessionData.currentRun = ArumeCore.ExperimentRun.SaveRunData(this.currentRun);
                sessionData.pastRuns = ArumeCore.ExperimentRun.SaveRunDataArray(this.pastRuns);
            end
            
            filename = fullfile( this.dataPath, 'ArumeSession.mat');
            save( filename, 'sessionData' );
        end
        
        function session = copy( this, newSubjectCode, newSessionCode)
            projectFolder = fileparts(this.dataPath);

            session = ArumeCore.Session.NewSession( ...
                projectFolder, ...
                this.experimentDesign.Name, ...
                newSubjectCode, ...
                newSessionCode, ...
                this.experimentDesign.ExperimentOptions );
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
                this.currentRun.LinkedFiles.(fileTag) = vertcat( this.currentRun.LinkedFiles.(fileTag), [fileName ext] );
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
            [samples, rawData] = this.experimentDesign.PrepareSamplesDataTable();
            
            if ( ~isempty(samples) )
                this.WriteVariable(samples,'samplesDataTable');
            end
            
            if ( ~isempty(rawData) )
                this.WriteVariable(rawData,'rawDataTable');
            end
            
            %% 2) Prepare the trial dataset
            trials = this.experimentDesign.PrepareTrialDataTable(trials);
            if ( ~isempty(trials) )
                this.WriteVariable(trials,'trialDataTable');
            end
            
            %% 3) Prepare session dataTable
            newSessionDataTable = this.GetBasicSessionDataTable();
            newSessionDataTable = this.experimentDesign.PrepareSessionDataTable(newSessionDataTable);
            if ( ~isempty(newSessionDataTable) )
                this.WriteVariable(newSessionDataTable,'sessionDataTable');
            end
        end
        
        function runAnalysis(this, options)
            
            %% 1) Prepare events datasets
            results = [];
            samplesIn = this.samplesDataTable;
            trialsIn = this.trialDataTable;
            sessionTableIn = this.sessionDataTable;
            [results, samples, trials, sessionTable]  = this.experimentDesign.RunDataAnalyses(results, samplesIn, trialsIn, sessionTableIn, options);
        
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
            
            if ( ~isempty(sessionTable) )
                this.WriteVariable(sessionTable,'sessionDataTable');
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
            
            [projectPath,sessionName] = fileparts(sessionPath);    
            [newExperimentName, newSubjectCode, newSessionCode] = ArumeCore.Session.SessionNameToParts(sessionName);
            filename = fullfile( sessionPath, 'ArumeSession.mat');
            
            sessionData = load( filename, 'sessionData' );
            data = sessionData.sessionData;  
            
            session = ArumeCore.Session();
            session.init( projectPath, newExperimentName, newSubjectCode, newSessionCode, data.experimentOptions );
            
            if (isfield(data, 'currentRun') && ~isempty( data.currentRun ))
                session.currentRun = ArumeCore.ExperimentRun.LoadRunData( data.currentRun );
            end
            
            if (isfield(data, 'pastRuns') && ~isempty( data.pastRuns ))
                session.pastRuns = ArumeCore.ExperimentRun.LoadRunDataArray( data.pastRuns );
            end
            
            if (isfield(data, 'comment') && ~isempty( data.comment ))
                session.comment = data.comment;
            end
        end
        
        %
        % Other methods
        %
        function result = IsValidSubjectCode( name )
            result = ~isempty(regexp(name,'^[_a-zA-Z0-9]+$','ONCE') );
            result = result && ~contains(name,'__');
        end
        
        function result = IsValidSessionCode( name )
            result = ~isempty(regexp(name,'^[_a-zA-Z0-9]+$','ONCE') );
            result = result && ~contains(name,'__');
        end
        
        function [experimentName, subjectCode, sessionCode] = SessionNameToParts( sessionName )
            parts = split(sessionName,'__');
            experimentName   = parts{1};
            subjectCode      = parts{2};
            sessionCode      = parts{3};
        end
        
        function sessionName = SessionPartsToName(experimentName, subjectCode, sessionCode)
           sessionName = [ experimentName '__' subjectCode '__' sessionCode];
        end
        
        function newNumber = GetNewSessionNumber()
            persistent number;
            if isempty(number)
                % all this is just in case clear all was called. In that
                % case number will be empty but we can recover it more or
                % less by looking at the current project. A bit messy but
                % works.
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
    
end

