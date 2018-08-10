classdef ReboundVariCenter < ArumeCore.ExperimentDesign & ArumeExperimentDesigns.EyeTracking
    
    properties
        fixRad = 20;
        fixColor = [255 0 0];
    end
    
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this);
            
            dlg.TargetSize = 0.3;
            dlg.InitialFixaitonDuration = 10;
            dlg.EccentricDuration       = 30;
            dlg.CenterDuration          = 20;
            
            dlg.EccentricPosition = 40;
            dlg.EccentricFlashing = {{'{Yes}' 'No'}};
            dlg.FlashingPeriodMs = 750;
            dlg.FlashingOnDurationFrames = 1;
            
            dlg.NumberOfRepetitions = 5;
            
            dlg.CenterLocationRange = {{'{Minus20to30}' 'Minus40to40'}};
            dlg.InterleaveCalibration = {{'{No}' 'Yes'}};
            
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
            this.blockSequence = 'Sequential';	% Sequential, Random, ...
            
            if (strcmp(this.ExperimentOptions.InterleaveCalibration , 'Yes') )
                this.trialsPerSession = (this.NumberOfConditions+1)*this.ExperimentOptions.NumberOfRepetitions;
                this.blocksToRun = 7;
                this.blocks = [ ...
                    struct( 'fromCondition', 1,     'toCondition', 18, 'trialsToRun', 18 )...
                    struct( 'fromCondition', 1,     'toCondition', 18, 'trialsToRun', 18 )...
                    struct( 'fromCondition', 19,    'toCondition', 36, 'trialsToRun', 18 )...
                    struct( 'fromCondition', 1,     'toCondition', 18, 'trialsToRun', 18 )...
                    struct( 'fromCondition', 1,     'toCondition', 18, 'trialsToRun', 18 )...
                    struct( 'fromCondition', 19,    'toCondition', 36, 'trialsToRun', 18 )...
                    struct( 'fromCondition', 1,     'toCondition', 18, 'trialsToRun', 18 )];
            else
                this.trialsPerSession = (this.NumberOfConditions+1)*this.ExperimentOptions.NumberOfRepetitions;
                this.numberOfTimesRepeatBlockSequence = this.ExperimentOptions.NumberOfRepetitions;
                this.blocksToRun = 1;
                this.blocks = [ ...
                    struct( 'fromCondition', 1, 'toCondition', this.NumberOfConditions, 'trialsToRun', this.NumberOfConditions  )];
            end
            
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            if (strcmp(this.ExperimentOptions.CenterLocationRange , 'Minus20to30') )
                i = i+1;
                conditionVars(i).name   = 'CenterLocation';
                conditionVars(i).values = [-20:10:30];
            elseif (strcmp(this.ExperimentOptions.CenterLocationRange , 'Minus40to40') )
                i = i+1;
                conditionVars(i).name   = 'CenterLocation';
                conditionVars(i).values = [-40:10:40];
            end
            
            i = i+1;
            conditionVars(i).name   = 'Side';
            conditionVars(i).values = {'Left' 'Right'};
            
            if (strcmp(this.ExperimentOptions.InterleaveCalibration , 'Yes') )
                i = i+1;
                conditionVars(i).name   = 'TypeOfTrial';
                conditionVars(i).values = {'Rebound' 'Calibration'};
            end
        end
        
        function initBeforeRunning( this )
            initBeforeRunning@ArumeExperimentDesigns.EyeTracking(this);
        end
        
        function cleanAfterRunning(this)
            cleanAfterRunning@ArumeExperimentDesigns.EyeTracking(this);
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
                
                if (strcmp(variables.TypeOfTrial , 'Rebound') )
                    totalDuration = this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.EccentricDuration + this.ExperimentOptions.CenterDuration;
                else
                    totalDuration = this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.CenterDuration;
                end
                lastFlipTime        = GetSecs;
                secondsRemaining    = totalDuration;
                startLoopTime = lastFlipTime;
                
                    sound1 = 0;
                    sound2 = 0;
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - startLoopTime;
                    secondsRemaining    = totalDuration - secondsElapsed;
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    initialFixationPeriod = secondsElapsed < this.ExperimentOptions.InitialFixaitonDuration;
                    if ( strcmp(variables.TypeOfTrial , 'Rebound') )
                        eccentricFixationPeriod = secondsElapsed >= this.ExperimentOptions.InitialFixaitonDuration && secondsElapsed < (this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.EccentricDuration);
                        variCenterFixationPeriod = secondsElapsed >= (this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.EccentricDuration);
                    else
                        eccentricFixationPeriod = 0;
                        variCenterFixationPeriod = secondsElapsed >= this.ExperimentOptions.InitialFixaitonDuration;
                    end
                                        
                    if ( initialFixationPeriod )
                        xdeg = 0;
                        ydeg = 0;
                    elseif ( eccentricFixationPeriod )
                        
                        if (sound1==0) 
                            sound(sin( (1:round(0.1*8192))  *  (2*pi*500/8192)   ), 8192);
                            sound1=1;
                        end
                        
                        switch(variables.Side)
                            case 'Left'
                                xdeg = -this.ExperimentOptions.EccentricPosition;
                            case 'Right'
                                xdeg = this.ExperimentOptions.EccentricPosition;
                        end
                        
                        ydeg = 0;
                    elseif ( variCenterFixationPeriod )
                        
                        if (sound2==0) 
                            sound(sin( (1:round(0.1*8192))  *  (2*pi*500/8192)   ), 8192);
                            sound2=1;
                        end
                        
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
            
            trialDataSet = [dataset2table(trialDataSet) events1];
            
            trialData = trialDataSet(trialDataSet.TrialResult==0,:);
            data = this.Session.samplesDataSet;
            trialData.Side = categorical(trialData.Side);
            
            dataFiles = this.Session.currentRun.LinkedFiles.vogDataFile;
                        
            if (~iscell(dataFiles) )
                dataFiles = {dataFiles};
            end
            
            if (strcmp(dataFiles{1}, 'ReboundVariCenter_NGA-2018May22-154031.txt'))
                dataFiles = {'ReboundVariCenter_NGA-2018May22-152034.txt' dataFiles{:}};
            end
            if (strcmp(dataFiles{1}, 'ReboundVariCenter_KCA-2018May22-134440.txt'))
                dataFiles{end+1} = 'ReboundVariCenter_KCA-2018May22-144011.txt';
            end
            
            allRawData = {};
            for i=1:length(dataFiles)
                dataFile = dataFiles{i}                
                dataFilePath = fullfile(this.Session.dataRawPath, dataFile);
                
                % load data
                rawData = dataset2table(VOG.LoadVOGdataset(dataFilePath));
                
                allRawData{i} = rawData;
            end
            
            d = this.ExperimentOptions.EccentricDuration;
            
            for i=1:height(trialData)
                fileNumber = trialData.FileNumber(i);
                idxInFile = find(data.FileNumber==fileNumber);
                if ( isempty(idxInFile) )
                    continue;
                end
                b = bins(data.Time(idxInFile)', (allRawData{fileNumber}.LeftSeconds(find(allRawData{fileNumber}.LeftFrameNumberRaw==trialData.FrameNumber(i)))-allRawData{fileNumber}.LeftSeconds(1))');
                if ( isempty(b))
                    continue;
                end
                trialData.trialStartSample(i) =  idxInFile(1) + bins(data.Time(idxInFile)', (allRawData{fileNumber}.LeftSeconds(find(allRawData{fileNumber}.LeftFrameNumberRaw==trialData.FrameNumber(i)))-allRawData{fileNumber}.LeftSeconds(1))');
                trialData.StartEccentricity(i) = idxInFile(1) + bins(data.Time(idxInFile)', 11+(allRawData{fileNumber}.LeftSeconds(find(allRawData{fileNumber}.LeftFrameNumberRaw==trialData.FrameNumber(i)))-allRawData{fileNumber}.LeftSeconds(1))');
                trialData.StartRebound(i) = idxInFile(1) + bins(data.Time(idxInFile)', 11+d+(allRawData{fileNumber}.LeftSeconds(find(allRawData{fileNumber}.LeftFrameNumberRaw==trialData.FrameNumber(i)))-allRawData{fileNumber}.LeftSeconds(1))');
                trialData.EndRebound(i) = idxInFile(1) + bins(data.Time(idxInFile)', 31+d+(allRawData{fileNumber}.LeftSeconds(find(allRawData{fileNumber}.LeftFrameNumberRaw==trialData.FrameNumber(i)))-allRawData{fileNumber}.LeftSeconds(1))');
            end
            
            target = nan(size(data.LeftX));
            for i=1:height(trialData)
                if ( trialData.trialStartSample(i) == 0 )
                    trialData.SPVBaseline(i) = nan;
                    trialData.SPVBegEcc(i) = nan;
                    trialData.SPVEndEcc(i) = nan;
                    trialData.SPVBegRebound(i) = nan;
                    trialData.SPVEndRebound(i) = nan;
                    continue;
                end
                idx1 = trialData.trialStartSample(i):trialData.StartEccentricity(i);
                idx2 = trialData.StartEccentricity(i):trialData.StartRebound(i);
                idx3 = trialData.StartRebound(i):trialData.EndRebound(i);
                
                switch(trialData.Side(i))
                    case 'Left'
                        ecc = -40;
                        cen = -trialData.CenterLocation(i);
                    case 'Right'
                        ecc = 40;
                        cen = trialData.CenterLocation(i);
                end
                target(idx1) = 0;
                target(idx2) = ecc;
                target(idx3) = cen;
                
                if ( length(idx3)< 5*500)
                    trialData.SPVBaseline(i) = nan;
                    trialData.SPVBegEcc(i) = nan;
                    trialData.SPVEndEcc(i) = nan;
                    trialData.SPVBegRebound(i) = nan;
                    trialData.SPVEndRebound(i) = nan;
                    continue;
                end
                idxBaseline = idx1(end-6*500:end-1*500);
                idxBegEcc = idx2(1:5*500);
                idxEndEcc = idx2(end-6*500:end-1*500);
                idxBegRebound = idx3(1:5*500);
                idxEndRebound = idx3(end-6*500:end-1*500);
                trialData.SPVBaseline(i) = nanmedian([data.LeftSPVX(idxBaseline);data.RightSPVX(idxBaseline)]);
                trialData.SPVBegEcc(i) = nanmedian([data.LeftSPVX(idxBegEcc);data.RightSPVX(idxBegEcc)]);
                trialData.SPVEndEcc(i) = nanmedian([data.LeftSPVX(idxEndEcc);data.RightSPVX(idxEndEcc)]);
                trialData.SPVBegRebound(i) = nanmedian([data.LeftSPVX(idxBegRebound);data.RightSPVX(idxBegRebound)]);
                trialData.SPVEndRebound(i) = nanmedian([data.LeftSPVX(idxEndRebound);data.RightSPVX(idxEndRebound)]);
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
                dataFile = dataFiles{i}
                calibrationFile = calibrationFiles{i};
                
                dataFilePath = fullfile(this.Session.dataRawPath, dataFile);
                calibrationFilePath = fullfile(this.Session.dataRawPath, calibrationFile);
                
                % load data
                rawData = VOG.LoadVOGdataset(dataFilePath);
                
                % calibrate data
                [calibratedData leftEyeCal rightEyeCal] = VOG.CalibrateData(rawData, calibrationFilePath);
                
                [cleanedData, fileSamplesDataSet] = VOG.ResampleAndCleanData3(calibratedData, 1000);
                                
                fileSamplesDataSet = [table(repmat(i,height(fileSamplesDataSet),1),'variablenames',{'FileNumber'}), fileSamplesDataSet];

                                
                if ( isempty(samplesDataSet) )
                    samplesDataSet = fileSamplesDataSet;
                else
                    samplesDataSet = cat(1,samplesDataSet,fileSamplesDataSet);
                end
            end
        end
        
        function sessionDataTable = PrepareSessionDataTable(this, sessionDataTable)
            trialData = this.Session.trialDataSet;
            g1 = grpstats(trialData,{'CenterLocation', 'Side'},{'mean'},'DataVars',{'SPVBaseline', 'SPVBegRebound'})
        end
    end
    
    % ---------------------------------------------------------------------
    % Plot  methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
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