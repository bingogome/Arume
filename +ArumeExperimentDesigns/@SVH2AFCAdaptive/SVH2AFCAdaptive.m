classdef SVH2AFCAdaptive < ArumeExperimentDesigns.SVV2AFCAdaptive
    
    properties
        hapticDevice = [];
        
        motorAngle = 0;
        initialAccelerometerAngle = 0;
        endAccelerometerAngle = 0;
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function dlg = GetOptionsDialog( this, importing )
            if ( ~exist('importing','var') )
                importing = 0;
            end
            dlg = GetOptionsDialog@ArumeExperimentDesigns.SVV2AFCAdaptive(this, importing);
            % Change some of the defaults
            dlg.Type_of_line = { 'Radius|{Diameter}'} ;
            dlg.UseGamePad = { {'{0}','1'} };
            dlg.UseMouse = { {'0','{1}'} };
            dlg.responseDuration = { 5000 '* (ms)' [100 10000] };
        end
        
        function shouldContinue = initBeforeRunning( this )
            shouldContinue = 1;
            
            % Initialize eyetracker
            shouldContinue = initBeforeRunning@ArumeExperimentDesigns.SVV2AFCAdaptive(this);
            
            if ( ~shouldContinue)
                return;
            end
            
            % Initialize HapticDevice
            this.hapticDevice = [];
            this.hapticDevice = ArumeHardware.HapticDevice();
            this.hapticDevice.reset();
            fprintf ('Finished reset, starting experiment.');
            % end initialize HapticDevice
        end
                
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            graph = this.Graph;
            
            response = [];
            reactionTime = nan;
            
            
            % -----------------------------------------------------------------
            % --- MOVE MOTOR -----------------------------------------
            % -----------------------------------------------------------------
            SingleBeep(1000);
            thisTrialData.StartMotorTime            = GetSecs;
            thisTrialData.MotorAngle                = (thisTrialData.AnglePercentRange/100*thisTrialData.Range) + thisTrialData.RangeCenter;
            thisTrialData.InitialAccelerometerAngle = this.hapticDevice.getCurrentAngle();
            %                 pause(.5);
            this.hapticDevice.directMove(thisTrialData.MotorAngle);
            
            %                 while GetSecs - startMotorTime < 1
            %                 end
            
            % checking if the end angle is desired angle
            thisTrialData.EndAccelerometerAngle = this.hapticDevice.getCurrentAngle();
            errorinAngle = thisTrialData.EndAccelerometerAngle-thisTrialData.MotorAngle;
            fprintf('\nError angle = %1.1f\n',errorinAngle);
            
            DoubleBeep(1000);
            % -----------------------------------------------------------------
            % --- END MOVE MOTOR -----------------------------------------
            % -----------------------------------------------------------------
            
            %-- add here the trial code
            Screen('FillRect', graph.window, 0);
            lastFlipTime        = Screen('Flip', graph.window);
            secondsRemaining    = this.trialDuration;
            
            thisTrialData.StartLoopTime = lastFlipTime;
            
            if ( ~isempty(this.eyeTracker) )
                thisTrialData.EyeTrackerFrameStartLoop = this.eyeTracker.RecordEvent(sprintf('TRIAL_START_LOOP %d %d', thisTrialData.TrialNumber, thisTrialData.Condition) );
            end
            this.Graph.ResetFlipTimes();
            
            while secondsRemaining > 0
                
                secondsElapsed      = GetSecs - thisTrialData.StartLoopTime;
                secondsRemaining    = this.trialDuration - secondsElapsed;
                
                % -----------------------------------------------------------------
                % --- Drawing of stimulus -----------------------------------------
                % -----------------------------------------------------------------
                
                %-- Find the center of the screen
                [mx, my] = RectCenter(graph.wRect);
                
                t1 = this.ExperimentOptions.fixationDuration/1000;
                if ( secondsElapsed > t1)
                    %-- Draw target
                    
                    this.DrawLine(thisTrialData.Angle, thisTrialData.Position, this.ExperimentOptions.Type_of_line);
                    
                end
                
                fixRect = [0 0 10 10];
                fixRect = CenterRectOnPointd( fixRect, mx, my );
                Screen('FillOval', graph.window,  this.targetColor, fixRect);
                
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
                
                if ( secondsElapsed > max(t1,0.200)  )
                    response = this.CollectLeftRightResponse();
                    
                    if ( ~isempty( response) )
                        reactionTime = secondsElapsed-t1;
                        break;
                    end
                end
                % -----------------------------------------------------------------
                % --- END Collecting responses  -----------------------------------
                % -----------------------------------------------------------------
            end
            
            % -----------------------------------------------------------------
            % --- Save data and trial result ----------------------------------
            % -----------------------------------------------------------------
            
            if ( isempty(response) )
                trialResult =  Enum.trialResult.ABORT;
            else
                trialResult =  Enum.trialResult.CORRECT;
                thisTrialData.Response = response;
                thisTrialData.ReactionTime = reactionTime;
                thisTrialData.EndAccelerometerAngle = this.hapticDevice.getCurrentAngle();
                thisTrialData.ErrorInAngle = thisTrialData.EndAccelerometerAngle-thisTrialData.MotorAngle;
                fprintf('\nError angle = %1.1f\n',thisTrialData.ErrorInAngle);
                if ( abs(thisTrialData.ErrorInAngle) > 1.25 )
                    disp('TRIAL ABORTED BECAUSE BAR MOVED');
                    trialResult =  Enum.trialResult.SOFTABORT;
                end
            end
            
            % -----------------------------------------------------------------
            % --- END Save data and trial result ------------------------------
            % -----------------------------------------------------------------
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
end
function SingleBeep(freq)
fs = 8000;
T = 0.1; % 2 seconds duration
t = 0:(1/fs):T;
f = freq;
y = sin(2*pi*f*t);
sound(y, fs);
end

function DoubleBeep(freq)
fs = 8000;
T = 0.1; % 2 seconds duration
t = 0:(1/fs):T;
f = freq;
y = [sin(2*pi*f*t) zeros(1,800) sin(2*pi*f*t)]; %changed to 800 from 400 for better distinction of double beep
sound(y, fs);
end

