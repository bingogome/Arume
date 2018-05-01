classdef ReboundVariCenter < ArumeCore.ExperimentDesign
    
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
            dlg.UseEyeTracker = { {'0' '{1}'} };
            
            dlg.TargetSize = 0.3;
            dlg.InitialFixaitonDuration = 10;
            dlg.EccentricDuration       = 30;
            dlg.CenterDuration          = 20;
            
            dlg.EccentricPosition = 40;
            dlg.EccentricFlashing = {{'{Yes}' 'No'}};
            dlg.FlashingPeriodMs = 500;
            dlg.FlashingOnDurationFrames = 1;
            
            dlg.NumberOfRepetitions = 5;
            
            dlg.ScreenWidth = 100;
            dlg.ScreenHeight = 100;
            dlg.ScreenDistance =100;
            
            dlg.BackgroundBrightness = 0;
        end
        
        function initExperimentDesign( this  )
            this.HitKeyBeforeTrial = 1;
            this.BackgroundColor = this.ExperimentOptions.BackgroundBrightness;
            
            this.trialDuration = 60; %seconds
            
            % default parameters of any experiment
            this.trialSequence = 'Random';	% Sequential, Random, Random with repetition, ...
            
            this.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            this.trialsPerSession = (this.NumberOfConditions+1)*this.ExperimentOptions.NumberOfRepetitions;
            
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
            conditionVars(i).name   = 'CenterLocation';
            conditionVars(i).values = [-20:10:30];
            
            i = i+1;
            conditionVars(i).name   = 'Side';
            conditionVars(i).values = {'Left' 'Right'};
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
                    this.eyeTracker.RecordEvent(['new trial [' variables.Side ',' num2str(variables.CenterLocation) ']'] );
                end
                
                graph = this.Graph;
                
                trialResult = Enum.trialResult.CORRECT;
                
                % flashing control variables
                flashingTimer  = 100000;
                flashCounter = 0;
                
                %-- add here the trial code
                
                totalDuration = this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.EccentricDuration + this.ExperimentOptions.CenterDuration;
                lastFlipTime        = GetSecs;
                secondsRemaining    = totalDuration;
                startLoopTime = lastFlipTime;
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - startLoopTime;
                    secondsRemaining    = totalDuration - secondsElapsed;
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    if (secondsElapsed < this.ExperimentOptions.InitialFixaitonDuration )
                        xdeg = 0;
                        ydeg = 0;
                    elseif ( secondsElapsed > this.ExperimentOptions.InitialFixaitonDuration && secondsElapsed < (this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.EccentricDuration))
                        switch(variables.Side)
                            case 'Left'
                                xdeg = -this.ExperimentOptions.EccentricPosition;
                            case 'Right'
                                xdeg = this.ExperimentOptions.EccentricPosition;
                        end
                        
                        ydeg = 0;
                    else
                        switch(variables.Side)
                            case 'Left'
                                xdeg = -variables.CenterLocation;
                            case 'Right'
                                xdeg = variables.CenterLocation;
                        end
                        ydeg = 0;
                    end
                    
                    
                    tempFlashingTimer = mod(secondsElapsed*1000,this.ExperimentOptions.FlashingPeriodMs);
                    if ( tempFlashingTimer < flashingTimer )
                        flashCounter = 0;
                    end
                    flashingTimer = tempFlashingTimer;
                    if ( flashCounter < this.ExperimentOptions.FlashingOnDurationFrames )
                        flashCounter = flashCounter +1;
                        
                        [mx, my] = RectCenter(this.Graph.wRect);
                        xpix = mx + this.Graph.pxWidth/this.ExperimentOptions.ScreenWidth * this.ExperimentOptions.ScreenDistance * tan(xdeg/180*pi);
                        aspectRatio = 1;
                        ypix = my + this.Graph.pxHeight/this.ExperimentOptions.ScreenHeight * this.ExperimentOptions.ScreenDistance * tan(ydeg/180*pi)*aspectRatio;
                        
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