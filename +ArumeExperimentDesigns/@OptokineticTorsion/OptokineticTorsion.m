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
            
            dlg.Trial_Duration =  { 30 '* (s)' [1 100] };
            dlg.Max_Speed = { 10 '* (deg/s)' [0 100] };
            dlg.Number_of_Speeds = {4 '* (N)' [1 100] };
            
            dlg.Number_of_Dots = { 2000 '* (deg/s)' [10 10000] };
            dlg.Max_Radius = { 40 '* (deg)' [1 100] };
            dlg.Min_Radius = { 1 '* (deg)' [0 100] };

            dlg.Min_Dot_Diam = {0.1  '* (deg)' [0.01 100] };
            dlg.Max_Dot_Diam = {0.4  '* (deg)' [0.01 100] };
            dlg.Number_of_Dot_Sizes = {4 '* (N)' [1 100] };
            
            dlg.NumberOfRepetitions = {1 '* (N)' [1 100] };
            
            dlg.TargetSize = 0.5;
            
            dlg.BackgroundBrightness = 0;
        end
        
        function initExperimentDesign( this  )
%             this.DisplayVariableSelection = {'TrialNumber' 'TrialResult' 'TypeOfTrial' 'Side' 'CenterLocation' 'TimeFlashes'};
        
            this.HitKeyBeforeTrial = 1;
            this.BackgroundColor = this.ExperimentOptions.BackgroundBrightness;
            
            this.trialDuration = this.ExperimentOptions.Trial_Duration; %seconds
            
            % default parameters of any experiment
            this.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, ...
            
            this.trialSequence = 'Random';	% Sequential, Random, Random with repetition, ...
            this.trialsPerSession = this.NumberOfConditions*this.ExperimentOptions.NumberOfRepetitions;
            this.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberOfRepetitions;
            this.blocksToRun = 1;
            this.blocks = struct( 'fromCondition', 1, 'toCondition', this.NumberOfConditions, 'trialsToRun', this.NumberOfConditions  );
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Speed';
            conditionVars(i).values = this.ExperimentOptions.Max_Speed/this.ExperimentOptions.Number_of_Speeds * [0:this.ExperimentOptions.Number_of_Speeds];
        end
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            try
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                graph = this.Graph;
                trialResult = Enum.trialResult.CORRECT;
                
                
                lastFlipTime        = GetSecs;
                secondsRemaining    = this.trialDuration;
                thisTrialData.TimeStartLoop = lastFlipTime;
                
                % prepare dots
                
                mon_width   = this.Graph.pxWidth/this.ExperimentOptions.ScreenWidth;   % horizontal dimension of viewable screen (cm)
                v_dist      = this.ExperimentOptions.ScreenDistance ;   % viewing distance (cm)
                
                dot_speed   = thisTrialData.Speed;    % dot speed (deg/sec)
                ndots       = this.ExperimentOptions.Number_of_Dots; % number of dots
                
                max_d       = this.ExperimentOptions.Max_Radius;   % maximum radius of  annulus (degrees)
                min_d       = this.ExperimentOptions.Min_Radius;    % minumum
                
                differentsizes = this.ExperimentOptions.Number_of_Dot_Sizes; % Use different sizes for each point if >= 1. Use one common size if == 0.
                dot_w       = this.ExperimentOptions.Min_Dot_Diam;  % width of dot (deg)
                                
                ppd = pi * (this.Graph.wRect(3)-this.Graph.wRect(1)) / atan(mon_width/v_dist/2) / 360;    % pixels per degree
                pfs = dot_speed * ppd / this.Graph.frameRate;           % dot speed (pixels/frame)
                s = dot_w * ppd;                                        % dot size (pixels)
                
                rmax = max_d * ppd;	% maximum radius of annulus (pixels from center)
                rmin = min_d * ppd; % minimum
                r = rmin + (rmax-rmin) * sqrt(rand(ndots,1));	% r
                t = 2*pi*rand(ndots,1);                         % theta polar coordinate
                
                cs = [cos(t), sin(t)];
                xy = [r r] .* cs;   % dot positions in Cartesian coordinates (pixels from center)
                xymatrix = transpose(xy);
                 
                mdir = -1;    % motion direction (in or out) for each dot
                dt = pfs * mdir ./ max(r);                       % change in theta per frame (radians)
                % Create a vector with different point sizes for each single dot, if
                % requested:
                if (differentsizes>0)
                    s=(1+rand(1, ndots)*(differentsizes-1))*s;
                end
                [center(1), center(2)] = RectCenter(this.Graph.wRect);
                
                % end prepare dots
                
                if ( ~isempty(this.eyeTracker) )
                    thisTrialData.EyeTrackerFrameStartLoop = this.eyeTracker.RecordEvent(sprintf('TRIAL_START_LOOP %d %d', thisTrialData.TrialNumber, thisTrialData.Condition) );
                end
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = this.trialDuration - secondsElapsed;
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    Screen('DrawDots', graph.window, xymatrix, s, WhiteIndex(graph.window), center,1);  % change 1 to 0 to draw square dots
                    Screen('DrawingFinished', graph.window); % Tell PTB that no further drawing commands will follow before Screen('Flip')
                    
                    
                    t = t + dt;                         % update theta
                    xy = [r r] .* [cos(t), sin(t)];     % compute new positions
                    xymatrix = transpose(xy);
                    
                    
                    
                    %-- Draw fixation spot
                    [mx, my] = RectCenter(this.Graph.wRect);
                    
                    targetPix = this.Graph.pxWidth/this.ExperimentOptions.ScreenWidth * this.ExperimentOptions.ScreenDistance * tan(this.ExperimentOptions.TargetSize/180*pi);
                    fixRect = [0 0 targetPix targetPix];
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
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
    
end