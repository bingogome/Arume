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
                this.eyeTracker.SetSessionName(this.Session.name);
                this.eyeTracker.StartRecording();
            end
            
        end
        
        function cleanAfterRunning(this)
            
            if ( this.ExperimentOptions.UseEyeTracker )
                this.eyeTracker.StopRecording();
        
                disp('Downloading files...');
                files = this.eyeTracker.DownloadFile();
                
                disp(files{1});
                disp(files{2});
                disp(files{3});
                disp('Finished downloading');
                
                this.addFile('vogDataFile', files{1});
                this.addFile('vogCalibrationFile', files{2});
                this.addFile('vogEventsFile', files{3});
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
            samplesDataSet = [];
            
            dataFiles = this.Session.currentRun.LinkedFiles.vogDataFile;
            calibrationFiles = this.Session.currentRun.LinkedFiles.vogCalibrationFile;
            eventFiles = this.Session.currentRun.LinkedFiles.vogEventsFile;

            
            if (~iscell(dataFiles) )
                dataFiles = {dataFiles};
                calibrationFiles = {calibrationFiles};
                eventFiles = {eventFiles};
            end
            
            for i=1:length(dataFiles)
                dataFile = dataFiles{i};
                calibrationFile = calibrationFiles{i};
                eventFile = eventFiles{i};
             
                dataFilePath = fullfile(this.Session.dataRawPath, dataFile);
                calibrationFilePath = fullfile(this.Session.dataRawPath, calibrationFile);
                eventFilesPath = fullfile(this.Session.dataRawPath, eventFile);
                t= readtable(eventFilesPath);
                t(contains(t.Var4,'KEYPRESS'),:) = [];
                FrameNumberTrialOneStrat = t.Var3{1}(8:end-2);
                
                % load data
                rawData = VOG.LoadVOGdataset(dataFilePath);
                
                % calibrate data
                [calibratedData leftEyeCal rightEyeCal] = VOG.CalibrateData(rawData, calibrationFilePath);
                
                [cleanedData, fileSamplesDataSet] = VOG.ResampleAndCleanData3(calibratedData, 1000);
            end
            if ( isempty(samplesDataSet) )
                samplesDataSet = fileSamplesDataSet;
            else
                samplesDataSet = cat(1,samplesDataSet,fileSamplesDataSet);
            end
        end
    end
    
    % ---------------------------------------------------------------------
    % Plot  methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        function plotResults = Plot_Traces(this)
            
            data = this.Session.samplesDataSet;
            figure
            
            MEDIUM_BLUE =  [0.1000 0.5000 0.8000];
            MEDIUM_RED = [0.9000 0.2000 0.2000];
            
            figure
            time = (1:length(data.RightT))/500;
            
%             lb = (boxcar(abs([0;diff(data.LeftUpperLid)])>20,10)>0) | (abs(data.LeftUpperLid-median(data.LeftUpperLid)) > 50);
%             rb = boxcar(abs([0;diff(data.RightUpperLid)])>20,10)>0 | (abs(data.RightUpperLid-median(data.RightUpperLid)) > 50);
%             
%             data.LeftX(lb) = nan;
%             data.LeftY(lb) = nan;
%             data.LeftT(lb) = nan;
%             
%             data.RightX(rb) = nan;
%             data.RightY(rb) = nan;
%             data.RightT(rb) = nan;
            
            subplot(3,1,1,'nextplot','add')
            plot(time, data.LeftX, 'color', [ MEDIUM_BLUE ])
            plot(time, data.RightX, 'color', [ MEDIUM_RED])
            set(gca,'ylim',[-50 50])
            ylabel('Horizontal (deg)','fontsize', 16);
            
            subplot(3,1,2,'nextplot','add')
            plot(time, data.LeftY, 'color', [ MEDIUM_BLUE ])
            plot(time, data.RightY, 'color', [ MEDIUM_RED])
            set(gca,'ylim',[-50 50])
            ylabel('Vertical (deg)','fontsize', 16);
            
            subplot(3,1,3,'nextplot','add')
            plot(time, data.LeftT, 'color', [ MEDIUM_BLUE ])
            plot(time, data.RightT, 'color', [ MEDIUM_RED])
            set(gca,'ylim',[-50 50])
            ylabel('Torsion (deg)','fontsize', 16);
            xlabel('Time (s)');
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