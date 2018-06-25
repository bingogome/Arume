classdef PSPSaccades < ArumeCore.ExperimentDesign
    
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
            
            dlg.TargetSize = 0.3;
            dlg.FixationMinDuration = 1200;
            dlg.FixationMaxDuration = 2000;
            dlg.EccentricDuration   = 1500;
            
            dlg.NumberOfRepetitions = 10;
            
            dlg.ScreenWidth = 100;
            dlg.ScreenHeight = 100;
            dlg.ScreenDistance =100;
            
            dlg.BackgroundBrightness = 50;
        end
        
        function initExperimentDesign( this  )
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
            conditionVars(i).values = {[2,0], [-2,0], [5,0], [-5,0], [8,0], [-8,0], [10,0], [-10,0], [0,2], [0,-2], [0,5], [0,-5], [0,8], [0,-8], [0,10], [0,-10]};
            
            i = i+1;
            conditionVars(i).name   = 'InitialFixationDuration';
            a = this.ExperimentOptions.FixationMaxDuration;
            b = this.ExperimentOptions.FixationMinDuration;
            n = this.ExperimentOptions.NumberOfRepetitions;
            conditionVars(i).values = (a:((b-a)/(n-1)):b);
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
                    msg = ['new trial [' num2str(variables.TargetLocation(1)) ',' num2str(variables.TargetLocation(2)) ']'];
                    this.eyeTracker.RecordEvent( msg );
                    disp(msg);
                end
                
                graph = this.Graph;
                        
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
                
                lastFlipTime        = GetSecs;
                
                fixDuration = (variables.InitialFixationDuration)/1000;
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
                        xdeg = variables.TargetLocation(1);
                        ydeg = variables.TargetLocation(2);
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