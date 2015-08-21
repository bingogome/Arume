classdef SVV2AFCAdaptive < ArumeExperimentDesigns.SVV2AFC
    %SVVdotsAdaptFixed Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        currentAngle = 0;
        currentCenterRange = 0;
        currentRange = 180;
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function dlg = GetOptionsDialog( this )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.SVV2AFC(this);
        end
        
        function initExperimentDesign( this  )
            
            this.trialDuration = this.ExperimentOptions.fixationDuration/1000 ...
                + this.ExperimentOptions.targetDuration/1000 ...
                + this.ExperimentOptions.responseDuration/1000 ; %seconds
            
            % default parameters of any experiment
            this.trialSequence      = 'Random';      % Sequential, Random, Random with repetition, ...
            this.trialAbortAction   = 'Delay';    % Repeat, Delay, Drop
            this.trialsPerSession   = 100;
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 10;
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
        
        function [ randomVars] = getRandomVariables( this )
            randomVars = {};
        end
        
        function staircaseVars = getStaircaseVariables( this )
            i= 0;
            
            i = i+1;
            staircaseVars = [];
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
                        previousValues(n) = this.Session.currentRun.Data{i}.trialOutput.Angle;
                        previousResponses(n) = this.Session.currentRun.Data{i}.trialOutput.Response;
                        n = n+1;
                    end
                end
            end
            
            NtrialPerBlock = 10;
            
            % recalculate every 10 trials
            N = mod(length(previousValues),NtrialPerBlock);
            Nblocks = floor(length(previousValues)/NtrialPerBlock)*NtrialPerBlock+1;
            
            if ( length(previousValues)>0 )
                if ( N == 0 )
                    ds = dataset;
                    ds.Response = previousResponses(1:end);
                    ds.Angle = previousValues(1:end);
                    modelspec = 'Response ~ Angle';
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
        
        function trialOutput = runPostTrial(this)
            
            
            if ( ~isempty( this.eyeTracker ) )
                
                if ( length(this.Session.currentRun.futureConditions) == 0 )
                    this.eyeTracker.StopRecording();
                end
            end
            
            trialOutput = [];
            trialOutput.Response = this.lastResponse;
            trialOutput.ReactionTime = this.reactionTime;
            trialOutput.Angle = this.currentAngle;
            trialOutput.Range = this.currentRange;
            trialOutput.RangeCenter = this.currentCenterRange;
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
                
        function plotResults = Plot_ExperimentTimeCourse(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds.Response = ds.Response == 'L';
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];
            NtrialPerBlock = 10;
            
            Nblocks = ceil(length(ds)/NtrialPerBlock/2)*2;
            
            figure('position',[400 200 700 400],'color','w','name',this.Session.name)
            axes('nextplot','add');
            
            % Plot button presses
            plot(ds(ds.Response==0 & strcmp(ds.Position,'Up'),'TrialNumber'), ds(ds.Response==0 & strcmp(ds.Position,'Up'),'Angle'),'^','MarkerEdgeColor',[0.3 0.3 0.3],'linewidth',1);
            plot(ds(ds.Response==1 & strcmp(ds.Position,'Up'),'TrialNumber'), ds(ds.Response==1 & strcmp(ds.Position,'Up'),'Angle'),'^','MarkerEdgeColor','r','linewidth',1);
            plot(ds(ds.Response==0 & strcmp(ds.Position,'Down'),'TrialNumber'), ds(ds.Response==0 & strcmp(ds.Position,'Down'),'Angle'),'v','MarkerEdgeColor',[0.3 0.3 0.3],'linewidth',1);
            plot(ds(ds.Response==1 & strcmp(ds.Position,'Down'),'TrialNumber'), ds(ds.Response==1 & strcmp(ds.Position,'Down'),'Angle'),'v','MarkerEdgeColor','r','linewidth',1);
            
            % Plot center of the range
            plot(ds.TrialNumber, ds.RangeCenter,'linewidth',3,'color',[.5 .8 .3]);
            plot(ds.TrialNumber, ds.RangeCenter-ds.Range,'linewidth',1,'color',[.5 .8 .3]);
            plot(ds.TrialNumber, ds.RangeCenter+ds.Range,'linewidth',1,'color',[.5 .8 .3]);
            
            legend({'Ansered tilted to the right', 'Answered tilted to the left'},'fontsize',16)
            legend('boxoff')
            set(gca,'xlim',[-3 503],'ylim',[-90 90],'ylim',[-20 20])
            ylabel('Angle (deg)', 'fontsize',16);
            xlabel('Trial number', 'fontsize',16);
            set(gca,'ygrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
        end
        
        function plotResults = Plot_ReactionTimes(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];
            
            angles = ds.Angle;
            times = ds.ReactionTime;
            
            binAngles = [-90:5:90];
            
            binMiddles = binAngles(1:end-1) + diff(binAngles)/2;
            timeAvg = zeros(size(binMiddles));
            for i=1:length(binMiddles)
                timeAvg(i) = median(times(angles>binAngles(i) & angles<binAngles(i+1)));
            end
            
            figure('position',[400 400 1000 400],'color','w','name',this.Session.name)
            axes( 'fontsize',12);
            plot(angles,times*1000,'o', 'color', [0.7 0.7 0.7], 'markersize',10,'linewidth',2)
            hold
            plot(binMiddles, timeAvg*1000, 'color', 'k','linewidth',2);
            set(gca,'xlim',[-30 30],'ylim',[0 1500])
            xlabel('Angle (deg)','fontsize',16);
            ylabel('Reaction time (ms)','fontsize',16);
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca,'xgrid','on')
            
            %%
        end
        
        function plotResults = PlotAggregate_SVVCombined(this, sessions)
            
            SVV = nan(size(sessions));
            SVVUp = nan(size(sessions));
            SVVDown = nan(size(sessions));
            SVVLine = nan(size(sessions));
            names = {};
            for i=1:length(sessions)
                session = sessions(i);
                names{i} = session.sessionCode;
                switch(class(session.experiment))
                    case {'ArumeExperimentDesigns.SVVdotsAdaptFixed' 'ArumeExperimentDesigns.SVVLineAdaptFixed' 'ArumeExperimentDesigns.SVVForcedChoice'}
                        ds = session.trialDataSet;
                        ds(ds.TrialResult>0,:) = [];
                        ds(ds.Response<0,:) = [];
                        
                        subds = ds(:,:);
                        [SVV(i), a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
                        
                        subds = ds(strcmp(ds.Position,'Up'),:);
                        [SVVUp(i), a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
                        subds = ds(strcmp(ds.Position,'Down'),:);
                        [SVVDown(i), a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
                        
                        
                    case 'ArumeExperimentDesigns.SVVClassical'
                        ds = session.trialDataSet;
                        ds(ds.TrialResult>0,:) = [];
                        
                        SVV(i) = median(ds.Response');
                        SVVLine(i) = SVV(i);
                    case {'ArumeExperimentDesigns.SVVClassicalUpDown' 'ArumeExperimentDesigns.SVVClassicalDotUpDown'}
                        ds = session.trialDataSet;
                        ds(ds.TrialResult>0,:) = [];
                        
                        SVV(i) = median(ds.Response');
                        SVVLine(i) = SVV(i);
                        
                        SVVUp(i) = median(ds.Response(streq(ds.Position,'Up'),:)');
                        SVVDown(i) = median(ds.Response(streq(ds.Position,'Down'),:)');
                end
            end
            
            figure('position',[100 100 1000 700])
            
            subplot(1,2,1,'fontsize',14);
            plot(SVV,1:length(SVV),'o','markersize',10)
            hold
            plot(SVVLine,1:length(SVV),'+','markersize',10)
            set(gca,'ytick',1:length(SVV),'yticklabel',names)
            
            set(gca,'ydir','reverse');
            line([0 0], get(gca,'ylim'),'color',[0.5 0.5 0.5])
            
            set(gca,'xlim',[-20 20])
            
            xlabel('SVV (deg)','fontsize',16);
            
            subplot(1,2,2,'fontsize',14);
            plot(SVVUp-SVVDown,1:length(SVV),'o','markersize',10)
            set(gca,'ytick',1:length(SVV),'yticklabel',names)
            set(gca,'ydir','reverse');
            line([0 0], get(gca,'ylim'),'color',[0.5 0.5 0.5])
            
            xlabel('SVV UP-Down diff. (deg)','fontsize',16);
            
            set(gca,'xlim',[-6 6])
            
            ds =[];
            
            for i=1:length(sessions)
                session = sessions(i);
                names{i} = session.sessionCode;
                switch(class(session.experiment))
                    case {'ArumeExperimentDesigns.SVVdotsAdaptFixed' 'ArumeExperimentDesigns.SVVLineAdaptFixed' 'ArumeExperimentDesigns.SVVForcedChoice'}
                        sds = session.trialDataSet;
                        sds(sds.TrialResult>0,:) = [];
                        sds(sds.Response<0,:) = [];
                        
                        if ( isempty(ds) )
                            ds = sds;
                        else
                            ds =[ds;sds]
                        end
                        
                end
            end
            
            figure
            
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( ds.Angle, ds.Response);
            
            plot( allAngles, allResponses,'o', 'color', [0.7 0.7 0.7], 'markersize',10,'linewidth',2)
            plot(a,p, 'color', 'k','linewidth',2);
            line([SVV, SVV], [0 100], 'color','k','linewidth',2);
        end
        
        function analysisResults = Analysis_SVVbin(this)
            data = this.Session.trialDataSet;
            
            binDataSVV = [];
            binDataSVVth = [];
            for j=1:floor(size(data,1)/100)
                idx = (50:100) + (j-1)*100;
                if ( max(idx) <= length(data.Angle) )
                    angles = data.Angle(idx);
                    responses = data.Response(idx);
                    [SVV1, a, p, allAngles, allResponses, trialCounts, SVVth1] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, responses);
                    binDataSVV(j) = SVV1;
                    binDataSVVth(j) = SVVth1;
                end
            end
            
            analysisResults.SVV = binDataSVV;
            analysisResults.SVVth = binDataSVVth;
            
        end
        
        function analysisResults = Analysis_SVVSmooth(this)
            
            data = this.Session.trialDataSet;
            
            smoothDataSVV = [];
            smoothDataSVVth = [];
            
            % Get SVVsmooth
            for j=1:floor(size(data,1)/10)
                idx1 = max(min((j)*10 -10,length(data.Angle)),1);
                idx2 = max(min((j)*10 +19,length(data.Angle)),1);
                idx = idx1:idx2;
                if ( max(idx) <= length(data.Angle) && length(idx) >= 10)
                    angles = data.Angle(idx);
                    responses = data.Response(idx);
                    [SVV1, a, p, allAngles, allResponses, trialCounts, SVVth1] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, responses);
                    smoothDataSVV(j) = SVV1;
                    smoothDataSVVth(j) = SVVth1;
                end
            end
            
            analysisResults.SVV = smoothDataSVV;
            analysisResults.SVVth = smoothDataSVVth;
        end
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
end

