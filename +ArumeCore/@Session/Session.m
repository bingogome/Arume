classdef Session < handle
    %SESSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        project
        name
        dataRawPath
        dataAnalysisPath
        
        subjectCode = '000';
        sessionCode = 'Z';
        
        ExperimentDesign
        
        CurrentRun  = [];
        PastRuns    = [];
        
        EyeTracker  = [];
        Graph       = [];
        SysInfo     = [];
        
        Config      = [];
        
        Filename    = '';
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
        function init( this, project, subjectCode, sessionCode )
            this.project        = project;
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
        
        function initNew( this, project, subjectCode, sessionCode )
            
            % check if session already exists with that subjectCode and
            % sessionCode
            for session = project.sessions
                if ( isequal(subjectCode, session.subjectCode) && isequal( sessionCode, session.sessionCode) )
                    error( 'Arume: session already exists use a diferent name' );
                end
            end
            
            this.init( project, subjectCode, sessionCode );
            
            % create the new folders
            mkdir( project.dataRawPath, this.name );
            mkdir( project.dataAnalysisPath, this.name );
            
            % load variables
            this.setUpVariables();
            
            % load parameters
            this.setUpParameters();
            
            
            this.Config = this.psyCortex_DefaultConfig();
            this.Config.Debug = 1;
            
            this.CurrentRun = this.setUpNewRun( );
            
        end
        
        function initExisting( this, project, data )
            
            this.init( project, data.subjectCode, data.sessionCode  );
            
            this.ExperimentDesign = data.ExperimentDesign;
            this.CurrentRun = data.CurrentRun;
            this.PastRuns = data.PastRuns;
            this.Filename = data.Filename;
            this.Config = data.Config;
            
        end
        
        function start( this )
            this.run();
        end
        
        function resume( this )
            %-- save the status of the current run in  the past runs
            if ( isempty( this.PastRuns) )
                this.PastRuns = this.CurrentRun;
            else
                this.PastRuns( length(this.PastRuns) + 1 ) = this.CurrentRun;
            end
            this.run();
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
            this.run();
        end
        
        function data = save( this )
            data = [];
            
            data.subjectCode = this.subjectCode;
            data.sessionCode = this.sessionCode;
            data.ExperimentDesign = this.ExperimentDesign;
            data.CurrentRun = this.CurrentRun;
            data.PastRuns = this.PastRuns;
            data.Filename = this.Filename;
            data.Config = this.Config;
            
        end
        
    end
    
    methods (Static = true )
        
        function session = NewSession( project, subjectCode, sessionCode )
            % TODO add factory for multiple types of experiments
            session = Experiments.OptokineticTorsion();
            session.initNew( project, subjectCode, sessionCode );
        end
        
        function session = LoadSession( project, data )
            % TODO add factory for multiple types of experiments
            
            session = Experiments.OptokineticTorsion();
            
            session.initExisting( project, data );
            
        end
        
    end
    
    
    
    
    % --------------------------------------------------------------------
    %% Protected abstract methods, to be implemented by the Experiments ---
    % --------------------------------------------------------------------
    methods (Access=protected, Abstract)
        
        %% getParameters
        parameters = getParameters( parameters, this );
        
        %% getVariables
        [conditionVars, randomVars] = getVariables( this );
        
        %% runPreTrial
        runPreTrial(this, variables );
        
        %% runTrial
        [trialResult] = runTrial( this, variables);
        
        %% runPostTrial
        [trialOutput] = runPostTrial(this);
        
    end
    
    
    % --------------------------------------------------------------------
    %% PUBLIC and sealed METHODS ------------------------------------------
    % --------------------------------------------------------------------
    % to be called from gui or command line
    % --------------------------------------------------------------------
    methods
        
        
        function abortExperiment(this, trial)
            
            throw(MException('PSYCORTEX:USERQUIT', ''));
            
        end
        
        function DisplayConditionMatrix(this)
            c = this.ExperimentDesign.ConditionMatrix;
            for i=1:size(c,1)
                disp(c(i,:))
            end
        end
        
        %% function psyCortex_defaultConfig
        %--------------------------------------------------------------------------
        function config = psyCortex_DefaultConfig(this)
            
            config.UsingEyeTracking = 1;
            config.UsingVideoGraphics = 1;
            
            config.Debug = 0;
            config.HitKeyBeforeTrial = 1;
            config.Graphical.mmMonitorWidth    = 400;
            config.Graphical.mmMonitorHeight   = 300;
            config.Graphical.mmDistanceToMonitor = 600;
            config.Graphical.backGroundColor = 'black';
            config.Graphical.textColor = 'white';
        end
        
    end
    
    
    
    methods (Sealed)
        
        
        %% GetStats
        function stats = GetStats(this)
            Enum = ArumeCore.Session.getEnum();
            
            trialsPerSession = this.ExperimentDesign.Parameters.trialsPerSession;
            
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
            
            conditionMatrix = this.ExperimentDesign.ConditionMatrix;
            conditionVars = this.ExperimentDesign.ConditionVars;
            
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
            
            for iVar=1:length(this.ExperimentDesign.RandomVars)
                varName = this.ExperimentDesign.RandomVars{iVar}.name;
                varType = this.ExperimentDesign.RandomVars{iVar}.type;
                if ( isfield( this.ExperimentDesign.RandomVars{iVar}, 'values' ) )
                    varValues = this.ExperimentDesign.RandomVars{iVar}.values;
                end
                if ( isfield( this.ExperimentDesign.RandomVars{iVar}, 'params' ) )
                    varParams = this.ExperimentDesign.RandomVars{iVar}.params;
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
            
            numberOfConditions = size(this.ExperimentDesign.ConditionMatrix,1);
            
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
            
            
            %-- get the parameters of this experiment
            parameters = this.getParameters( parameters );
            
            %TODO: it would be nice to check the parameters and give
            % information
            
            this.ExperimentDesign.Parameters = parameters;
        end
        
        %% setUpVariables
        function setUpVariables(this)
            [conditionVars randomVars] = this.getVariables();
            this.ExperimentDesign.ConditionVars   = conditionVars;
            this.ExperimentDesign.ConditionMatrix = this.getConditionMatrix( conditionVars );
            this.ExperimentDesign.RandomVars      = randomVars;
        end
        
        %% setUpConditionMatrix
        function conditionMatrix = getConditionMatrix( this, conditionVars )
            
            %-- total number of conditions is the product of the number of
            % values of each condition variable
            nConditions = 1;
            for iVar = 1:length(conditionVars)
                nConditions = nConditions * length(conditionVars{iVar}.values);
            end
            
            conditionMatrix = [];
            
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
            for iVar = 1:length(conditionVars)
                nValues(iVar) = length(conditionVars{iVar}.values);
                conditionMatrix = [ repmat(conditionMatrix,nValues(iVar),1)  ceil((1:prod(nValues))/prod(nValues(1:end-1)))' ];
            end
        end
        
        
        %% setUpNewRun
        function currentRun = setUpNewRun( this )
            
            parameters = this.ExperimentDesign.Parameters;
            
            % use predictable randomization saving state
            currentRun.Info.globalStream   = RandStream.getGlobalStream;
            currentRun.Info.stateRandStream     = currentRun.Info.globalStream.State;
            
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
        
        
        function run(this)
            Enum = ArumeCore.Session.getEnum();
            
            % --------------------------------------------------------------------
            %% -- HARDWARE SET UP ------------------------------------------------
            % --------------------------------------------------------------------
            try
                
                this.SysInfo.PsychtoolboxVersion   = Screen('Version');
                this.SysInfo.hostSO                = Screen('Computer');
                
                
                % -- GRAPHICS KEYBOARD and MOUSE
                if ( this.Config.UsingVideoGraphics )
                    
                    %-- hide the mouse cursor during the experiment
                    if ( ~this.Config.Debug )
                        HideCursor;
                        ListenChar(1);
                    else
                        ListenChar(1);
                    end
                    
                    Screen('Preference', 'VisualDebugLevel', 3);
                    
                    this.Graph = ArumeCore.Display( this );
                else
                    this.Graph = [];
                end
                
                
                
                % -- EYELINK
                if ( this.Config.UsingEyeTracking )
                    try
                        this.EyeTracker = EyeTrackers.EyeTrackerAbstract.Initialize( 'EyeLink', this );
                    catch
                        disp( 'PSYCORTEX: EyeTracker set up failed ');
                        this.EyeTracker = [];
                    end
                else
                    this.EyeTracker = [];
                end
                
            catch
                % If any error during the start up
                
                if ( this.Config.UsingVideo )
                    ShowCursor;
                    ListenChar(0);
                    Priority(0);
                    
                    Screen('CloseAll');
                    commandwindow;
                end
                
                err = psychlasterror;
                
                % display error
                disp(['PSYCORTEX: Hardware set up failed: ' err.message ]);
                disp(err.stack(1));
                return;
            end
            
            % --------------------------------------------------------------------
            %% -- EXPERIMENT LOOP -------------------------------------------------
            % --------------------------------------------------------------------
            try
                
                IDLE = 0;
                RUNNING = 1;
                SESSIONFINISHED = 5;
                FINISHED = 6;
                SAVEDATA = 7;
                
                status = RUNNING;
                
                
                while(1)
                    Screen('FillRect', this.Graph.window, this.Graph.dlgBackgroundScreenColor);
                    
                    switch( status )
                        
                        
                        %% ++ IDLE -------------------------------------------------------
                        case IDLE
                            result = this.Graph.DlgSelect( 'Choose an option:', ...
                                { 'n' 'q'}, ...
                                { 'Next trial'  'Quit'} , [],[]);
                            switch( result )
                                case 'n'
                                    status = RUNNING;
                                case {'q' 0}
                                    dlgResult = this.Graph.DlgYesNo( 'Are you sure you want to exit?',[],[],20,20);
                                    if( dlgResult )
                                        status = SAVEDATA;
                                    end
                            end
                       
                            
                            %% ++ RUNNING -------------------------------------------------------
                        case RUNNING
                            if ( (exist('trialResult', 'var') && trialResult == Enum.trialResult.ABORT) || this.Config.HitKeyBeforeTrial && ( ~exist('trialResult', 'var') || trialResult ~= Enum.trialResult.SOFT_ABORT )) % TODO: don't like the soft abort very much
                                dlgResult = this.Graph.DlgHitKey( 'Hit a key to continue',[],[]);
                                if ( ~dlgResult )
                                    status = IDLE;
                                    continue;
                                end
                            end
                            
                            try
                                %-- find which condition to run and the variable values for that condition
                                if ( ~isempty(this.CurrentRun.pastConditions) )
                                    trialnumber = sum(this.CurrentRun.pastConditions(:,Enum.pastConditions.trialResult)==Enum.trialResult.CORRECT)+1;
                                else
                                    trialnumber = 1;
                                end
                                currentCondition    = this.CurrentRun.futureConditions(1,1);
                                variables           = this.getVariablesCurrentCondition( currentCondition );
                                
                                %------------------------------------------------------------
                                %% -- PRE TRIAL ----------------------------------------------
                                %------------------------------------------------------------
                                this.Graph.fliptimes{end +1} = zeros(100000,1);
                                this.Graph.NumFlips = 0;
                                
                                this.SaveEvent( Enum.Events.PRE_TRIAL_START);
                                trialResult = this.runPreTrial( variables );
                                this.SaveEvent( Enum.Events.PRE_TRIAL_STOP);
                                
                                
                                if ( ~ (trialResult == Enum.trialResult.SOFT_ABORT) )
                                    
                                    %------------------------------------------------------------
                                    %% -- TRIAL ---------------------------------------------------
                                    %------------------------------------------------------------
                                    fprintf('\nTRIAL START: N=%d Cond=%d ...', trialnumber , currentCondition );
                                    
                                    %%-- Start Recording eye movements
                                    if ( ~isempty(this.EyeTracker) )
                                        [result, messageString] = Eyelink('CalMessage');
                                        
                                        this.EyeTracker.SendMessage('CALIB: result=%d message=%s', result, messageString);
                                        this.EyeTracker.StartRecording();
                                        this.SaveEvent( Enum.Events.EYELINK_START_RECORDING);
                                        this.EyeTracker.SendMessage('TRIAL_START: N=%d Cond=%d t=%d', trialnumber, currentCondition, round(GetSecs*1000));
                                        % % %                             messageLeandro = { 'Look over here Leandro!!!!', 'Hey Leandro, pay attention, bitch!!!' , 'Stop jerking off and do your job, bastardo!!', ...
                                        % % %                                 'Hey dumbass get good data!' , 'Hey fulbright, check the respiration rate!!!!'};
                                        % % %                             a = randi(5);
                                        messageLeandro = { ''};
                                        a = randi(1);
                                        this.EyeTracker.ChangeStatusMessage('TRIAL N=%d Cond=%d NtoBreak=%d %s', trialnumber, currentCondition, this.ExperimentDesign.Parameters.trialsBeforeBreak-trialsSinceBreak, messageLeandro{a});
                                    end
                                    %%-- Run the trial
                                    this.SaveEvent( Enum.Events.TRIAL_START);
                                    
                                    trialResult = this.runTrial( variables );
                                    this.SaveEvent( Enum.Events.TRIAL_STOP);
                                    
                                    this.Graph.fliptimes{end} = this.Graph.fliptimes{end}(1:this.Graph.NumFlips);
                                    
                                    fprintf(' TRIAL END: slow flips: %d\n\n', sum(this.Graph.flips_hist) - max(this.Graph.flips_hist));
                                    fprintf(' TRIAL END: avg flip time: %d\n\n', mean(diff(this.Graph.fliptimes{end})));
                                    
                                    %%-- Stop Recording eye movements
                                    if ( ~isempty(this.EyeTracker) )
                                        this.SaveEvent( Enum.Events.EYELINK_STOP_RECORDING);
                                        this.EyeTracker.SendMessage( 'TRIAL_STOP: N=%d Cond=%d t=%d',trialnumber, currentCondition, round(GetSecs*1000));
                                        this.EyeTracker.StopRecording();
                                    end
                                    
                                    %------------------------------------------------------------
                                    %% -- POST TRIAL ----------------------------------------------
                                    %------------------------------------------------------------
                                    this.SaveEvent( Enum.Events.POST_TRIAL_START);
                                    [trialOutput] = this.runPostTrial(  );
                                    this.SaveEvent( Enum.Events.POST_TRIAL_STOP);
                                    
                                    %-- save data from trial
                                    clear data;
                                    data.trialOutput  = trialOutput;
                                    data.variables    = variables;
                                    
                                    this.CurrentRun.Data{end+1} = data;
                                end
                                
                            catch
                                %                     if ( ~iscell(this.CurrentRun.Data ) )
                                %                         % crappy thing to solve an issue with different
                                %                         % types of structs
                                %                         d = this.CurrentRun.Data;
                                %                         this.CurrentRun.Data = {};
                                %                         for i=1:length(d)
                                %                             this.CurrentRun.Data{i} = d(i);
                                %                         end
                                %                         %                         5
                                %                         %                         d(1)
                                %                         %                         this.CurrentRun.Data{1}
                                %                     end
                                err = psychlasterror;
                                if ( streq(err.identifier, 'PSYCORTEX:USERQUIT' ) )
                                    trialResult = Enum.trialResult.QUIT;
                                else
                                    trialResult = Enum.trialResult.ERROR;
                                    % display error
                                    disp(['Error in trial: ' err.message ]);
                                    disp(err.stack(1));
                                    this.Graph.DlgHitKey( ['Error, trial could not be run: \n' err.message],[],[] );
                                end
                            end
                            
                            
                            % -- Update pastcondition list
                            n = size(this.CurrentRun.pastConditions,1)+1;
                            this.CurrentRun.pastConditions(n, Enum.pastConditions.condition)    = this.CurrentRun.futureConditions(1,1);
                            this.CurrentRun.pastConditions(n, Enum.pastConditions.trialResult)  = trialResult;
                            this.CurrentRun.pastConditions(n, Enum.pastConditions.blocknumber)  = this.CurrentRun.futureConditions(1,2);
                            this.CurrentRun.pastConditions(n, Enum.pastConditions.blockid)      = this.CurrentRun.futureConditions(1,3);
                            this.CurrentRun.pastConditions(n, Enum.pastConditions.session)      = this.CurrentRun.CurrentSession;
                            
                            if ( trialResult == Enum.trialResult.CORRECT )
                                %-- remove the condition that has just run from the future conditions list
                                this.CurrentRun.futureConditions(1,:) = [];
                                
                                %-- save to disk temporary data
                                this.SaveTempData();
                                
                                
                                trialsSinceCalibration      = trialsSinceCalibration + 1;
                                trialsSinceDriftCorrection	= trialsSinceDriftCorrection + 1;
                                trialsSinceBreak            = trialsSinceBreak + 1;
                            else
                                %-- what to do in case of abort
                                switch(this.ExperimentDesign.Parameters.trialAbortAction)
                                    case 'Repeat'
                                        % do nothing
                                    case 'Delay'
                                        % randomly get one of the future conditions in the current block
                                        % and switch it with the next
                                        currentblock = this.CurrentRun.futureConditions(1,Enum.futureConditions.blocknumber);
                                        futureConditionsInCurrentBlock = this.CurrentRun.futureConditions(this.CurrentRun.futureConditions(:,Enum.futureConditions.blocknumber)==currentblock,:);
                                        
                                        newPosition = ceil(rand(1)*(size(futureConditionsInCurrentBlock,1)-1))+1;
                                        c = futureConditionsInCurrentBlock(1,:);
                                        futureConditionsInCurrentBlock(1,:) = futureConditionsInCurrentBlock(newPosition,:);
                                        futureConditionsInCurrentBlock(newPosition,:) = c;
                                        this.CurrentRun.futureConditions(this.CurrentRun.futureConditions(:,Enum.futureConditions.blocknumber)==currentblock,:) = futureConditionsInCurrentBlock;
                                        % TODO: improve
                                    case 'Drop'
                                        %-- remove the condition that has just run from the future conditions list
                                        this.CurrentRun.futureConditions(1,:) = [];
                                end
                            end
                            
                            %-- handle errors
                            switch ( trialResult )
                                case Enum.trialResult.ERROR
                                    status = IDLE;
                                    continue;
                                case Enum.trialResult.QUIT
                                    status = IDLE;
                                    continue;
                            end
                            
                            % -- Experiment or session finished ?
                            stats = this.GetStats();
                            if ( stats.trialsToFinishExperiment == 0 )
                                status = FINISHED;
                            elseif ( stats.trialsToFinishSession == 0 )
                                status = SESSIONFINISHED;
                            elseif ( trialsSinceBreak >= this.ExperimentDesign.Parameters.trialsBeforeBreak )
                                status = BREAK;
                            elseif ( trialsSinceCalibration >= this.ExperimentDesign.Parameters.trialsBeforeCalibration )
                                status = CALIBRATION;
                            elseif ( trialsSinceDriftCorrection >= this.ExperimentDesign.Parameters.trialsBeforeDriftCorrection )
                                status = DRIFTCORRECTION;
                            end
                            
                            %% ++ FINISHED -------------------------------------------------------
                        case {FINISHED,SESSIONFINISHED}
                            
                            if ( this.CurrentRun.CurrentSession < this.CurrentRun.SessionsToRun)
                                % -- session finished
                                this.CurrentRun.CurrentSession = this.CurrentRun.CurrentSession + 1;
                                this.Graph.DlgHitKey( 'Session finished, hit a key to exit' );
                            else
                                % -- experiment finished
                                % % %                     this.Graph.DlgHitKey( 'Experiment finished, hit a key to exit' );
                                this.Graph.DlgHitKey( 'Finished, hit a key to exit' );
                                
                            end
                            status = SAVEDATA;
                        case SAVEDATA
                            %% -- SAVE DATA --------------------------------------------------

                            
                            break; % finish loop
                    end
                end
                % --------------------------------------------------------------------
                %% -------------------- END EXPERIMENT LOOP ---------------------------
                % --------------------------------------------------------------------
                
                
            catch
                err = psychlasterror;
                disp(['Error: ' err.message ]);
                disp(err.stack(1));
            end %try..catch.
            
            
            % --------------------------------------------------------------------
            %% -- FREE RESOURCES -------------------------------------------------
            % --------------------------------------------------------------------
            
            ShowCursor;
            ListenChar(0);
            Priority(0);
            commandwindow;
            
            if ( ~isempty( this.EyeTracker ) )
                this.EyeTracker.Close();
            end
            
            Screen('CloseAll');
            % --------------------------------------------------------------------
            %% -------------------- END FREE RESOURCES ----------------------------
            % --------------------------------------------------------------------
            
        end
        
        
    end % methods (Access=private)
    
    
    methods ( Static = true )
        
        function Enum = getEnum()
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
        
    end
    
end

