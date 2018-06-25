classdef ReboundCalibration < ArumeCore.ExperimentDesign
    
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
            
            dlg.TargetSize  = 0.3;
            dlg.Duration    = 15;
            
            dlg.MaxEccentricity = 40;
            dlg.StepSize        = 10;
            dlg.FlashingPeriodMs = 750;
            dlg.FlashingOnDurationFrames = 1;
            
            dlg.ScreenWidth = 100;
            dlg.ScreenHeight = 100;
            dlg.ScreenDistance =100;
            
            dlg.BackgroundBrightness = 0;
        end
        
        function initExperimentDesign( this  )
            this.HitKeyBeforeTrial = 0;
            this.BackgroundColor = this.ExperimentOptions.BackgroundBrightness;
            
            this.trialDuration = this.ExperimentOptions.Duration; %seconds
            
            % default parameters of any experiment
            this.trialSequence = 'Random';	% Sequential, Random, Random with repetition, ...
            
            this.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            this.trialsPerSession = (this.NumberOfConditions+1);
            
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
            conditionVars(i).name   = 'Position';
            conditionVars(i).values = [-this.ExperimentOptions.MaxEccentricity:this.ExperimentOptions.StepSize:this.ExperimentOptions.MaxEccentricity];
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
                    this.eyeTracker.RecordEvent(['new trial [' num2str(variables.Position) ']'] );
                end
                
                graph = this.Graph;
                
                trialResult = Enum.trialResult.CORRECT;
                
                % flashing control variables
                flashingTimer  = 100000;
                flashCounter = 0;
                
                %-- add here the trial code
                
                totalDuration = this.ExperimentOptions.Duration;
                lastFlipTime        = GetSecs;
                secondsRemaining    = totalDuration;
                startLoopTime = lastFlipTime;
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - startLoopTime;
                    secondsRemaining    = totalDuration - secondsElapsed;
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    if (secondsElapsed < 2 )
                        xdeg = 0;
                        ydeg = 0;
                        flashing = 0;
                    elseif ( secondsElapsed > 2 && secondsElapsed < 5)
                        xdeg = variables.Position;
                        ydeg = 0;
                        flashing = 0;
                    elseif ( secondsElapsed > 5)
                        xdeg = variables.Position;
                        ydeg = 0;
                        flashing = 1;
                    end
                    
                    
                    tempFlashingTimer = mod(secondsElapsed*1000,this.ExperimentOptions.FlashingPeriodMs);
                    if ( tempFlashingTimer < flashingTimer )
                        flashCounter = 0;
                    end
                    flashingTimer = tempFlashingTimer;
                    if ( flashCounter < this.ExperimentOptions.FlashingOnDurationFrames || (flashing == 0))
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
            
            
            eventFiles = this.Session.currentRun.LinkedFiles.vogEventsFile;
            if (~iscell(eventFiles) )
                eventFiles = {eventFiles};
            end
            
            if (strcmp(eventFiles{1}, 'ReboundVariCenter_NGA-2018May22-154031-events.txt'))
                eventFiles = {'ReboundVariCenter_NGA-2018May22-152034-events.txt' eventFiles{:}};
            end
            if (strcmp(eventFiles{1}, 'ReboundVariCenter_KCA-2018May22-134440-events.txt'))
                eventFiles{end+1} = 'ReboundVariCenter_KCA-2018May22-144011-events.txt';
            end

            events1 = [];
            for i=1:length(eventFiles)
                eventFile = eventFiles{i};
                disp(eventFile);
                eventFilesPath = fullfile(this.Session.dataRawPath, eventFile);
                text = fileread(eventFilesPath);
                matches = regexp(text,'[^\n]*new trial[^\n]*','match')';
                eventsFromFile = struct2table(cell2mat(regexp(matches,'Time=(?<DateTime>[^\s]*) FrameNumber=(?<FrameNumber>[^\s]*)','names')));
                eventsFromFile.FrameNumber = str2double(eventsFromFile.FrameNumber);
                eventsFromFile = [eventsFromFile table(string(repmat(eventFile,height(eventsFromFile),1)),repmat(i,height(eventsFromFile),1),'variablenames',{'File' 'FileNumber'})];
                if ( isempty(events1) )
                    events1 = eventsFromFile;
                else
                    events1 = cat(1,events1,eventsFromFile);
                end
            end
            
            trialDataSet = [dataset2table(trialDataSet) events1];  trialData = trialDataSet(trialDataSet.TrialResult==0,:);
            data = this.Session.samplesDataSet;
            
            dataFiles = this.Session.currentRun.LinkedFiles.vogDataFile;
                        
            if (~iscell(dataFiles) )
                dataFiles = {dataFiles};
            end
            allRawData = {};
            for i=1:length(dataFiles)
                dataFile = dataFiles{i}                
                dataFilePath = fullfile(this.Session.dataRawPath, dataFile);
                
                % load data
                rawData = dataset2table(VOG.LoadVOGdataset(dataFilePath));
                
                allRawData{i} = rawData;
            end
            
            
            for i=1:height(trialData)
                trialData.trialStartSample(i) =  bins(data.Time', (allRawData{1}.LeftSeconds(find(allRawData{1}.LeftFrameNumberRaw==trialData.FrameNumber(i)))-allRawData{1}.LeftSeconds(1))');
                trialData.StartEccentricityCont(i) = bins(data.Time', 2+(allRawData{1}.LeftSeconds(find(allRawData{1}.LeftFrameNumberRaw==trialData.FrameNumber(i)))-allRawData{1}.LeftSeconds(1))');
                trialData.StartEccentricity(i) = bins(data.Time', 5+(allRawData{1}.LeftSeconds(find(allRawData{1}.LeftFrameNumberRaw==trialData.FrameNumber(i)))-allRawData{1}.LeftSeconds(1))');
                trialData.EndEccentricity(i) = bins(data.Time', 15+(allRawData{1}.LeftSeconds(find(allRawData{1}.LeftFrameNumberRaw==trialData.FrameNumber(i)))-allRawData{1}.LeftSeconds(1))');
            end
            
            for i=1:height(trialData)
                idx1 = trialData.trialStartSample(i):trialData.StartEccentricityCont(i);
                idx2 = trialData.StartEccentricityCont(i):trialData.StartEccentricity(i);
                idx3 = trialData.StartEccentricity(i):trialData.EndEccentricity(i);
               
                idxBegEcc = idx3(1:5*500);
                trialData.SPVBegEcc(i) = nanmedian([data.LeftSPVX(idxBegEcc);data.RightSPVX(idxBegEcc)]);
            end
            
            trialDataSet = trialData;
        end
        
        function samplesDataSet = PrepareSamplesDataSet(this, trialDataSet, dataFile, calibrationFile)
            samplesDataSet = [];
            dataFiles = this.Session.currentRun.LinkedFiles.vogDataFile;
            calibrationFiles = this.Session.currentRun.LinkedFiles.vogCalibrationFile;

            
            if (~iscell(dataFiles) )
                dataFiles = {dataFiles};
                calibrationFiles = {calibrationFiles};
            end
            
            for i=1:length(dataFiles)
                dataFile = dataFiles{i};
                disp(dataFile); 
                calibrationFile = calibrationFiles{i};
             
                dataFilePath = fullfile(this.Session.dataRawPath, dataFile);
                calibrationFilePath = fullfile(this.Session.dataRawPath, calibrationFile);
                
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
            
            VOG.PlotQuickPhaseDebug(data)
        end
        
        function plotResults = Plot_Saccades(this)
            data = this.Session.samplesDataSet;
            VOG.PlotQuickPhaseDebug(data)
        end
        
        
         function plotResults = PlotAggregate_SPVAvg(this, sessions)
             
             figure
             hold
             g1 = table();
             g2 = table();
             for i=1:length(sessions)
                 
                 data = sessions(i).samplesDataSet;
                 trialData = sessions(i).trialDataSet;
                 
                 g11 = grpstats(trialData,{'Position'},{'mean'},'DataVars',{'SPVBegEcc'});
                 g11.Properties.RowNames = {};
                 g1 = [g1;[g11 table(repmat(i,height(g11),1))]];
                 
                 
                 plot(g11.Position,g11.mean_SPVBegEcc,'k-o')
             end
             
             d = grpstats(g1,{'Position'},{'mean' 'sem'},'DataVars',{'mean_SPVBegEcc'});
%              d2 = grpstats(g2,{'CenterLocation', 'Side'},{'mean' 'sem'},'DataVars',{'SPVBegEcc', 'SPVEndEcc'});
             
             
             
             figure
             errorbar(d.Position,d.mean_mean_SPVBegEcc,d.sem_mean_SPVBegEcc,'ko')
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