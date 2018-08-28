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
            dlg = GetOptionsDialog@ArumeExperimentDesigns.SVV2AFCAdaptive(this);
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
        
        function trialResult = runTrial( this, variables )
            
            try
                this.lastResponse = [];
                this.reactionTime = nan;
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                
                graph = this.Graph;
                
                trialResult = Enum.trialResult.CORRECT;
                
                % MOVE MOTOR
                % beep before moving the motor
                
                SingleBeep(1000);
                startMotorTime = Screen('Flip', graph.window);
                this.motorAngle = (variables.AnglePercentRange/100*this.currentRange) + this.currentCenterRange;
                this.initialAccelerometerAngle = this.hapticDevice.getCurrentAngle();
                %                 pause(.5);
                this.hapticDevice.directMove(this.motorAngle);
                
%                 while GetSecs - startMotorTime < 1
%                 end
                
                % checking if the end angle is desired angle
                this.endAccelerometerAngle = this.hapticDevice.getCurrentAngle();
                errorinAngle = this.endAccelerometerAngle-this.motorAngle;
                fprintf('\nError angle = %1.1f\n',errorinAngle);
                
                DoubleBeep(1000);
                
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
                    
                    t1 = this.ExperimentOptions.fixationDuration/1000;
                    t2 = this.ExperimentOptions.fixationDuration/1000 +this.ExperimentOptions.targetDuration/1000;
                    
                    lineLength = 300;
                    
                    % if ( secondsElapsed > t1 && secondsElapsed < t2 )
                    if ( secondsElapsed > t1)
                        %-- Draw target
                        
                        switch(variables.Position)
                            case 'Up'
                                fromH = mx;
                                fromV = my;
                                toH = mx + lineLength*sin(this.currentAngle/180*pi);
                                toV = my - lineLength*cos(this.currentAngle/180*pi);
                            case 'Down'
                                fromH = mx;
                                fromV = my;
                                toH = mx - lineLength*sin(this.currentAngle/180*pi);
                                toV = my + lineLength*cos(this.currentAngle/180*pi);
                        end
                        
                        Screen('DrawLine', graph.window, this.targetColor, fromH, fromV, toH, toV, 4);
                        
                    end
                    
                    % if (secondsElapsed < t2)
                    %   % black patch to block part of the line
                    
                    fixRect = [0 0 10 10];
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    Screen('FillOval', graph.window,  this.targetColor, fixRect);
                    %                     end
                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------
                    
                    
                    % -----------------------------------------------------------------
                    % DEBUG
                    % -----------------------------------------------------------------
                    if (1)
                        % TODO: it would be nice to have some call back system here
                        Screen('DrawText', graph.window, sprintf('%i seconds remaining...', round(secondsRemaining)), 20, 50, graph.white);
                        currentline = 50 + 25;
                        vNames = fieldnames(variables);
                        for iVar = 1:length(vNames)
                            if ( ischar(variables.(vNames{iVar})) )
                                s = sprintf( '%s = %s',vNames{iVar},variables.(vNames{iVar}) );
                            else
                                s = sprintf( '%s = %s',vNames{iVar},num2str(variables.(vNames{iVar})) );
                            end
                            Screen('DrawText', graph.window, s, 20, currentline, graph.white);
                            
                            currentline = currentline + 25;
                        end
                        
                        Screen('DrawText', graph.window, sprintf('Line angle: %d Motor angle: %d', this.currentAngle, this.motorAngle), 400, 400, graph.white);
                    end
                    % -----------------------------------------------------------------
                    % END DEBUG
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
                        reverse = isequal(variables.Position,'Down');
                        response = this.CollectLeftRightResponse(reverse);
                        
                        %                         % REMEMBER TO REMOVE THIS LINES!!!!!!! it will make the experiment to go alone
                        %                         if ( this.currentAngle >  0 )
                        %                             response = 'R';
                        %                         else
                        %                             response = 'L';
                        %                         end
                        %                         % REMOVE UP TO HERE
                            
                        
                        if ( ~isempty( response) )
                            this.lastResponse = response;
                        end
                    end
                    
                    if ( ~isempty(this.lastResponse) )
                        this.reactionTime = secondsElapsed-1;
                        disp(num2str(this.lastResponse));
                        
                        % checking if the angle difference before and after
                        % response is greater than 3, abort trial if it is
                        this.endAccelerometerAngle = this.hapticDevice.getCurrentAngle();
                        errorinAngle = this.endAccelerometerAngle-this.motorAngle;
                        fprintf('\nError angle = %1.1f\n',errorinAngle);
                        if ( abs(errorinAngle) > 1.25 ) 
                            disp('TRIAL ABORTED BECAUSE BAR MOVED');
                            trialResult =  Enum.trialResult.SOFTABORT;
                        end
                        
                        break;
                    end
                    
                    % -----------------------------------------------------------------
                    % --- END Collecting responses  -----------------------------------
                    % -----------------------------------------------------------------
                end
            catch ex
                rethrow(ex)
            end
            
            if ( this.lastResponse < 0)
                trialResult =  Enum.trialResult.ABORT;
            end
            
        end
        
        function trialOutput = runPostTrial(this)
            trialOutput = runPostTrial@ArumeExperimentDesigns.SVV2AFCAdaptive(this);
            trialOutput.initialAccelerometerAngle = this.initialAccelerometerAngle;
            trialOutput.endAccelerometerAngle = this.endAccelerometerAngle;
            trialOutput.motorAngle = this.motorAngle;
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

