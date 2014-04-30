classdef SVVdots < ArumeCore.ExperimentDesign
    %SVVdots Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        eyeTracker = [];
        
        lastResponse = '';
        reactionTime = '';
        
        
        fixColor = [0 255 0];
        
        targetColor = [255 0 0];
        
    end
    
    % ---------------------------------------------------------------------
    % Options to set at runtime
    % ---------------------------------------------------------------------
    methods ( Static = true )
        function dlg = GetOptionsStructDlg( this )
            dlg.UseGamePad = { {'0','{1}'} };
            dlg.FixationDiameter = { 10 '* (pix)' [3 50] };
            dlg.TargetDiameter = { 10 '* (pix)' [3 50] };
            dlg.targetDistance = { 100 '* (pix)' [10 500] };
            dlg.targetDuration = { 200 '* (ms)' [100 500] };
        end
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function initExperimentDesign( this  )
            
            this.trialDuration = 3; %seconds
            
            % default parameters of any experiment
            this.trialSequence      = 'Random';      % Sequential, Random, Random with repetition, ...
            this.trialAbortAction   = 'Delay';    % Repeat, Delay, Drop
            this.trialsPerSession   = 136;
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 4;
            this.blocksToRun = 1;
            this.blocks = [ ...
                struct( 'fromCondition', 1, 'toCondition', 34, 'trialsToRun', 34) ];
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
                this.lastResponse = 0;
                this.reactionTime = -1;
                
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
                    fixRect = [0 0 this.ExperimentOptions.FixationDiameter this.ExperimentOptions.FixationDiameter];
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    Screen('FillOval', graph.window, this.fixColor, fixRect);
                    
                    if ( secondsElapsed > 1 && secondsElapsed < (1 +this.ExperimentOptions.targetDuration/1000) )
                        %-- Draw target
                        targetRect = [0 0 this.ExperimentOptions.TargetDiameter this.ExperimentOptions.TargetDiameter];
                         
                        targetDist = this.ExperimentOptions.targetDistance;
                        switch(variables.Position)
                            case 'Up'
                                targetRect = CenterRectOnPointd( targetRect, mx - targetDist*sin(variables.Angle/180*pi), my + targetDist*cos(variables.Angle/180*pi) );
                            case 'Down'
                                targetRect = CenterRectOnPointd( targetRect, mx + targetDist*sin(variables.Angle/180*pi), my - targetDist*cos(variables.Angle/180*pi) );
                        end
                        Screen('FillOval', graph.window, this.targetColor, targetRect);
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
                    
                    if ( secondsElapsed > 1.2 )
                        
                        if ( this.ExperimentOptions.UseGamePad )
                            [d, l, r] = ArumeHardware.GamePad.Query;
                            if ( l == 1)
                                switch(variables.Position)
                                    case 'Up'
                                        this.lastResponse = 2;
                                    case 'Down'
                                        this.lastResponse = 1;
                                end
                            elseif( r == 1)
                                switch(variables.Position)
                                    case 'Up'
                                        this.lastResponse = 1;
                                    case 'Down'
                                        this.lastResponse = 2;
                                end
                            end
                        else
                            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                            if ( keyIsDown )
                                keys = find(keyCode);
                                for i=1:length(keys)
                                    KbName(keys(i))
                                    switch(KbName(keys(i)))
                                        case 'RightArrow'
                                            switch(variables.Position)
                                                case 'Up'
                                                    this.lastResponse = 1;
                                                case 'Down'
                                                    this.lastResponse = 2;
                                            end
                                        case 'LeftArrow'
                                            switch(variables.Position)
                                                case 'Up'
                                                    this.lastResponse = 2;
                                                case 'Down'
                                                    this.lastResponse = 1;
                                            end
                                    end
                                end
                            end
                        end
                    end
                    if ( this.lastResponse > 0 )
                        this.reactionTime = secondsElapsed-1;
                        disp(num2str(this.lastResponse));
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
            trialOutput.ReactionTime = this.reactionTime;
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
      function analysisResults = Plot_Sigmoid(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds.Response = ds.Response -1;
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];
            
            figure
            set(gca,'nextplot','add')
            colors = jet(length(ds)/10);
            for i=10:10:length(ds)
                nplot = ceil(10*i/length(ds));
                subplot(length(colors)/2,2,mod(((nplot*2)-1+floor((nplot-1)/5))-1,10)+1,'nextplot','add')
                modelspec = 'Response ~ Angle';
                subds = ds(1:i,:);
                subds((subds.Response==1 & subds.Angle<-50) | (subds.Response==0 & subds.Angle>50),:) = [];
                mdl = fitglm(subds(:,{'Response', 'Angle'}), modelspec, 'Distribution', 'binomial');
                angles = subds.Angle;
                responses = subds.Response;
                %             for i=1:length(this.ConditionVars(1).values)
                %                 angles(i) = this.ConditionVars(1).values(i);
                %                 responses(i) = mean(ds.Response(ds.Angle==angles(i)));
                %             end
                a = min(angles):0.1:max(angles);
                
                p = predict(mdl,a')*100;
                plot(a,p, 'color', colors(nplot,:),'linewidth',2);
                xlabel('Angle (deg)');
                ylabel('Percent answered right');
                
                [svvr svvidx] = min(abs( p-50));
                line([a(svvidx),a(svvidx)], [0 100], 'color', colors(nplot,:),'linewidth',2);
                set(gca,'xlim',[-10 10])
                plot( angles,responses*100,'o')
                text(3, 40, sprintf('SVV: %0.2f',a(svvidx)));
            end
            
            %%
      end
        
       function analysisResults = Plot_ReactionTimes(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds.Response = ds.Response -1;
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];
            
            angles = ds.Angle;
            responses = ds.Response;
            times = ds.ReactionTime;
            
            binAngles = [-180 -90 -30 -15 -10 -7:2:7 10 15 30 90 180];
            
            binMiddles = binAngles(1:end-1) + diff(binAngles)/2;
            timeAvg = zeros(size(binMiddles));
            for i=1:length(binMiddles)
                timeAvg(i) = median(times(angles>binAngles(i) & angles<binAngles(i+1)));
            end
            
            figure
            plot(angles,times*1000,'o')
            hold
            plot(binMiddles, timeAvg*1000,'r','linewidth',3)
            set(gca,'xlim',[-20 20])
                xlabel('Angle (deg)');
                ylabel('Reaction time (ms) right');
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