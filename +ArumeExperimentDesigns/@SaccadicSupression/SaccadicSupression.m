classdef SaccadicSupression < ArumeExperimentDesigns.Fixation
    %OPTOKINETICTORSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
        
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function dlg = GetOptionsDialog( this )
            dlg.UseEyeTracker = { {'{0}' '1'} };
            dlg.Shuffle = { {'0' '{1}'} };
            dlg.TargetDiameter = { 0.2 '* (deg)' [0.1 10] };
            
            dlg.Trial_Duration =  { 2 '* (s)' [0 500] };
            
            dlg.ScreenDistance = { 124 '* (cm)' [1 200] };
            dlg.ScreenWidth = { 40 '* (cm)' [1 200] };
            dlg.ScreenHeight = { 30 '* (cm)' [1 200] };
            
            dlg.AspectRatio = {{'1/1' '{4/3}'}};
            
            dlg.NumberOfRepetitions = { 1 '* (N)' [1 200] };
            
            dlg.BackgroundBrightness = { 50 '* (%)' [0 100] };
            
            
            
            
            dlg.Mode = {{'{TopBottom}' 'LeftRight'}};
            dlg.FlashDuration = { 100 '* (ms)' [10 1000] };
            dlg.BarSize = { 0.2 '* (%total)' [0 0.5] };
        end
        
        function initExperimentDesign( this  )
            this.HitKeyBeforeTrial = 0;
            this.BackgroundColor = this.ExperimentOptions.BackgroundBrightness/100*255;
            this.trialDuration = this.ExperimentOptions.Trial_Duration; %seconds
                        
            % default parameters of any experiment
            if ( this.ExperimentOptions.Shuffle )
                this.trialSequence = 'Random';	% Sequential, Random, Random with repetition, ...
            else
                this.trialSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            end
            
            this.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            this.trialsPerSession = this.NumberOfConditions*this.ExperimentOptions.NumberOfRepetitions;
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberOfRepetitions;
            this.blocksToRun = 1;
            this.blocks = [ ...
                struct( 'fromCondition', 1, 'toCondition', this.NumberOfConditions, 'trialsToRun', this.NumberOfConditions  )];
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'TimeOffset';
            conditionVars(i).values = 0:100:500;
        end
        
        function trialResult = runPreTrial(this, variables )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            trialResult =  Enum.trialResult.CORRECT;
        end
        
        
        function trialResult = runTrial( this, variables )
                       
            try            
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                
                if ( this.ExperimentOptions.UseEyeTracker )
                    this.eyeTracker.RecordEvent(['new trial']);
                end
                
                graph = this.Graph;
                        
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
                
                lastFlipTime        = GetSecs;
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
                    targetPix = this.Graph.pxWidth/this.ExperimentOptions.ScreenWidth * this.ExperimentOptions.ScreenDistance * tan(this.ExperimentOptions.TargetDiameter/180*pi);
                    fixRect = [0 0 targetPix targetPix];

                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    Screen('FillOval', graph.window, this.fixColor, fixRect);
                    
                    
                    onsetTime = this.trialDuration/2 + variables.TimeOffset;
                    offsetTime= this.trialDuration/2 + variables.TimeOffset+this.ExperimentOptions.FlashDuration; 
                    if ( secondsElapsed*1000 > onsetTime && secondsElapsed*1000 < offsetTime )
                        topRect  = graph.wRect;
                        topRect(4) = topRect(4)*this.ExperimentOptions.BarSize;
                        
                        bottomRect = graph.wRect;
                        bottomRect(2) = bottomRect(4)*(1-this.ExperimentOptions.BarSize);
                        Screen('FillRect', graph.window, this.fixColor, topRect );
                        Screen('FillRect', graph.window, this.fixColor, bottomRect );
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
                rethrow(ex)
                
                if ( this.ExperimentOptions.UseEyeTracker )
                    this.eyeTracker.StopRecording();
                end
            end
            
        end
        
        function trialOutput = runPostTrial(this)
            trialOutput = [];   
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
    end
    
    % ---------------------------------------------------------------------
    % Plot  methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
    end
    
    % ---------------------------------------------------------------------
    % Plot Aggregate methods
    % ---------------------------------------------------------------------
    methods ( Static = true, Access = public )
    end
    
    % ---------------------------------------------------------------------
    % Other methods
    % ---------------------------------------------------------------------
    methods( Access = public )
    end
end