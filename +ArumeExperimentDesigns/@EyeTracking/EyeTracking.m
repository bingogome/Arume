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
            vars.TrialResult = 0;
            newRun.AddPastTrialData(vars)
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
                params = VOGAnalysis.GetParameters();
                params.timescale = 1000;
                
                rawDataFile         = VOGAnalysis.LoadVOGdata(dataFilePath);
                calibrationTable    = VOGAnalysis.ReadCalibration(calibrationFilePath);
                calibratedData      = VOGAnalysis.CalibrateData(rawDataFile, calibrationTable);
                fileSamplesDataSet  = VOGAnalysis.ResampleAndCleanData(calibratedData, params);
                                
                % add a column to indicate which file the samples came from
                fileSamplesDataSet = [table(repmat(i,height(fileSamplesDataSet),1),'variablenames',{'FileNumber'}), fileSamplesDataSet];
 
                samplesDataTable = cat(1,samplesDataTable,fileSamplesDataSet);
                rawData = cat(1,rawData,rawDataFile);
            end
        end
        
        function trialDataTable = PrepareTrialDataTable( this, trialDataTable)
            s = this.Session.samplesDataTable;
            
            if ( any(strcmp(trialDataTable.Properties.VariableNames,'EyeTrackerFrameNumberTrialStart')) )
                ft = trialDataTable.EyeTrackerFrameNumberTrialStart;
                fte = trialDataTable.EyeTrackerFrameNumberTrialStop;
            else
                ft = s.FrameNumber(1);
                fte = s.FrameNumber(end);
            end
            
            
            % Find the samples that mark the begining and ends of trials
            trialDataTable.SampleStartTrial = nan(size(trialDataTable.TrialNumber));
            s.TrialNumber = nan(size(s.FrameNumber));
            for i=1:height(trialDataTable)
                trialDataTable.SampleStartTrial(i) = bins(s.FrameNumber',ft(i));
                trialDataTable.SampleStopTrial(i) = bins(s.FrameNumber',fte(i));
                idx = trialDataTable.SampleStartTrial(i):trialDataTable.SampleStopTrial(i);
                s.TrialNumber(idx) = trialDataTable.TrialNumber(i);
            end
            
            st = grpstats(...
                s(~isnan(s.TrialNumber),:), ...     % Selected rows of data
                'TrialNumber', ...                  % GROUP VARIABLE
                {'median' 'mean' 'std'}, ...        % Stats to calculate
                'DataVars', {'TrialNumber', 'LeftX' 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'}); 
            st.Properties.VariableNames{'GroupCount'} = 'count_GoodSamples';
            st.TrialNumber = [];
            
            trialDataTable = [trialDataTable st];
        end
        
        function [eventDataTables, samplesDataTable, trialDataTable]  = PrepareEventDataTables(this, eventDataTables, samplesDataTable, trialDataTable)
            params = VOGAnalysis.GetParameters();
            
            samplesDataTable = VOGAnalysis.DetectQuickPhases(samplesDataTable, params);
            samplesDataTable = VOGAnalysis.DetectSlowPhases(samplesDataTable, params);
            [qp, sp] = VOGAnalysis.GetQuickAndSlowPhaseTable(samplesDataTable);
            eventDataTables.QuickPhases = qp;
            eventDataTables.SlowPhases = sp;
            
        end
    end
            
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function plotResults = Plot_VOG_RawData(this)
            data = this.Session.rawDataTable;
        
            
            MEDIUM_BLUE =  [0.1000 0.5000 0.8000];
            MEDIUM_RED = [0.9000 0.2000 0.2000];
            
            figure
            timeL = data.LeftSeconds;
            timeR = data.RightSeconds;
            
            subplot(3,1,1,'nextplot','add')
            plot(timeL, data.LeftX, 'color', [ MEDIUM_BLUE ])
            plot(timeR, data.RightX, 'color', [ MEDIUM_RED])
            set(gca,'ylim',[-50 50])
            ylabel('Horizontal (deg)','fontsize', 16);
            
            subplot(3,1,2,'nextplot','add')
            plot(timeL, data.LeftY, 'color', [ MEDIUM_BLUE ])
            plot(timeR, data.RightY, 'color', [ MEDIUM_RED])
            set(gca,'ylim',[-50 50])
            ylabel('Vertical (deg)','fontsize', 16);
            
            subplot(3,1,3,'nextplot','add')
            plot(timeL, data.LeftTorsion, 'color', [ MEDIUM_BLUE ])
            plot(timeR, data.RightTorsion, 'color', [ MEDIUM_RED])
            set(gca,'ylim',[-50 50])
            ylabel('Torsion (deg)','fontsize', 16);
            xlabel('Time (s)');
        end
        
        function plotResults = Plot_VOG_Traces(this)
            
            data = this.Session.samplesDataTable;
        
            
            MEDIUM_BLUE =  [0.1000 0.5000 0.8000];
            MEDIUM_RED = [0.9000 0.2000 0.2000];
            
            figure
            time = (1:length(data.RightT))/500;
            
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
        
        function plotResults = Plot_VOG_Saccades(this)
            data = this.Session.samplesDataTable;
            VOG.PlotQuickPhaseDebug(data)
        end
        
        function plotResults = Plot_VOG_SPV(this)
               
            data = this.Session.samplesDataSet;
            trialData = this.Session.trialDataSet;
           
            
            g1 = grpstats(trialData,{'CenterLocation', 'Side'},{'mean'},'DataVars',{'SPVBaseline', 'SPVBegRebound'});
            g2 = grpstats(trialData,{'Side'},{'mean'},'DataVars',{'SPVBegEcc', 'SPVEndEcc'});
            
            figure
            plot(-g1.CenterLocation(g1.Side=='Left'),g1.mean_SPVBegRebound(g1.Side=='Left'),'-o')
            hold
            plot(g1.CenterLocation(g1.Side=='Right'),g1.mean_SPVBegRebound(g1.Side=='Right'),'-o')
            
            plot(-40,g2.mean_SPVBegEcc(g2.Side=='Left'),'-o')
            plot(40,g2.mean_SPVBegEcc(g2.Side=='Right'),'-o')
            plot(-40,g2.mean_SPVEndEcc(g2.Side=='Left'),'-o')
            plot(40,g2.mean_SPVEndEcc(g2.Side=='Right'),'-o')
            a=1;
        end
        
        function plotResults = PlotAggregate_VOG_SPVAvg(this, sessions)
            
            reboundSessions = [];
            calibrationSessions = [];
            for i=1:length(sessions)
                if ( strcmp(sessions(i).experiment.Name, 'ReboundCalibration'))
                    if ( isempty(calibrationSessions) )
                        calibrationSessions = sessions(i);
                    else
                        calibrationSessions(end+1) = sessions(i);
                    end
                end
                if ( strcmp(sessions(i).experiment.Name, 'ReboundVariCenter'))
                    if ( isempty(reboundSessions) )
                        reboundSessions = sessions(i);
                    else
                        reboundSessions(end+1) = sessions(i);
                    end
                end
            end
             
             figure
             hold
             g1 = table();
             g2 = table();
             for i=1:length(reboundSessions)
                 trialData = reboundSessions(i).trialDataSet;
                 
                 g11 = grpstats(trialData,{'CenterLocation', 'Side'},{'mean'},'DataVars',{'SPVBaseline', 'SPVBegRebound'});
                 g11.Properties.RowNames = {};
                 g1 = [g1;[g11 table(repmat(i,height(g11),1))]];
                 
                 g22 = grpstats(trialData,{'Side'},{'mean'},'DataVars',{'SPVBegEcc', 'SPVEndEcc'});
                 g22.Properties.RowNames = {};
                 g2 = [g2;[g22 table(repmat(i,height(g22),1))]];
                 
                 plot(-g11.CenterLocation(g11.Side=='Left'),g11.mean_SPVBegRebound(g11.Side=='Left'),'r-o')
                 plot(g11.CenterLocation(g11.Side=='Right'),g11.mean_SPVBegRebound(g11.Side=='Right'),'b-o')
             end
             
             d = grpstats(g1,{'CenterLocation', 'Side'},{'mean' 'sem'},'DataVars',{'mean_SPVBaseline', 'mean_SPVBegRebound'});
             d2 = grpstats(g2,{'Side'},{'mean' 'sem'},'DataVars',{'mean_SPVBegEcc', 'mean_SPVEndEcc'});
             
             
             g1 = table();
             g2 = table();
             for i=1:length(calibrationSessions)
                 
                 data = calibrationSessions(i).samplesDataSet;
                 trialData = calibrationSessions(i).trialDataSet;
                 
                 g11 = grpstats(trialData,{'Position'},{'mean'},'DataVars',{'SPVBegEcc'});
                 g11.Properties.RowNames = {};
                 g1 = [g1;[g11 table(repmat(i,height(g11),1))]];
                 
                 
                 plot(g11.Position,g11.mean_SPVBegEcc,'k-o')
             end
             
             dcali = grpstats(g1,{'Position'},{'mean' 'sem'},'DataVars',{'mean_SPVBegEcc'});
             
             
             
             
             figure
             h1=errorbar(-d.CenterLocation(d.Side=='Left'),d.mean_mean_SPVBegRebound(d.Side=='Left'),d.sem_mean_SPVBegRebound(d.Side=='Left'),'-o','linewidth',2)
             hold
             h2=errorbar(d.CenterLocation(d.Side=='Right'),d.mean_mean_SPVBegRebound(d.Side=='Right'),d.sem_mean_SPVBegRebound(d.Side=='Right'),'-o','linewidth',2)
             
             
             h3=errorbar([-40 40],d2.mean_mean_SPVBegEcc,d2.sem_mean_SPVBegEcc,'ko','linewidth',2)
             h4= errorbar(dcali.Position,dcali.mean_mean_SPVBegEcc,dcali.sem_mean_SPVBegEcc,'k-o')
%              errorbar([-40 40],d2.mean_mean_SPVEndEcc,d2.mean_mean_SPVEndEcc,'o','color',[0.5 .5 .5],'linewidth',2)
             set(gca,'xlim',[-42 42])
%              legend({'Rebound after left','Rebound after right','Initial gaze evoked','Final gaze evoked'});
             xlabel('Position (deg)');
             ylabel('Slow phase velocity (deg/s)');
             line([-40 40],[0 0],'linestyle','--');
             line([0 0],[-2 2],'linestyle','--');
%              errorbar(40,d2.mean_mean_SPVBegEcc(d2.Side=='Right'),d2.sem_mean_SPVBegEcc(d2.Side=='Right'),'-o')
%              errorbar(-40,d2.mean_mean_SPVEndEcc(d2.Side=='Left'),d2.sem_mean_SPVEndEcc(d2.Side=='Left'),'-o')
%              errorbar(40,d2.mean_mean_SPVEndEcc(d2.Side=='Right'),d2.sem_mean_SPVEndEcc(d2.Side=='Right'),'-o')
             
%              arrow([40 d2.mean_mean_SPVBegEcc(d2.Side=='Left')], [40 d2.mean_mean_SPVEndEcc(d2.Side=='Left')])

             legend([h1 h2 h3 h4],{'Rebound after left','Rebound after right','Gaze evoked (rebound exp)', 'Gae evoked (calib.)'});
        end
    end
    
end



