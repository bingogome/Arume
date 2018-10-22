classdef EyeTrackingOtosuite  < ArumeExperimentDesigns.EyeTracking
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods (Access=protected)
        function dlg = GetOptionsDialog( this, importing )
            dlg = [];
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
            
            rawFile = this.ExperimentOptions.RawDataFile;
            spvFile = this.ExperimentOptions.SpvDataFile;
            
            if (exist(rawFile,'file') )
                this.Session.addFile('vogRawDataFile', rawFile);
            end
            
            if (exist(spvFile,'file') )
                this.Session.addFile('vogSpvDataFile', spvFile);
            end
            
        end
        
        function [rawData, rawPixelData] = PrepareSamplesDataTable(this)
            rawData = table();
            rawPixelData = table();
            
            if ( ~isprop(this.Session.currentRun, 'LinkedFiles' ) || ~isfield(this.Session.currentRun.LinkedFiles,  'vogRawDataFile') )
                return;
            end
            
            % FOR SAI load the file that you added in import using Linkedfiles
            rawFile = this.Session.currentRun.LinkedFiles.vogRawDataFile;
            
            cprintf('blue','ARUME :: PreparingDataTable::Reading data File %s ...\n',rawFile);
            
            rawFilePath = fullfile(this.Session.dataPath, rawFile);
            
            % load and preprocess data         
            
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
            
            [calibratedData, rawPixelData] = LoadRawData(rawFilePath);   
                        
            % FOR SAI do not change this creates the nice cleaned data
            params   = VOGAnalysis.GetParameters();
            rawData  = VOGAnalysis.ResampleAndCleanData(calibratedData,params);
            
        end
        
        function optionsDlg = GetAnalysisOptionsDialog(this)
            optionsDlg = GetAnalysisOptionsDialog@ArumeExperimentDesigns.EyeTracking(this);
            
            % add options for analysis
        end
        
        function [analysisResults, samplesDataTable, trialDataTable, sessionTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable, sessionTable, options)
            
            [analysisResults, samplesDataTable, trialDataTable, sessionTable]  =  RunDataAnalyses@ArumeExperimentDesigns.EyeTracking(this, analysisResults, samplesDataTable, trialDataTable, sessionTable, options);
            
            % fill in with new analysis for otosuite data
        end
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function Plot_Example(this)
            a=1;
        end
    end
    
end



