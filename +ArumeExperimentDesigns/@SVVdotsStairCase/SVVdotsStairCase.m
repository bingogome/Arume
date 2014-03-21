classdef SVVdotsStairCase < ArumeCore.ExperimentDesign
    %OPTOKINETICTORSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        eyeTracker = [];
        
        lastResponse = '';
        
        
        fixRad = 20;
        fixColor = [255 0 0];
        
        targetDistance = 100;
        targetColor = [0 255 0];
        
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
            this.numberOfTimesRepeatBlockSequence = 40;
            this.blocksToRun = 1;
            this.blocks = [ ...
                struct( 'fromCondition', 1, 'toCondition', 2, 'trialsToRun', 2) ];
        end
        
        %% run initialization before the first trial is run
        function initBeforeRunning( this )
%             Hardware.GamePad.Open
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Position';
            conditionVars(i).values = {'Up' 'Down'};
        end
        
        function [ randomVars] = getRandomVariables( this )
            randomVars = {};
        end
        
        function staircaseVars = getStaircaseVariables( this )
            i= 0;
            
            i = i+1;
            staircaseVars(i).name   = 'Angle';
            staircaseVars(i).initialValues = [-16 16];
            staircaseVars(i).stepChange = 1;
            staircaseVars(i).associatedResponse = 'Response';
            staircaseVars(i).associatedResponseIncrease = 1;
            staircaseVars(i).q = QuestCreate(0,10,0.82,3.5,0.01,0.5,0.1,32);
                
        end
        
        function trialResult = runPreTrial(this, variables )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            % Add stuff here
            
            trialResult =  Enum.trialResult.CORRECT;
        end
        
        function trialResult = runTrial( this, variables )
            
            try
                this.lastResponse = 0;
                
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
%                     mx = mx-graph.wRect(3)/4+50;

                    %-- Draw fixation spot
                    fixRect = [0 0 3 3];
                    %                 fixRect = CenterRectOnPointd( fixRect, mx-graph.wRect(3)/4, my );
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    
                    circFrameRect = [0 0 300 300];
                    circFrameRect = CenterRectOnPointd( circFrameRect,  mx, my );
                    circFrameRect2 = [0 0 305 305];
                    circFrameRect2 = CenterRectOnPointd( circFrameRect2,  mx, my );
                    
%                     Screen('FillOval', graph.window, 255, circFrameRect2 );
%                     Screen('FillOval', graph.window, 0, circFrameRect );
                    Screen('FillRect', graph.window, this.fixColor, fixRect);
                    
                    if ( secondsElapsed > 1 && secondsElapsed < 1.1 )
                        %-- Draw target
                        fixRect = [0 0 7 7];
                         
                        switch(variables.Position)
                            case 'Up'
                                fixRect = CenterRectOnPointd( fixRect, mx - this.targetDistance*sin(variables.Angle/180*pi), my + this.targetDistance*cos(variables.Angle/180*pi) );
                            case 'Down'
                                fixRect = CenterRectOnPointd( fixRect, mx + this.targetDistance*sin(variables.Angle/180*pi), my - this.targetDistance*cos(variables.Angle/180*pi) );
                        end
                        Screen('FillOval', graph.window, this.targetColor, fixRect);
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
%                         [d, l, r] = Hardware.GamePad.Query;
%                         if ( l == 1)
%                             this.lastResponse = 1;
%                         elseif( r == 1)
%                             this.lastResponse = 2;
%                         end
                        
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
                    if ( this.lastResponse > 0 )
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
            
            modelspec = 'Response ~ Angle';
            mdl = fitglm(ds(:,{'Response', 'Angle'}), modelspec, 'Distribution', 'binomial');
            
            angles = ds.Angle;
            responses = ds.Response;
%             for i=1:length(this.ConditionVars(1).values)
%                 angles(i) = this.ConditionVars(1).values(i);
%                 responses(i) = mean(ds.Response(ds.Angle==angles(i)));
%             end
            a = min(angles):0.1:max(angles);
            
            figure
            plot(angles,responses*100,'o')
            hold
            p = predict(mdl,a')*100;
            plot(a,p)
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