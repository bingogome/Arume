classdef ExperimentDesign < handle
    %EXPERIMENTDESIGN Base class for all experiment designs (paradigms).
    % All experiment designs must inherit from this class and must override
    % some of the methods.
    %
    % A experiment design contains the main trail flow but also a lot of
    % options regarding configuration of the experiment, randomization,
    % etc.
    
    properties( SetAccess = private)
        Project = [];       % The project that this experiment design belongs to.
        Session = [];       % The session that is current running this experiment design
        
        Graph       = [];   % Display handle (psychtoolbox).
        SysInfo     = [];   % Information regarding the system
        
        Config      = [];   % Configuration of the system.
        
        ExperimentOptions = [];  % Options of this specific experiment design
        
        % Experimental variables
        ConditionVars = [];
        RandomVars = [];
        StaircaseVars = [];
        
        ConditionMatrix 
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
        trialSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
        trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
        trialsPerSession = 1;
        
        blockSequence       = 'Sequential';	% Sequential, Random, Random with repetition, ...numberOfTimesRepeatBlockSequence = 1;
        blocksToRun         = 1;
        blocks              =  struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 1) ;
        numberOfTimesRepeatBlockSequence = 1;
        
        % Other parameters
        trialsBeforeBreak	= 1000;
        trialDuration       = 5; %seconds
    end
   
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % THESE ARE THE METHODS THAT CAN BE IMPLEMENTED BY NEW EXPERIMENT
    % DESIGNS
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods (Access=protected)
        
        % Gets the options that be set in the UI when creating a new 
        % session of this experiment (in structdlg format)
        % Some common options will be added
        function dlg = GetOptionsDialog( this )
            dlg = [];
        end
        
        function conditionVars = getConditionVariables( this )
            conditionVars = [];
        end
        
        function  randomVars = getRandomVariables( this )
            randomVars = [];
        end
        
        function staircaseVars = getStaircaseVariables( this )
            staircaseVars = [];
        end
        
        %% run initialization when the session is created.
        % Use this to set parameters of the trial sequence, etc.
        % This is executed at the time of creating a session
        function initExperimentDesign( this )
            
        end
        
        %% run initialization before the first trial is run
        % Use this function to initialize things that need to be
        % initialized before running but don't need to be initialized for
        % every single trial
        function initBeforeRunning( this )
        end
        
        %% runPreTrial
        % use this to prepare things before the trial starts
        function runPreTrial(this, variables )
        end
        
        %% runTrial
        function [trialResult] = runTrial( this, variables)
            Enum = ArumeCore.ExperimentDesign.getEnum();
            trialResult = Enum.trialResult.CORRECT;
        end
        
        %% runPostTrial
        function [trialOutput] = runPostTrial(this)
            trialOutput = [];
        end
        
        %% run cleaning up after the session is completed or interrupted
        function cleanAfterRunning(this)
        end
        
        %% runs after the session is completed
        function runAfterSessionCompleted(this)
        end
    end
    
    
    methods( Access = public)
        
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
        % It needs to be static because it is called before the experimental
        % session and the experiment design is created
        function dlg = GetExperimentOptionsDialog( this )
            
