classdef OptokineticTorsion < ArumeExperimentDesigns.EyeTracking
    %OPTOKINETICTORSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fixRad = 20;
        fixColor = [255 0 0];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this);
            
            dlg.ScreenWidth = { 121 '* (cm)' [1 3000] };
            dlg.ScreenHeight = { 68 '* (cm)' [1 3000] };
            dlg.ScreenDistance = { 60 '* (cm)' [1 3000] };
            
            dlg.TargetSize = 0.5;
            dlg.Sizes = [1 3 5];
            dlg.Number_of_dots = 1000;
            dlg.Speeds = [0  10;
            
                        
            dlg.BackgroundBrightness = 0;
        end
        
        function initExperimentDesign( this  )
%             this.DisplayVariableSelection = {'TrialNumber' 'TrialResult' 'TypeOfTrial' 'Side' 'CenterLocation' 'TimeFlashes'};
        
            this.HitKeyBeforeTrial = 1;
            this.BackgroundColor = this.ExperimentOptions.BackgroundBrightness;
            
            this.trialDuration = 60; %seconds
            
            % default parameters of any experiment
            this.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, ...
            
            if (strcmp(this.ExperimentOptions.InterleaveCalibration, 'Yes'))
                this.trialSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
                this.trialsPerSession = 18*6/2;
                this.trialsBeforeBreak = 11;
                this.blocksToRun = 3;
                this.blocks = [ ...
                    struct( 'fromCondition', 1,     'toCondition', 18, 'trialsToRun', 18 )...
                    struct( 'fromCondition', 1,     'toCondition', 18, 'trialsToRun', 18 )...
                    struct( 'fromCondition', 19,    'toCondition', 36, 'trialsToRun', 18 )];
                this.numberOfTimesRepeatBlockSequence = ceil(this.ExperimentOptions.NumberOfRepetitions/2);
            else
                this.trialSequence = 'Random';	% Sequential, Random, Random with repetition, ...
                this.trialsPerSession = (this.NumberOfConditions+1)*this.ExperimentOptions.NumberOfRepetitions;
                this.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberOfRepetitions;
                this.blocksToRun = 1;
                this.blocks = [ ...
                    struct( 'fromCondition', 1, 'toCondition', this.NumberOfConditions, 'trialsToRun', this.NumberOfConditions  )];
            end
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            if (this.ExperimentOptions.CenterLocationRange == 'Minus20to30') 
                i = i+1;
                conditionVars(i).name   = 'CenterLocation';
                conditionVars(i).values = [-20:10:30];
            elseif (this.ExperimentOptions.CenterLocationRange == 'Minus40to40')
                i = i+1;
                conditionVars(i).name   = 'CenterLocation';
                conditionVars(i).values = [-40:10:40];
            end
            
            i = i+1;
            conditionVars(i).name   = 'Side';
            conditionVars(i).values = {'Left' 'Right'};
            
            if (strcmp(this.ExperimentOptions.InterleaveCalibration, 'Yes'))
                i = i+1;
                conditionVars(i).name   = 'TypeOfTrial';
                conditionVars(i).values = {'Rebound' 'Calibration'};
            end
        end
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            try
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                
                % prepare sound
                beepSound1 = sin( (1:round(0.1*8192))  *  (2*pi*500/8192)   );
                beepSound2 = [beepSound1 zeros(size(beepSound1)) beepSound1];
                beepSound3 = [beepSound1 zeros(size(beepSound1)) beepSound1 zeros(size(beepSound1)) beepSound1];
                FsSound = 8192;
                
                    
                graph = this.Graph;
                
                trialResult = Enum.trialResult.CORRECT;
                
                % flashing control variables
                flashingTimer  = 100000;
                flashCounter = 0;
                
                %-- add here the trial code
                
                if (thisTrialData.TypeOfTrial == 'Rebound') 
                    totalDuration = this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.EccentricDuration + this.ExperimentOptions.CenterDuration;
                else
                    totalDuration = this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.CenterDuration;
                end
                
                nflashes =  ceil((this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.EccentricDuration + this.ExperimentOptions.CenterDuration)/this.ExperimentOptions.FlashingPeriodMs*1000);
                
                lastFlipTime        = GetSecs;
                secondsRemaining    = totalDuration;
                thisTrialData.TimeStartLoop = lastFlipTime;
                
                if ( ~isempty(this.eyeTracker) )
                    thisTrialData.EyeTrackerFrameStartLoop = this.eyeTracker.RecordEvent(sprintf('TRIAL_START_LOOP %d %d', thisTrialData.TrialNumber, thisTrialData.Condition) );
                end
                
                
                sound1 = 0;
                sound2 = 0;
                sound3 = 0;
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = totalDuration - secondsElapsed;
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    isInitialFixationPeriod = secondsElapsed < this.ExperimentOptions.InitialFixaitonDuration;
                    if ( thisTrialData.TypeOfTrial == 'Rebound' )
                        isEccentricFixationPeriod = secondsElapsed >= this.ExperimentOptions.InitialFixaitonDuration && secondsElapsed < (this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.EccentricDuration);
                        isVariCenterFixationPeriod = secondsElapsed >= ( this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.EccentricDuration);
                    else
                        isEccentricFixationPeriod = 0;
                        isVariCenterFixationPeriod = secondsElapsed >= this.ExperimentOptions.InitialFixaitonDuration;
                    end
                    
                    if ( isInitialFixationPeriod )
                        
                        thisTrialData.Xdeg = 0;
                        thisTrialData.Ydeg = 0;
                        
                        if (sound1==0) 
                            sound(beepSound1, FsSound);
                            sound1=1;
                        end
                        
                    elseif ( isEccentricFixationPeriod )
                        
                        if (sound2==0) 
                            sound(beepSound2, FsSound);
                            sound2=1;
                            if ( ~isempty(this.eyeTracker) )
                                thisTrialData.EyeTrackerFrameStartEccectric = this.eyeTracker.RecordEvent(sprintf('TRIAL_START_ECCENTRIC %d', thisTrialData.TrialNumber) );
                            end
                            thisTrialData.TimeStartEccentric = GetSecs;
                        end
                        
                        switch(thisTrialData.Side)
                            case 'Left'
                                thisTrialData.Xdeg = -this.ExperimentOptions.EccentricPosition;
                            case 'Right'
                                thisTrialData.Xdeg = this.ExperimentOptions.EccentricPosition;
                        end
                        
                        thisTrialData.Ydeg = 0;
                    
                    elseif ( isVariCenterFixationPeriod )
                        
                        if (sound3==0)
                            if ( thisTrialData.TypeOfTrial == 'Rebound' )
                                sound(beepSound3, FsSound);
                            else
                                sound(beepSound2, FsSound);
                            end
                            sound3=1;
                            if ( ~isempty(this.eyeTracker) )
                                thisTrialData.EyeTrackerFrameStartVariCenter = this.eyeTracker.RecordEvent(sprintf('TRIAL_START_VARICENTER %d', thisTrialData.TrialNumber) );
                            end
                            thisTrialData.TimeStartVariCenter = GetSecs;
                        end
                        
                        switch(thisTrialData.Side)
                            case 'Left'
                                thisTrialData.Xdeg = -thisTrialData.CenterLocation;
                            case 'Right'
                                thisTrialData.Xdeg = thisTrialData.CenterLocation;
                        end
                        thisTrialData.Ydeg = 0;
                        
                    end
                    
                    
                    tempFlashingTimer = mod(secondsElapsed*1000,this.ExperimentOptions.FlashingPeriodMs);
                    if ( tempFlashingTimer < flashingTimer )
                        flashCounter = 0;
                    end
                    flashingTimer = tempFlashingTimer;
                    if ( flashCounter < this.ExperimentOptions.FlashingOnDurationFrames )
                        flashCounter = flashCounter +1;
                        
                        [mx, my] = RectCenter(this.Graph.wRect);
                        xpix = mx + this.Graph.pxWidth/this.ExperimentOptions.ScreenWidth * this.ExperimentOptions.ScreenDistance * tan(thisTrialData.Xdeg/180*pi);
                        aspectRatio = 1;
                        ypix = my + this.Graph.pxHeight/this.ExperimentOptions.ScreenHeight * this.ExperimentOptions.ScreenDistance * tan(thisTrialData.Ydeg/180*pi)*aspectRatio;
                        
                        %-- Draw fixation spot
                        targetPix = this.Graph.pxWidth/this.ExperimentOptions.ScreenWidth * this.ExperimentOptions.ScreenDistance * tan(this.ExperimentOptions.TargetSize/180*pi);
                        fixRect = [0 0 targetPix targetPix];
                        fixRect = CenterRectOnPointd( fixRect, xpix, ypix );
                        Screen('FillOval', graph.window, this.fixColor, fixRect);
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
            end
            
        end        
    end
    
end