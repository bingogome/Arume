classdef Saccades < ArumeCore.ExperimentDesign
    
    properties
        eyeTracker
        
        fixRad = 20;
        fixColor = [255 0 0];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this )
            dlg.UseEyeTracker = { {'{0}' '1'} };
            
            dlg.Mode = {{'{Horizontal}' 'Vertical' 'HVcross' 'DiagonalCross' 'Grid'}};
            dlg.Shuffle = { {'{0}' '1'} };
            
            dlg.TargetDiameter = { 0.2 '* (deg)' [0.1 10] };
            
            dlg.FixationDuration = { 2 '* (seconds)' [1 200] };
            
            dlg.ScreenDistance = { 124 '* (cm)' [1 200] };
            dlg.ScreenWidth = { 40 '* (cm)' [1 200] };
            dlg.ScreenHeight = { 30 '* (cm)' [1 200] };
            
            dlg.MaxEccentricity = { 20 '* (deg)' [0 200] };
            dlg.TargetSeparation = { 5 '* (deg)' [0 200] };
            dlg.AspectRatio = {{'1/1' '{4/3}'}};
            
            dlg.NumberOfRepetitions = { 1 '* (N)' [1 200] };
            
            dlg.BackgroundBrightness = { 100 '* (%)' [0 100] };
        end
        
        function initExperimentDesign( this  )
            this.HitKeyBeforeTrial = 0;
            this.BackgroundColor = this.ExperimentOptions.BackgroundBrightness/100*255;
            
            this.trialDuration = 2; %seconds
            
            % default parameters of any experiment
            if ( this.ExperimentOptions.Shuffle )
                this.trialSequence = 'Random';	% Sequential, Random, Random with repetition, ...
            else
                this.trialSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            end
            
            this.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            this.trialsPerSession = this.NumberOfConditions+1;
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 1;
            this.blocksToRun = 3;
            this.blocks = [ ...
                struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 2), ...
                struct( 'fromCondition', 2, 'toCondition', this.NumberOfConditions, 'trialsToRun', this.NumberOfConditions - 1 ),...
                struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 2)];
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'TargetLocation';
            conditionVars(i).values = {[0,0]};
            switch(this.ExperimentOptions.Mode)
                case 'Horizontal' 
                case 'Vertical' 
                case 'HVcross' 
                case 'DiagonalCross' 
                case 'Grid'
                    for x=(-this.ExperimentOptions.MaxEccentricity):this.ExperimentOptions.TargetSeparation:this.ExperimentOptions.MaxEccentricity
                        for y=(-this.ExperimentOptions.MaxEccentricity):this.ExperimentOptions.TargetSeparation:this.ExperimentOptions.MaxEccentricity
                            conditionVars(i).values{end+1}   =  [x,y];
                        end
                    end
            end
        end
        
        function initBeforeRunning( this )

            if ( this.ExperimentOptions.UseEyeTracker )
                this.eyeTracker = ArumeHardware.VOG();
                this.eyeTracker.Connect();
                this.eyeTracker.StartRecording();
            end
                
        end
        
        function cleanAfterRunning(this)
            
                if ( this.ExperimentOptions.UseEyeTracker )
                    this.eyeTracker.StopRecording();
                end
        end
        
        function trialResult = runPreTrial(this, variables )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            trialResult =  Enum.trialResult.CORRECT;
        end
        
        function trialResult = runTrial( this, variables )
                       
            try            
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                
                if ( this.ExperimentOptions.UseEyeTracker )
                    this.eyeTracker.RecordEvent(['new trial [' num2str(variables.TargetLocation(1)) ',' num2str(variables.TargetLocation(2)) ']'] );
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
                    
                    [mx, my] = RectCenter(this.Graph.wRect);
                    xdeg = variables.TargetLocation(1);
                    ydeg = variables.TargetLocation(2);
                    xpix = mx + this.Graph.pxWidth/this.ExperimentOptions.ScreenWidth * this.ExperimentOptions.ScreenDistance * tan(xdeg/180*pi);
                    aspectRatio = 1/eval(this.ExperimentOptions.AspectRatio);
                    ypix = my + this.Graph.pxHeight/this.ExperimentOptions.ScreenHeight * this.ExperimentOptions.ScreenDistance * tan(ydeg/180*pi)*aspectRatio;
                    
                    %-- Draw fixation spot
                    targetPix = this.Graph.pxWidth/this.ExperimentOptions.ScreenWidth * this.ExperimentOptions.ScreenDistance * tan(this.ExperimentOptions.TargetDiameter/180*pi);
                    fixRect = [0 0 targetPix targetPix];
                    fixRect = CenterRectOnPointd( fixRect, xpix, ypix );
                    Screen('FillOval', graph.window, this.fixColor, fixRect);
                    
                    
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