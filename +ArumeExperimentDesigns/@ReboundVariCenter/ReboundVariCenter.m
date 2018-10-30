classdef ReboundVariCenter < ArumeCore.ExperimentDesign & ArumeExperimentDesigns.EyeTracking
    
    properties
        fixRad = 20;
        fixColor = [255 0 0];
    end
    
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function dlg = GetOptionsDialog( this, importing )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this);
            
            dlg.ScreenWidth = { 121 '* (cm)' [1 3000] };
            dlg.ScreenHeight = { 68 '* (cm)' [1 3000] };
            dlg.ScreenDistance = { 60 '* (cm)' [1 3000] };
            
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
                        
            dlg.BackgroundBrightness = 0;
        end
        
        function initExperimentDesign( this  )
            this.DisplayVariableSelection = {'TrialNumber' 'TrialResult' 'TypeOfTrial' 'Side' 'CenterLocation' 'TimeFlashes'};
        
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
        
        function [trialResult, thisTrialData] = runTrial( this, thisTrialData )
            
            try
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
               
                
                graph = this.Graph;
                
                trialResult = Enum.trialResult.CORRECT;
                
                % flashing control variables
                flashingTimer  = 100000;
                flashCounter = 0;
                
                %-- add here the trial code
                
                if (thisTrialData.TypeOfTrial == 'Rebound') 
                    totalDuration = this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.EccentricDuration + this.ExperimentOptions.CenterDuration;
                else
                    totalDuration = this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.CenterDuration;
                end
                
                nflashes =  ceil((this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.EccentricDuration + this.ExperimentOptions.CenterDuration)/this.ExperimentOptions.FlashingPeriodMs*1000);
                thisTrialData.TimeFlashes = nan(1,nflashes);
                
                lastFlipTime        = GetSecs;
                secondsRemaining    = totalDuration;
                thisTrialData.TimeStartLoop = lastFlipTime;
                
                if ( ~isempty(this.eyeTracker) )
                    thisTrialData.EyeTrackerFrameStartLoop = this.eyeTracker.RecordEvent(sprintf('TRIAL_START_LOOP %d %d', thisTrialData.TrialNumber, thisTrialData.Condition) );
                end
                
                
                sound1 = 0;
                sound2 = 0;
                nFlashCounter = 1;
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - thisTrialData.TimeStartLoop;
                    secondsRemaining    = totalDuration - secondsElapsed;
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    isInitialFixationPeriod = secondsElapsed < this.ExperimentOptions.InitialFixaitonDuration;
                    if ( strcmp(thisTrialData.TypeOfTrial , 'Rebound') )
                        isEccentricFixationPeriod = secondsElapsed >= this.ExperimentOptions.InitialFixaitonDuration && secondsElapsed < (this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.EccentricDuration);
                        isVariCenterFixationPeriod = secondsElapsed >= (this.ExperimentOptions.InitialFixaitonDuration + this.ExperimentOptions.EccentricDuration);
                    else
                        isEccentricFixationPeriod = 0;
                        isVariCenterFixationPeriod = secondsElapsed >= this.ExperimentOptions.InitialFixaitonDuration;
                    end
                                        
                    if ( isInitialFixationPeriod )
                        
                        thisTrialData.Xdeg = 0;
                        thisTrialData.Ydeg = 0;
                        
                    elseif ( isEccentricFixationPeriod )
                        
                        if (sound1==0) 
                            sound(sin( (1:round(0.1*8192))  *  (2*pi*500/8192)   ), 8192);
                            sound1=1;
                            if ( ~isempty(this.eyeTracker) )
                                thisTrialData.EyeTrackerFrameStartEccectric = this.eyeTracker.RecordEvent(sprintf('TRIAL_START_ECCENTRIC %d', thisTrialData.TrialNumber) );
                            end
                            thisTrialData.TimeStartEccentric = GetSecs;
                        end
                        
                        switch(thisTrialData.Side)
                            case 'Left'
                                thisTrialData.Xdeg = -this.ExperimentOptions.EccentricPosition;
                            case 'Right'
                                thisTrialData.Xdeg = this.ExperimentOptions.EccentricPosition;
                        end
                        
                        thisTrialData.Ydeg = 0;
                    
                    elseif ( isVariCenterFixationPeriod )
                        
                        if (sound2==0) 
                            sound(sin( (1:round(0.1*8192))  *  (2*pi*500/8192)   ), 8192);
                            sound2=1;
                            if ( ~isempty(this.eyeTracker) )
                                thisTrialData.EyeTrackerFrameStartVariCenter = this.eyeTracker.RecordEvent(sprintf('TRIAL_START_VARICENTER %d', thisTrialData.TrialNumber) );
                            end
                            thisTrialData.TimeStartVariCenter = GetSecs;
                        end
                        
                        switch(thisTrialData.Side)
                            case 'Left'
                                thisTrialData.Xdeg = -thisTrialData.CenterLocation;
                            case 'Right'
                                thisTrialData.Xdeg = thisTrialData.CenterLocation;
                        end
                        thisTrialData.Ydeg = 0;
                        
                    end
                    
                    
                    tempFlashingTimer = mod(secondsElapsed*1000,this.ExperimentOptions.FlashingPeriodMs);
                    if ( tempFlashingTimer < flashingTimer )
                        flashCounter = 0;
                    end
                    flashingTimer = tempFlashingTimer;
                    if ( flashCounter < this.ExperimentOptions.FlashingOnDurationFrames )
                        flashCounter = flashCounter +1;
                        disp('flash')
                        thisTrialData.TimeFlashes(nFlashCounter) = GetSecs;
                        nFlashCounter = nFlashCounter+1;
                        
                        [mx, my] = RectCenter(this.Graph.wRect);
                        xpix = mx + this.Graph.pxWidth/this.ExperimentOptions.ScreenWidth * this.ExperimentOptions.ScreenDistance * tan(thisTrialData.Xdeg/180*pi);
                        aspectRatio = 1;
                        ypix = my + this.Graph.pxHeight/this.ExperimentOptions.ScreenHeight * this.ExperimentOptions.ScreenDistance * tan(thisTrialData.Ydeg/180*pi)*aspectRatio;
                        
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
    end
    
    % --------------------------------------------------------------------
    %% Analysis methods --------------------------------------------------
    % --------------------------------------------------------------------
    methods
        
        function optionsDlg = GetAnalysisOptionsDialog(this)
            optionsDlg = GetAnalysisOptionsDialog@ArumeExperimentDesigns.EyeTracking(this);
            optionsDlg.SPV = { {'0' '{1}'} };
        end
        
        function [analysisResults, samplesDataTable, trialDataTable, sessionTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable,sessionTable, options)
            
            [analysisResults, samplesDataTable, trialDataTable, sessionTable] = RunDataAnalyses@ArumeExperimentDesigns.EyeTracking(this, analysisResults, samplesDataTable, trialDataTable,sessionTable, options);
            
            if ( options.SPV )
                analysisResults.SPV = table();
                
                T = samplesDataTable.Properties.UserData.sampleRate;
                analysisResults.SPV.Time = samplesDataTable.Time;
                fields = {'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'};
                
                t = samplesDataTable.Time;
                
                %
                % calculate monocular spv
                %
                for j =1:length(fields)
                    
                    [vmed, xmed] = VOGAnalysis.GetSPV_Simple(t, samplesDataTable.(fields{j}));
                    
                    analysisResults.SPV.(fields{j}) = vmed;
                    analysisResults.SPV.([fields{j} 'Pos']) = xmed;
                end
                
                %
                % calculate binocular spv
                %
                LRdataVars = {'X' 'Y' 'T'};
                for j =1:length(LRdataVars)
                    
                    [vleft, xleft] = VOGAnalysis.GetSPV_Simple(t, samplesDataTable.(['Left' LRdataVars{j}]));
                    [vright, xright] = VOGAnalysis.GetSPV_Simple(t, samplesDataTable.(['Right' LRdataVars{j}]));
                    
                    vmed = nanmedfilt(nanmean([vleft, vright],2),T,1/2);
                    xmed = nanmedfilt(nanmean([xleft, xright],2),T,1/2);
                    
                    analysisResults.SPV.(LRdataVars{j}) = vmed;
                    analysisResults.SPV.([LRdataVars{j} 'Pos']) = xmed;
                end
                
                
                
                trialData = this.Session.trialDataTable;
                data = this.Session.samplesDataTable;
                dataSPV = analysisResults.SPV;
                trialData.Side = categorical(trialData.Side);
                
                for i=1:height(trialData)
                    fileNumber = trialData.FileNumber(i);
                    
                    if ( trialData.TypeOfTrial(i) == 'Rebound' )
                        trialData.StartEccentricity(i) = find(data.FileNumber' == trialDataTable.FileNumber(i) & data.RawFrameNumber'== trialData.EyeTrackerFrameStartEccectric(i),1,'first');
                    else
                        trialData.StartEccentricity(i) = nan;
                    end
                    trialData.StartRebound(i) = find(data.FileNumber' == trialDataTable.FileNumber(i) & data.RawFrameNumber'== trialData.EyeTrackerFrameStartVariCenter(i),1,'first');
                    trialData.EndRebound(i) = find(data.FileNumber' == trialDataTable.FileNumber(i) & data.RawFrameNumber'== trialData.EyeTrackerFrameNumberTrialStop(i),1,'first');
                end
                
                for i=1:height(trialData)
                    if ( trialData.TypeOfTrial(i) == 'Rebound' )
                        idx1 = trialData.SampleStartTrial(i):trialData.StartEccentricity(i);
                    else
                        idx1 = trialData.SampleStartTrial(i):trialData.StartRebound(i);
                    end
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
                    
                    idxBaseline = idx1(end-6*500:end-1*500);
                    if ( trialData.TypeOfTrial(i) == 'Rebound' )
                        idxBegEcc = idx2(1:5*500);
                        idxEndEcc = idx2(end-6*500:end-1*500);
                    end
                    idxBegRebound = idx3(1:5*500);
                    idxEndRebound = idx3(end-6*500:end-1*500);
                    trialData.SPVBaseline(i) = nanmean(dataSPV.X(idxBaseline));
                    
                    if ( trialData.TypeOfTrial(i) == 'Rebound' )
                        trialData.SPVBegEcc(i) = nanmean(dataSPV.X(idxBegEcc));
                        trialData.SPVEndEcc(i) = nanmean(dataSPV.X(idxEndEcc));
                    else
                        trialData.SPVBegEcc(i) = nan;
                        trialData.SPVEndEcc(i) = nan;
                    end
                    trialData.SPVBegRebound(i) = nanmean(dataSPV.X(idxBegRebound));
                    trialData.SPVEndRebound(i) = nanmean(dataSPV.X(idxEndRebound));
                end
                
                trialDataTable = trialData;
            end
        end
        
        
        
