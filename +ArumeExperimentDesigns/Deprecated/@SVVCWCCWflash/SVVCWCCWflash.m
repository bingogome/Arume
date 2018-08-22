classdef SVVCWCCWflash < ArumeExperimentDesigns.SVVCWCCW
    
    properties
                
    end
    
    % ---------------------------------------------------------------------
    % Options to set at runtime
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
       
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
                        
                        if ( secondsElapsed > 0.1 & secondsElapsed <0.4 )
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
       
    end
    
    % ---------------------------------------------------------------------
    % Other methods
    % ---------------------------------------------------------------------
    methods( Access = public )
   
    end
end
