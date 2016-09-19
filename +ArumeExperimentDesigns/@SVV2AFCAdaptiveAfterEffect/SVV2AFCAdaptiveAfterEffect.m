classdef SVV2AFCAdaptiveAfterEffect < ArumeExperimentDesigns.SVV2AFCAdaptiveLong
    %SVVLineAdaptiveLong Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function dlg = GetOptionsDialog( this )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.SVV2AFCAdaptiveLong(this);
            
            dlg.TiltHeadAtBegining = { {'{0}','1'} };
            
            dlg.BaselineTrials = {100 '* (trials)' [1 500] };
            dlg.TiltedTrials = {500 '* (trials)' [1 1000] };
            dlg.AfterEffectTrials = {150 '* (trials)' [1 500] };
            
            dlg.RestartAfterBaseline = { {'0','{1}'} };
            dlg.RestartAfterTilt = { {'0','{1}'} };
        end
        
        function initExperimentDesign( this  )
            this.trialDuration = this.ExperimentOptions.fixationDuration/1000 ...
                + this.ExperimentOptions.targetDuration/1000 ...
                + this.ExperimentOptions.responseDuration/1000 ; %seconds
            
            % default parameters of any experiment
            this.trialSequence      = 'Random';      % Sequential, Random, Random with repetition, ...
            this.trialAbortAction   = 'Delay';    % Repeat, Delay, Drop
            this.trialsPerSession   = 750;
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 75;
            this.blocksToRun = 1;
            this.blocks = [ struct( 'fromCondition', 1, 'toCondition', 10, 'trialsToRun', 10) ];
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'AnglePercentRange';
            conditionVars(i).values = ([-100:100/2.5:100-100/5]+100/5);
            
            i = i+1;
            conditionVars(i).name   = 'Position';
            conditionVars(i).values = {'Up' 'Down'};
        end
        
        function trialResult = runPreTrial(this, variables )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            % Add stuff here
            
            if ( ~isempty( this.Session.currentRun ) )
                nCorrect = sum(this.Session.currentRun.pastConditions(:,Enum.pastConditions.trialResult) ==  Enum.trialResult.CORRECT );
                
                previousValues = zeros(nCorrect,1);
                previousResponses = zeros(nCorrect,1);
                
                n = 1;
                for i=1:length(this.Session.currentRun.pastConditions(:,1))
                    if ( this.Session.currentRun.pastConditions(i,Enum.pastConditions.trialResult) ==  Enum.trialResult.CORRECT )
                        isdown = strcmp(this.Session.currentRun.Data{i}.variables.Position, 'Down');
                        previousValues(n) = this.Session.currentRun.Data{i}.trialOutput.Angle;
                        previousResponses(n) = this.Session.currentRun.Data{i}.trialOutput.Response;
                        n = n+1;
                    end
                end
            else
                trialResult = Enum.trialResult.ABORT;
                return;
            end
            
             % Initialize bitebar
            if ( this.ExperimentOptions.UseBiteBarMotor )
                if ( nCorrect == this.ExperimentOptions.BaselineTrials )
                    
                    if ( ~isempty( this.eyeTracker ) )
                        this.eyeTracker.StopRecording();
                    end
                    
                    result = 'n';
                    while( result ~= 'y' )
                        result = this.Graph.DlgSelect( ...
                            'Continue:', ...
                            { 'y' 'n'}, ...
                            { 'Yes'  'No'} , [],[]);
                    end
                    
                    if ( ~isempty( this.eyeTracker ) )
                        this.eyeTracker.StartRecording();
                    end
                    
                    [mx, my] = RectCenter(this.Graph.wRect);
                    fixRect = [0 0 10 10];
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    Screen('FillOval', this.Graph.window,  255, fixRect);
                    fliptime = Screen('Flip', this.Graph.window);
                    
                    if ( this.ExperimentOptions.UseBiteBarMotor)
                        pause(2);
                        this.biteBarMotor.SetTiltAngle(this.ExperimentOptions.HeadAngle);
                        disp('30 s pause');
                        pause(30);
                        disp('done');
                    end
                end
                
                if ( nCorrect == this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials)
                    
                    [mx, my] = RectCenter(this.Graph.wRect);
                    fixRect = [0 0 10 10];
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    Screen('FillOval', this.Graph.window,  255, fixRect);
                    fliptime = Screen('Flip', this.Graph.window);
                    
                    if ( this.ExperimentOptions.UseBiteBarMotor)
                        pause(2);
                        this.biteBarMotor.GoUpright();
                        disp('30 s pause');
                        pause(30);
                        disp('done');
                    end
                end
            end
            
            
            
            if ( length(previousResponses) > this.ExperimentOptions.BaselineTrials && ...
                length(previousResponses) < this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials && ...
                this.ExperimentOptions.RestartAfterBaseline)
                previousResponses(1:this.ExperimentOptions.BaselineTrials ) = [];
                previousValues(1:this.ExperimentOptions.BaselineTrials ) = [];
            end
            
            if ( length(previousResponses) > this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials && ...
                this.ExperimentOptions.RestartAfterTilt)
                previousResponses(1:(this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials) ) = [];
                previousValues(1:(this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials) ) = [];
            end
            
            NtrialPerBlock = 10;
            
            % recalculate every 10 trials
            N = mod(length(previousValues),NtrialPerBlock);
            Nblocks = floor(length(previousValues)/NtrialPerBlock)*NtrialPerBlock+1;
            
            if ( length(previousValues)>0 )
                if ( N == 0 )
                    ds = dataset;
                    ds.Response = previousResponses(max(1,end-30):end);
                    ds.Angle = previousValues(max(1,end-30):end);
                    subds = ds;
                    
                    SVV = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
                    
                    % Limit the center of the new range to the extremes of
                    % the past range of angles
                    if ( SVV > max(ds.Angle) )
                        SVV = max(ds.Angle);
                    elseif( SVV < min(ds.Angle))
                        SVV = min(ds.Angle);
                    end
                    
                    this.currentCenterRange = SVV + this.ExperimentOptions.offset;
                    
                    this.currentRange = (90)./min(18,round(2.^(Nblocks/15)));
                end
            else
                this.currentCenterRange = rand(1)*30-15;
                this.currentRange = 90;
            end
            
            this.currentAngle = (variables.AnglePercentRange/100*this.currentRange) + this.currentCenterRange;
            this.currentAngle = mod(this.currentAngle+90,180)-90;
            
            this.currentAngle = round(this.currentAngle);
            
            disp(['CURRENT: ' num2str(this.currentAngle) ' Percent: ' num2str(variables.AnglePercentRange) ' Block: ' num2str(N) ' SVV : ' num2str(this.currentCenterRange) ' RANGE: ' num2str(this.currentRange)]);
            
            if ( ~isempty(this.eyeTracker) )
                if ( ~this.eyeTracker.IsRecording())
                    this.eyeTracker.StartRecording();
                    pause(1);
                end
                this.eyeTracker.RecordEvent(num2str(size(this.Session.currentRun.pastConditions,1)));
            end
            
            trialResult =  Enum.trialResult.CORRECT;
        end
        
        function trialResult = runTrial( this, variables )
                        
            try
                this.lastResponse = -1;
                this.reactionTime = -1;
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                
                graph = this.Graph;
                
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
                Screen('FillRect', graph.window, 0);
                lastFlipTime        = Screen('Flip', graph.window);
                secondsRemaining    = this.trialDuration;
                
                startLoopTime = lastFlipTime;
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - startLoopTime;
                    secondsRemaining    = this.trialDuration - secondsElapsed;
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    %-- Find the center of the screen
                    [mx, my] = RectCenter(graph.wRect);

                    t1 = this.ExperimentOptions.fixationDuration/1000;
                    t2 = this.ExperimentOptions.fixationDuration/1000 +this.ExperimentOptions.targetDuration/1000;
                    
                    lineLength = 300;
                    
