function run_session(this)

global Enum;

% --------------------------------------------------------------------
%% -- HARDWARE SET UP ------------------------------------------------
% --------------------------------------------------------------------
try
    % -- KEYBOARD and MOUSE
    
    %-- hide the mouse cursor during the experiment
    if ( ~this.Config.Debug )
        HideCursor;
        ListenChar(2);
    else
        ListenChar(1);
    end
    
    % -- GRAPHICS
    this.Graph = Display( this );
    
    this.SysInfo = psyCortex_systemSetUp(  );
    
    % -- EYELINK
    if ( this.Config.UsingEyelink )
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
    
    ShowCursor;
    ListenChar(0);
    
    Screen('CloseAll');
    commandwindow;
    
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
    CALIBRATION = 2;
    DRIFTCORRECTION =3;
    BREAK = 4;
    SESSIONFINISHED = 5;
    FINISHED = 6;
    SAVEDATA = 7;
    
    
    trialsSinceBreak            = 0;
    trialsSinceCalibration      = 0;
    trialsSinceDriftCorrection  = 0;
    
    status = CALIBRATION;
    
    
    while(1)
        Screen('FillRect', this.Graph.window, this.Graph.white);
        
        switch( status )
            
            
            %% ++ IDLE -------------------------------------------------------
            case IDLE
                result = this.Graph.DlgSelect( 'Choose an option:', ...
                    { 'n' 'c' 'd' 'b' 'q'}, ...
                    { 'Next trial' 'Calibration', 'Drift Correction', 'Break', 'Quit'} );
                switch( result )
                    case 'n'
                        status = RUNNING;
                    case 'c'
                        status = CALIBRATION;
                    case 'd'
                        status = DRIFTCORRECTION;
                    case 'b'
                        status = BREAK;
                    case {'q' 0}
                        dlgResult = this.Graph.DlgYesNo( 'Are you sure you want to exit?',[],[],20,20,[200 0 0]);
                        if( dlgResult )
                            status = SAVEDATA;
                        end
                end
                
            %% ++ CALIBRATION -------------------------------------------------------
            case CALIBRATION
                if ( isempty( this.EyeTracker ) )
                    status = RUNNING;
                    continue;
                end
                calibrationResult = this.EyeTracker.Calibration( this.Graph );
                if ( ~calibrationResult )
                    status = IDLE;
                else
                    trialsSinceCalibration      = 0;
                    trialsSinceDriftCorrection	= 0;
                    status = RUNNING;
                end
                
            %% ++ DRIFTCORRECTION -------------------------------------------------------
            case DRIFTCORRECTION
                if ( isempty( this.EyeTracker ) )
                    status = RUNNING;
                    continue;
                end
                driftCorrectionResult = this.EyeTracker.DriftCorrection( this.Graph );
                if ( ~driftCorrectionResult )
                    status = IDLE;
                else
                    trialsSinceDriftCorrection	= 0;
                    status = RUNNING;
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
                    status = CALIBRATION;
                end
                
            %% ++ RUNNING -------------------------------------------------------
            case RUNNING
                if ( this.Config.HitKeyBeforeTrial && ( ~exist('trialResult', 'var') || trialResult ~= Enum.trialResult.SOFT_ABORT )) % TODO: don't like the soft abort very much
                    dlgResult = this.Graph.DlgHitKey( 'Hit a key to continue',[],[] );
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
                    this.Graph.fliptimes{end +1} = zeros(size(0:.005:.100));
                    
                    this.SaveEvent( Enum.Events.PRE_TRIAL_START);
                    trial = this.runPreTrial( variables );
                    this.SaveEvent( Enum.Events.PRE_TRIAL_STOP);
                                       
                    %------------------------------------------------------------
                    %% -- TRIAL ---------------------------------------------------
                    %------------------------------------------------------------
                    fprintf('\nTRIAL START: N=%d Cond=%d ...', trialnumber , currentCondition );
                    
                    %%-- Start Recording eye movements
                    if ( ~isempty(this.EyeTracker) )
                        this.EyeTracker.StartRecording();
                        this.SaveEvent( Enum.Events.EYELINK_START_RECORDING);
                        this.EyeTracker.SendMessage('TRIAL_START: N=%d Cond=%d t=%d', trialnumber, currentCondition, round(GetSecs*1000));
                    end
                    
                    %%-- Run the trial
                    this.SaveEvent( Enum.Events.TRIAL_START);
                    [trialResult trial] = this.runTrial( variables, trial );
                    this.SaveEvent( Enum.Events.TRIAL_STOP);
                    
