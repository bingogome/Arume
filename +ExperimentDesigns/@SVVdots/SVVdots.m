classdef SVVdots < ArumeCore.ExperimentDesign
    %OPTOKINETICTORSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        lastResponse = '';
        
        eyeTracker = [];
        
        
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
            this.trialSequence = 'Random';	% Sequential, Random, Random with repetition, ...
            this.trialAbortAction = 'Delay';     % Repeat, Delay, Drop
            this.trialsPerSession = 136;
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 4;
            this.blocksToRun              = 1;
            this.blocks{1}.fromCondition  = 1;
            this.blocks{1}.toCondition    = 34;
            this.blocks{1}.trialsToRun    = 34;
            
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars{i}.name   = 'Angle';
            conditionVars{i}.values = [-16:2:16];
            
            i = i+1;
            conditionVars{i}.name   = 'Position';
            conditionVars{i}.values = {'Up' 'Down'};
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
                fixRect = [0 0 5 5];
                fixRect = CenterRectOnPointd( fixRect, mx-graph.wRect(3)/4, my );
                Screen('FillOval', graph.window, this.fixColor, fixRect);
                
                if ( secondsElapsed > 1 && secondsElapsed < 1.1 )
                    %-- Draw target
                    fixRect = [0 0 7 7];
                    mx = mx-graph.wRect(3)/4;
                    switch(variables.Position)
                        case 'Up'
                            fixRect = CenterRectOnPointd( fixRect, mx + this.targetDistance*sin(variables.Angle/180*pi), my + this.targetDistance*cos(variables.Angle/180*pi) );
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
        function analysisResults = Analysis_getSigmoid(this)
            analysisResults = 0;
            
            data = zeros(length(this.Session.CurrentRun.Data),3);
            for i=1:length(this.Session.CurrentRun.Data)
                data(i,1) =  this.Session.CurrentRun.Data{i}.variables.Angle;
                switch(this.Session.CurrentRun.Data{i}.variables.Position)
                    case 'Up'
                        data(i,2) =  0;
                    case 'Down'
                        data(i,2) =  1;
               end
               data(i,3) =  this.Session.CurrentRun.Data{i}.trialOutput.Response;
            end
            
            data1 = data(data(:,3) > 0,:);
            
            ds = dataset
            
            ds.angle = data1(:,1);
            ds.response = data1(:,3)-1;
            
            modelspec = 'response ~ angle';
            mdl = fitglm(ds,modelspec,'Distribution','binomial');
            
            angles = [];
            responses = [];
            for i=1:length(this.ConditionVars{1}.values)
                angles(i) = this.ConditionVars{1}.values(i);
                responses(i) = mean(ds.response(ds.angle==angles(i)))
            end
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
end