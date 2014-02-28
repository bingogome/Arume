classdef ExperimentDesign < handle
    %EXPERIMENTDESIGN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        Project = [];
        Session = [];
        
        EyeTracker  = [];
        Graph       = [];
        SysInfo     = [];
        
        Config      = [];
        
        % Experimental variables
        ConditionVars = [];
        RandomVars = [];
        StaircaseVars = [];
        
        ConditionMatrix
        
        % Default parameters of any experiment
        trialSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
        trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
        trialsPerSession = 1;
        
        %%-- Blocking
        blockSequence       = 'Sequential';	% Sequential, Random, Random with repetition, ...numberOfTimesRepeatBlockSequence = 1;
        blocksToRun         = 1;
        blocks              =  struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 1) ;
        numberOfTimesRepeatBlockSequence = 1;
        
        trialsBeforeBreak	= 1000;
        trialDuration       = 5; %seconds
        
        % Other settings
        ForegroundColor = 0;
        BackgroundColor = 255;
    end
    
    % --------------------------------------------------------------------
    %% Protected abstract methods, to be implemented by the Experiments ---
    % --------------------------------------------------------------------
    methods (Access=protected)
        
        %% getVariables must be overriden by new experiments
        function conditionVars = getConditionVariables( this )
            conditionVars = [];
        end
        
        function  randomVars = getRandomVariables( this )
            randomVars = [];
        end
        
        function staircaseVars = getStaircaseVariables( this )
            staircaseVars = [];
        end
        
    end
    % --------------------------------------------------------------------
    %% Protected abstract methods, to be implemented by the Experiments ---
    % --------------------------------------------------------------------
    methods (Access=protected, Abstract)
        
        %% getParameters must be overriden by new experiments
        initExperimentDesign( this );
        
        %% runPreTrial
        runPreTrial(this, variables );
        
        %% runTrial
        [trialResult] = runTrial( this, variables);
        
        %% runPostTrial
        [trialOutput] = runPostTrial(this);
        
    end
    
    methods( Access = public, Abstract)
        %% ImportSession
        [trialDataSet, sampleDataSet] = ImportSession( this )
        
    end
    
    % --------------------------------------------------------------------
    %% PUBLIC and sealed METHODS ------------------------------------------
    % --------------------------------------------------------------------
    % to be called from gui or command line
    % --------------------------------------------------------------------
    methods
        
        function init(this, session)
            this.Project = session.project;
            
            this.Session = session;
            
            % load variables
            this.initVariables();
            
            % load parameters
            this.initParameters();
            
            this.Config = this.psyCortex_DefaultConfig();
            this.Config.Debug = 1;
        end
        
        function run(this)
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
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
                BREAK = 8;
                
                status = RUNNING;
                
                trialsSinceBreak = 0;
                
                while(1)
                    Screen('FillRect', this.Graph.window, this.Graph.dlgBackgroundScreenColor);
                    
                    switch( status )
                        
                        %% ++ IDLE -------------------------------------------------------
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
                                        status = SAVEDATA;
                                    end
                            end
                            
                            
                            %% ++ BREAK -------------------------------------------------------
                        case BREAK
                            dlgResult = this.Graph.DlgHitKey( 'Break: hit a key to continue',[],[] );
                            %             this.Graph.DlgTimer( 'Break');
                            %             dlgResult = this.Graph.DlgYesNo( 'Finish break and continue?');
                            % problems with breaks i am going to skip the timer
                            if ( ~dlgResult )
                                status = IDLE;
                            else
                                trialsSinceBreak            = 0;
                                status = RUNNING;
                            end
                            
                            %% ++ RUNNING -------------------------------------------------------
                        case RUNNING
                            if ( (exist('trialResult', 'var') && trialResult == Enum.trialResult.ABORT) || this.Config.HitKeyBeforeTrial )
                                dlgResult = this.Graph.DlgHitKey( 'Hit a key to continue',[],[]);
                                if ( ~dlgResult )
                                    status = IDLE;
                                    continue;
                                end
                            end
                            
                            try
                                %-- find which condition to run and the variable values for that condition
                                if ( ~isempty(this.Session.CurrentRun.pastConditions) )
                                    trialnumber = sum(this.Session.CurrentRun.pastConditions(:,Enum.pastConditions.trialResult)==Enum.trialResult.CORRECT)+1;
                                else
                                    trialnumber = 1;
                                end
                                currentCondition    = this.Session.CurrentRun.futureConditions(1,1);
                                variables           = this.getVariablesCurrentCondition( currentCondition );
                                
                                %------------------------------------------------------------
                                %% -- PRE TRIAL ----------------------------------------------
                                %------------------------------------------------------------
                                this.Graph.fliptimes{end +1} = zeros(100000,1);
                                this.Graph.NumFlips = 0;
                                
                                this.SaveEvent( Enum.Events.PRE_TRIAL_START);
                                this.runPreTrial( variables );
                                this.SaveEvent( Enum.Events.PRE_TRIAL_STOP);
                                
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
                                    this.EyeTracker.ChangeStatusMessage('TRIAL N=%d Cond=%d NtoBreak=%d', trialnumber, currentCondition, this.trialsBeforeBreak-trialsSinceBreak);
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
                                
                                this.Session.CurrentRun.Data{end+1} = data;
                                
                            catch
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
                            n = size(this.Session.CurrentRun.pastConditions,1)+1;
                            this.Session.CurrentRun.pastConditions(n, Enum.pastConditions.condition)    = this.Session.CurrentRun.futureConditions(1,Enum.futureConditions.condition );
                            this.Session.CurrentRun.pastConditions(n, Enum.pastConditions.trialResult)  = trialResult;
                            this.Session.CurrentRun.pastConditions(n, Enum.pastConditions.blocknumber)  = this.Session.CurrentRun.futureConditions(1,Enum.futureConditions.blocknumber);
                            this.Session.CurrentRun.pastConditions(n, Enum.pastConditions.blockid)      = this.Session.CurrentRun.futureConditions(1, Enum.futureConditions.blockid);
                            this.Session.CurrentRun.pastConditions(n, Enum.pastConditions.session)      = this.Session.CurrentRun.CurrentSession;
                            
                            if ( trialResult == Enum.trialResult.CORRECT )
                                %-- remove the condition that has just run from the future conditions list
                                this.Session.CurrentRun.futureConditions(1,:) = [];
                                
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
                                        currentblock = this.Session.CurrentRun.futureConditions(1,Enum.futureConditions.blocknumber);
                                        futureConditionsInCurrentBlock = this.Session.CurrentRun.futureConditions(this.Session.CurrentRun.futureConditions(:,Enum.futureConditions.blocknumber)==currentblock,:);
                                        
                                        newPosition = ceil(rand(1)*(size(futureConditionsInCurrentBlock,1)-1))+1;
                                        c = futureConditionsInCurrentBlock(1,:);
                                        futureConditionsInCurrentBlock(1,:) = futureConditionsInCurrentBlock(newPosition,:);
                                        futureConditionsInCurrentBlock(newPosition,:) = c;
                                        this.Session.CurrentRun.futureConditions(this.Session.CurrentRun.futureConditions(:,Enum.futureConditions.blocknumber)==currentblock,:) = futureConditionsInCurrentBlock;
                                        % TODO: improve
                                    case 'Drop'
                                        %-- remove the condition that has just run from the future conditions list
                                        this.Session.CurrentRun.futureConditions(1,:) = [];
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
                            stats = this.Session.CurrentRun.GetStats();
                            if ( stats.trialsToFinishExperiment == 0 )
                                status = FINISHED;
                            elseif ( stats.trialsToFinishSession == 0 )
                                status = SESSIONFINISHED;
                            elseif ( trialsSinceBreak >= this.trialsBeforeBreak )
                                status = BREAK;
                            end
                            
                            %% ++ FINISHED -------------------------------------------------------
                        case {FINISHED,SESSIONFINISHED}
                            if ( this.Session.CurrentRun.CurrentSession < this.Session.CurrentRun.SessionsToRun)
                                % -- session finished
                                this.Session.CurrentRun.CurrentSession = this.Session.CurrentRun.CurrentSession + 1;
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
        
        function abortExperiment(this, trial)
            throw(MException('PSYCORTEX:USERQUIT', ''));
        end
        
        function DisplayConditionMatrix(this)
            c = this.ConditionMatrix;
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
            config.HitKeyBeforeTrial = 0;
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
    methods(Access=protected)
        
        %% SaveEvent
        %--------------------------------------------------------------------------
        function SaveEvent( this, event )
            % TODO: think much better
            currentTrial            = size( this.Session.CurrentRun.pastConditions, 1) +1;
            currentCondition        = this.Session.CurrentRun.futureConditions(1);
            this.Session.CurrentRun.Events  = cat(1, this.Session.CurrentRun.Events, [GetSecs event currentTrial currentCondition] );
        end
        
        %% getVariablesCurrentCondition
        %--------------------------------------------------------------------------
        function variables = getVariablesCurrentCondition( this, currentCondition )
            
            % psyCortex_variablesCurrentCondition
            % gets the variables that correspond to the current condition
            
            conditionMatrix = this.ConditionMatrix;
            conditionVars = this.ConditionVars;
            
            variables = [];
            for iVar=1:length(conditionVars)
                varName = conditionVars(iVar).name;
                varValues = conditionVars(iVar).values;
                if iscell( varValues )
                    variables.(varName) = varValues{conditionMatrix(currentCondition,iVar)};
                else
                    variables.(varName) = varValues(conditionMatrix(currentCondition,iVar));
                end
            end
            
            for iVar=1:length(this.RandomVars)
                varName = this.RandomVars(iVar).name;
                varType = this.RandomVars(iVar).type;
                if ( isfield( this.RandomVars(iVar), 'values' ) )
                    varValues = this.RandomVars(iVar).values;
                end
                if ( isfield( this.RandomVars(iVar), 'params' ) )
                    varParams = this.RandomVars(iVar).params;
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
        
        %% setUpVariables
        function initVariables(this)
            this.ConditionVars = this.getConditionVariables();
            this.RandomVars = this.getRandomVariables();
            
            this.ConditionMatrix = this.getConditionMatrix( this.ConditionVars );
        end
        
        %% setUpParameters
        function initParameters(this)
            
            numberOfConditions = size(this.ConditionMatrix,1);
            
            % default parameters of any experiment
            this.trialsPerSession = numberOfConditions;
            
            %%-- Blocking
            this.blocks(1).toCondition    = numberOfConditions;
            this.blocks(1).trialsToRun    = numberOfConditions;
            
            this.trialsBeforeBreak = numberOfConditions;
            
            %-- init the parameters of this specific experiment
            this.initExperimentDesign( );
        end
        
        
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
        
        
        
        
    end % methods (Access=private)
    
    
    methods ( Static = true )
        function experimentList = GetExperimentList()
            experimentList = {};
            
            expPackage = meta.package.fromName('ExperimentDesigns');
            
            for i=1:length(expPackage.ClassList)
                experimentList{i} = strrep( expPackage.ClassList(i).Name, 'ExperimentDesigns.','');
            end
        end
        
        function experiment = Create(session, experimentName)
            experiment = ExperimentDesigns.(experimentName)();
            
            experiment.init(session);
        end
        
        function Enum = getEnum()
            % -- possible trial results
            Enum.trialResult.CORRECT = 0; % Trial finished correctly
            Enum.trialResult.ABORT = 1;   % Trial not finished, wrong key pressed, subject did not fixate, etc
            Enum.trialResult.ERROR = 2;   % Error during the trial
            Enum.trialResult.QUIT = 3;    % Escape was pressed during the trial
            
            
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

