classdef SVVLineAdaptFixed < ArumeExperimentDesigns.SVVdotsAdaptFixed
    %SVVLineAdaptFixed Summary of this class goes here
    %   Detailed explanation goes here
    
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
            
            if ( ~isempty(this.eyeTracker) )
                this.eyeTracker.SetDataFileName(this.Session.name);
                if ( ~this.eyeTracker.recording )
                    this.eyeTracker.StartRecording();
                    pause(1);
                end
                this.eyeTracker.SaveEvent(size(this.Session.CurrentRun.pastConditions,1));
            end
            
            try
                this.lastResponse = -1;
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

                    t1 = this.ExperimentOptions.fixationDuration/1000;
                    t2 = this.ExperimentOptions.fixationDuration/1000 +this.ExperimentOptions.targetDuration/1000;
                    
                    lineLength = 300;
                    
                    if ( secondsElapsed > t1 && secondsElapsed < t2 )
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
                    
                    if (secondsElapsed < t2)
%                         % black patch to block part of the line
%                         fixRect = [0 0 150 150];
%                         fixRect = CenterRectOnPointd( fixRect, mx, my );
%                         Screen('FillOval', graph.window,  [0 0 0] , fixRect);
                        
                        fixRect = [0 0 10 10];
                        fixRect = CenterRectOnPointd( fixRect, mx, my );
                        Screen('FillOval', graph.window,  this.targetColor, fixRect);
                    end
                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------
                    
                    
                % -----------------------------------------------------------------
                % DEBUG
                % -----------------------------------------------------------------
                if (0)
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
                        if ( this.ExperimentOptions.UseGamePad )
                            [d, l, r] = ArumeHardware.GamePad.Query;
                            if ( l == 1)
                                switch(variables.Position)
                                    case 'Up'
                                        this.lastResponse = 1;
                                    case 'Down'
                                        this.lastResponse = 0;
                                end
                            elseif( r == 1)
                                switch(variables.Position)
                                    case 'Up'
                                        this.lastResponse = 0;
                                    case 'Down'
                                        this.lastResponse = 1;
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
                                                    this.lastResponse = 0;
                                            end
                                        case 'LeftArrow'
                                            switch(variables.Position)
                                                case 'Up'
                                                    this.lastResponse = 0;
                                                case 'Down'
                                                    this.lastResponse = 1;
                                            end
                                    end
                                end
                            end
                        end
%                         if ( this.ExperimentOptions.UseGamePad )
%                             [d, l, r] = ArumeHardware.GamePad.Query;
%                             if ( l == 1)
%                                 this.lastResponse = 1;
%                             elseif( r == 1)
%                                 this.lastResponse = 0;
%                             end
%                         else
%                             [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
%                             if ( keyIsDown )
%                                 keys = find(keyCode);
%                                 for i=1:length(keys)
%                                     KbName(keys(i))
%                                     switch(KbName(keys(i)))
%                                         case 'RightArrow'
%                                             this.lastResponse = 1;
%                                         case 'LeftArrow'
%                                             this.lastResponse = 0;
%                                     end
%                                 end
%                             end
%                         end
                    end
                    if ( this.lastResponse >= 0 )
                        this.reactionTime = secondsElapsed-1;
                        disp(num2str(this.lastResponse));
                        break;
                    end
                    
                    
                    % -----------------------------------------------------------------
                    % --- END Collecting responses  -----------------------------------
                    % -----------------------------------------------------------------
                    
                end
            catch ex
                if ( ~isempty( this.eyeTracker ) )
                    this.eyeTracker.StopRecording();
                end
                %  this.eyeTracker.StopRecording();
                rethrow(ex)
            end
            
            
            if ( this.lastResponse < 0)
                trialResult =  Enum.trialResult.ABORT;
            end
            
            if ( ~isempty( this.eyeTracker ) )
                
                if ( length(this.Session.CurrentRun.futureConditions) == 0 )
                    this.eyeTracker.StopRecording();
                end
            end
            
            % this.eyeTracker.StopRecording();
            
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

