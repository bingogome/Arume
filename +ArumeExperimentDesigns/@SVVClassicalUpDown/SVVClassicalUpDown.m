classdef SVVClassicalUpDown < ArumeCore.ExperimentDesign
    %OPTOKINETICTORSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        currentAngle = 0;
        
        eyeTracker = [];
        
        
        fixRad = 20;
        fixColor = [255 0 0];
        
        lineLength = 125;
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
            
            this.trialDuration = 10; %seconds
            
            % default parameters of any experiment
            this.trialSequence = 'Random';	% Sequential, Random, Random with repetition, ...
            this.trialAbortAction = 'Delay';     % Repeat, Delay, Drop
            this.trialsPerSession = 52;
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 2;
            this.blocksToRun              = 1;
            this.blocks(1).fromCondition  = 1;
            this.blocks(1).toCondition    = 26;
            this.blocks(1).trialsToRun    = 26;
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
            conditionVars(i).name   = 'InitialAngle';
            conditionVars(i).values = [-30:5:30];
            
            i = i+1;
            conditionVars(i).name   = 'Position';
            conditionVars(i).values = {'Up' 'Down'};
            
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
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                
                graph = this.Graph;
                
                trialResult = Enum.trialResult.CORRECT;
                buttonReleased = 0;
                
                %-- add here the trial code
                Screen('FillRect', graph.window, 0);
                lastFlipTime        = Screen('Flip', graph.window);
                secondsRemaining    = this.trialDuration;
                
                startLoopTime = lastFlipTime;
                
                this.currentAngle = variables.InitialAngle;
                delta = 0;
                
                while secondsRemaining > -10000
                    
                    secondsElapsed      = GetSecs - startLoopTime;
                    secondsRemaining    = this.trialDuration - secondsElapsed;
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    %-- Find the center of the screen
                    [mx, my] = RectCenter(graph.wRect);
                    
                    %-- Draw fixation spot
                    
                    this.currentAngle = this.currentAngle+delta;
                    
                    
                    switch(variables.Position)
                        case 'Up'
                            fromH = mx;
                            fromV = my;
                            toH = mx + this.lineLength*sin(this.currentAngle/180*pi);
                            toV = my - this.lineLength*cos(this.currentAngle/180*pi);
                        case 'Down'
                            fromH = mx;
                            fromV = my;
                            toH = mx - this.lineLength*sin(this.currentAngle/180*pi);
                            toV = my + this.lineLength*cos(this.currentAngle/180*pi);
                    end
                    
                    
                    if ( secondsElapsed > 0.5 )
                        Screen('DrawLine', graph.window, this.lineColor, fromH, fromV, toH, toV, 4);
                    end
                    
                    fixRect = [0 0 4 4];
                    fixRect = CenterRectOnPointd( fixRect, mx, my )
                    Screen('FillOval', graph.window,  [0 255 0], fixRect);
                    
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
                    
                    exit = 0;
                    
                    switch(variables.Position)
                        case 'Up'
                            direction = 1;
                        case 'Down'
                            direction = -1;
                    end
                    
                    if ( this.ExperimentOptions.UseGamePad )
                        [d, l, r, a, b, x, y] = ArumeHardware.GamePad.Query;
                        if ( buttonReleased == 0 )
                            if ( l==0 && r==0 && a==0)
                                buttonReleased = 1;
                            end
                        else
                            if ( l == 1)
                                delta = direction*-0.2;
                            elseif( r == 1)
                                delta = direction*0.2;
                            elseif( a == 1 | b == 1 | x == 1 | y == 1 )
                                exit = 1;
                            else
                                delta = 0;
                            end
                        end
                    else
                        
                        [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                        if ( keyIsDown )
                            keys = find(keyCode);
                            for i=1:length(keys)
                                KbName(keys(i));
                                switch(KbName(keys(i)))
                                    case 'LeftArrow'
                                        delta = direction*-0.2;
                                    case 'RightArrow'
                                        delta = direction*0.2;
                                    case 'space'
                                        exit = 1;
                                    otherwise
                                        delta = 0;
                                end
                            end
                        else
                            delta = 0;
                        end
                    end
                    if ( exit )
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
                        
            % this.eyeTracker.StopRecording();
            
        end
        
        function trialOutput = runPostTrial(this)
            trialOutput = [];
            trialOutput.Response = this.currentAngle;
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        function analysisResults = Plot_SVVupdown(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds.Response = ds.Response -1;
            ds(ds.TrialResult>0,:) = [];
            
            figure('position',[400 400 600 400],'color','w','name',this.Session.name)
            set(gca,'nextplot','add');
            plot(ds.Response(streq(ds.Position,'Up'),:),ds.InitialAngle(streq(ds.Position,'Up'),:), 'o', 'color', [0 0.7 0.7], 'markersize',10,'linewidth',2)
            plot(ds.Response(streq(ds.Position,'Down'),:),ds.InitialAngle(streq(ds.Position,'Down'),:), 'o', 'color', [0.7 0 0.7], 'markersize',10,'linewidth',2)
            xlabel('SVV Angle (deg)','fontsize',16)
            ylabel('Initial Line Angle','fontsize',16)
                        
            legend({'Up' 'Down'})
            set(gca,'xlim',[-30 30],'ylim',[-32 32])
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            
            
            text(20, 5, sprintf('SVV: %0.2f°',mean(ds.Response')), 'fontsize',16);
            
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