classdef EyeTrackingOtosuite  < ArumeCore.EyeTracking
    
    properties
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods (Access=protected)
        function dlg = GetOptionsDialog( this, importing )
            
            if ( exist('importing','var') && importing )
                dlg.RawDataFile = { {['uigetfile(''' fullfile(pwd,'*.txt') ''',''MultiSelect'', ''on'')']} };
                dlg.SpvDataFile = { {['uigetfile(''' fullfile(pwd,'*.txt') ''',''MultiSelect'', ''on'')']} };
                dlg.Test = '';
            end
        end
        
        function initBeforeRunning( this )            
        end
        
        function cleanAfterRunning(this)
        end
        
        function variables = TrialStartCallback(this, variables)
        end
        function variables = TrialStopCallBack(this, variables)
        end
            
    end
        
    % --------------------------------------------------------------------
    % Analysis methods --------------------------------------------------
    % --------------------------------------------------------------------
    methods ( Access = public )    
        %% ImportSession
        function ImportSession( this )
            
            
            % FOR SAI do not delete
            newRun = ArumeCore.ExperimentRun.SetUpNewRun( this );
            vars = newRun.futureTrialTable;
            vars.TrialResult = categorical(cellstr('CORRECT'));
            vars.TrialNumber = 1;
            newRun.AddPastTrialData(vars);
            newRun.futureTrialTable(:,:) = [];
            this.Session.importCurrentRun(newRun);
            % END FOR SAI
            
            
            % FOR SAI should have code to copy files into the session folder using this.Session.addFile
            
            dataFiles = this.ExperimentOptions.DataFiles;
            eventFiles = this.ExperimentOptions.EventFiles;
            calibrationFiles = this.ExperimentOptions.CalibrationFiles;
            if ( ~iscell(dataFiles) )
                dataFiles = {dataFiles};
            end
            if ( ~iscell(eventFiles) )
                eventFiles = {eventFiles};
            end
            if ( ~iscell(calibrationFiles) )
                calibrationFiles = {calibrationFiles};
            end
            
            for i=1:length(dataFiles)
                if (exist(dataFiles{i},'file') )
                    this.Session.addFile('vogDataFile', dataFiles{i});
                end
            end
            for i=1:length(eventFiles)
                if (exist(eventFiles{i},'file') )
                    this.Session.addFile('vogEventsFile', eventFiles{i});
                end
            end
            for i=1:length(calibrationFiles)
                if (exist(calibrationFiles{i},'file') )
                    this.Session.addFile('vogCalibrationFile', calibrationFiles{i});
                end
            end
        end
        
        function [samplesDataTable, rawData] = PrepareSamplesDataTable(this)
            samplesDataTable = table();
            rawData = table();
            
            if ( ~isprop(this.Session.currentRun, 'LinkedFiles' ) || ~isfield(this.Session.currentRun.LinkedFiles,  'vogDataFile') )
                return;
            end
            % FOR SAI load the file that you added in import using
            % Linkedfiles
            dataFile = this.Session.currentRun.LinkedFiles.vogDataFile;
            calibrationFiles = this.Session.currentRun.LinkedFiles.vogCalibrationFile;
                        
                cprintf('blue','ARUME :: PrepareSamplesDataTable::Reading data File %s ...\n',dataFile);
                calibrationFile = calibrationFiles{i};
                
                dataFilePath = fullfile(this.Session.dataPath, dataFile);
                calibrationFilePath = fullfile(this.Session.dataPath, calibrationFile);
                
                % load and preprocess data
                
                rawDataFile         = VOGAnalysis.LoadVOGdata(dataFilePath);
                calibrationTable    = VOGAnalysis.ReadCalibration(calibrationFilePath);
                calibratedData      = VOGAnalysis.CalibrateData(rawDataFile, calibrationTable);
                
                % FOR SAI create a new function that loads the data and
                % puts it in this format:
                % 
                %             calibratedData = table(t, f, fr, lx, ly, lt, rx, ry, rt, lel,rel,lell,rell, lp, rp, ...
                %                 'VariableNames',{'Time' 'FrameNumber', 'FrameNumberRaw', 'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT' 'LeftUpperLid' 'RightUpperLid'  'LeftLowerLid' 'RightLowerLid' 'LeftPupil' 'RightPupil'});
                %
                %             headData = table( rawData.AccelerometerX, rawData.AccelerometerY, rawData.AccelerometerZ, rawData.GyroX, rawData.GyroY, rawData.GyroZ, ...
                %                 'VariableNames', {'HeadRoll', 'HeadPitch', 'HeadYaw', 'HeadRollVel', 'HeadPitchVel', 'HeadYawVel'});
                %
                %             calibratedData = [calibratedData headData];
                
                % FOR SAI do not change this creates the nice cleaned data
                params              = VOGAnalysis.GetParameters();
                samplesDataTable  = VOGAnalysis.ResampleAndCleanData(calibratedData,params);
                       
        end
        
        function optionsDlg = GetAnalysisOptionsDialog(this)
            optionsDlg = GetAnalysisOptionsDialog@ArumeExperimentDesigns.EyeTracking(this);
            
            % add options for analysis
        end
        
        function [analysisResults, samplesDataTable, trialDataTable, sessionTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable, sessionTable, options)
            % fill in with new analysis for otosuite data
        end
    end
            
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function Plot_Example(this)
        end
    end
    
end



