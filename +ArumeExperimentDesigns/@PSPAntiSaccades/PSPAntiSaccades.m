classdef PSPAntiSaccades < ArumeCore.ExperimentDesign
    
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
            
            dlg.TargetSize = 0.3;
            dlg.FixationMinDuration = 1200;
            dlg.FixationMaxDuration = 2000;
            dlg.EccentricDuration   = 2000;
            
            dlg.NumberOfRepetitions = 15;
            
            dlg.ScreenWidth = { 121 '* (cm)' [1 3000] };
            dlg.ScreenHeight = { 68 '* (cm)' [1 3000] };
            dlg.ScreenDistance = { 60 '* (cm)' [1 3000] };
            
            dlg.BackgroundBrightness = 50;
        end
        
        function initExperimentDesign( this  )
            this.DisplayVariableSelection = {'TrialNumber' 'TrialResult' 'TargetLocation' 'TargetSide' 'FixationDuration'};
            
            this.HitKeyBeforeTrial = 0;
            this.BackgroundColor = this.ExperimentOptions.BackgroundBrightness/100*255;
            
            this.trialDuration = 3; %seconds
            
            % default parameters of any experiment
            this.trialSequence = 'Random';	% Sequential, Random, Random with repetition, ...
            
            this.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            this.trialsPerSession = (this.NumberOfConditions);
            
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
            conditionVars(i).values = [5 10];
            
            i = i+1;
            conditionVars(i).name   = 'TargetSide';
            conditionVars(i).values = {'Left' 'Right'};
            
            i = i+1;
            conditionVars(i).name   = 'FixationDuration';
            a = this.ExperimentOptions.FixationMaxDuration;
            b = this.ExperimentOptions.FixationMinDuration;
            n = this.ExperimentOptions.NumberOfRepetitions;
            conditionVars(i).values = (a:((b-a)/(n-1)):b);    
        end
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
                       
            try            
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                
                if ( this.ExperimentOptions.UseEyeTracker )
                    msg = ['new trial [' num2str(thisTrialData.TargetLocation) ',' thisTrialData.TargetSide ']'];
                    thisTrialData.EyeTrackerFrameStartLoop = this.eyeTracker.RecordEvent( msg );
                    disp(msg);
                end
                
                graph = this.Graph;
                        
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
                
                lastFlipTime        = GetSecs;
                
                fixDuration = (thisTrialData.FixationDuration)/1000;
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
                        xdeg = thisTrialData.TargetLocation;
                        if ( strcmp(thisTrialData.TargetSide,'Left') )
                            xdeg = -xdeg;
                        end
                        ydeg = 0;
                    end
                    
                    if (secondsElapsed > fixDuration  && secondsElapsed < fixDuration+1)
                        targetPix = this.Graph.pxWidth/this.ExperimentOptions.ScreenWidth * this.ExperimentOptions.ScreenDistance * tan(0.5/180*pi);
                        fixRect = [0 0 targetPix targetPix/2];
                        [mx, my] = RectCenter(this.Graph.wRect);
                        fixRect = CenterRectOnPointd( fixRect, mx, my );
                        Screen('FillRect', graph.window, this.fixColor, fixRect);
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
                
                if ( this.ExperimentOptions.UseEyeTracker )
                    this.eyeTracker.StopRecording();
                end
            end
            
        end
        
        function trialOutput = runPostTrial(this)
            trialOutput = [];   
        end
        
    end
    
    % --------------------------------------------------------------------
    %% Analysis methods --------------------------------------------------
    % --------------------------------------------------------------------
    methods
        
        function trialDataSet = PrepareTrialDataSet( this, ds)
            trialDataSet = ds;
        end
            
        function samplesDataSet = PrepareSamplesDataSet(this, trialDataSet, dataFile, calibrationFile)
            if ( ~exist('dataFile','var') || ~exist('calibrationFile', 'var') )
                res = questdlg('Do you want to import the eye data?', 'Import data', 'Yes', 'No', 'Yes');
                if ( streq(res,'No'))
                    return;
                end
            end
            
            S = [];
            
            if ( ~exist('dataFile', 'var') )
                S.Data_File = { {'uigetfile(''*.txt'')'} };
            end
            
            if ( ~exist('calibrationFile', 'var') )
                S.Calibration_File = { {'uigetfile(''*.cal'')'} };
            end
            
            S = StructDlg(S,'Select data file',[]);
            if ( isempty(S) )
                return;
            end
            
            if ( ~exist('dataFile', 'var') )
                dataFile = S.Data_File;
            end
            
            if ( ~exist('calibrationFile', 'var') )
                calibrationFile = S.Calibration_File;
            end
            
            sessionVogDataFile = fullfile(this.Session.dataRawPath,[this.Session.name '_VOGData.txt']);
            sessionVogCalibrationFile = fullfile(this.Session.dataRawPath,[this.Session.name '_VOGCalibration.cal']);
            
            copyfile(dataFile, sessionVogDataFile);
            copyfile(calibrationFile, sessionVogCalibrationFile);
            
            dataset = GetCalibratedData(sessionVogDataFile, sessionVogCalibrationFile, 1);
            
            samplesDataSet = dataset;
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