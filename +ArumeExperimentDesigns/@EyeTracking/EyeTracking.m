classdef EyeTracking  < ArumeCore.ExperimentDesign
    
    properties
        eyeTracker
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods (Access=protected)
        function dlg = GetOptionsDialog( this, importing )
            dlg.UseEyeTracker = { {'0' '{1}'} };
            dlg.Debug = { {'{0}','1'} };
            
            dlg.ScreenWidth = { 40 '* (cm)' [1 3000] };
            dlg.ScreenHeight = { 30 '* (cm)' [1 3000] };
            dlg.ScreenDistance = { 135 '* (cm)' [1 3000] };
            
            if ( exist('importing','var') && importing )
                dlg.DataFiles = { {['uigetfile(''' fullfile(pwd,'*.txt') ''',''MultiSelect'', ''on'')']} };
                dlg.EventFiles = { {['uigetfile(''' fullfile(pwd,'*.txt') ''',''MultiSelect'', ''on'')']} };
                dlg.CalibrationFiles = { {['uigetfile(''' fullfile(pwd,'*.cal') ''',''MultiSelect'', ''on'')']} };
            end
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            % This is necessary for basic imported sessions of eye movement
            % recordings
            
            i = i+1;
            conditionVars(i).name   = 'Recording';
            conditionVars(i).values = 1;
        end
        
        function initBeforeRunning( this )            
            if ( this.ExperimentOptions.UseEyeTracker )
                this.eyeTracker = ArumeHardware.VOG();
                this.eyeTracker.Connect();
                this.eyeTracker.SetSessionName(this.Session.name);
                this.eyeTracker.StartRecording();
                this.AddTrialStartCallback(@this.TrialStartCallback)
                this.AddTrialStopCallback(@this.TrialStopCallBack)
            end
        end
        
        function cleanAfterRunning(this)
            
            if ( this.ExperimentOptions.UseEyeTracker )
                this.eyeTracker.StopRecording();
        
                disp('Downloading eye tracking files...');
                files = this.eyeTracker.DownloadFile();

                if (~isempty( files) )
                    disp(files{1});
                    disp(files{2});
                    if (length(files) > 2 )
                        disp(files{3});
                    end
                    disp('Finished downloading');

                    this.Session.addFile('vogDataFile', files{1});
                    this.Session.addFile('vogCalibrationFile', files{2});
                    if (length(files) > 2 )
                        this.Session.addFile('vogEventsFile', files{3});
                    end
                else
                disp('No eye tracking files downloaded!');
                end
            end
        end
        
        function variables = TrialStartCallback(this, variables)
            variables.EyeTrackerFrameNumberTrialStart = this.eyeTracker.RecordEvent(sprintf('TRIAL_START %d %d', variables.TrialNumber, variables.Condition) );
        end
        function variables = TrialStopCallBack(this, variables)
            variables.EyeTrackerFrameNumberTrialStop = this.eyeTracker.RecordEvent(sprintf('TRIAL_STOP %d %d', variables.TrialNumber, variables.Condition) );
        end
            
    end
        
    % --------------------------------------------------------------------
    % Analysis methods --------------------------------------------------
    % --------------------------------------------------------------------
    methods ( Access = public )    
        %% ImportSession
        function ImportSession( this )
            newRun = ArumeCore.ExperimentRun.SetUpNewRun( this );
            vars = newRun.futureTrialTable;
            vars.TrialResult = categorical(cellstr('CORRECT'));
            vars.TrialNumber = 1;
            newRun.AddPastTrialData(vars);
            newRun.futureTrialTable(:,:) = [];
            this.Session.importCurrentRun(newRun);
            
            
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
            
            dataFiles = this.Session.currentRun.LinkedFiles.vogDataFile;
            calibrationFiles = this.Session.currentRun.LinkedFiles.vogCalibrationFile;
                        
            if (~iscell(dataFiles) )
                dataFiles = {dataFiles};
            end
            
            if (~iscell(calibrationFiles) )
                calibrationFiles = {calibrationFiles};
            end
            
            if (length(calibrationFiles) == 1)
                calibrationFiles = repmat(calibrationFiles,size(dataFiles));
            elseif length(calibrationFiles) ~= length(dataFiles)
                error('ERROR preparing sample data set: The session should have the same number of calibration files as data files or 1 calibration file');
            end
            
            for i=1:length(dataFiles)
                dataFile = dataFiles{i};
                cprintf('blue','Reading data File %s\n',dataFile);
                calibrationFile = calibrationFiles{i};
                
                dataFilePath = fullfile(this.Session.dataPath, dataFile);
                calibrationFilePath = fullfile(this.Session.dataPath, calibrationFile);
                
                % load and preprocess data
                
                rawDataFile         = VOGAnalysis.LoadVOGdata(dataFilePath);
                calibrationTable    = VOGAnalysis.ReadCalibration(calibrationFilePath);
                calibratedData      = VOGAnalysis.CalibrateData(rawDataFile, calibrationTable);
                params              = VOGAnalysis.GetParameters();
                fileSamplesDataSet  = VOGAnalysis.ResampleAndCleanData(calibratedData,params);
                                
                % add a column to indicate which file the samples came from
                fileSamplesDataSet = [table(repmat(i,height(fileSamplesDataSet),1),'variablenames',{'FileNumber'}), fileSamplesDataSet];
 
                samplesDataTable = cat(1,samplesDataTable,fileSamplesDataSet);
                % TODO: maybe fix timestamps while concatenating so they
                % keep growing?
                rawData = cat(1,rawData,rawDataFile);
            end
        end
        
        function trialDataTable = PrepareTrialDataTable( this, trialDataTable)
            s = this.Session.samplesDataTable;
            
            if ( ~isempty( s) )
                if ( any(strcmp(trialDataTable.Properties.VariableNames,'EyeTrackerFrameNumberTrialStart')) )
                    ft = trialDataTable.EyeTrackerFrameNumberTrialStart;
                    fte = trialDataTable.EyeTrackerFrameNumberTrialStop;
                else
                    if ( any(ismember(s.Properties.VariableNames,'FrameNumber')) )
                        ft = s.FrameNumber(1);
                        fte = s.FrameNumber(end);
                    end
                end
                
                if ( exist( 'ft' , 'var') )
                    % BIG TODO:!!!!  Match timestamps with samples of the
                    % corresponding file. careful with this!
                    
                    % Find the samples that mark the begining and ends of trials
                    trialDataTable.SampleStartTrial = nan(size(trialDataTable.TrialNumber));
                    s.TrialNumber = nan(size(s.FrameNumber));
                    for i=1:height(trialDataTable)
                        trialDataTable.SampleStartTrial(i) = bins(s.FrameNumber',ft(i));
                        trialDataTable.SampleStopTrial(i) = bins(s.FrameNumber',fte(i));
                        idx = trialDataTable.SampleStartTrial(i):trialDataTable.SampleStopTrial(i);
                        s.TrialNumber(idx) = trialDataTable.TrialNumber(i);
                    end
                    
                    LRdataVars = {'X' 'Y' 'T'};
                    
                    for i=1:length(LRdataVars)
                        s.(LRdataVars{i}) = mean([s.(['Left' LRdataVars{i}]),s.(['Right' LRdataVars{i}])],2);
                    end
                    dataVars = { 'X' 'Y' 'T' 'LeftX' 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'};
                    
                    st = grpstats(...
                        s(~isnan(s.TrialNumber),:), ...     % Selected rows of data
                        'TrialNumber', ...                  % GROUP VARIABLE
                        {'median' 'mean' 'std'}, ...        % Stats to calculate
                        'DataVars', dataVars );             % Vars to do stats on
                    st.Properties.VariableNames{'GroupCount'} = 'count_GoodSamples';
                    st.TrialNumber = [];
                                        
                    if ( height(trialDataTable) == height(st))
                        trialDataTable = [trialDataTable st];
                    end
                end
            end
        end
        
        function optionsDlg = GetAnalysisOptionsDialog(this)
            optionsDlg.Detect_Quik_and_Slow_Phases =  { {'{0}','1'} };
        end
        
        function [analysisResults, samplesDataTable, trialDataTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable, options)
            analysisResults = [];
            params = VOGAnalysis.GetParameters();
            
            if ( options.Detect_Quik_and_Slow_Phases )
                samplesDataTable = VOGAnalysis.DetectQuickPhases(samplesDataTable, params);
                samplesDataTable = VOGAnalysis.DetectSlowPhases(samplesDataTable, params);
                [qp, sp] = VOGAnalysis.GetQuickAndSlowPhaseTable(samplesDataTable);
                
                analysisResults.QuickPhases = qp;
                analysisResults.SlowPhases = sp;
            end
            
        end
    end
            
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function Plot_VOG_RawData(this)
            data = this.Session.rawDataTable;
            
            VOGAnalysis.PlotRawTraces(data);
        end
        
        function Plot_VOG_Traces(this)
            
            data = this.Session.samplesDataTable;
        
            VOGAnalysis.PlotTraces(data);
            
        end
        
        function Plot_VOG_DebugCleaning(this)
            
            rawdata = this.Session.rawDataTable;
            data = this.Session.samplesDataTable;
            
            VOGAnalysis.PlotCleanAndResampledData(rawdata,data);
        end
        
        function Plot_VOG_SaccadeTraces(this)
            data = this.Session.samplesDataTable;
            VOGAnalysis.PlotQuickPhaseDebug(data)
        end
        
        function Plot_VOG_MainSequence(this)
            
            props = this.Session.analysisResults.QuickPhases;
            VOGAnalysis.PlotMainsequence(props);
             
        end
    end
    
end