%                   fprintf(' TRIAL END: Avg.Flip: %2.2f ms\n\n', 1000*mean(diff(this.Graph.fliptimes{end}(this.Graph.fliptimes{end}>0))) );
                    fprintf(' TRIAL END: slow flips: %d\n\n', sum(this.Graph.fliptimes{end}) - max(this.Graph.fliptimes{end}));
                    
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
                    [trialOutput] = this.runPostTrial( trial );
                    this.SaveEvent( Enum.Events.POST_TRIAL_STOP);
                    
                    %-- save data from trial
                    clear data;
                    data.trialOutput  = trialOutput;
                    data.variables    = variables;
                  
                    if ( ~isempty( this.CurrentRun.Data ) )
                        if ( ~iscell(this.CurrentRun.Data ) )
                            % crappy thing to solve an issue with different
                            % types of structs 
                            d = this.CurrentRun.Data;
                            this.CurrentRun.Data = {};
                            for i=1:length(d)
                                this.CurrentRun.Data{i} = d(i);
                            end
%                             1
%                             this.CurrentRun.Data{end+1} = data
                        else
%                             2
%                             this.CurrentRun.Data{end+1} = data
                        end
%                         this.CurrentRun.Data( end +1 ) = data;
                    else
                        this.CurrentRun.Data = data;
                    end
                                        
                catch
                    if ( ~iscell(this.CurrentRun.Data ) )
                        % crappy thing to solve an issue with different
                        % types of structs
                        d = this.CurrentRun.Data;
                        this.CurrentRun.Data = {};
                        for i=1:length(d)
                            this.CurrentRun.Data{i} = d(i);
                        end
%                         5
%                         d(1)
%                         this.CurrentRun.Data{1}
                    end
                    err = psychlasterror;
                    if ( streq(err.identifier, 'PSYCORTEX:USERQUIT' ) )
                        trialResult = Enum.trialResult.QUIT;
                    else
                        trialResult = Enum.trialResult.ERROR;
                        % display error
                        disp(['Error in trial: ' err.message ]);
                        disp(err.stack(1));
                        this.Graph.DlgHitKey( ['Error, trial could not be run: \n' err.message],[],[], [255 0 0] );
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
                    switch(this.ExperimentInfo.Parameters.trialAbortAction)
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
                elseif ( trialsSinceBreak >= this.ExperimentInfo.Parameters.trialsBeforeBreak )
                    status = BREAK;
                elseif ( trialsSinceCalibration >= this.ExperimentInfo.Parameters.trialsBeforeCalibration )
                    status = CALIBRATION;
                elseif ( trialsSinceDriftCorrection >= this.ExperimentInfo.Parameters.trialsBeforeDriftCorrection )
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
                    this.Graph.DlgHitKey( 'Experiment finished, hit a key to exit' );
                end
                 status = SAVEDATA;
            case SAVEDATA
                %% -- SAVE DATA --------------------------------------------------
                
                % -- Save eyelink data if necessary
                if ( ~isempty( this.EyeTracker ) )
                    this.EyeTrackerFiles{end+1} = this.EyeTracker.GetFile( this.ExperimentInfo.Parameters.dataPath );
                end
                
                % -- save session data
                eval( [this.Filename ' = this;']);
                save( [ this.ExperimentInfo.Parameters.dataPath '\\' this.Filename], this.Filename);
                
                % -- delete temporary data
                tempfile = [this.ExperimentInfo.Parameters.dataPath '\' this.Name '_' this.SubjectCode '_' this.SessionSuffix  '_temp.mat'];
                delete(tempfile)
                
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
commandwindow;

if ( ~isempty( this.EyeTracker ) )
    this.EyeTracker.Close();
end

Screen('CloseAll');
% --------------------------------------------------------------------
%% -------------------- END FREE RESOURCES ----------------------------
% --------------------------------------------------------------------

end







%% function psyCortex_systemSetUp
%--------------------------------------------------------------------------
function sysInfo = psyCortex_systemSetUp(  )
sysInfo.PsychtoolboxVersion   = Screen('Version');
sysInfo.hostSO                = Screen('Computer');
end
