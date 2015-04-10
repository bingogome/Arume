classdef Pursuit < ArumeCore.ExperimentDesign
    
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
            
            dlg.Mode = {{'{Horizontal}' 'Vertical'}};
            dlg.Shuffle = { {'{0}' '1'} };
            
            dlg.TargetDiameter = { 0.2 '* (deg)' [0.1 10] };
            
            dlg.Minimum_Peak_Velocity = { 1 '* (deg/s)' [0 500] };
            dlg.Peak_Velocity_Steps = { 1 '' [1 100] };
            dlg.Maximum_Peak_Velocity = { 1 '* (deg/s)' [0 500] };
            dlg.Miminum_Range = { 20 '* (deg)' [0 200] };
            dlg.Range_Steps = { 1 '* (N)' [1 100] };
            dlg.Maximum_Range = { 20 '* (deg)' [0 200] };
            
            dlg.Initial_Fixation_Duration =  { 2 '* (s)' [0 500] };
            dlg.Trial_Duration =  { 10 '* (s)' [0 500] };
            
            dlg.ScreenDistance = { 124 '* (cm)' [1 200] };
            dlg.ScreenWidth = { 40 '* (cm)' [1 200] };
            dlg.ScreenHeight = { 30 '* (cm)' [1 200] };
            dlg.AspectRatio = {{'1/1' '{4/3}'}};
            
            dlg.NumberOfRepetitions = { 1 '* (N)' [1 200] };
            
            dlg.BackgroundBrightness = { 100 '* (%)' [0 100] };
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
                struct( 'fromCondition', 1, 'toCondition', this.NumberOfConditions, 'trialsToRun', this.NumberOfConditions  ),...
                ];
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'PeakVelocity';
            minvel = this.ExperimentOptions.Minimum_Peak_Velocity;
            maxvel = this.ExperimentOptions.Maximum_Peak_Velocity;
            step = (maxvel-minvel)/this.ExperimentOptions.Peak_Velocity_Steps;
            if ( step==0)
                step = 1;
            end
            conditionVars(i).values = [minvel:step:maxvel];
            
            i = i+1;
            conditionVars(i).name   = 'Range';
            minrange = this.ExperimentOptions.Miminum_Range;
            maxrange = this.ExperimentOptions.Maximum_Range;
            step = (maxrange-minrange)/this.ExperimentOptions.Range_Steps;
            if ( step==0)
                step = 1;
            end
            conditionVars(i).values = [minrange:step:maxrange];
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
                    this.eyeTracker.RecordEvent(['new trial'] );
                end
                
                graph = this.Graph;
                        
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
                
                lastFlipTime        = GetSecs;
                secondsRemaining    = this.trialDuration;
                
                startLoopTime = lastFlipTime;
                
                freq = variables.PeakVelocity/2/pi;
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - startLoopTime;
                    secondsRemaining    = this.trialDuration - secondsElapsed;
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    [mx, my] = RectCenter(this.Graph.wRect);
                    
                    switch ( this.ExperimentOptions.Mode )
                        case 'Horizontal'
                            if (secondsElapsed > this.ExperimentOptions.Initial_Fixation_Duration )
                                xdeg = sin((secondsElapsed-this.ExperimentOptions.Initial_Fixation_Duration)*freq)*variables.Range;
                                ydeg = 0;
                            else
                                xdeg = 0;
                                ydeg = 0;
                            end
                        case 'Vertical'
                            if (secondsElapsed > this.ExperimentOptions.Initial_Fixation_Duration )
                                ydeg = sin((secondsElapsed-this.ExperimentOptions.Initial_Fixation_Duration)*freq)*variables.Range;
                                xdeg = 0;
                            else
                                xdeg = 0;
                                ydeg = 0;
                            end
                    end
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