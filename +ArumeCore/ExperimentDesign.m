classdef ExperimentDesign < handle
    %EXPERIMENTDESIGN Base class for all experiment designs (paradigms).
    % All experiment designs must inherit from this class and must override
    % some of the methods.
    %
    % A experiment design contains the main trail flow but also a lot of
    % options regarding configuration of the experiment, randomization,
    % etc.
    
    properties( SetAccess = private)
        Session = [];       % The session that is current running this experiment design
        
        Graph       = [];   % Display handle (psychtoolbox).
        Config      = [];   % Configuration of the system.
        
        ExperimentOptions = [];  % Options of this specific experiment design
        
        % Experimental variables
        ConditionVars = [];
        ConditionMatrix
        
        TrialStartCallbacks
        TrialStopCallbacks
    end
    
    properties ( Dependent = true )
        Name
        
        NumberOfConditions
    end
    
    methods
        function name = get.Name(this)
            className = class(this);
            name = className(find(className=='.',1, 'last')+1:end);
        end
        
        function number = get.NumberOfConditions(this)
            number = size(this.ConditionMatrix,1);
        end
    end
    
    %
    % Options for every experimental paradigm
    %
    properties
        DisplayToUse = 'ptbScreen'; % 'ptbScreen' 'cmdline'
        
        HitKeyBeforeTrial = 0;
        
        ForegroundColor = 0;
        BackgroundColor = 0;
        
        % Trial sequence and blocking
        trialSequence       = 'Sequential';	% Sequential, Random, Random with repetition, ...
        trialAbortAction    = 'Repeat';     % Repeat, Delay, Drop
        trialsPerSession    = 1;
        trialsBeforeBreak   = 1;
        
        blockSequence       = 'Sequential';	% Sequential, Random, Random with repetition, ...numberOfTimesRepeatBlockSequence = 1;
        blocksToRun         = 1;
        blocks              =  struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 1) ;
        numberOfTimesRepeatBlockSequence = 1;
        
        % Other parameters
        trialDuration       = 5; %seconds
    end
    
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % THESE ARE THE METHODS THAT SHOULD BE IMPLEMENTED BY NEW EXPERIMENT
    % DESIGNS
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access=protected)
        
        % Gets the options that be set in the UI when creating a new
        % session of this experiment (in structdlg format)
        % Some common options will be added
        function dlg = GetOptionsDialog( this )
            dlg = [];
        end
        
        function conditionVars = getConditionVariables( this )
            conditionVars = this.ConditionVars;
        end
        
        % run initialization when the session is created.
        % Use this to set parameters of the trial sequence, etc.
        % This is executed at the time of creating a session
        function initExperimentDesign( this )
            
        end
        
        % run initialization before the first trial is run
        % Use this function to initialize things that need to be
        % initialized before running but don't need to be initialized for
        % every single trial
        function shouldContinue = initBeforeRunning( this )
            shouldContinue = 1;
        end
        
        % runPreTrial
        % use this to prepare things before the trial starts
        function runPreTrial(this, variables )
        end
        
        % runTrial
        function [trialResult] = runTrial( this, variables)
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;
        end
        
        % runPostTrial
        function [trialOutput] = runPostTrial(this)
            trialOutput = [];
        end
        
        % run cleaning up after the session is completed or interrupted
        function cleanAfterRunning(this)
        end
        
        % --------------------------------------------------------------------
        % Analysis methods --------------------------------------------------
        % --------------------------------------------------------------------
        
        function [samplesDataTable, rawDataTable] = PrepareSamplesDataTable(this)
            samplesDataTable= [];
            rawDataTable = [];
        end
        
        function trialDataTable = PrepareTrialDataTable( this, trialDataTable)
        end
        
        function eventDataTable = PrepareEventDataTable(this, eventDataTable)
        end
        
        function sessionDataTable = PrepareSessionDataTable(this, sessionDataTable)
        end
        
    end
    
    methods(Access=protected,Sealed=true)
        
        function AddTrialStartCallback(this, fun)
            if ( isempty(this.TrialStartCallbacks) )
                this.TrialStartCallbacks = {fun};
            else
                this.TrialStartCallbacks{end+1} = fun;
            end
        end
        
        function AddTrialStopCallback(this, fun)
            if ( isempty(this.TrialStopCallbacks) )
                this.TrialStopCallbacks = {fun};
            else
                this.TrialStopCallbacks{end+1} = fun;
            end
        end
        
    end
    
    methods (Access = public)
        function trialTable = GetTrialTable(this)
            
            % generate the sequence of blocks, a total of
            % parameters.blocksToRun blocks will be run
            nBlocks = length(this.blocks);
            blockSeq = [];
            switch(this.blockSequence)
                case 'Sequential'
                    blockSeq = mod( (1:this.blocksToRun)-1,  nBlocks ) + 1;
                case 'Random'
                    [~, theBlocks] = sort( rand(1,this.blocksToRun) ); % get a random shuffle of 1 ... blocks to run
                    blockSeq = mod( theBlocks-1,  nBlocks ) + 1; % limit the random sequence to 1 ... nBlocks
                case 'Random with repetition'
                    blockSeq = ceil( rand(1,this.blocksToRun) * nBlocks ); % just get random block numbers
                case 'Manual'
                    blockSeq = [];
                    
                    while length(blockSeq) ~= this.blocksToRun
                        S.Block_Sequence = [1:this.blocksToRun];
                        S = StructDlg( S, ['Block Sequence'], [],  CorrGui.get_default_dlg_pos() );
                        blockSeq =  S.Block_Sequence;
                    end
                    %                     if length(parameters.manualBlockSequence) == parameters.blocksToRun;
                    %                         %                         blockSequence = parameters.manualBlockSequence;
                    %
                    %                     else
                    %                         disp(['Error with the manual block sequence. Please fix.']);
                    %                     end
            end
            blockSeq = repmat( blockSeq,1,this.numberOfTimesRepeatBlockSequence);
            
            futureConditions = [];
            for iblock=1:length(blockSeq)
                i = blockSeq(iblock);
                possibleConditions = this.blocks(i).fromCondition : this.blocks(i).toCondition; % the possible conditions to select from in this block
                nConditions = length(possibleConditions);
                nTrials = this.blocks(i).trialsToRun;
                
                switch( this.trialSequence )
                    case 'Sequential'
                        trialSeq = possibleConditions( mod( (1:nTrials)-1,  nConditions ) + 1 );
                    case 'Random'
                        [~, conditions] = sort( rand(1,nTrials) ); % get a random shuffle of 1 ... nTrials
                        conditionIndexes = mod( conditions-1,  nConditions ) + 1; % limit the random sequence to 1 ... nConditions
                        trialSeq = possibleConditions( conditionIndexes ); % limit the random sequence to fromCondition ... toCondition for this block
                    case 'Random with repetition'
                        trialSeq = possibleConditions( ceil( rand(1,nTrials) * nConditions ) ); % nTrialss numbers between 1 and nConditions
                end
                futureConditions = cat(1,futureConditions, [trialSeq' ones(size(trialSeq'))*iblock  ones(size(trialSeq'))*i] );
            end
            
            newTrialTable = table();
            newTrialTable.Condition = futureConditions(:,1);
            newTrialTable.BlockNumber = futureConditions(:,2);
            newTrialTable.BlockSequenceNumber = futureConditions(:,3);
            newTrialTable.Session = ceil((1:height(newTrialTable))/this.trialsPerSession)';
            
            variableTable = table();
            for i=1:height(newTrialTable)
                vars = this.getVariablesCurrentCondition( newTrialTable.Condition(i) );
                variableTable = cat(1,variableTable,struct2table(vars,'AsArray',true));
            end
            
            trialTable = [newTrialTable variableTable];
        end
        
        %% ImportSession
        function ImportSession( this )
        end
        
        function UpdateExperimentOptions(this, newOptions)
            this.ExperimentOptions = newOptions;
        end
    end
    
    % --------------------------------------------------------------------
    %% PUBLIC and sealed METHODS ------------------------------------------
    % --------------------------------------------------------------------
    % to be called from gui or command line
    % --------------------------------------------------------------------
    methods(Sealed = true)
        
        %
        % Options to set at runtime, this options will appear as a dialog
        % when creating a new session. If one experiment inherits from another
        % one it is a good idea to first call GetExperimentDesignOptions from
        % the parent class to get the options and then add new ones.
        %
        % This options may also appear when importing a session and it is
        % possible that the parameters that want to be displaied in that
        % case are different
        function dlg = GetExperimentOptionsDialog( this, importing )
            if ( ~exist( 'importing', 'var') )
                importing = 0;
            end
            dlg = this.GetOptionsDialog(importing);
        end
        
        function init(this, session, options)
            if ( exist( 'session', 'var') && exist('options', 'var') )
                this.Session            = session;
                this.ExperimentOptions  = options;
            end
            
            %-- init variables
            this.ConditionVars      = this.getConditionVariables();
            this.ConditionMatrix    = this.getConditionMatrix( this.ConditionVars );
            
            %-- init options
            %-- Check if all the options are there, if not add the default
            % values. This is important to mantain past compatibility if
            % options are added in the future.
            optionsDlg = this.GetOptionsDialog( );
            if ( ~isempty( optionsDlg ) )
                options = StructDlg(optionsDlg,'',[],[],'off');
                fields = fieldnames(options);
                for i=1:length(fields)
                    if ( ~isfield(this.ExperimentOptions, fields{i}))
                        this.ExperimentOptions.(fields{i}) = options.(fields{i});
                    end
                end
            end
            
            % default parameters of any experiment
            this.trialsPerSession   = this.NumberOfConditions;
            this.trialsBeforeBreak  = this.NumberOfConditions;            
            
            %-- Blocking
            this.blocks(1).toCondition    = this.NumberOfConditions;
            this.blocks(1).trialsToRun    = this.NumberOfConditions;
            
            %-- init the parameters of this specific experiment
            this.initExperimentDesign( );
            
            this.Config = this.psyCortex_DefaultConfig();
            this.Config.Debug = 1;
        end
        
        function run(this)
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            % --------------------------------------------------------------------
            %% -- EXPERIMENT LOOP -------------------------------------------------
            % --------------------------------------------------------------------
            INITIALIZNG_HARDWARE = 0;
            INITIALIZNG_EXPERIMENT = 1;
            IDLE = 2;
            RUNNING = 3;
            FINILIZING_EXPERIMENT = 4;
            SESSIONFINISHED = 5;
            BREAK = 6;
            FINALIZING_HARDWARE = 7;
            
            status = INITIALIZNG_HARDWARE;
            
            trialsSinceBreak = 0;
            
            while(1)
                try
                    switch( status )
                        % -------------------------------------------------
                        % ++ INITIALIZNG_HARDWARE -------------------------
                        % -------------------------------------------------
                        case INITIALIZNG_HARDWARE
                            
                            % -- GRAPHICS KEYBOARD and MOUSE
                            if ( this.Config.UsingVideoGraphics )
                                
                                %-- hide the mouse cursor during the experiment
                                if ( ~this.Config.Debug )
                                    HideCursor;
                                    ListenChar(1);
                                else
                                    ListenChar(1);
                                end
                                
                                
                                switch(this.DisplayToUse)
                                    case 'ptbScreen'
                                        this.Graph = ArumeCore.Display( );
                                    case 'cmdline'
                                        this.Graph = ArumeCore.DisplayCmdLine( );
                                end
                                this.Graph.Init( this );
                            else
                                this.Graph = [];
                            end
                            status = INITIALIZNG_EXPERIMENT;
                            
                            % ---------------------------------------------
                            % ++ INITIALIZNG_EXPERIMENT -------------------
                            % ---------------------------------------------
                        case INITIALIZNG_EXPERIMENT
                            
                            this.TrialStartCallbacks = [];
                            this.TrialStopCallbacks = [];
                            
                            shouldContinue = this.initBeforeRunning();
                            
                            if ( shouldContinue )
                                status = RUNNING;
                            else
                                status = FINILIZING_EXPERIMENT;
                            end
                            
                            % ---------------------------------------------
                            % ++ IDLE -------------------------------------
                            % ---------------------------------------------
                        case IDLE
                            result = this.Graph.DlgSelect( ...
                                'Choose an option:', ...
                                { 'n' 'q'}, ...
                                { 'Next trial'  'Quit'} , [],[]);
                            
                            switch( result )
                                case 'n'
                                    status = RUNNING;
                                case {'q' 0}
                                    dlgResult = this.Graph.DlgYesNo( 'Are you sure you want to exit?',[],[],20,20);
                                    if( dlgResult )
                                        status = FINILIZING_EXPERIMENT;
                                    end
                            end
                            
                            % ---------------------------------------------
                            % ++ BREAK ------------------------------------
                            % ---------------------------------------------
                        case BREAK
                            dlgResult = this.Graph.DlgHitKey( 'Break: hit a key to continue',[],[] );
                            %             this.Graph.DlgTimer( 'Break');
                            %             dlgResult = this.Graph.DlgYesNo( 'Finish break and continue?');
                            % problems with breaks i am going to skip the timer
                            if ( ~dlgResult )
                                status = IDLE;
                            else
                                trialsSinceBreak = 0;
                                status = RUNNING;
                            end
                            
                            % ---------------------------------------------
                            % ++ RUNNING ----------------------------------
                            % ---------------------------------------------
                        case RUNNING
                            % force to hit a key to continue if the
                            % previous trial was an abort or if the
                            % experiment is set to ask for hit key before
                            % every trial
                            if ( (~isempty(this.Session.currentRun.pastTrialTable) && this.Session.currentRun.pastTrialTable.TrialResult(end) == Enum.trialResult.ABORT) ...
                                     || this.HitKeyBeforeTrial )
                                dlgResult = this.Graph.DlgHitKey( 'Hit a key to continue',[],[]);
                                if ( ~dlgResult )
                                    status = IDLE;
                                    continue;
                                end
                            end
                            
                            try
                                commandwindow;
                                
                                %-- find which condition to run and the variable values for that condition
                                trialData = table();
                                trialData.TrialNumber  = height(this.Session.currentRun.pastTrialTable)+1;
                                trialData.DateTimeTrialStart = datestr(now);
                                trialData = [trialData this.Session.currentRun.futureTrialTable(1,:)];
                                
                                fprintf('\nARUME :: TRIAL %d START: ...\n', trialData.TrialNumber);
                                
                                %------------------------------------------------------------
                                %% -- PRE TRIAL ----------------------------------------------
                                %------------------------------------------------------------
                                trialData.TimePreTrialStart = GetSecs;
                                
                                this.runPreTrial( trialData );
                                
                                trialData.TimePreTrialStop = GetSecs;
                                
                                %------------------------------------------------------------
                                %% -- TRIAL ---------------------------------------------------
                                %------------------------------------------------------------
                                trialData.TimeTrialStart = GetSecs;
                                for i=1:length(this.TrialStartCallbacks)
                                    trialData = feval(this.TrialStartCallbacks{i}, trialData);
                                end
                                
                                trialData.TrialResult = this.runTrial( trialData );
                                
                                trialData.TimeTrialStop = GetSecs;
                                for i=1:length(this.TrialStopCallbacks)
                                    trialData = feval(this.TrialStopCallbacks{i}, trialData);
                                end
                                
                                %------------------------------------------------------------
                                %% -- POST TRIAL ----------------------------------------------
                                %------------------------------------------------------------
                                
                                this.PlaySound(trialData.TrialResult);
                                
                                trialData.TimePostTrialStart = GetSecs;
                                
                                trialOutput = this.runPostTrial(  );
                                
                                trialData.TimePostTrialStop = GetSecs;
                                
                            catch err
                                if ( streq(err.identifier, 'PSYCORTEX:USERQUIT' ) )
                                    trialData.TrialResult = Enum.trialResult.QUIT;
                                else
                                    trialData.TrialResult = Enum.trialResult.ERROR;
                                    trialData.ErrorMessage = err.message;
                                    % display error
                                    disp('!!!!!!!!!!!!! ARUME ERROR: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                                    disp(err.getReport);
                                    disp('!!!!!!!!!!!!! END ARUME ERROR: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
                                    this.Graph.DlgHitKey( ['Error, trial could not be run: \n' err.message],[],[] );
                                end
                            end
                            
                            % -- Update past trial table
                            this.Session.currentRun.AddPastTrialData(trialData, trialOutput);
                            
                            % -- Display trial Table for last 20 trials
                            condvars = struct2table(this.Session.experimentDesign.ConditionVars);
                            outputVars = {};
                            if ( ~isempty( trialOutput) )
                                outputVars = fieldnames(trialOutput);
                            end
                            varSelection = {'TrialNumber'  outputVars{:} 'TrialResult' condvars.name{:} };
                            trials = this.Session.currentRun.pastTrialTable;
                            varSelection = intersect(varSelection,trials.Properties.VariableNames,'stable');
                            disp(trials(max(1,height(trials)-20):end,varSelection));
                            
                            
                            if ( trialData.TrialResult == Enum.trialResult.CORRECT )
                                %-- remove the condition that has just run from the future conditions list
                                this.Session.currentRun.futureTrialTable(1,:) = [];
                                
                                %-- save to disk temporary data
                                %//TODO this.SaveTempData();
                                
                                trialsSinceBreak = trialsSinceBreak + 1;
                            else
                                %-- what to do in case of abort
                                switch(this.trialAbortAction)
                                    case 'Repeat'
                                        % do nothing
                                    case 'Delay'
                                        % randomly get one of the future conditions in the current block
                                        % and switch it with the next
                                        currentblock = this.Session.currentRun.futureTrialTable.BlockNumber(1);
                                        currentblockSeqNumber = this.Session.currentRun.futureTrialTable.BlockSequenceNumber(1);
                                        futureConditionsInCurrentBlock = this.Session.currentRun.futureTrialTable(this.Session.currentRun.futureTrialTable.BlockNumber==currentblock & this.Session.currentRun.futureTrialTable.BlockSequenceNumber==currentblockSeqNumber,:);
                                        
                                        newPosition = ceil(rand(1)*(height(futureConditionsInCurrentBlock)-1))+1;
                                        c = futureConditionsInCurrentBlock(1,:);
                                        futureConditionsInCurrentBlock(1,:) = futureConditionsInCurrentBlock(newPosition,:);
                                        futureConditionsInCurrentBlock(newPosition,:) = c;
                                        this.Session.currentRun.futureTrialTable(this.Session.currentRun.futureTrialTable.BlockNumber==currentblock & this.Session.currentRun.futureTrialTable.BlockSequenceNumber==currentblockSeqNumber,:) = futureConditionsInCurrentBlock;
                                    case 'Drop'
                                        %-- remove the condition that has just run from the future conditions list
                                        this.Session.currentRun.futureTrialTable(1,:) = [];
                                end
                            end
                            
                            %-- handle errors
                            switch ( trialData.TrialResult )
                                case Enum.trialResult.ERROR
                                    status = IDLE;
                                    continue;
                                case Enum.trialResult.QUIT
                                    status = IDLE;
                                    continue;
                            end
                            
                            % -- Experiment or session finished ?
                            if ( trialsSinceBreak >= this.trialsBeforeBreak )
                                status = BREAK;
                            end
                            if ( ~isempty(this.Session.currentRun.futureTrialTable) && ~isempty(this.Session.currentRun.pastTrialTable) )
                                if ( this.Session.currentRun.pastTrialTable.Session(end) ~= this.Session.currentRun.futureTrialTable.Session(1) )
                                    status = SESSIONFINISHED;
                                end
                            end
                            if ( isempty(this.Session.currentRun.futureTrialTable) )
                                status = FINILIZING_EXPERIMENT;
                            end
                            
                            % ---------------------------------------------
                            % ++ FINISHED ---------------------------------
                            % ---------------------------------------------
                        case {SESSIONFINISHED}
                            cprintf('blue', '---------------------------------------------------------\n')
                            cprintf('blue', '---------------------------------------------------------\n')
                            cprintf('blue', 'Session part finished! closing down and saving data ...\n');
                            cprintf('blue', '---------------------------------------------------------\n')
                            cprintf('blue', '---------------------------------------------------------\n')
                            status = FINILIZING_EXPERIMENT;
                            
                            % ---------------------------------------------
                            % ++ FINILIZING_EXPERIMENT --------------------
                            % ---------------------------------------------
                        case FINILIZING_EXPERIMENT
                            cprintf('blue', '---------------------------------------------------------\n')
                            cprintf('blue', '---------------------------------------------------------\n')
                            cprintf('blue', 'Session finished! closing down and saving data ...\n');
                            cprintf('blue', '---------------------------------------------------------\n')
                            cprintf('blue', '---------------------------------------------------------\n')
                            
                            this.cleanAfterRunning();
                            
                            status = FINALIZING_HARDWARE;
                            
                            % ---------------------------------------------
                            % ++ FINALIZING_HARDWARE ----------------------
                            % ---------------------------------------------
                        case FINALIZING_HARDWARE
                            
                            ShowCursor;
                            ListenChar(0);
                            Priority(0);
                            
                            this.Graph = [];
                            Screen('CloseAll');
                            disp('ARUME:: Done closing display and connections!');
                            break; % finish loop
                            
                    end
                catch lastError
                    beep
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!! ARUME ERROR: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    disp(lastError.getReport);
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!! END ARUME ERROR: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    
                    if ( status == FINILIZING_EXPERIMENT )
                        break; % finish loop
                    end
                    
                    status = FINILIZING_EXPERIMENT;
                end
            end
            % --------------------------------------------------------------------
            %% -------------------- END EXPERIMENT LOOP ---------------------------
            % --------------------------------------------------------------------
        end
        
        function abortExperiment(this, trial)
            throw(MException('PSYCORTEX:USERQUIT', ''));
        end
        
        function conditionTable = GetConditionTable(this)
            cm = table();
            for i=1:size(this.ConditionMatrix,1)
                for j=1:size(this.ConditionMatrix,2)
                    var = this.ConditionVars(j);
                    if ( iscell(var.values) )
                        if ( width(cm) < j )
                            cm.(var.name) = cell(size(this.ConditionMatrix(:,j)));
                        end
                        cm{i,j} = {var.values{this.ConditionMatrix(i,j)}};
                    else
                        if ( width(cm) < j )
                            cm.(var.name) = nan(size(this.ConditionMatrix(:,j)));
                        end
                        cm{i,j} = var.values(this.ConditionMatrix(i,j));
                    end
                end
            end
            conditionTable = cm;
        end
        
        function DisplayConditionMatrix(this)
            
            this.GetConditionTable()
        end
        
        %% function psyCortex_defaultConfig
        %--------------------------------------------------------------------------
        function config = psyCortex_DefaultConfig(this)
            
            config.UsingEyeTracking = 1;
            config.UsingVideoGraphics = 1;
            
            config.Debug = 0;
            config.Graphical.mmMonitorWidth    = 400;
            config.Graphical.mmMonitorHeight   = 300;
            config.Graphical.mmDistanceToMonitor = 600;
            config.Graphical.backGroundColor = 'black';
            config.Graphical.textColor = 'white';
        end
        
    end
    
    
    % --------------------------------------------------------------------
    %% Protected methods --------------------------------------------------
    % --------------------------------------------------------------------
    % to be called from any experiment
    % --------------------------------------------------------------------
    methods(Access=public)
        
        %% getVariablesCurrentCondition
        %--------------------------------------------------------------------------
        function variables = getVariablesCurrentCondition( this, currentCondition )
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            conditionMatrix = this.ConditionMatrix;
            conditionVars = this.ConditionVars;
            
            %
            % Condition variables
            %
            variables = [];
            for iVar=1:length(conditionVars)
                varName = conditionVars(iVar).name;
                varValues = conditionVars(iVar).values;
                if iscell( varValues )
                    variables.(varName) = categorical(varValues(conditionMatrix(currentCondition,iVar)));
                else
                    variables.(varName) = varValues(conditionMatrix(currentCondition,iVar));
                end
            end
        end
        
        function shuffleConditionMatrix(this, variableNumber)
            this.ConditionMatrix(:,variableNumber) = Shuffle(this.ConditionMatrix(:,variableNumber));
        end
        
        %% ShowDebugInfo
        function ShowDebugInfo( this, variables )
            if ( this.Config.Debug )
                currentline = 50 + 25;
                vNames = fieldnames(variables);
                for iVar = 1:length(vNames)
                    if ( ischar(variables.(vNames(iVar))) )
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
        
    end % methods(Access=protected)
    
    
    % --------------------------------------------------------------------
    %% Private methods ----------------------------------------------------
    % --------------------------------------------------------------------
    % to be called only by this class
    % --------------------------------------------------------------------
    methods (Access=private)
                
        %% setUpConditionMatrix
        function conditionMatrix = getConditionMatrix( this, conditionVars )
            
            %-- total number of conditions is the product of the number of
            % values of each condition variable
            nConditions = 1;
            for iVar = 1:length(conditionVars)
                nConditions = nConditions * length(conditionVars(iVar).values);
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
                nValues(iVar) = length(conditionVars(iVar).values);
                conditionMatrix = [ repmat(conditionMatrix,nValues(iVar),1)  ceil((1:prod(nValues))/prod(nValues(1:end-1)))' ];
            end
        end
        
        function PlaySound(this,trialResult)
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            %% make a sound for the end of the trial
            fs = 8000;
            T = 0.1; % 2 seconds duration
            t = 0:(1/fs):T;
            if ( trialResult == Enum.trialResult.CORRECT )
                f = 500;
            else
                f = 250;
            end
            y = sin(2*pi*f*t);
            sound(y, fs);
        end
    end % methods (Access=private)
    
    
    methods ( Static = true )
        
        function experimentList = GetExperimentList()
            experimentList = {};
            
            expPackage = meta.package.fromName('ArumeExperimentDesigns');
            disp('Setting up experiments...')
            for i=1:length(expPackage.ClassList)
                if (~expPackage.ClassList(i).Abstract)
                    experimentList{end+1} = strrep( expPackage.ClassList(i).Name, 'ArumeExperimentDesigns.','');
                    disp(experimentList{end});
                end
            end
        end
        
        function experiment = Create(experimentName)
            
            if ( exist( ['ArumeExperimentDesigns.' experimentName],  'class') )
                % Create the experiment design object
                experiment = ArumeExperimentDesigns.(experimentName)();
            else
                % Create the experiment design object
                experiment = ArumeExperimentDesigns.BlankExperiment();
            end
        end
        
        function Enum = getEnum()
            % -- possible trial results
            Enum.trialResult.CORRECT = categorical(cellstr('CORRECT')); % Trial finished correctly
            Enum.trialResult.ABORT = categorical(cellstr('ABORT'));   % Trial not finished, wrong key pressed, subject did not fixate, etc
            Enum.trialResult.ERROR = categorical(cellstr('ERROR'));   % Error during the trial
            Enum.trialResult.QUIT = categorical(cellstr('QUIT'));    % Escape was pressed during the trial
            Enum.trialResult.SOFTABORT = categorical(cellstr('SOFTABORT')); % Like an abort but does not go to hitkey to continue
            Enum.trialResult.PossibleResults = [...
                Enum.trialResult.CORRECT ...
                Enum.trialResult.ABORT ...
                Enum.trialResult.ERROR ...
                Enum.trialResult.QUIT ...
                Enum.trialResult.SOFTABORT]';
                
            
            % -- useful key codes
            try
                
                KbName('UnifyKeyNames');
                Enum.keys.SPACE     = KbName('space');
                Enum.keys.ESCAPE    = KbName('ESCAPE');
                Enum.keys.RETURN    = KbName('return');
                % Enum.keys.BACKSPACE = KbName('backspace');
                %
                %             Enum.keys.TAB       = KbName('tab');
                %             Enum.keys.SHIFT     = KbName('shift');
                %             Enum.keys.CONTROL   = KbName('control');
                %             Enum.keys.ALT       = KbName('alt');
                %             Enum.keys.END       = KbName('end');
                %             Enum.keys.HOME      = KbName('home');
                
                Enum.keys.LEFT      = KbName('LeftArrow');
                Enum.keys.UP        = KbName('UpArrow');
                Enum.keys.RIGHT     = KbName('RightArrow');
                Enum.keys.DOWN      = KbName('DownArrow');
            catch
            end
            
        end
        
    end
end