%         
%         function trialDataSet = PrepareTrialDataTable( this, ds)
%             trialDataSet = ds;
%             
%              eventFiles = this.Session.currentRun.LinkedFiles.vogEventsFile;
%             if (~iscell(eventFiles) )
%                 eventFiles = {eventFiles};
%             end
%             
%             if (strcmp(eventFiles{1}, 'ReboundVariCenter_NGA-2018May22-154031-events.txt'))
%                 eventFiles = {'ReboundVariCenter_NGA-2018May22-152034-events.txt' eventFiles{:}};
%             end
%             if (strcmp(eventFiles{1}, 'ReboundVariCenter_KCA-2018May22-134440-events.txt'))
%                 eventFiles{end+1} = 'ReboundVariCenter_KCA-2018May22-144011-events.txt';
%             end
% 
%             events1 = [];
%             for i=1:length(eventFiles)
%                 eventFile = eventFiles{i};
%                 disp(eventFile);
%                 eventFilesPath = fullfile(this.Session.dataPath, eventFile);
%                 text = fileread(eventFilesPath);
%                 matches = regexp(text,'[^\n]*new trial[^\n]*','match')';
%                 eventsFromFile = struct2table(cell2mat(regexp(matches,'Time=(?<DateTime>[^\s]*) FrameNumber=(?<FrameNumber>[^\s]*)','names')));
%                 eventsFromFile.FrameNumber = str2double(eventsFromFile.FrameNumber);
%                 eventsFromFile = [eventsFromFile table(string(repmat(eventFile,height(eventsFromFile),1)),repmat(i,height(eventsFromFile),1),'variablenames',{'File' 'FileNumber'})];
%                 if ( isempty(events1) )
%                     events1 = eventsFromFile;
%                 else
%                     events1 = cat(1,events1,eventsFromFile);
%                 end
%             end
%             
%             trialDataSet = [trialDataSet events1];
%             
%             trialData = trialDataSet(trialDataSet.TrialResult==0,:);
%             data = this.Session.samplesDataSet;
%             trialData.Side = categorical(trialData.Side);
%             
%             dataFiles = this.Session.currentRun.LinkedFiles.vogDataFile;
%                         
%             if (~iscell(dataFiles) )
%                 dataFiles = {dataFiles};
%             end
%             
%             if (strcmp(dataFiles{1}, 'ReboundVariCenter_NGA-2018May22-154031.txt'))
%                 dataFiles = {'ReboundVariCenter_NGA-2018May22-152034.txt' dataFiles{:}};
%             end
%             if (strcmp(dataFiles{1}, 'ReboundVariCenter_KCA-2018May22-134440.txt'))
%                 dataFiles{end+1} = 'ReboundVariCenter_KCA-2018May22-144011.txt';
%             end
%             
%             allRawData = {};
%             for i=1:length(dataFiles)
%                 dataFile = dataFiles{i}                
%                 dataFilePath = fullfile(this.Session.dataPath, dataFile);
%                 
%                 % load data
%                 rawData = dataset2table(VOG.LoadVOGdataset(dataFilePath));
%                 
%                 allRawData{i} = rawData;
%             end
%             
%             d = this.ExperimentOptions.EccentricDuration;
%             
%             for i=1:height(trialData)
%                 fileNumber = trialData.FileNumber(i);
%                 idxInFile = find(data.FileNumber==fileNumber);
%                 if ( isempty(idxInFile) )
%                     continue;
%                 end
%                 b = bins(data.Time(idxInFile)', (allRawData{fileNumber}.LeftSeconds(find(allRawData{fileNumber}.LeftFrameNumberRaw==trialData.FrameNumber(i)))-allRawData{fileNumber}.LeftSeconds(1))');
%                 if ( isempty(b))
%                     continue;
%                 end
%                 trialData.trialStartSample(i) =  idxInFile(1) + bins(data.Time(idxInFile)', (allRawData{fileNumber}.LeftSeconds(find(allRawData{fileNumber}.LeftFrameNumberRaw==trialData.FrameNumber(i)))-allRawData{fileNumber}.LeftSeconds(1))');
%                 trialData.StartEccentricity(i) = idxInFile(1) + bins(data.Time(idxInFile)', 11+(allRawData{fileNumber}.LeftSeconds(find(allRawData{fileNumber}.LeftFrameNumberRaw==trialData.FrameNumber(i)))-allRawData{fileNumber}.LeftSeconds(1))');
%                 trialData.StartRebound(i) = idxInFile(1) + bins(data.Time(idxInFile)', 11+d+(allRawData{fileNumber}.LeftSeconds(find(allRawData{fileNumber}.LeftFrameNumberRaw==trialData.FrameNumber(i)))-allRawData{fileNumber}.LeftSeconds(1))');
%                 trialData.EndRebound(i) = idxInFile(1) + bins(data.Time(idxInFile)', 31+d+(allRawData{fileNumber}.LeftSeconds(find(allRawData{fileNumber}.LeftFrameNumberRaw==trialData.FrameNumber(i)))-allRawData{fileNumber}.LeftSeconds(1))');
%             end
%             
%             target = nan(size(data.LeftX));
%             for i=1:height(trialData)
%                 if ( trialData.trialStartSample(i) == 0 )
%                     trialData.SPVBaseline(i) = nan;
%                     trialData.SPVBegEcc(i) = nan;
%                     trialData.SPVEndEcc(i) = nan;
%                     trialData.SPVBegRebound(i) = nan;
%                     trialData.SPVEndRebound(i) = nan;
%                     continue;
%                 end
%                 idx1 = trialData.trialStartSample(i):trialData.StartEccentricity(i);
%                 idx2 = trialData.StartEccentricity(i):trialData.StartRebound(i);
%                 idx3 = trialData.StartRebound(i):trialData.EndRebound(i);
%                 
%                 switch(trialData.Side(i))
%                     case 'Left'
%                         ecc = -40;
%                         cen = -trialData.CenterLocation(i);
%                     case 'Right'
%                         ecc = 40;
%                         cen = trialData.CenterLocation(i);
%                 end
%                 target(idx1) = 0;
%                 target(idx2) = ecc;
%                 target(idx3) = cen;
%                 
%                 if ( length(idx3)< 5*500)
%                     trialData.SPVBaseline(i) = nan;
%                     trialData.SPVBegEcc(i) = nan;
%                     trialData.SPVEndEcc(i) = nan;
%                     trialData.SPVBegRebound(i) = nan;
%                     trialData.SPVEndRebound(i) = nan;
%                     continue;
%                 end
%                 idxBaseline = idx1(end-6*500:end-1*500);
%                 idxBegEcc = idx2(1:5*500);
%                 idxEndEcc = idx2(end-6*500:end-1*500);
%                 idxBegRebound = idx3(1:5*500);
%                 idxEndRebound = idx3(end-6*500:end-1*500);
%                 trialData.SPVBaseline(i) = nanmedian([data.LeftSPVX(idxBaseline);data.RightSPVX(idxBaseline)]);
%                 trialData.SPVBegEcc(i) = nanmedian([data.LeftSPVX(idxBegEcc);data.RightSPVX(idxBegEcc)]);
%                 trialData.SPVEndEcc(i) = nanmedian([data.LeftSPVX(idxEndEcc);data.RightSPVX(idxEndEcc)]);
%                 trialData.SPVBegRebound(i) = nanmedian([data.LeftSPVX(idxBegRebound);data.RightSPVX(idxBegRebound)]);
%                 trialData.SPVEndRebound(i) = nanmedian([data.LeftSPVX(idxEndRebound);data.RightSPVX(idxEndRebound)]);
%             end
%             
%             trialDataSet = trialData;
%             
%         end
%         
%         function [samplesDataSet rawDataTable] = PrepareSamplesDataTable(this, trialDataSet, dataFile, calibrationFile)
%             samplesDataSet = [];
%             rawDataTable = [];
%             
%             dataFiles = this.Session.currentRun.LinkedFiles.vogDataFile;
%             calibrationFiles = this.Session.currentRun.LinkedFiles.vogCalibrationFile;
%                         
%             if (~iscell(dataFiles) )
%                 dataFiles = {dataFiles};
%                 calibrationFiles = {calibrationFiles};
%             end
%             
%             for i=1:length(dataFiles)
%                 dataFile = dataFiles{i}
%                 calibrationFile = calibrationFiles{i};
%                 
%                 dataFilePath = fullfile(this.Session.dataPath, dataFile);
%                 calibrationFilePath = fullfile(this.Session.dataPath, calibrationFile);
%                 
%                 % load data
%                 rawData = VOG.LoadVOGdataset(dataFilePath);
%                 
%                 % calibrate data
%                 [calibratedData leftEyeCal rightEyeCal] = VOG.CalibrateData(rawData, calibrationFilePath);
%                 
%                 [cleanedData, fileSamplesDataSet] = VOG.ResampleAndCleanData3(calibratedData, 1000);
%                                 
%                 fileSamplesDataSet = [table(repmat(i,height(fileSamplesDataSet),1),'variablenames',{'FileNumber'}), fileSamplesDataSet];
% 
%                                 
%                 if ( isempty(samplesDataSet) )
%                     samplesDataSet = fileSamplesDataSet;
%                     rawDataTable = rawDataTable;
%                 else
%                     samplesDataSet = cat(1,samplesDataSet,fileSamplesDataSet);
%                     rawDataTable = cat(1,rawDataTable,rawDataTable);
%                 end
%             end
%         end
%         
%         function sessionDataTable = PrepareSessionDataTable(this, sessionDataTable)
%             trialData = this.Session.trialDataSet;
%             g1 = grpstats(trialData,{'CenterLocation', 'Side'},{'mean'},'DataVars',{'SPVBaseline', 'SPVBegRebound'})
%         end
    end
    
    % ---------------------------------------------------------------------
    % Plot  methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function plotResults = Plot_VOG_SPV(this)
            
            trialData = this.Session.trialDataTable;
            trialDataCal = trialData(trialData.TypeOfTrial=='Calibration',:);
            trialData = trialData(trialData.TypeOfTrial=='Rebound',:);
            
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
            
            
            g1 = grpstats(trialDataCal,{'CenterLocation'},{'mean'},'DataVars',{'SPVBaseline', 'SPVBegRebound'});
            plot(g1.CenterLocation,g1.mean_SPVBegRebound,'-o')
            
            set(gca,'ylim',max(abs(get(gca,'ylim')))*[-1 1]);
            line([-40 40],[0 0]);
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