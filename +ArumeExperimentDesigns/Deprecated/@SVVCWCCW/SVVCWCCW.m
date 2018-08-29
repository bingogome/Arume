classdef SVVCWCCW < ArumeExperimentDesigns.SVV2AFC
    
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
            dlg.offset = {0 '* (deg)' [-20 20] };
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
            this.trialsPerSession = 17*8*2;
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 1;
            this.blocksToRun              = 2;
            this.blocks(1).fromCondition  = 1;
            this.blocks(1).toCondition    = 17;
            this.blocks(1).trialsToRun    = 17*8;
            this.blocks(2).fromCondition  = 18;
            this.blocks(2).toCondition    = 34;
            this.blocks(2).trialsToRun    = 17*8;
            
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
                        
                        angle1 = angle1+this.ExperimentOptions.offset;
                        
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
        
        % Function that gets the angles of each trial with 0 meaning 
        % upright, positive tilted CW and negative CCW.
        function angles = GetAngles( this )
            ds = this.Session.trialDataSet;
            angles = ds.Angle;
            angles(streq(ds.Direction,'CCW')) = -angles(streq(ds.Direction,'CCW'));
            
            if ( isfield( this.ExperimentOptions, 'offset') )
                angles = angles + this.ExperimentOptions.offset;
            end
            
            responses = this.Session.trialDataSet.Response-1;
            angles = angles(responses >= 0 & responses < 2);
        end
        
        % Function that gets the left and right responses with 1 meaning 
        % right and 0 meaning left.
        function responses = GetLeftRightResponses( this )
            responses = this.Session.trialDataSet.Response-1;
            responses = responses(responses >= 0 & responses < 2);
        end
        
        
        function plotResults = Plot_ExperimentTimeCourse(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];
            
            ds.Response = 2-ds.Response;
            ds.Angle(streq(ds.Direction,'CCW')) = -ds.Angle(streq(ds.Direction,'CCW'));
            
            
            NtrialPerBlock = 10;
            %             figure
            %             set(gca,'nextplot','add')
            %             colors = jet(length(ds)/NtrialPerBlock);
            
            Nblocks = ceil(length(ds)/NtrialPerBlock/2)*2;
         
            figure('position',[400 200 700 400],'color','w','name',this.Session.name)
            axes('nextplot','add');
            plot(ds(ds.Response==0,'TrialNumber'), ds(ds.Response==0 ,'Angle'),'o','MarkerEdgeColor',[0.3 0.3 0.3],'linewidth',2);
            plot(ds(ds.Response==1,'TrialNumber'), ds(ds.Response==1 ,'Angle'),'o','MarkerEdgeColor','r','linewidth',2);
            
            
            SVV = nan(1,length(ds.Response));
            
            if ( length(ds.Response) > 272 )
                N = 18;
            else
                N = 17;
            end
            
            for i=1:(length(ds.Response)/N)
                idx = (-1:N+2) + (i-1)*N;
                idx(idx<1) = [];
                idx(idx>length(ds.Response)) = [];
                ang = ds.Angle(idx);
                res = ds.Response(idx);
                
                [SVV1, a, p, allAngles, allResponses,trialCounts, SVVth1] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( ang, res);
                SVV(idx) = SVV1;
            end
            
            plot(SVV,'linewidth',2,'color',[.5 .8 .3]);
            
            legend({'Answered tilted to the right', 'Answered tilted to the left'},'fontsize',16)
            legend('boxoff')
            set(gca,'xlim',[-3 length(ds.Response)+3],'ylim',[-50 50])
            ylabel('Angle (deg)', 'fontsize',16);
            xlabel('Trial number', 'fontsize',16);
            set(gca,'ygrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
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
