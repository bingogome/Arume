classdef PsyCortexExperiment < handle
    %PsyCortexExperiment Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Name = '';
        Config      = [];
    end
    
    properties(SetAccess=private);
        SubjectCode     = '000';
        SessionSuffix   = 'Z';
        
        ExperimentInfo      = [];
        
        CurrentRun  = [];
        PastRuns    = [];
        EyeTracker  = [];
        Graph       = [];
        SysInfo     = [];
        
        Filename    = '';
        EyeTrackerFiles = {};       
             
        
    end  
    
    % --------------------------------------------------------------------
    %% Protected abstract methods, to be implemented by the Experiments ---
    % --------------------------------------------------------------------
    methods (Access=protected, Abstract)
        
        %% getParameters
        parameters = getParameters( parameters, this );
        
        %% getVariables
        [conditionVars randomVars] = getVariables( this );
        
        %% runPreTrial
        [trial] = runPreTrial(this, variables );
        
        %% runTrial
        [trialResult trial] = runTrial( this, variables, trial );
        
        %% runPostTrial
        [trialOutput] = runPostTrial(this, trial);
        
        
       
    end
    
    
    % --------------------------------------------------------------------
    %% PUBLIC and sealed METHODS ------------------------------------------
    % --------------------------------------------------------------------
    % to be called from gui or command line
    % --------------------------------------------------------------------
    methods
        %% CONSTRUCTOR
        function this = PsyCortexExperiment( )
            
            %in case a child class derived from
            %PsyCortexExperiments.PsyCortexExperiment wants to call
            %something before the construction
            this.preConstruct();
            
            psyCortex_Enum();
            
            %-- load variables
            this.setUpVariables();
            
            %-- generate condition matrix
            this.setUpConditionMatrix();
            
            %-- load parameters
            this.setUpParameters();
            
            
            this.Config      = psyCortex_DefaultConfig(this);
            
            this.CurrentRun = this.setUpNewRun( );
            
            %-- subject info
            this.SubjectCode = '000';
            this.SessionSuffix = 'Z';
            
            
            
        end

        function this = preConstruct(this)
            %Method here in case a child class derived from
            %PsyCortexExperiments.PsyCortexExperiment wants to call
            %something before the normal construction 

        end
        
        function abortExperiment(this, trial)
            
            throw(MException('PSYCORTEX:USERQUIT', ''));
            
            
        end
        
        function DisplayConditionMatrix(this)
            c = this.ExperimentInfo.ConditionMatrix;
            for i=1:size(c,1)
                disp(c(i,:))
            end
        end
        
         %% function psyCortex_defaultConfig
        %--------------------------------------------------------------------------
        function config = psyCortex_DefaultConfig(this)
            
            config.UsingEyelink = 1;
            config.Debug = 0;
            config.HitKeyBeforeTrial = 1;
            config.Graphical.mmMonitorWidth    = 400;
            config.Graphical.mmMonitorHeight   = 300;
            config.Graphical.mmDistanceToMonitor = 600;
            config.Graphical.backGroundColor = 'black';
            config.Graphical.textColor = 'white';
        end
        
        
        %% setEyeTrackerFiles
        function  setEyeTrackerFilesAndFileName(this, edfNames, matFileName, subjectCode)
            %name is a cell of all edf filenames
            for iname = 1:length(edfNames)
                this.EyeTrackerFiles{iname} = edfNames{iname};
            end
            
            if exist ('matFileName', 'var')
                this.Filename = matFileName;
            end
            
             if exist ('subjectCode', 'var')
                this.SubjectCode = subjectCode;
            end
        end
    end
    
    
    
    methods (Sealed)
        
        %% StartSession ---------------------------------------------------
        function StartSession(this, subjectName, sessionSuffix )
            this.SubjectCode = subjectName;
            this.SessionSuffix = sessionSuffix;
            date = datevec(now);
            filename = sprintf( ['%s_%s_%s_%0.4d%0.2d%0.2d' ],...
                this.Name,...
                this.SubjectCode,...
                this.SessionSuffix,...
                date(1),...
                date(2),...
                date(3));
            this.Filename = filename;
            
            %             this.Filename = [this.Name '_' this.SubjectCode '_' this.SessionSuffix '_'  num2str(date(1)) num2str(date(2)) num2str(date(3))];
            if ( exist( [this.ExperimentInfo.Parameters.dataPath '\' this.Filename ,'.mat'], 'file') )% file already exists
                result = questdlg(['There is already a file named ' this.Filename ', continue?'], 'Question', 'Yes', 'No', 'Yes');
                if ( isequal( result, 'No') )
                    return;
                end
            end
            
            this.run_session();
        end
        
        %% RestartSession -------------------------------------------------
        function RestartSession(this)
            % save the status of the current run in  the past runs
            if ( isempty( this.PastRuns) )
                this.PastRuns    = this.CurrentRun;
            else
                this.PastRuns( length(this.PastRuns) + 1 ) = this.CurrentRun;
            end
            % generate new sequence of trials
            this.CurrentRun = this.setUpNewRun( );
            this.run_session();
        end
        
        %% ResumeSession --------------------------------------------------
        function ResumeSession( this )
            %-- save the status of the current run in  the past runs
            if ( isempty( this.PastRuns) )
                this.PastRuns    = this.CurrentRun;
            else
                this.PastRuns( length(this.PastRuns) + 1 )    = this.CurrentRun;
            end
            %             %TODO if resuming from an specific runthe past run is now the current run
            %             if ( length(varargin) == 2 )
            %                 runToResume     = varargin{2};
            %                 this.CurrentRun = this.PastRuns(runToResume);
            %             end
            this.run_session();
        end
        
        %% GetStats
        function stats = GetStats(this)
            global Enum;
            if ( isempty(Enum) )
                psyCortex_Enum();
            end
            trialsPerSession = this.ExperimentInfo.Parameters.trialsPerSession;
            
            if ( ~isempty(this.CurrentRun) )
                
                if ( ~isempty(this.CurrentRun.pastConditions) )
                    cond = this.CurrentRun.pastConditions(:,Enum.pastConditions.condition);
                    res = this.CurrentRun.pastConditions(:,Enum.pastConditions.trialResult);
                    blockn = this.CurrentRun.pastConditions(:,Enum.pastConditions.blocknumber);
                    blockid = this.CurrentRun.pastConditions(:,Enum.pastConditions.blockid);
                    sess = this.CurrentRun.pastConditions(:,Enum.pastConditions.session);
                    
                    stats.trialsCorrect = sum( res == Enum.trialResult.CORRECT );
                    stats.trialsAbort   =  sum( res ~= Enum.trialResult.CORRECT );
                    stats.totalTrials   = length(cond);
                    stats.sessionTrialsCorrect = sum( res == Enum.trialResult.CORRECT & sess == this.CurrentRun.CurrentSession );
                    stats.sessionTrialsAbort   =  sum( res ~= Enum.trialResult.CORRECT & sess == this.CurrentRun.CurrentSession );
                    stats.sessionTotalTrials   = length(cond & sess == this.CurrentRun.CurrentSession );
                else
                    stats.trialsCorrect = 0;
                    stats.trialsAbort   =  0;
                    stats.totalTrials   = 0;
                    stats.sessionTrialsCorrect = 0;
                    stats.sessionTrialsAbort   =  0;
                    stats.sessionTotalTrials   = 0;
                end
                
                stats.currentSession = this.CurrentRun.CurrentSession;
                stats.SessionsToRun = this.CurrentRun.SessionsToRun;
                stats.trialsInExperiment = size(this.CurrentRun.originalFutureConditions,1);
                
                if ( ~isempty(this.CurrentRun.futureConditions) )
                    futcond = this.CurrentRun.futureConditions(:,Enum.futureConditions.condition);
                    futblockn = this.CurrentRun.futureConditions(:,Enum.futureConditions.blocknumber);
                    futblockid = this.CurrentRun.futureConditions(:,Enum.futureConditions.blockid);
                    stats.currentBlock = futblockn(1);
                    stats.currentBlockID = futblockid(1);
                    stats.blocksFinished = futblockn(1)-1;
                    stats.trialsToFinishSession = min(trialsPerSession - stats.sessionTrialsCorrect,length(futcond));
                    stats.trialsToFinishExperiment = length(futcond);
                    stats.blocksInExperiment = futblockn(end);
                else
                    stats.currentBlock = 1;
                    stats.currentBlockID = 1;
                    stats.blocksFinished = 0;
                    stats.trialsToFinishSession = 0;
                    stats.trialsToFinishExperiment = 0;
                    stats.blocksInExperiment = 1;
                end
                
            else
                stats.currentSession = 1;
                stats.SessionsToRun = 1;
                stats.currentBlock = 1;
                stats.currentBlockID = 1;
                stats.blocksFinished = 0;
                stats.trialsToFinishSession = 1;
                stats.trialsToFinishExperiment = 1;
                stats.trialsInExperiment = 1;
                stats.blocksInExperiment = 1;
            end
        end
    end % methods (Sealed)
    
    
    % --------------------------------------------------------------------
    %% Protected methods --------------------------------------------------
    % --------------------------------------------------------------------
    % to be called from any experiment
    % --------------------------------------------------------------------
    methods(Access=protected)
        
        %% SaveEvent
        %--------------------------------------------------------------------------
        function SaveEvent( this, event )
            % TODO: think much better
            currentTrial            = size( this.CurrentRun.pastConditions, 1) +1;
            currentCondition        = this.CurrentRun.futureConditions(1);
            this.CurrentRun.Events  = cat(1, this.CurrentRun.Events, [GetSecs event currentTrial currentCondition] );
        end
        
        %% getVariablesCurrentCondition
        %--------------------------------------------------------------------------
        function variables = getVariablesCurrentCondition( this, currentCondition )
            
            % psyCortex_variablesCurrentCondition
            % gets the variables that correspond to the current condition
            
            conditionMatrix = this.ExperimentInfo.ConditionMatrix;
            conditionVars = this.ExperimentInfo.ConditionVars;
            
            variables = [];
            for iVar=1:length(conditionVars)
                varName = conditionVars{iVar}.name;
                varValues = conditionVars{iVar}.values;
                if iscell( varValues )
                    variables.(varName) = varValues{conditionMatrix(currentCondition,iVar)};
                else
                    variables.(varName) = varValues(conditionMatrix(currentCondition,iVar));
                end
            end
            
            for iVar=1:length(this.ExperimentInfo.RandomVars)
                varName = this.ExperimentInfo.RandomVars{iVar}.name;
                varType = this.ExperimentInfo.RandomVars{iVar}.type;
                if ( isfield( this.ExperimentInfo.RandomVars{iVar}, 'values' ) )
                    varValues = this.ExperimentInfo.RandomVars{iVar}.values;
                end
                if ( isfield( this.ExperimentInfo.RandomVars{iVar}, 'params' ) )
                    varParams = this.ExperimentInfo.RandomVars{iVar}.params;
                end
                
                switch(varType)
                    case 'List'
                        if iscell(varValues)
                            variables.(varName) = varValues{ceil(rand(1)*length(varValues))};
                        else
                            variables.(varName) = varValues(ceil(rand(1)*length(varValues)));
                        end
                    case 'UniformReal'
                        variables.(varName) = varParams(1) + (varParams(2)-varParams(1))*rand(1);
                    case 'UniformInteger'
                        variables.(varName) = floor(varParams(1) + (varParams(2)+1-varParams(1))*rand(1));
                    case 'Gaussian'
                        variables.(varName) = varParams(1) + varParams(2)*rand(1);
                    case 'Exponential'
                        variables.(varName) = -varParams(1) .* log(rand(1));
                end
            end
        end
        
        %% SaveTempData
        function SaveTempData(this)
            try
                filename = [this.Name '_' this.SubjectCode '_' this.SessionSuffix  '_temp'];
                eval( [filename ' = this;']);
                save( [ this.ExperimentInfo.Parameters.dataPath '\' filename], filename);
                
                %now check if the file saved properly
                currSavedFileDir = dir([ this.ExperimentInfo.Parameters.dataPath '\' ]);
                
                for ifile = 1:length(currSavedFileDir)
                    if strcmp(currSavedFileDir(ifile).name, [filename '.mat'])
                        idxCurrFile = ifile;
                        break;
                    end
                end
                
                if exist('idxCurrFile', 'var') && currSavedFileDir(idxCurrFile).bytes > 1000                    
                    %this means the prior save was successful so lets create a
                    %backup just in case there is a future problem and we
                    %somehow save a corrupt file.
                    
                    %check if backup directory exists
                    d = dir('C:\secure\matfilebackup\');
                    if  ~isempty(d)
                        eval( [this.Filename ' = this;']);
                        save( [ 'C:\secure\matfilebackup\' this.Filename], this.Filename);
                    end
                end
                
            catch
                %-- error saving temporal data (not necessaryly critical)
                d = dir('C:\secure\matfilebackup\');
                if  ~isempty(d)
                    eval( [this.Filename ' = this;']);
                    save( [ 'C:\secure\matfilebackup\' this.Filename], this.Filename);
                end
                save_error = psychlasterror;
                disp(['ERROR SAVING TEMP DATA: ' save_error.message]);
            end
        end
        
        %% ShowDebugInfo
        function ShowDebugInfo( this, variables )
            if ( this.Config.Debug )
                % TODO: it would be nice to have some call back system here
%                  Screen('DrawText', this.Graph.window, sprintf('%i seconds remaining...', round(secondsRemaining)), 20, 50, graph.black);
                currentline = 50 + 25;
                vNames = fieldnames(variables);
                for iVar = 1:length(vNames)
                    if ( ischar(variables.(vNames{iVar})) )
                        s = sprintf( '%s = %s',vNames{iVar},variables.(vNames{iVar}) );
                    else
                        s = sprintf( '%s = %s',vNames{iVar},num2str(variables.(vNames{iVar})) );
                    end
                    Screen('DrawText', graph.window, s, 20, currentline, graph.black);
                    
                    currentline = currentline + 25;
                end
                %
                %                             if ( ~isempty( this.EyeTracker ) )
                %                                 draweye( this.EyeTracker.eyelink, graph)
                %                             end
            end
        end
        
        function setCurrentRun( this, newCurrentRun)
            this.Currentrun = newCurrentRun;
        end
    end % methods(Access=protected)
    
    
    % --------------------------------------------------------------------
    %% Private methods ----------------------------------------------------
    % --------------------------------------------------------------------
    % to be called only by this class
    % --------------------------------------------------------------------
    methods (Access=private)
        
        %% setUpParameters
        function setUpParameters(this)
            
            numberOfConditions = size(this.ExperimentInfo.ConditionMatrix,1);
            
            % default parameters of any experiment
            
            parameters.trialSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            parameters.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            parameters.trialsPerSession = numberOfConditions;
            
            %%-- Blocking
            parameters.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            parameters.numberOfTimesRepeatBlockSequence = 1;
            parameters.blocksToRun              = 1;
            parameters.blocks{1}.fromCondition  = 1;
            parameters.blocks{1}.toCondition    = numberOfConditions;
            parameters.blocks{1}.trialsToRun    = numberOfConditions;
            
            
            parameters.trialsBeforeCalibration      = 10;
            parameters.trialsBeforeDriftCorrection  = 10;
            parameters.trialsBeforeBreak            = 10;
            
            parameters.trialDuration = 5; %seconds
            
            parameters.fixRad = .125;
            parameters.fixColor     = [255 0 0];
            
            myClass = metaclass(this);
            parameters.dataPath = strrep(fileparts(mfilename('fullpath')), '+PsyCortexExperiments\@PsyCortexExperiment', myClass.Name);
            
            %-- get the parameters of this experiment
            parameters = this.getParameters( parameters );
            
            %TODO: it would be nice to check the parameters and give
            % information
            
            this.ExperimentInfo.Parameters = parameters;
        end
        
        %% setUpVariables
        function setUpVariables(this)
            [conditionVars randomVars] = this.getVariables();
            this.ExperimentInfo.ConditionVars   = conditionVars;
            this.ExperimentInfo.RandomVars      = randomVars;
        end
        
        %% setUpConditionMatrix
        function setUpConditionMatrix(this)
            
            %-- total number of conditions is the product of the number of
            % values of each condition variable
            nConditions = 1;
            for iVar = 1:length(this.ExperimentInfo.ConditionVars)
                nConditions = nConditions * length(this.ExperimentInfo.ConditionVars{iVar}.values);
            end
            
            this.ExperimentInfo.ConditionMatrix = [];
            
            %-- recursion to create the condition matrix
            % for each variable, we repeat the previous matrix as many
            % times as values the current variable has and in each
            % repetition we add a new column with one of the values of the
            % current variable
            % example: var1 = {a b} var2 = {e f g}
            % step 1: matrix = [ a ;
            %                    b ];
            % step 2: matrix = [ a e ;
            %                    b e ;
            %                    a f ;
            %                    b f ;
            %                    a g ;
            %                    b g ];
            for iVar = 1:length(this.ExperimentInfo.ConditionVars)
                nValues(iVar) = length(this.ExperimentInfo.ConditionVars{iVar}.values);
                this.ExperimentInfo.ConditionMatrix = [ repmat(this.ExperimentInfo.ConditionMatrix,nValues(iVar),1)  ceil((1:prod(nValues))/prod(nValues(1:end-1)))' ];
            end
        end
        
        
        %% setUpNewRun
        %--------------------------------------------------------------------------
        function currentRun = setUpNewRun( this )
            
            parameters = this.ExperimentInfo.Parameters;
            
            % use predictable randomization saving state
            currentRun.Info.defaultRandStream   = RandStream.getDefaultStream;
            currentRun.Info.stateRandStream     = currentRun.Info.defaultRandStream.State;
            
            currentRun.pastConditions   = []; % conditions already run, including aborts
            currentRun.futureConditions = []; % conditions left for running (the whole list is created a priori)
            currentRun.Events           = [];
            currentRun.Data             = [];
            
            % generate the sequence of blocks, a total of
            % parameters.blocksToRun blocks will be run
            nBlocks = length(parameters.blocks);
            blockSequence = [];
            switch(parameters.blockSequence)
                case 'Sequential'
                    blockSequence = mod( (1:parameters.blocksToRun)-1,  nBlocks ) + 1;
                case 'Random'
                    [junk blocks] = sort( rand(1,parameters.blocksToRun) ); % get a random shuffle of 1 ... blocks to run
                    blockSequence = mod( blocks-1,  nBlocks ) + 1; % limit the random sequence to 1 ... nBlocks
                case 'Random with repetition'
                    blockSequence = ceil( rand(1,parameters.blocksToRun) * nBlocks ); % just get random block numbers
                case 'Manual'
                    blockSequence = [];
                    
                    while length(blockSequence) ~= parameters.blocksToRun
                        S.Block_Sequence = [1:parameters.blocksToRun];
                        S = StructDlg( S, ['Block Sequence'], [],  CorrGui.get_default_dlg_pos() );
                        blockSequence =  S.Block_Sequence;
                    end
                    %                     if length(parameters.manualBlockSequence) == parameters.blocksToRun;
                    %                         %                         blockSequence = parameters.manualBlockSequence;
                    %
                    %                     else
                    %                         disp(['Error with the manual block sequence. Please fix.']);
                    %                     end
            end
            
            currentRun.futureConditions = [];
            for iblock=1:length(blockSequence)
                i = blockSequence(iblock);
                possibleConditions = parameters.blocks{i}.fromCondition : parameters.blocks{i}.toCondition; % the possible conditions to select from in this block
                nConditions = length(possibleConditions);
                nTrials = parameters.blocks{i}.trialsToRun;
                
                switch( parameters.trialSequence )
                    case 'Sequential'
                        trialSequence = possibleConditions( mod( (1:nTrials)-1,  nConditions ) + 1 );
                    case 'Random'
                        [junk conditions] = sort( rand(1,nTrials) ); % get a random shuffle of 1 ... nTrials
                        conditionIndexes = mod( conditions-1,  nConditions ) + 1; % limit the random sequence to 1 ... nConditions
                        trialSequence = possibleConditions( conditionIndexes ); % limit the random sequence to fromCondition ... toCondition for this block
                    case 'Random with repetition'
                        trialSequence = possibleConditions( ceil( rand(1,nTrials) * nConditions ) ); % nTrialss numbers between 1 and nConditions
                end
                currentRun.futureConditions = cat(1,currentRun.futureConditions, [trialSequence' ones(size(trialSequence'))*iblock  ones(size(trialSequence'))*i] );
            end
            
            currentRun.CurrentSession   = 1;
            currentRun.futureConditions = repmat( currentRun.futureConditions,parameters.numberOfTimesRepeatBlockSequence,1);
            currentRun.SessionsToRun    = ceil(size(currentRun.futureConditions,1) / parameters.trialsPerSession);
            currentRun.originalFutureConditions = currentRun.futureConditions;
        end
        
        
        %% run_session
        run_session(this);
        
        
        
    end % methods (Access=private)
    
    
end


%% function psyCortex_Enum
%--------------------------------------------------------------------------
function psyCortex_Enum()
global Enum ;
% -- possible trial results
Enum.trialResult.CORRECT = 0; % Trial finished correctly
Enum.trialResult.ABORT = 1;   % Trial not finished, wrong key pressed, subject did not fixate, etc
Enum.trialResult.ERROR = 2;   % Error during the trial
Enum.trialResult.QUIT = 3;    % Escape was pressed during the trial
Enum.trialResult.SOFT_ABORT = 4;    % Abort by software, no error


% -- useful key codes
KbName('UnifyKeyNames');
Enum.keys.SPACE     = KbName('space');
Enum.keys.ESCAPE    = KbName('ESCAPE');
Enum.keys.RETURN    = KbName('return');
Enum.keys.BACKSPACE = KbName('backspace');

Enum.keys.TAB       = KbName('tab');
Enum.keys.SHIFT     = KbName('shift');
Enum.keys.CONTROL   = KbName('control');
Enum.keys.ALT       = KbName('alt');
Enum.keys.END       = KbName('end');
Enum.keys.HOME      = KbName('home');

Enum.keys.LEFT      = KbName('LeftArrow');
Enum.keys.UP        = KbName('UpArrow');
Enum.keys.RIGHT     = KbName('RightArrow');
Enum.keys.DOWN      = KbName('DownArrow');

i=1;
Enum.Events.EYELINK_START_RECORDING     = i;i=i+1;
Enum.Events.EYELINK_STOP_RECORDING      = i;i=i+1;
Enum.Events.PRE_TRIAL_START             = i;i=i+1;
Enum.Events.PRE_TRIAL_STOP              = i;i=i+1;
Enum.Events.TRIAL_START                 = i;i=i+1;
Enum.Events.TRIAL_STOP                  = i;i=i+1;
Enum.Events.POST_TRIAL_START            = i;i=i+1;
Enum.Events.POST_TRIAL_STOP             = i;i=i+1;
Enum.Events.TRIAL_EVENT                 = i;i=i+1;

Enum.pastConditions.condition = 1;
Enum.pastConditions.trialResult = 2;
Enum.pastConditions.blocknumber = 3;
Enum.pastConditions.blockid = 4;
Enum.pastConditions.session = 5;

Enum.futureConditions.condition     = 1;
Enum.futureConditions.blocknumber   = 2;
Enum.futureConditions.blockid   = 3;
end