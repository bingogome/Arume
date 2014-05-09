classdef SVVCWCCW < ArumeCore.ExperimentDesign
    %OPTOKINETICTORSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        lastResponse = '';
        
        eyeTracker = [];
        
        
        fixRad = 20;
        fixColor = [255 0 0];
        
        lineLength = 300;
        lineColor = [255 0 0];
        
    end
    
    % ---------------------------------------------------------------------
    % Options to set at runtime
    % ---------------------------------------------------------------------
    methods ( Static = true )
        function dlg = GetOptionsStructDlg( this )
            dlg.UseGamePad = { {'0','{1}'} };
        end
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function initExperimentDesign( this  )
            
            this.trialDuration = 3; %seconds
            
            % default parameters of any experiment
            this.trialSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            this.trialsPerSession = 136;
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 4;
            this.blocksToRun              = 2;
            this.blocks(1).fromCondition  = 1;
            this.blocks(1).toCondition    = 17;
            this.blocks(1).trialsToRun    = 17;
            this.blocks(2).fromCondition  = 18;
            this.blocks(2).toCondition    = 34;
            this.blocks(2).trialsToRun    = 17;
            
        end
        
        %% run initialization before the first trial is run
        function initBeforeRunning( this )
            if ( this.ExperimentOptions.UseGamePad )
                ArumeHardware.GamePad.Open
            end
        end
        
        
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Angle';
            conditionVars(i).values = [-16:2:16];
            
            i = i+1;
            conditionVars(i).name   = 'Direction';
            conditionVars(i).values = {'CW' 'CCW'};
        end
        
        function [ randomVars] = getRandomVariables( this )
            randomVars = {};
        end
        
        function trialResult = runPreTrial(this, variables )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            % Add stuff here
            
            trialResult =  Enum.trialResult.CORRECT;
        end
        
        function trialResult = runTrial( this, variables )
            
            try
                this.lastResponse = 0;
                buttonReleased = 0;
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                
                
                graph = this.Graph;
                
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
                Screen('FillRect', graph.window, 0);
                lastFlipTime        = Screen('Flip', graph.window);
                secondsRemaining    = this.trialDuration;
                
                startLoopTime = lastFlipTime;
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - startLoopTime;
                    secondsRemaining    = this.trialDuration - secondsElapsed;
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    %-- Find the center of the screen
                    [mx, my] = RectCenter(graph.wRect);
                    
                    %-- Draw fixation spot
                    fixRect = [0 0 10 10];
                    %                 fixRect = CenterRectOnPointd( fixRect, mx-graph.wRect(3)/4, my );
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    if ( secondsElapsed > 0.5 )
                    Screen('FillOval', graph.window, this.fixColor, fixRect);
                    
                    %-- Draw target
                    %                         mx = mx-graph.wRect(3)/4;
                    switch(variables.Direction)
                        case 'CW'
                            angle1 = variables.Angle;
                        case 'CCW'
                            angle1 = -variables.Angle;
                    end
                    
                    fromH = mx;
                    fromV = my;
                    toH = mx + this.lineLength*sin(angle1/180*pi);
                    toV = my - this.lineLength*cos(angle1/180*pi);
                    
                    if ( secondsElapsed > 1 )
                        Screen('DrawLine', graph.window, this.lineColor, fromH, fromV, toH, toV, 2);
                    end
                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------
                    
                    
                    
                    % -----------------------------------------------------------------
                    % -- Flip buffers to refresh screen -------------------------------
                    % -----------------------------------------------------------------
                    this.Graph.Flip();
                    % -----------------------------------------------------------------
                    
                    
                    % -----------------------------------------------------------------
                    % --- Collecting responses  ---------------------------------------
                    % -----------------------------------------------------------------
                    
                    if ( this.ExperimentOptions.UseGamePad )
                        [d, l, r a] = ArumeHardware.GamePad.Query;
                        if ( buttonReleased == 0 )
                            if ( l==0 && r==0 && a==0)
                                buttonReleased = 1;
                            end
                        else % wait until the buttons are released
                            if ( l == 1)
                                this.lastResponse = 1;
                            elseif( r == 1)
                                this.lastResponse = 2;
                            elseif( a == 1)
                                this.lastResponse = 3;
                            end
                        end
                    else
                        if ( secondsElapsed > 0.2 )
                            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                            if ( keyIsDown )
                                keys = find(keyCode);
                                for i=1:length(keys)
                                    KbName(keys(i))
                                    switch(KbName(keys(i)))
                                        case 'LeftArrow'
                                            this.lastResponse = 1;
                                        case 'RightArrow'
                                            this.lastResponse = 2;
                                        case 'UpArrow'
                                            this.lastResponse = 3;
                                    end
                                end
                            end
                        end
                    end
                    if ( this.lastResponse > 0 )
                        break;
                    end
                    
                    
                    % -----------------------------------------------------------------
                    % --- END Collecting responses  -----------------------------------
                    % -----------------------------------------------------------------
                    
                end
            catch ex
                %  this.eyeTracker.StopRecording();
                rethrow(ex)
            end
            
            
            if ( this.lastResponse == 0)
                trialResult =  Enum.trialResult.ABORT;
            end
            
            % this.eyeTracker.StopRecording();
            
        end
        
        function trialOutput = runPostTrial(this)
            trialOutput = [];
            trialOutput.Response = this.lastResponse;
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        function analysisResults = Plot_Sigmoid(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds.Response = (ds.Response-1)/2;
            ds(ds.TrialResult>0,:) = [];
                       
            figure
            plot(ds.Angle,ds.Response+rand(size(ds.Angle))/10,'o')
            xlabel('Angle (deg)');
            ylabel('Percent answered right');
            
            [svvr svvidx] = min(abs( p-50));
            line([a(svvidx),a(svvidx)], [0 100])
            %%
        end
    end
    
    % ---------------------------------------------------------------------
    % Other methods
    % ---------------------------------------------------------------------
    methods( Access = public )
        function [dsTrials, dsSamples] = ImportSession( this )
        end
    end
end