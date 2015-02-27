classdef SVVdotsAdaptFixed < ArumeExperimentDesigns.SVV2AFC
    %SVVdotsAdaptFixed Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        eyeTracker = [];
        
        lastResponse = '';
        reactionTime = '';
        
        fixColor = [255 0 0];
        
        targetColor = [255 0 0];
        
        currentAngle = 0;
        currentCenterRange = 0;
        currentRange = 180;
        
    end
    
    % ---------------------------------------------------------------------
    % Options to set at runtime
    % ---------------------------------------------------------------------
    methods ( Static = true )
        function dlg = GetOptionsStructDlg( this )
            dlg.UseGamePad = { {'0','{1}'} };
            dlg.UseEyeTracker = { {'{0}','1'} };
            dlg.FixationDiameter = { 12.5 '* (pix)' [3 50] };
            dlg.TargetDiameter = { 12.5 '* (pix)' [3 50] };
            dlg.targetDistance = { 125 '* (pix)' [10 500] };
            dlg.fixationDuration = { 1000 '* (ms)' [1 3000] };
            dlg.targetDuration = { 300 '* (ms)' [100 30000] };
            dlg.responseDuration = { 1500 '* (ms)' [100 3000] };
            
            dlg.offset = {0 '* (deg)' [-20 20] };
        end
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
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
        
        function initBeforeRunning( this )
            if ( this.ExperimentOptions.UseGamePad )
                ArumeHardware.GamePad.Open
            end
            
            if ( this.ExperimentOptions.UseEyeTracker )
                if ( exist('C:\secure\Code\EyeTracker\bin\Debug','file') )
                    asm = NET.addAssembly('C:\secure\Code\EyeTracker\bin\Debug\EyeTrackerRemoteClient.dll');
                    this.eyeTracker = ArumeHardware.VOG();
                    this.eyeTracker.Connect('127.0.0.1',9000);
                else
                    asm = NET.addAssembly('D:\Code\EyeTracker\bin\Debug\EyeTrackerRemoteClient.dll');
                    this.eyeTracker = ArumeHardware.VOG();
                    this.eyeTracker.Connect('127.0.0.1',9000);
                end
                
                this.eyeTracker.SetSessionName(this.Session.name);
            end
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
            
            if ( ~isempty( this.Session.CurrentRun ) )
                nCorrect = sum(this.Session.CurrentRun.pastConditions(:,Enum.pastConditions.trialResult) ==  Enum.trialResult.CORRECT );
                
                previousValues = zeros(nCorrect,1);
                previousResponses = zeros(nCorrect,1);
                
                n = 1;
                for i=1:length(this.Session.CurrentRun.pastConditions(:,1))
                    if ( this.Session.CurrentRun.pastConditions(i,Enum.pastConditions.trialResult) ==  Enum.trialResult.CORRECT )
                        isdown = strcmp(this.Session.CurrentRun.Data{i}.variables.Position, 'Down');
                        previousValues(n) = this.Session.CurrentRun.Data{i}.trialOutput.Angle;
                        previousResponses(n) = this.Session.CurrentRun.Data{i}.trialOutput.Response;
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
                this.eyeTracker.RecordEvent(num2str(size(this.Session.CurrentRun.pastConditions,1)));
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
                    
                    if (secondsElapsed < t2)
                        %-- Draw fixation spot
                        fixRect = [0 0 this.ExperimentOptions.FixationDiameter this.ExperimentOptions.FixationDiameter];
                        fixRect = CenterRectOnPointd( fixRect, mx, my );
                        Screen('FillOval', graph.window, this.fixColor, fixRect);
                    end
                    
                    if ( secondsElapsed > t1 && secondsElapsed < t2 )
                        %-- Draw target
                        targetRect = [0 0 this.ExperimentOptions.TargetDiameter this.ExperimentOptions.TargetDiameter];
                        
                        targetDist = this.ExperimentOptions.targetDistance;
                        switch(variables.Position)
                            case 'Up'
                                targetRect = CenterRectOnPointd( targetRect, mx + targetDist*sin(this.currentAngle/180*pi), my - targetDist*cos(this.currentAngle/180*pi) );
                            case 'Down'
                                targetRect = CenterRectOnPointd( targetRect, mx - targetDist*sin(this.currentAngle/180*pi), my + targetDist*cos(this.currentAngle/180*pi) );
                        end
                        Screen('FillOval', graph.window, this.targetColor, targetRect);
                    end
                    
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
                        
                        if ( this.ExperimentOptions.UseGamePad )
                            [d, l, r] = ArumeHardware.GamePad.Query;
                            if ( l == 1)
                                switch(variables.Position)
                                    case 'Up'
                                        this.lastResponse = 1;
                                    case 'Down'
                                        this.lastResponse = 0;
                                end
                            elseif( r == 1)
                                switch(variables.Position)
                                    case 'Up'
                                        this.lastResponse = 0;
                                    case 'Down'
                                        this.lastResponse = 1;
                                end
                            end
                        else
                            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                            if ( keyIsDown )
                                keys = find(keyCode);
                                for i=1:length(keys)
                                    KbName(keys(i))
                                    switch(KbName(keys(i)))
                                        case 'RightArrow'
                                            switch(variables.Position)
                                                case 'Up'
                                                    this.lastResponse = 1;
                                                case 'Down'
                                                    this.lastResponse = 0;
                                            end
                                        case 'LeftArrow'
                                            switch(variables.Position)
                                                case 'Up'
                                                    this.lastResponse = 0;
                                                case 'Down'
                                                    this.lastResponse = 1;
                                            end
                                    end
                                end
                            end
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
                
                if ( length(this.Session.CurrentRun.futureConditions) == 0 )
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
        
        % Function that gets the angles of each trial with 0 meaning
        % upright, positive tilted CW and negative CCW.
        function angles = GetAngles( this )
            angles = this.Session.trialDataSet.Angle;
            responses = 1-this.Session.trialDataSet.Response;
            angles = angles(responses<2);
        end
        
        % Function that gets the left and right responses with 1 meaning
        % right and 0 meaning left.
        function responses = GetLeftRightResponses( this )
            responses = 1-this.Session.trialDataSet.Response;
            responses = responses(responses<2);
        end
        
        function plotResults = Plot_ExperimentTimeCourse(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];
            NtrialPerBlock = 10;
            %             figure
            %             set(gca,'nextplot','add')
            %             colors = jet(length(ds)/NtrialPerBlock);
            
            Nblocks = ceil(length(ds)/NtrialPerBlock/2)*2;
            
            %             for i=NtrialPerBlock:NtrialPerBlock:length(ds)
            %                 nplot = ceil(i/NtrialPerBlock);
            %                 subplot(ceil(length(colors)/2),2,mod(((nplot*2)-1+floor((nplot-1)/(Nblocks/2)))-1,Nblocks)+1,'nextplot','add')
            %                 modelspec = 'Response ~ Angle';
            %                 subds = ds(1:i,:);
            %                 subds((subds.Response==1 & subds.Angle<-50) | (subds.Response==0 & subds.Angle>50),:) = [];
            %
            %                 [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
            %
            %                 plot(a,p, 'color', colors(nplot,:),'linewidth',2);
            %                 xlabel('Angle (deg)');
            %                 ylabel('Percent answered right');
            %
            %                 [svvr svvidx] = min(abs( p-50));
            %                 line([a(svvidx),a(svvidx)], [0 100], 'color', colors(nplot,:),'linewidth',2);
            %                 set(gca,'xlim',[-20 20])
            %
            %                 allAngles = -90:90;
            %                 allResponses = nan(size(allAngles));
            %                 for ia=1:length(allAngles)
            %                     allResponses(ia) = mean(responses(angles==allAngles(ia))*100);
            %                 end
            %
            %                 plot( allAngles,allResponses,'o')
            %                 text(3, 40, sprintf('SVV: %0.2f',a(svvidx)));
            %             end
            
            figure('position',[400 200 700 400],'color','w','name',this.Session.name)
            axes('nextplot','add');
            plot(ds(ds.Response==0 & strcmp(ds.Position,'Up'),'TrialNumber'), ds(ds.Response==0 & strcmp(ds.Position,'Up'),'Angle'),'^','MarkerEdgeColor',[0.3 0.3 0.3],'linewidth',2);
            plot(ds(ds.Response==1 & strcmp(ds.Position,'Up'),'TrialNumber'), ds(ds.Response==1 & strcmp(ds.Position,'Up'),'Angle'),'^','MarkerEdgeColor','r','linewidth',2);
            plot(ds(ds.Response==0 & strcmp(ds.Position,'Down'),'TrialNumber'), ds(ds.Response==0 & strcmp(ds.Position,'Down'),'Angle'),'v','MarkerEdgeColor',[0.3 0.3 0.3],'linewidth',2);
            plot(ds(ds.Response==1 & strcmp(ds.Position,'Down'),'TrialNumber'), ds(ds.Response==1 & strcmp(ds.Position,'Down'),'Angle'),'v','MarkerEdgeColor','r','linewidth',2);
            
            
            SVV = nan(1,100);
            
            for i=1:10
                idx = (1:10) + (i-1)*10;
                ang = ds.Angle(idx);
                res = ds.Response(idx);
                
                [SVV1, a, p, allAngles, allResponses,trialCounts, SVVth1] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( ang, res);
                SVV(idx) = SVV1;
            end
            
            plot(SVV,'linewidth',2,'color',[.5 .8 .3]);
            
            legend({'Ansered tilted to the right', 'Answered tilted to the left'},'fontsize',16)
            legend('boxoff')
            set(gca,'xlim',[-3 103],'ylim',[-90 90])
            ylabel('Angle (deg)', 'fontsize',16);
            xlabel('Trial number', 'fontsize',16);
            set(gca,'ygrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
        end
        
        function plotResults = Plot_SigmoidUpDown(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];
            
            figure('position',[400 100 1000 600],'color','w','name',this.Session.name)
            subds = ds(strcmp(ds.Position,'Up'),:);
            subds((subds.Response==0 & subds.Angle<-50) | (subds.Response==1 & subds.Angle>50),:) = [];
            
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
            
            subplot(6,1,[1:2],'nextplot','add', 'fontsize',12);
            plot( allAngles, allResponses,'o', 'color', [0.7 0.7 0.7], 'markersize',10,'linewidth',2)
            plot(a,p, 'color', 'k','linewidth',2);
            line([SVV,SVV], [0 100], 'color','k','linewidth',2);
            
            
            %xlabel('Angle (deg)', 'fontsize',16);
            ylabel({'Percent answered' 'tilted right'}, 'fontsize',16);
            text(20, 80, sprintf('SVV: %0.2f°',SVV), 'fontsize',16);
            
            set(gca,'xlim',[-30 30],'ylim',[-10 110])
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca,'xticklabel',[])
            
            
            subplot(6,1,[3],'nextplot','add', 'fontsize',12);
            bar(allAngles, trialCounts, 'edgecolor','none','facecolor',[0.5 0.5 0.5])
            
            set(gca,'xlim',[-30 30],'ylim',[0 15])
            xlabel('Angle (deg)', 'fontsize',16);
            ylabel('Number of trials', 'fontsize',16);
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca, 'YAxisLocation','right')
            
            
            
            subds = ds(strcmp(ds.Position,'Down'),:);
            subds((subds.Response==0 & subds.Angle<-50) | (subds.Response==1 & subds.Angle>50),:) = [];
            
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
            
            subplot(6,1,[4:5],'nextplot','add', 'fontsize',12);
            plot( allAngles, allResponses,'o', 'color', [0.7 0.7 0.7], 'markersize',10,'linewidth',2)
            plot(a,p, 'color', 'k','linewidth',2);
            line([SVV, SVV], [0 100], 'color','k','linewidth',2);
            
            %xlabel('Angle (deg)', 'fontsize',16);
            ylabel({'Percent answered' 'tilted right'}, 'fontsize',16);
            text(20, 80, sprintf('SVV: %0.2f°',SVV), 'fontsize',16);
            
            set(gca,'xlim',[-30 30],'ylim',[-10 110])
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca,'xticklabel',[])
            
            
            subplot(6,1,[6],'nextplot','add', 'fontsize',12);
            bar(allAngles, trialCounts, 'edgecolor','none','facecolor',[0.5 0.5 0.5])
            
            set(gca,'xlim',[-30 30],'ylim',[0 15])
            xlabel('Angle (deg)', 'fontsize',16);
            ylabel('Number of trials', 'fontsize',16);
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca, 'YAxisLocation','right')
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
        
        function analysisResults = Analysis_SVV(this)
            
        end
        
        function analysisResults = Analysis_SVVUpDown(this)
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
end

