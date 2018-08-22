classdef SVVClassicalStereo < ArumeCore.ExperimentDesign
    %OPTOKINETICTORSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        currentAngle = 0;
        rollAngle = 0;
        
        eyeTracker = [];
        
        
        fixRad = 20;
        fixColor = [255 0 0];
        
        lineLength = 100;
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
            this.trialsPerSession = 100;
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 20;
            this.blocksToRun              = 2;
            this.blocks(1).fromCondition  = 1;
            this.blocks(1).toCondition    = 1;
            this.blocks(1).trialsToRun    = 4;
            this.blocks(2).fromCondition  = 2;
            this.blocks(2).toCondition    = 2;
            this.blocks(2).trialsToRun    = 1;
        end
        
        %% run initialization before the first trial is run
        function initBeforeRunning( this )
            if ( this.ExperimentOptions.UseGamePad )
                ArumeHardware.GamePad.Open
            end
            ArumeHardware.OculusVR.Open();
        end
        
        
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'InitialAngle';
            conditionVars(i).values = [15];
            
            i = i+1;
            conditionVars(i).name   = 'TestSVV';
            conditionVars(i).values = [0 1];
            
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
                
                %-- add here the trial code
                Screen('FillRect', graph.window, 0);
                lastFlipTime        = Screen('Flip', graph.window);
                secondsRemaining    = this.trialDuration;
                
                startLoopTime = lastFlipTime;
                
                this.currentAngle = sign((rand(1)-0.5))*20;
                delta = 0;
                timeTargeting = 1000;
                
                BEGINING = 1;
                MOVING = 2;
                TARGETING = 5;
                MOVINGBACK = 3;
                SVV = 4;
                
                trialState = BEGINING;
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - startLoopTime;
                    secondsRemaining    = this.trialDuration - secondsElapsed;
                    
                    
                    screensize = 149.76; %mm
                    IPD = 64;%mm
                    
                    IPDpx = graph.wRect(3)/149.76*IPD;
                    
                    centerLeft =  graph.wRect(3)/2 - IPDpx/2;
                    centerRight =  graph.wRect(3)/2 + IPDpx/2;
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    %-- Find the center of the screen
                    [mx, my] = RectCenter(graph.wRect);
                    
                    angles = ArumeHardware.OculusVR.Query();
                    
                    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                    if ( keyIsDown )
                                keys = find(keyCode);
                    else
                        keys = [];
                    end
                    
                    
                    headAngle = 0 + angles(3)/2;
                    frameAngle = 0 + angles(3);
                    targetangle = frameAngle - variables.InitialAngle;
                    
                    switch(trialState) 
                        case BEGINING
                            this.drawTiltedLine(graph, headAngle, this.lineColor);
                            
                            this.drawFrame(graph, frameAngle, [0 255 0]);
                            
                            if ( secondsElapsed > 1 )
                                trialState = MOVING;
                            end
                        case MOVING
                            this.drawTiltedLine(graph, targetangle, [0 255 0]);
                            
                            this.drawFrame(graph, frameAngle, [0 255 0]);
                            
                            if (variables.TestSVV)
                                this.drawTiltedLine(graph, headAngle, [255 255 0]);
                            else
                                this.drawTiltedLine(graph, headAngle, this.lineColor);
                            end
                            
                            if ( abs(targetangle-headAngle) < 1 )
                                timeTargeting = secondsElapsed;
                                trialState = TARGETING;
                            end
                        case TARGETING
                            this.drawTiltedLine(graph, targetangle, [0 255 0]);
                            this.drawFrame(graph, frameAngle, [0 255 0]);
                            
                            if (variables.TestSVV)
                                this.drawTiltedLine(graph, headAngle, [255 255 0]);
                            else
                                this.drawTiltedLine(graph, headAngle, this.lineColor);
                            end
                            
                            if ( abs(targetangle-headAngle) > 1.5 )
                                timeTargeting = 1000;
                                trialState = MOVING;
                            else
                                if ((secondsElapsed - timeTargeting) > 0.5 )
                                    if (variables.TestSVV)
                                        trialState = SVV;
                                    else
                                        trialState = MOVINGBACK;
                                    end
                                end
                            end
                            
                        case SVV
                            this.currentAngle = this.currentAngle+delta;
                            
                            this.rollAngle =  angles(3);
                            svvangle = this.currentAngle + angles(3);
                            this.drawTiltedLine(graph, svvangle, [255 255 255]);
                            
                            delta = 0;
                            for i=1:length(keys)
                                KbName(keys(i));
                                switch(KbName(keys(i)))
                                    case 'LeftArrow'
                                        delta = -0.2;
                                    case 'RightArrow'
                                        delta = 0.2;
                                    case 'Return'
                                        trialState = MOVINGBACK;
                                    otherwise
                                end
                            end
                    
                        case MOVINGBACK
                            this.drawTiltedLine(graph, headAngle, [0 0 255]);
                            exit = 0;
                            for i=1:length(keys)
                                KbName(keys(i));
                                switch(KbName(keys(i)))
                                    case 'space'
                                        exit = 1;
                                    otherwise
                                end
                            end
                            if ( exit)
                                break;
                            end
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
            trialOutput.RollAngle = this.rollAngle;
        end
        
        function drawTiltedLine(this, graph, angle, color)
            
            IPD = 64;%mm
            
            IPDpx = graph.wRect(3)/149.76*IPD;
            
            centerLeft =  graph.wRect(3)/2 - IPDpx/2;
            centerRight =  graph.wRect(3)/2 + IPDpx/2;
            
            [mx, my] = RectCenter(graph.wRect);
            
            
            fromH = centerLeft - this.lineLength*sin(angle/180*pi);
            fromV = my + this.lineLength*cos(angle/180*pi);
            toH = centerLeft + this.lineLength*sin(angle/180*pi);
            toV = my - this.lineLength*cos(angle/180*pi);
            Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, 2);
            
            
            fromH = centerRight - this.lineLength*sin(angle/180*pi);
            fromV = my + this.lineLength*cos(angle/180*pi);
            toH = centerRight + this.lineLength*sin(angle/180*pi);
            toV = my - this.lineLength*cos(angle/180*pi);
            Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, 2);
        end
        
        function drawFrame(this, graph, angle, color)
            
            IPD = 64;%mm
            
            IPDpx = graph.wRect(3)/149.76*IPD;
            
            centerLeft =  graph.wRect(3)/2 - IPDpx/2;
            centerRight =  graph.wRect(3)/2 + IPDpx/2;
            
            [mx, my] = RectCenter(graph.wRect);
            
            
            fromH = +cos(angle/180*pi)*100+centerLeft - this.lineLength*sin(angle/180*pi);
            fromV = sin(angle/180*pi)*100+my + this.lineLength*cos(angle/180*pi);
            toH = +cos(angle/180*pi)*100+centerLeft+ this.lineLength*sin(angle/180*pi);
            toV = sin(angle/180*pi)*100+my - this.lineLength*cos(angle/180*pi);
            Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, 2);
            
            fromH = -cos(angle/180*pi)*100+centerLeft - this.lineLength*sin(angle/180*pi);
            fromV = -sin(angle/180*pi)*100+my + this.lineLength*cos(angle/180*pi);
            toH = -cos(angle/180*pi)*100+centerLeft+ this.lineLength*sin(angle/180*pi);
            toV = -sin(angle/180*pi)*100+my - this.lineLength*cos(angle/180*pi);
            Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, 2);
            
            
            fromH = +cos(angle/180*pi)*100+centerLeft - this.lineLength*sin(angle/180*pi);
            fromV = sin(angle/180*pi)*100+my + this.lineLength*cos(angle/180*pi);
            toH = -cos(angle/180*pi)*100+centerLeft - this.lineLength*sin(angle/180*pi);
            toV = -sin(angle/180*pi)*100+my + this.lineLength*cos(angle/180*pi);
            Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, 2);
            
            fromH = +cos(angle/180*pi)*100+centerLeft+ this.lineLength*sin(angle/180*pi);
            fromV = sin(angle/180*pi)*100+my - this.lineLength*cos(angle/180*pi);
            toH = -cos(angle/180*pi)*100+centerLeft+ this.lineLength*sin(angle/180*pi);
            toV = -sin(angle/180*pi)*100+my - this.lineLength*cos(angle/180*pi);
            Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, 2);
            
            
            
            
            fromH = +cos(angle/180*pi)*100+centerRight - this.lineLength*sin(angle/180*pi);
            fromV = sin(angle/180*pi)*100+my + this.lineLength*cos(angle/180*pi);
            toH = +cos(angle/180*pi)*100+centerRight+ this.lineLength*sin(angle/180*pi);
            toV = sin(angle/180*pi)*100+my - this.lineLength*cos(angle/180*pi);
            Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, 2);
            
            fromH = -cos(angle/180*pi)*100+centerRight - this.lineLength*sin(angle/180*pi);
            fromV = -sin(angle/180*pi)*100+my + this.lineLength*cos(angle/180*pi);
            toH = -cos(angle/180*pi)*100+centerRight+ this.lineLength*sin(angle/180*pi);
            toV = -sin(angle/180*pi)*100+my - this.lineLength*cos(angle/180*pi);
            Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, 2);
            
            
            fromH = +cos(angle/180*pi)*100+centerRight - this.lineLength*sin(angle/180*pi);
            fromV = sin(angle/180*pi)*100+my + this.lineLength*cos(angle/180*pi);
            toH = -cos(angle/180*pi)*100+centerRight - this.lineLength*sin(angle/180*pi);
            toV = -sin(angle/180*pi)*100+my + this.lineLength*cos(angle/180*pi);
            Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, 2);
            
            fromH = +cos(angle/180*pi)*100+centerRight+ this.lineLength*sin(angle/180*pi);
            fromV = sin(angle/180*pi)*100+my - this.lineLength*cos(angle/180*pi);
            toH = -cos(angle/180*pi)*100+centerRight+ this.lineLength*sin(angle/180*pi);
            toV = -sin(angle/180*pi)*100+my - this.lineLength*cos(angle/180*pi);
            Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, 2);
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
            
            response = ds(ds.TestSVV==1,'Response');
            
            figure
            plot(response);
            
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
