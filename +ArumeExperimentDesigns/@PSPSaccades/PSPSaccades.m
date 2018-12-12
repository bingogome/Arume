classdef PSPSaccades < ArumeExperimentDesigns.EyeTracking
    
    properties
        fixRad = 20;
        fixColor = [255 0 0];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing)
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this);
            
            dlg.TargetSize = 0.3;
            dlg.FixationMinDuration = 1200;
            dlg.FixationMaxDuration = 2000;
            dlg.EccentricDuration   = 1500;
            
            dlg.NumberOfRepetitions = 10;
            
            dlg.ScreenWidth = { 121 '* (cm)' [1 3000] };
            dlg.ScreenHeight = { 68 '* (cm)' [1 3000] };
            dlg.ScreenDistance = { 60 '* (cm)' [1 3000] };
            
            
            dlg.BackgroundBrightness = 50;
            dlg.CalibrationMode = { {'{No}' 'Yes'} };
        end
        
        function initExperimentDesign( this  )
            this.DisplayVariableSelection = {'TrialNumber' 'TrialResult' 'TargetLocation' 'InitialFixationDuration'};
            
            % this shuffles the second column (initial durations) of the
            % condition matrix. This will break the typical characteristics
            % of a condition matrix
            this.shuffleConditionMatrix(2);
            
            this.HitKeyBeforeTrial = 0;
            this.BackgroundColor = this.ExperimentOptions.BackgroundBrightness/100*255;
            
            this.trialDuration = 4; %seconds
            
            % default parameters of any experiment
            this.trialSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            
            this.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            this.trialsPerSession = this.NumberOfConditions;
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 1;
            this.blocksToRun = 1;
            this.blocks = [ ...
                struct( 'fromCondition', 1, 'toCondition', this.NumberOfConditions, 'trialsToRun', this.NumberOfConditions  )];
            
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'TargetLocation';
            if (~isfield(this.ExperimentOptions, 'CalibrationMode') || strcmp(this.ExperimentOptions.CalibrationMode, 'No'))
                conditionVars(i).values = {[2,0], [-2,0], [5,0], [-5,0], [8,0], [-8,0], [10,0], [-10,0], [0,2], [0,-2], [0,5], [0,-5], [0,8], [0,-8], [0,10], [0,-10]};
            else
                conditionVars(i).values = {[5,0], [-5,0], [10,0], [-10,0], [0,5], [0,-5], [0,10], [0,-10]};
            end

            i = i+1;
            conditionVars(i).name   = 'InitialFixationDuration';
            a = this.ExperimentOptions.FixationMaxDuration;
            b = this.ExperimentOptions.FixationMinDuration;
            n = this.ExperimentOptions.NumberOfRepetitions;
            if ( n> 1 )
                conditionVars(i).values = (a:((b-a)/(n-1)):b);
            else
                conditionVars(i).values = (a+b)/2;
            end
        end
        
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
                       
            try            
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                
                if ( this.ExperimentOptions.UseEyeTracker )
                    msg = ['new trial [' num2str(thisTrialData.TargetLocation(1)) ',' num2str(thisTrialData.TargetLocation(2)) ']'];
                    thisTrialData.EyeTrackerFrameStartLoop = this.eyeTracker.RecordEvent( msg );
                    disp(msg);
                end
                
                graph = this.Graph;
                        
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
                
                lastFlipTime        = GetSecs;
                
                fixDuration = (thisTrialData.InitialFixationDuration)/1000;
                totalDuration = fixDuration + this.ExperimentOptions.EccentricDuration/1000;
                
                secondsRemaining    = totalDuration;
                
                startLoopTime = lastFlipTime;
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - startLoopTime;
                    secondsRemaining    = totalDuration - secondsElapsed;
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    if (secondsElapsed < fixDuration )
                        xdeg = 0;
                        ydeg = 0;
                    else
                        xdeg = thisTrialData.TargetLocation(1);
                        ydeg = thisTrialData.TargetLocation(2);
                    end
                        
                    
                    [mx, my] = RectCenter(this.Graph.wRect);
                    xpix = mx + this.Graph.pxWidth/this.ExperimentOptions.ScreenWidth * this.ExperimentOptions.ScreenDistance * tan(xdeg/180*pi);
                    aspectRatio = 1;
                    ypix = my + this.Graph.pxHeight/this.ExperimentOptions.ScreenHeight * this.ExperimentOptions.ScreenDistance * tan(ydeg/180*pi)*aspectRatio;
                    
                    %-- Draw fixation spot
                    targetPix = this.Graph.pxWidth/this.ExperimentOptions.ScreenWidth * this.ExperimentOptions.ScreenDistance * tan(this.ExperimentOptions.TargetSize/180*pi);
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
            end
            
        end
        
    end
    
    % --------------------------------------------------------------------
    %% Analysis methods --------------------------------------------------
    % --------------------------------------------------------------------
    methods
        
        function trialDataTable = PrepareTrialDataTable( this, ds)
            trialDataTable = ds;
        end
    end
    
    % ---------------------------------------------------------------------
    % Plot  methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        function plotResults = Plot_Traces(this)
            figure
            
        end
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