%                     if ( secondsElapsed > t1 && secondsElapsed < t2 )
                    if ( secondsElapsed > t1)
                        %-- Draw target
                        
                        switch(variables.Position)
                            case 'Up'
                                fromH = mx;
                                fromV = my;
                                toH = mx + lineLength*sin(this.currentAngle/180*pi);
                                toV = my - lineLength*cos(this.currentAngle/180*pi);
                            case 'Down'
                                fromH = mx;
                                fromV = my;
                                toH = mx - lineLength*sin(this.currentAngle/180*pi);
                                toV = my + lineLength*cos(this.currentAngle/180*pi);
                        end
                        
                        Screen('DrawLine', graph.window, this.targetColor, fromH, fromV, toH, toV, 4);
                        
                    end
                    
%                     if (secondsElapsed < t2)
%                         % black patch to block part of the line
                        
                        fixRect = [0 0 10 10];
                        fixRect = CenterRectOnPointd( fixRect, mx, my );
                        Screen('FillOval', graph.window,  this.targetColor, fixRect);
%                     end
                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------
                    
                    
                % -----------------------------------------------------------------
                % DEBUG
                % -----------------------------------------------------------------
                if (0)
                    % TODO: it would be nice to have some call back system here
                    Screen('DrawText', graph.window, sprintf('%i seconds remaining...', round(secondsRemaining)), 20, 50, graph.white);
                    currentline = 50 + 25;
                    vNames = fieldnames(variables);
                    for iVar = 1:length(vNames)
                        if ( ischar(variables.(vNames{iVar})) )
                            s = sprintf( '%s = %s',vNames{iVar},variables.(vNames{iVar}) );
                        else
                            s = sprintf( '%s = %s',vNames{iVar},num2str(variables.(vNames{iVar})) );
                        end
                        Screen('DrawText', graph.window, s, 20, currentline, graph.white);
                        
                        currentline = currentline + 25;
                    end
                end
                % -----------------------------------------------------------------
                % END DEBUG
                % -----------------------------------------------------------------
                
                    
                    % -----------------------------------------------------------------
                    % -- Flip buffers to refresh screen -------------------------------
                    % -----------------------------------------------------------------
                    this.Graph.Flip();
                    % -----------------------------------------------------------------
                    
                    
                    % -----------------------------------------------------------------
                    % --- Collecting responses  ---------------------------------------
                    % -----------------------------------------------------------------
                    
                    if ( secondsElapsed > max(t1,0.200)  )
                        reverse = isequal(variables.Position,'Down');
                        response = this.CollectLeftRightResponse(reverse);
                        if ( ~isempty( response) )
                            this.lastResponse = response;
                        end
                    end
                    
                    if ( this.lastResponse >= 0 )
                        this.reactionTime = secondsElapsed-1;
                        disp(num2str(this.lastResponse));
                        break;
                    end
                    
                    % -----------------------------------------------------------------
                    % --- END Collecting responses  -----------------------------------
                    % -----------------------------------------------------------------
                    
                end
            catch ex
                if ( ~isempty( this.eyeTracker ) )
                    this.eyeTracker.StopRecording();
                end
                
                rethrow(ex)
            end
            
            
            if ( this.lastResponse < 0)
                trialResult =  Enum.trialResult.ABORT;
            end
        end
    end
        
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        function trialDataSet = PrepareTrialDataSet( this, ds)
            data = ds;
            if ( data.TimeStopTrial(end) == 0)
                data(end,:) = [];
            end
            
            binSize = 30;
            stepSize = 10;
            
            newData.Bin30SVV = nan(size(data,1),1);
            newData.Bin30SVVth = nan(size(data,1),1);
            newData.Bin30Start = nan(size(data,1),1);
            newData.Bin30End = nan(size(data,1),1);
            for j=1:ceil(size(data,1)/stepSize)
                idx = (1:binSize) + (j-1)*stepSize;
                idx(idx<1 | idx>size(data,1)) = [];
                
                MEANIDX = mean(idx);
                if (  MEANIDX < this.ExperimentOptions.BaselineTrials )
                    idx(idx>this.ExperimentOptions.BaselineTrials) = [];
                elseif ( MEANIDX < this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials)
                    idx(idx<=this.ExperimentOptions.BaselineTrials | idx > this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials) = [];
                else
                    idx(idx <= this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials) = [];
                end
                
                if ( length(idx) >= 20 )
                    angles = data.Angle(idx);
                    responses = data.Response(idx);
                    [SVV1, a, p, allAngles, allResponses, trialCounts, SVVth1] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, responses);
                    
                    saveidx = floor(MEANIDX - stepSize/2 + (1:stepSize));
                    saveidx(saveidx<1 | saveidx>size(data,1)) = [];
                    
                    if (  MEANIDX < this.ExperimentOptions.BaselineTrials )
                        saveidx(saveidx>this.ExperimentOptions.BaselineTrials) = [];
                    elseif ( MEANIDX < this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials)
                        saveidx(saveidx<=this.ExperimentOptions.BaselineTrials | saveidx > this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials) = [];
                    else
                        saveidx(saveidx <= this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials) = [];
                    end
                    
                    newData.Bin30SVV(saveidx) = SVV1;
                    newData.Bin30SVVth(saveidx) = SVVth1;
                    newData.Bin30Start(saveidx) = min(idx);
                    newData.Bin30End(saveidx) = max(idx);
                end
            end
            
            
            binSize = 100;
            stepSize = 10;
            f = binSize/stepSize;
            
            newData.Bin100SVV = nan(size(data,1),1);
            newData.Bin100SVVth = nan(size(data,1),1);
            newData.Bin100Start = nan(size(data,1),1);
            newData.Bin100End = nan(size(data,1),1);
            for j=1:ceil(size(data,1)/stepSize)
                idx = (1:binSize) + (j-1)*stepSize;
                idx(idx<1 | idx>size(data,1)) = [];
                
                MEANIDX = (j-1)*stepSize;
                if (  MEANIDX < this.ExperimentOptions.BaselineTrials )
                    idx(idx>this.ExperimentOptions.BaselineTrials) = [];
                elseif ( MEANIDX < this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials)
                    idx(idx<=this.ExperimentOptions.BaselineTrials | idx > this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials) = [];
                else
                    idx(idx <= this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials) = [];
                end
                
                if ( length(idx) >= 20 )
                    angles = data.Angle(idx);
                    responses = data.Response(idx);
                    [SVV1, a, p, allAngles, allResponses, trialCounts, SVVth1] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, responses);
                    
                    
                    saveidx = floor(mean(idx) - stepSize/2 + (1:stepSize));
                    saveidx(saveidx<1 | saveidx>size(data,1)) = [];
                    
                    if (  MEANIDX < this.ExperimentOptions.BaselineTrials )
                        saveidx(saveidx>this.ExperimentOptions.BaselineTrials) = [];
                    elseif ( MEANIDX < this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials)
                        saveidx(saveidx<=this.ExperimentOptions.BaselineTrials | saveidx > this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials) = [];
                    else
                        saveidx(saveidx <= this.ExperimentOptions.BaselineTrials + this.ExperimentOptions.TiltedTrials) = [];
                    end
                    
                    newData.Bin100SVV(saveidx) = SVV1;
                    newData.Bin100SVVth(saveidx) = SVVth1;
                    newData.Bin100Start(saveidx) = min(idx);
                    newData.Bin100End(saveidx) = max(idx);
                end
            end
            
            
            
            
            torsionFolder = 'N:\RAW_DATA\SVVTorsionAfterEffect\PostProcess';
            T = nan(size(data.TimeStartTrial));
            
            if (length(dir(fullfile(torsionFolder,[this.Session.name(1:end-1)  '*']))) == 2);
                folders = dir(fullfile(torsionFolder,[this.Session.name(1:end-1)  '*']));
                d = GetCalibratedData(fullfile(torsionFolder,folders(1).name));
                T = CleanTorsion(d);
                d = GetCalibratedData(fullfile(torsionFolder,folders(2).name));
                T = [T;CleanTorsion(d)];
                
                t = data.TimeStartTrial;
                t2 = data.TimeStopTrial;
                t2 = t2-t(1);
                t = t-t(1);
                t(101:end)= t(101:end)-t(101)+t2(100);
                t2(101:end)= t2(101:end)-t(101)+t2(100);
                
                L = t2(end)-t(1);
                LT = length(T);
                t = t * LT / L;
                t2 = t2 * LT / L;
                
                torsion = T;
                T = nan(size(t));
                for j=1:length(t)
                    idx = t(j):t2(j);
                    idx(idx<1) = [];
                    idx(idx>length(torsion)) = [];
                    T(j) = nanmedian(torsion(round(idx)));
                end
            end
            
            newData.Torsion = T;
            
            newDs = struct2dataset(newData);
            
            trialDataSet = [data newDs];
         end
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
end

