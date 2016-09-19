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
            
            dlg.Mode = {{'{Horizontal}' 'Vertical' 'HVcross' 'DiagonalCross' 'Grid' 'Across' 'AcrossV'}};
            dlg.Shuffle = { {'{0}' '1'} };
            
            dlg.TargetDiameter = { 0.2 '* (deg)' [0.1 10] };
            
            dlg.Trial_Duration =  { 2 '* (s)' [0 500] };
            
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
            
            this.trialDuration = this.ExperimentOptions.Trial_Duration; %seconds
            
            % default parameters of any experiment
            if ( this.ExperimentOptions.Shuffle )
                this.trialSequence = 'Random';	% Sequential, Random, Random with repetition, ...
            else
                this.trialSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            end
            
            this.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            this.trialsPerSession = (this.NumberOfConditions+1)*this.ExperimentOptions.NumberOfRepetitions;
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberOfRepetitions;
            
            switch(this.ExperimentOptions.Mode)
                case 'Across' 
                case 'AcrossV' 
                    this.blocksToRun = 1;
                    this.blocks = [ ...
                        struct( 'fromCondition', 1, 'toCondition', this.NumberOfConditions, 'trialsToRun', this.NumberOfConditions  )];
                otherwise
                    this.blocksToRun = 3;
                    this.blocks = [ ...
                        struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 1), ...
                        struct( 'fromCondition', 2, 'toCondition', this.NumberOfConditions, 'trialsToRun', this.NumberOfConditions - 1 ),...
                        struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 1)];
            end
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'TargetLocation';
            switch(this.ExperimentOptions.Mode)
                case 'Horizontal' 
                    conditionVars(i).values = {[0,0]};
                    for x=(-this.ExperimentOptions.MaxEccentricity):this.ExperimentOptions.TargetSeparation:this.ExperimentOptions.MaxEccentricity
                        conditionVars(i).values{end+1}   =  [x,0];
                    end
                case 'Vertical' 
                    conditionVars(i).values = {[0,0]};
                    for y=(-this.ExperimentOptions.MaxEccentricity):this.ExperimentOptions.TargetSeparation:this.ExperimentOptions.MaxEccentricity
                        conditionVars(i).values{end+1}   =  [0,y];
                    end
                case 'HVcross' 
                    conditionVars(i).values = {[0,0]};
                    for x=(-this.ExperimentOptions.MaxEccentricity):this.ExperimentOptions.TargetSeparation:this.ExperimentOptions.MaxEccentricity
                        conditionVars(i).values{end+1}   =  [x,0];
                    end
                    for y=(-this.ExperimentOptions.MaxEccentricity):this.ExperimentOptions.TargetSeparation:this.ExperimentOptions.MaxEccentricity
                        conditionVars(i).values{end+1}   =  [0,y];
                    end
                case 'Grid'
                    conditionVars(i).values = {[0,0]};
                    for x=(-this.ExperimentOptions.MaxEccentricity):this.ExperimentOptions.TargetSeparation:this.ExperimentOptions.MaxEccentricity
                        for y=(-this.ExperimentOptions.MaxEccentricity):this.ExperimentOptions.TargetSeparation:this.ExperimentOptions.MaxEccentricity
                            conditionVars(i).values{end+1}   =  [x,y];
                        end
                    end
                case 'Across'
                    conditionVars(i).values   =  {[-this.ExperimentOptions.MaxEccentricity,0]};
                    conditionVars(i).values{2}   =  [this.ExperimentOptions.MaxEccentricity,0];
                case 'AcrossV'
                    conditionVars(i).values   =  {[0, -this.ExperimentOptions.MaxEccentricity]};
                    conditionVars(i).values{2}   =  [0,this.ExperimentOptions.MaxEccentricity];
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