%             experimentOptions = [];
%             myclass = meta.class.fromName(class(this));
%             while( ~isempty( myclass.SuperClasses ) )
%                 if ( ismethod( eval(myclass.Name), 'GetOptionsDialog') )
%                     experimentOptions = mergestructs( feval([myclass.Name '.GetOptionsDialog']), experimentOptions);
%                 end
%                 myclass = myclass.SuperClasses{1};
%             end
            
            dlg = this.GetOptionsDialog();
        end
        
        function init(this, session, options)
            this.Project            = session.project;
            this.Session            = session;
            this.ExperimentOptions  = options;
            
            % load variables
            this.initVariables();
            
            % load parameters
            this.initParameters();
            
            %-- init the parameters of this specific experiment
            this.initExperimentDesign( );
            
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
                    
                    
                    switch(this.DisplayToUse)
                        case 'ptbScreen'
                            Screen('Preference', 'VisualDebugLevel', 3);
                            this.Graph = ArumeCore.Display( );
                        case 'cmdline'    
                            this.Graph = ArumeCore.DisplayCmdLine( );
                    end
                    this.Graph.Init( this );
                else
                    this.Graph = [];
                end
                
            catch
                % If any error during the start up
                
                err = psychlasterror;
                
                % display error
                disp(['PSYCORTEX: Hardware set up failed: ' err.message ]);
                disp(err.stack(1));
                
                if ( this.Config.UsingVideo )
                    ShowCursor;
                    ListenChar(0);
                    Priority(0);
                    
                    Screen('CloseAll');
                    commandwindow;
                end
                
                return;
            end
            
            
            % --------------------------------------------------------------------
            %% -- INITIALIZE EXPERIMENT ------------------------------------------
            % --------------------------------------------------------------------
            
            try
                this.initBeforeRunning();
            catch
                err = psychlasterror;
                disp(['Error initializing: ' err.message ]);
                disp(err.stack(1));
                
                return;
                                    
                this.cleanAfterRunning();                
                ShowCursor;
                ListenChar(0);
                Priority(0);
                commandwindow;
            end
            
            
            % --------------------------------------------------------------------
            %% -- EXPERIMENT LOOP -------------------------------------------------
            % --------------------------------------------------------------------
            try
                
                IDLE = 0;
                RUNNING = 1;
                SESSIONFINISHED = 2;
                SAVEDATA = 3;
                BREAK = 4;
                INTERRUPTED = 5;
                
                status = RUNNING;
                
                trialsSinceBreak = 0;
                
                while(1)
                    this.Graph.ResetBackground();
                    
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
                                        status = INTERRUPTED;
                                    end
                            end
                            
                        %% ++ INTERRUPTED -------------------------------------------------------
                        case INTERRUPTED
                            
                            status = SAVEDATA;
                            
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
                            if ( (exist('trialResult', 'var') && trialResult == Enum.trialResult.ABORT) || this.HitKeyBeforeTrial )
                                dlgResult = this.Graph.DlgHitKey( 'Hit a key to continue',[],[]);
                                if ( ~dlgResult )
                                    status = IDLE;
                                    continue;
                                end
                            end
                            
                            try
                                %-- find which condition to run and the variable values for that condition
                                if ( ~isempty(this.Session.currentRun.pastConditions) )
                                    trialnumber = sum(this.Session.currentRun.pastConditions(:,Enum.pastConditions.trialResult)==Enum.trialResult.CORRECT)+1;
                                else
                                    trialnumber = 1;
                                end
                                currentCondition    = this.Session.currentRun.futureConditions(1,1);
                                variables           = this.getVariablesCurrentCondition( currentCondition );
                                
                                %------------------------------------------------------------
                                %% -- PRE TRIAL ----------------------------------------------
                                %------------------------------------------------------------
                                this.SaveEvent( Enum.Events.PRE_TRIAL_START);
                                this.runPreTrial( variables );
                                this.SaveEvent( Enum.Events.PRE_TRIAL_STOP);
                                
                                %------------------------------------------------------------
                                %% -- TRIAL ---------------------------------------------------
                                %------------------------------------------------------------
                                fprintf('\nTRIAL START: N=%d Cond=%d ...', trialnumber , currentCondition );
                                
                                clear data;
                                data.variables = variables;
                                
                                %%-- Run the trial
                                this.SaveEvent( Enum.Events.TRIAL_START);
                                trialResult = this.runTrial( variables );
                                this.SaveEvent( Enum.Events.TRIAL_STOP);
                                                                
                                fprintf(' TRIAL END ');
                                
                                %------------------------------------------------------------
                                %% -- POST TRIAL ----------------------------------------------
                                %------------------------------------------------------------
                                
                                this.PlaySound(trialResult);
                                
                                this.SaveEvent( Enum.Events.POST_TRIAL_START);
                                [trialOutput] = this.runPostTrial(  );
                                this.SaveEvent( Enum.Events.POST_TRIAL_STOP);
                                
                                data.trialOutput  = trialOutput;
                                
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
                            
                            if ( exist( 'data', 'var') )
                                this.Session.currentRun.Data{end+1} = data;
                            end
                            
                            % -- Update pastcondition list
                            n = size(this.Session.currentRun.pastConditions,1)+1;
                            this.Session.currentRun.pastConditions(n, Enum.pastConditions.condition)    = this.Session.currentRun.futureConditions(1,Enum.futureConditions.condition );
                            this.Session.currentRun.pastConditions(n, Enum.pastConditions.trialResult)  = trialResult;
                            this.Session.currentRun.pastConditions(n, Enum.pastConditions.blocknumber)  = this.Session.currentRun.futureConditions(1,Enum.futureConditions.blocknumber);
                            this.Session.currentRun.pastConditions(n, Enum.pastConditions.blockid)      = this.Session.currentRun.futureConditions(1, Enum.futureConditions.blockid);
                            this.Session.currentRun.pastConditions(n, Enum.pastConditions.session)      = this.Session.currentRun.CurrentSession;
                            
                            if ( trialResult == Enum.trialResult.CORRECT )
                                %-- remove the condition that has just run from the future conditions list
                                this.Session.currentRun.futureConditions(1,:) = [];
                                
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
                                        currentblock = this.Session.currentRun.futureConditions(1,Enum.futureConditions.blocknumber);
                                        futureConditionsInCurrentBlock = this.Session.currentRun.futureConditions(this.Session.currentRun.futureConditions(:,Enum.futureConditions.blocknumber)==currentblock,:);
                                        
                                        newPosition = ceil(rand(1)*(size(futureConditionsInCurrentBlock,1)-1))+1;
                                        c = futureConditionsInCurrentBlock(1,:);
                                        futureConditionsInCurrentBlock(1,:) = futureConditionsInCurrentBlock(newPosition,:);
                                        futureConditionsInCurrentBlock(newPosition,:) = c;
                                        this.Session.currentRun.futureConditions(this.Session.currentRun.futureConditions(:,Enum.futureConditions.blocknumber)==currentblock,:) = futureConditionsInCurrentBlock;
                                        % TODO: improve
                                    case 'Drop'
                                        %-- remove the condition that has just run from the future conditions list
                                        this.Session.currentRun.futureConditions(1,:) = [];
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
                            stats = this.Session.currentRun.GetStats();
                            if ( stats.trialsToFinishExperiment == 0 )
                                status = SESSIONFINISHED;
                            elseif ( stats.trialsToFinishSession == 0 )
                                status = SESSIONFINISHED;
                            elseif ( trialsSinceBreak >= this.trialsBeforeBreak )
                                status = BREAK;
                            end
                            
                            %% ++ FINISHED -------------------------------------------------------
                        case {SESSIONFINISHED}
                            
                            this.runAfterSessionCompleted();
                            
                            if ( this.Session.currentRun.CurrentSession < this.Session.currentRun.SessionsToRun)
                                % -- session finished
                                this.Session.currentRun.CurrentSession = this.Session.currentRun.CurrentSession + 1;
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
            
            this.cleanAfterRunning();                
            ShowCursor;
            ListenChar(0);
            Priority(0);
            commandwindow;
                        
            Screen('CloseAll');
            % --------------------------------------------------------------------
            %% -------------------- END FREE RESOURCES ----------------------------
            % --------------------------------------------------------------------
            
        end
        
        % run without display
        function runSimulation(this)
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            this.initBeforeRunning();
            
            % --------------------------------------------------------------------
            %% -- EXPERIMENT LOOP -------------------------------------------------
            % --------------------------------------------------------------------
            try
                
                RUNNING = 1;
                SESSIONFINISHED = 5;
                FINISHED = 6;
                
                status = RUNNING;
                
                while(1)
                    
                    switch( status )
                        
                        %% ++ RUNNING -------------------------------------------------------
                        case RUNNING
                                %-- find which condition to run and the variable values for that condition
                                if ( ~isempty(this.Session.currentRun.pastConditions) )
                                    trialnumber = sum(this.Session.currentRun.pastConditions(:,Enum.pastConditions.trialResult)==Enum.trialResult.CORRECT)+1;
                                else
                                    trialnumber = 1;
                                end
                                currentCondition    = this.Session.currentRun.futureConditions(1,1);
                                variables           = this.getVariablesCurrentCondition( currentCondition );
                                
                                %------------------------------------------------------------
                                %% -- PRE TRIAL ----------------------------------------------
                                %------------------------------------------------------------
                                this.SaveEvent( Enum.Events.PRE_TRIAL_START);
                                this.runPreTrial( variables );
                                this.SaveEvent( Enum.Events.PRE_TRIAL_STOP);
                                
                                %------------------------------------------------------------
                                %% -- TRIAL ---------------------------------------------------
                                %------------------------------------------------------------                             
                                %%-- Run the trial
                                this.SaveEvent( Enum.Events.TRIAL_START);   
                                clear data;
                                data.variables = variables;
                                
                                trialResult = this.runTrial( variables );
                                this.SaveEvent( Enum.Events.TRIAL_STOP);
                                
                                %------------------------------------------------------------
                                %% -- POST TRIAL ----------------------------------------------
                                %------------------------------------------------------------
                               
                                this.SaveEvent( Enum.Events.POST_TRIAL_START);
                                [trialOutput] = this.runPostTrial(  );
                                this.SaveEvent( Enum.Events.POST_TRIAL_STOP);
                                
                            
                            %-- save data from trial
                            if ( exist( 'trialOutput', 'var') )
                                data.trialOutput  = trialOutput;
                            end
                            if ( exist( 'data', 'var') )
                                this.Session.currentRun.Data{end+1} = data;
                            end
                            
                            % -- Update pastcondition list
                            n = size(this.Session.currentRun.pastConditions,1)+1;
                            this.Session.currentRun.pastConditions(n, Enum.pastConditions.condition)    = this.Session.currentRun.futureConditions(1,Enum.futureConditions.condition );
                            this.Session.currentRun.pastConditions(n, Enum.pastConditions.trialResult)  = trialResult;
                            this.Session.currentRun.pastConditions(n, Enum.pastConditions.blocknumber)  = this.Session.currentRun.futureConditions(1,Enum.futureConditions.blocknumber);
                            this.Session.currentRun.pastConditions(n, Enum.pastConditions.blockid)      = this.Session.currentRun.futureConditions(1, Enum.futureConditions.blockid);
                            this.Session.currentRun.pastConditions(n, Enum.pastConditions.session)      = this.Session.currentRun.CurrentSession;
                            
                            if ( trialResult == Enum.trialResult.CORRECT )
                                %-- remove the condition that has just run from the future conditions list
                                this.Session.currentRun.futureConditions(1,:) = [];
                                
                                %-- save to disk temporary data
                                %//TODO this.SaveTempData();
                                
                            else
                                %-- what to do in case of abort
                                switch(this.trialAbortAction)
                                    case 'Repeat'
                                        % do nothing
                                    case 'Delay'
                                        % randomly get one of the future conditions in the current block
                                        % and switch it with the next
                                        currentblock = this.Session.currentRun.futureConditions(1,Enum.futureConditions.blocknumber);
                                        futureConditionsInCurrentBlock = this.Session.currentRun.futureConditions(this.Session.currentRun.futureConditions(:,Enum.futureConditions.blocknumber)==currentblock,:);
                                        
                                        newPosition = ceil(rand(1)*(size(futureConditionsInCurrentBlock,1)-1))+1;
                                        c = futureConditionsInCurrentBlock(1,:);
                                        futureConditionsInCurrentBlock(1,:) = futureConditionsInCurrentBlock(newPosition,:);
                                        futureConditionsInCurrentBlock(newPosition,:) = c;
                                        this.Session.currentRun.futureConditions(this.Session.currentRun.futureConditions(:,Enum.futureConditions.blocknumber)==currentblock,:) = futureConditionsInCurrentBlock;
                                        % TODO: improve
                                    case 'Drop'
                                        %-- remove the condition that has just run from the future conditions list
                                        this.Session.currentRun.futureConditions(1,:) = [];
                                end
                            end
                            
                            % -- Experiment or session finished ?
                            stats = this.Session.currentRun.GetStats();
                            if ( stats.trialsToFinishExperiment == 0 )
                                status = FINISHED;
                            elseif ( stats.trialsToFinishSession == 0 )
                                status = SESSIONFINISHED;
                            end
                            
                            %% ++ FINISHED -------------------------------------------------------
                        case {FINISHED,SESSIONFINISHED}
                            if ( this.Session.currentRun.CurrentSession < this.Session.currentRun.SessionsToRun)
                                % -- session finished
                                this.Session.currentRun.CurrentSession = this.Session.currentRun.CurrentSession + 1;
                            end
                            break
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
        
        function addFile(this, fileTag, filePath)
            
            [~,fileName, ext] = fileparts(filePath);
            copyfile(filePath, fullfile(this.Session.dataRawPath, [fileName ext] ));
                
            if ( ~isfield(this.Session.currentRun.LinkedFiles, fileTag) )
                this.Session.currentRun.LinkedFiles.(fileTag) = [fileName ext];
            else
                if ~iscell(this.Session.currentRun.LinkedFiles.(fileTag))
                    this.Session.currentRun.LinkedFiles.(fileTag) = {this.Session.currentRun.LinkedFiles.(fileTag)};
                end
                this.Session.currentRun.LinkedFiles.(fileTag) = cat(1, this.Session.currentRun.LinkedFiles.(fileTag), [fileName ext] );
            end               
        end
                
        %% SaveEvent
        %--------------------------------------------------------------------------
        function SaveEvent( this, event )
            % TODO: think much better
            currentTrial            = size( this.Session.currentRun.pastConditions, 1) +1;
            currentCondition        = this.Session.currentRun.futureConditions(1);
            this.Session.currentRun.Events  = cat(1, this.Session.currentRun.Events, [GetSecs now event currentTrial currentCondition] );
        end
        
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
                    variables.(varName) = varValues{conditionMatrix(currentCondition,iVar)};
                else
                    variables.(varName) = varValues(conditionMatrix(currentCondition,iVar));
                end
            end
            
            %
            % Random variables
            %
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
            
            %
            % Staircase variables
            %
            for iVar=1:length(this.StaircaseVars)
                varName = this.StaircaseVars(iVar).name;
                
                % kind of adaptive probit (APE)
                
                previousValues = [];
                previousResponses = [];
                
                                %             for i=1:length(this.ConditionVars(1).values)
                %                 angles(i) = this.ConditionVars(1).values(i);
                %                 responses(i) = mean(ds.Response(ds.Angle==angles(i)));
                %             end
               
                
                
                
                if ( ~isempty( this.Session.currentRun ) )
                    nCorrect = sum(this.Session.currentRun.pastConditions(:,Enum.pastConditions.trialResult) ==  Enum.trialResult.CORRECT );
                    
                    previousValues = zeros(nCorrect,1);
                    previousResponses = zeros(nCorrect,1);
                    
                    n = 1;
                    for i=1:length(this.Session.currentRun.pastConditions(:,1))
                        if ( this.Session.currentRun.pastConditions(i,Enum.pastConditions.trialResult) ==  Enum.trialResult.CORRECT )
                            previousValues(n) = this.Session.currentRun.Data{i}.variables.(varName);
                            previousResponses(n) = this.Session.currentRun.Data{i}.trialOutput.(this.StaircaseVars(iVar).associatedResponse);
                            n = n+1;
                        end
                    end
                end
                
                a = min(previousValues):0.1:max(previousValues);
                
                N = floor(length(previousValues)/10)*10;
                
                if ( N > 0 ) 
                    ds = dataset;
                    ds.Response = previousResponses(1:N) == this.StaircaseVars(iVar).associatedResponseIncrease;
                    ds.Angle = previousValues(1:N);
                    modelspec = 'Response ~ Angle';
                    mdl = fitglm(ds(:,{'Response', 'Angle'}), modelspec, 'Distribution', 'binomial');
                    p = predict(mdl,a')*100;
                    [svvr svvidx] = min(abs( p-50));
                    SVV = a(svvidx);
                else
                    SVV = 0;
                end
                
                N
                SVV
                variables.(varName) = (rand(1)*180-90)/min(16,round(2^(N/15))) + SVV;
                
                
%                 % QUEST - DOESNT WORK
%                 iTrial = 0;
%                 % find the last value in a correct trial
%                 if ( ~isempty( this.Session.currentRun ) )
%                     for i=length(this.Session.currentRun.pastConditions(:,1)):-1:1
%                         if ( this.Session.currentRun.pastConditions(i,Enum.pastConditions.trialResult) ==  Enum.trialResult.CORRECT )
%                             iTrial = i;
%                             break;
%                         end
%                     end
%                 end
%                 
%                 if ( iTrial > 0)
%                     response = ( this.Session.currentRun.Data{iTrial}.trialOutput.(this.StaircaseVars(iVar).associatedResponse) ~= this.StaircaseVars(iVar).associatedResponseIncrease )
%                     lastValue = this.Session.currentRun.Data{iTrial}.variables.(varName);
%                     this.StaircaseVars(iVar).q = QuestUpdate(this.StaircaseVars(iVar).q, lastValue, response);
%                 end
%                 variables.(varName) = QuestQuantile(this.StaircaseVars(iVar).q);
                
                
                % DOUBLE STAIRCASE
%                 iTrial = 0;
%                 % find the last value in a correct trial
%                 if ( ~isempty( this.Session.currentRun ) )
%                     foundOne = 0;
%                     for i=length(this.Session.currentRun.pastConditions(:,1)):-1:1
%                         if ( this.Session.currentRun.pastConditions(i,Enum.pastConditions.trialResult) ==  Enum.trialResult.CORRECT )
%                             if ( foundOne ) 
%                                 iTrial = i;
%                                 break;
%                             else
%                                 foundOne = 1;
%                             end
%                         end
%                     end
%                 end
%                 if ( iTrial == 0 && foundOne)
%                     variables.(varName) = this.StaircaseVars(iVar).initialValues(1);
%                     return;
%                 elseif ( iTrial == 0 && ~foundOne)
%                     variables.(varName) = this.StaircaseVars(iVar).initialValues(2);
%                     return;
%                 end
%                 
%                 lastValue = this.Session.currentRun.Data{iTrial}.variables.(varName);
%                 
%                 if ( this.Session.currentRun.Data{iTrial}.trialOutput.(this.StaircaseVars(iVar).associatedResponse) == this.StaircaseVars(iVar).associatedResponseIncrease )
%                     variables.(varName) = lastValue + this.StaircaseVars(iVar).stepChange;
%                 else
%                     variables.(varName) = lastValue - this.StaircaseVars(iVar).stepChange;
%                 end
                variables.(varName) 
            end
        end
        
        function shuffleConditionMatrix(this, variableNumber)
            this.ConditionMatrix(:,variableNumber) = Shuffle(this.ConditionMatrix(:,variableNumber));
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
            this.StaircaseVars = this.getStaircaseVariables();
            
            this.ConditionMatrix = this.getConditionMatrix( this.ConditionVars );
        end
        
        %% setUpParameters
        function initParameters(this)
            
            % default parameters of any experiment
            this.trialsPerSession = this.NumberOfConditions;
            
            %%-- Blocking
            this.blocks(1).toCondition    = this.NumberOfConditions;
            this.blocks(1).trialsToRun    = this.NumberOfConditions;
            
            %%-- Check if all the options are there, if not add the default
            %%values. This is important to mantain past compatibility if
            %%options are added in the future.
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
            
            for i=1:length(expPackage.ClassList)
                experimentList{i} = strrep( expPackage.ClassList(i).Name, 'ArumeExperimentDesigns.','');
            end
        end
        
        function experiment = Create(session, experimentName)
            
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
            Enum.trialResult.CORRECT = 0; % Trial finished correctly
            Enum.trialResult.ABORT = 1;   % Trial not finished, wrong key pressed, subject did not fixate, etc
            Enum.trialResult.ERROR = 2;   % Error during the trial
            Enum.trialResult.QUIT = 3;    % Escape was pressed during the trial
            Enum.trialResult.SOFTABORT = 4; % Like an abort but does not go to hitkey to continue
            
            
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
    
    
    % --------------------------------------------------------------------
    %% Analysis methods --------------------------------------------------
    % --------------------------------------------------------------------
    methods
        
        function trialDataSet = PrepareTrialDataSet( this, trialDataSet)
        end
            
        function [samplesDataSet rawDataSet] = PrepareSamplesDataSet(this, samplesDataSet)
            rawDataSet = [];
        end
        
        function eventDataset = PrepareEventDataSet(this, eventDataset)
        end
        
        function sessionDataTable = PrepareSessionDataTable(this, sessionDataTable)
        end
    end
end

