classdef SVVCWCCWRandom < ArumeCore.ExperimentDesign
    
    
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
            this.trialsPerSession = sum(21:-2:15)*4;
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 1;
            this.blocksToRun              = 16;
            
            n = Shuffle(1:4);
            
            this.blocks(n(1)).fromCondition  = 1;
            this.blocks(n(1)).toCondition    = 21;
            this.blocks(n(1)).trialsToRun    = 21;
            
            this.blocks(n(2)).fromCondition  = 2;
            this.blocks(n(2)).toCondition    = 20;
            this.blocks(n(2)).trialsToRun    = 19;
            
            this.blocks(n(3)).fromCondition  = 3;
            this.blocks(n(3)).toCondition    = 19;
            this.blocks(n(3)).trialsToRun    = 17;
            
            this.blocks(n(4)).fromCondition  = 4;
            this.blocks(n(4)).toCondition    = 18;
            this.blocks(n(4)).trialsToRun    = 15;
            
            n = Shuffle(5:8);
            
            this.blocks(n(1)).fromCondition  = 1;
            this.blocks(n(1)).toCondition    = 21;
            this.blocks(n(1)).trialsToRun    = 21;
            
            this.blocks(n(2)).fromCondition  = 2;
            this.blocks(n(2)).toCondition    = 20;
            this.blocks(n(2)).trialsToRun    = 19;
            
            this.blocks(n(3)).fromCondition  = 3;
            this.blocks(n(3)).toCondition    = 19;
            this.blocks(n(3)).trialsToRun    = 17;
            
            this.blocks(n(4)).fromCondition  = 4;
            this.blocks(n(4)).toCondition    = 18;
            this.blocks(n(4)).trialsToRun    = 15;
            
            n = Shuffle(9:12);
            
            this.blocks(n(1)).fromCondition  = 22;
            this.blocks(n(1)).toCondition    = 42;
            this.blocks(n(1)).trialsToRun    = 21;
            
            this.blocks(n(2)).fromCondition  = 23;
            this.blocks(n(2)).toCondition    = 41;
            this.blocks(n(2)).trialsToRun    = 19;
            
            this.blocks(n(3)).fromCondition  = 24;
            this.blocks(n(3)).toCondition    = 40;
            this.blocks(n(3)).trialsToRun    = 17;
            
            this.blocks(n(4)).fromCondition  = 25;
            this.blocks(n(4)).toCondition    = 39;
            this.blocks(n(4)).trialsToRun    = 15;
            
            n = Shuffle(13:16);
            
            this.blocks(n(1)).fromCondition  = 22;
            this.blocks(n(1)).toCondition    = 42;
            this.blocks(n(1)).trialsToRun    = 21;
            
            this.blocks(n(2)).fromCondition  = 23;
            this.blocks(n(2)).toCondition    = 41;
            this.blocks(n(2)).trialsToRun    = 19;
            
            this.blocks(n(3)).fromCondition  = 24;
            this.blocks(n(3)).toCondition    = 40;
            this.blocks(n(3)).trialsToRun    = 17;
            
            this.blocks(n(4)).fromCondition  = 25;
            this.blocks(n(4)).toCondition    = 39;
            this.blocks(n(4)).trialsToRun    = 15;
            
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
            conditionVars(i).values = [-20:2:20];
            
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
                    if ( secondsElapsed > 0 )
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
                        
                        if ( secondsElapsed > 0.1 )
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
                            if ( secondsElapsed > 0.4 )
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
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0 | ds.Response>2,:) = [];

            subds = ds(:,:);
            subds.Response = subds.Response-1;
%              subds.Response(streq(ds.Direction,'CCW')) = 1-subds.Response(streq(ds.Direction,'CCW')) ;
            subds.Angle(streq(ds.Direction,'CCW')) = -subds.Angle(streq(ds.Direction,'CCW'));
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVVdotsAdaptFixed.FitAngleResponses( subds.Angle, subds.Response);
            
                
           
            figure('position',[400 400 1000 400],'color','w','name',this.Session.name)
            subplot(3,1,[1:2],'nextplot','add', 'fontsize',12);
            
            plot( allAngles, allResponses,'o', 'color', [0.7 0.7 0.7], 'markersize',10,'linewidth',2)
            plot(a,p, 'color', 'k','linewidth',2);
            line([SVV, SVV], [0 100], 'color','k','linewidth',2);
            
               
            
            
            %xlabel('Angle (deg)', 'fontsize',16);
            ylabel({'Percent answered' 'tilted right'}, 'fontsize',16);
            text(20, 80, sprintf('SVV: %0.2f°',SVV), 'fontsize',16);
            
            set(gca,'xlim',[-30 30],'ylim',[-10 110])
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca,'xticklabel',[])
            
            
            subplot(3,1,[3],'nextplot','add', 'fontsize',12);
            bar(allAngles, trialCounts, 'edgecolor','none','facecolor',[0.5 0.5 0.5])
                
            set(gca,'xlim',[-30 30],'ylim',[0 15])
            xlabel('Angle (deg)', 'fontsize',16);
            ylabel('Number of trials', 'fontsize',16);
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca, 'YAxisLocation','right')
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
