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
            
            dlg.PreviousTrialsForRange = { {'{All}','Previous30'} };
            dlg.RangeChanges = { {'{Slow}','Fast'} };
            dlg.TotalNumberOfTrials = 100;
        end
        
        function initExperimentDesign( this  )
            this.trialDuration = this.ExperimentOptions.fixationDuration/1000 ...
                + this.ExperimentOptions.targetDuration/1000 ...
                + this.ExperimentOptions.responseDuration/1000 ; %seconds
            
            % default parameters of any experiment
            this.trialSequence      = 'Random';      % Sequential, Random, Random with repetition, ...
            this.trialAbortAction   = 'Delay';    % Repeat, Delay, Drop
            this.trialsPerSession   = this.ExperimentOptions.TotalNumberOfTrials;
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = ceil(this.ExperimentOptions.TotalNumberOfTrials/10);
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
                    switch(this.ExperimentOptions.PreviousTrialsForRange)
                        case 'All'
                            ds.Response = previousResponses(1:end);
                            ds.Angle = previousValues(1:end);
                        case 'Previous30'
                            ds.Response = previousResponses(max(1,end-30):end);
                            ds.Angle = previousValues(max(1,end-30):end);
                    end
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

                    switch(this.ExperimentOptions.RangeChanges)
                        case 'Slow'
                            this.currentRange = (90)./min(18,round(2.^(Nblocks/15)));
                        case 'Fast'
                            this.currentRange = (45)./min(9,round(2.^(Nblocks/15)));
                    end
                end
            else
                switch(this.ExperimentOptions.RangeChanges)
                    case 'Slow'
                        this.currentCenterRange = rand(1)*30-15;
                        this.currentRange = 90;
                    case 'Fast'
                        this.currentCenterRange = rand(1)*15-15;
                        this.currentRange = 45;
                end
            end
            
            this.currentAngle = (variables.AnglePercentRange/100*this.currentRange) + this.currentCenterRange;
            this.currentAngle = mod(this.currentAngle+90,180)-90;
            
            this.currentAngle = round(this.currentAngle);
            
            disp(sprintf(['\nLAST RESP.: ' char(previousResponses(max(end-100,1):end)')]));
            disp(['CURRENT TRIAL: ' num2str(this.currentAngle) ' Percent: ' num2str(variables.AnglePercentRange) ' Block: ' num2str(Nblocks) ' RANGE: ' num2str(this.currentRange) ' SVV : ' num2str(this.currentCenterRange)]);
            
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
                
                
                % SEND TO PARALEL PORT TRIAL NUMBER
                %write a value to the default LPT1 printer output port (at 0x378)
                %nCorrect = sum(this.Session.currentRun.pastConditions(:,Enum.pastConditions.trialResult) ==  Enum.trialResult.CORRECT );
                %outp(hex2dec('378'),rem(nCorrect,100)*2);
                
                
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
                                        
%                     if ( secondsElapsed > t1 && secondsElapsed < t2 )
                    if ( secondsElapsed > t1)
                        %-- Draw target
                        
                        this.DrawLine(variables);
                        
                        % SEND TO PARALEL PORT TRIAL NUMBER
                        %write a value to the default LPT1 printer output port (at 0x378)
                        %outp(hex2dec('378'),7);
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
                        
                        % SEND TO PARALEL PORT TRIAL NUMBER
                        %write a value to the default LPT1 printer output port (at 0x378)
                        %outp(hex2dec('378'),9);
                        
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
                
        function plotResults = Plot_TorsionSVV(this)
            
            ds = this.Session.trialDataSet;
            
            figure
            plot(ds.TrialNumber, ds.Bin100SVV,'linewidth',3,'color','b');
            hold
            plot(ds.TrialNumber, ds.Bin100Torsion,'linewidth',3,'color','r');
            
            legend({ 'SVV' 'Torsion'});
             
            xlabel('TrialNumber');
            ylabel('Deg');
        end
        
        function plotResults = Plot_ExperimentTimeCourse(this)
            analysisResults = 0;
            
            MEDIUM_BLUE =  [0.1000 0.5000 0.8000];
            MEDIUM_RED = [0.9000 0.2000 0.2000];
            MEDIUM_GREEN = [0.5000 0.8000 0.3000];
            MEDIUM_GOLD = [0.9000 0.7000 0.1000];
            
            ds = this.Session.trialDataSet;
            ds.Response = ds.Response == 'L';
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];
            NtrialPerBlock = 10;
            
            Nblocks = ceil(length(ds)/NtrialPerBlock/2)*2;
            
            figure('position',[400 200 700 400],'color','w','name',this.Session.name)
            axes('nextplot','add');
            
            % Plot button presses
            p = patch([ds.TrialNumber;ds.TrialNumber(end:-1:1);ds.TrialNumber(1)], [ds.RangeCenter-ds.Range;ds.RangeCenter(end:-1:1)+ds.Range(end:-1:1);ds.RangeCenter(1)-ds.Range(1)],[1 1 0.5]);
            set(p,'edgecolor','w');
            
            plot(ds(ds.Response==0 & strcmp(ds.Position,'Up'),'TrialNumber'), ds(ds.Response==0 & strcmp(ds.Position,'Up'),'Angle'),'^','MarkerEdgeColor',MEDIUM_RED,'linewidth',1);
            plot(ds(ds.Response==1 & strcmp(ds.Position,'Up'),'TrialNumber'), ds(ds.Response==1 & strcmp(ds.Position,'Up'),'Angle'),'^','MarkerEdgeColor',MEDIUM_BLUE,'linewidth',1);
            plot(ds(ds.Response==0 & strcmp(ds.Position,'Down'),'TrialNumber'), ds(ds.Response==0 & strcmp(ds.Position,'Down'),'Angle'),'v','MarkerEdgeColor',MEDIUM_RED,'linewidth',1);
            plot(ds(ds.Response==1 & strcmp(ds.Position,'Down'),'TrialNumber'), ds(ds.Response==1 & strcmp(ds.Position,'Down'),'Angle'),'v','MarkerEdgeColor',MEDIUM_BLUE,'linewidth',1);
            
            % Plot center of the range
            plot(ds.TrialNumber, ds.RangeCenter,'linewidth',3,'color',MEDIUM_GREEN);
            plot(ds.TrialNumber, ds.RangeCenter-ds.Range,'linewidth',1,'color',MEDIUM_GREEN);
            plot(ds.TrialNumber, ds.RangeCenter+ds.Range,'linewidth',1,'color',MEDIUM_GREEN);
%             plot(ds.TrialNumber, ds.Bin30SVV,'linewidth',3,'color',[.3 .5 .8]);
%             plot(ds.TrialNumber, ds.Bin100SVV,'linewidth',3,'color',[.8 .3 .5]);

SVV = [];
T = [];
                    for j=1:15;
                        idx = (50:100) + (j-1)*50;
                        idx(idx>=length(ds.Bin100SVV)) = [];
                        if ( length(idx) > 20)
                            SVV(j) = nanmean(ds.Bin100SVV(idx));
                            T(j) = nanmean(ds.Torsion(idx));
                        end
                    end
            SVV(:,[2 12 15]) = nan;
            T(:,[2 12 15]) = nan;
            
            
            legend({'Answered tilted to the right', 'Answered tilted to the left'},'fontsize',16)
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
            
            s.Subject = cell(length(sessions),1);
            s.SessionNumber = (1:length(sessions))';
            s.TMS = zeros(length(sessions),1);
            s.Pre = zeros(length(sessions),1);
            for i=1:length(sessions)
                s.Subject{i} = sessions(i).subjectCode;
                if ( strfind(sessions(i).sessionCode, 'Sham') )
                    s.TMS(i) = 0;
                elseif ( strfind(sessions(i).sessionCode, 'TMS6') )
                    s.TMS(i) = 6;
                elseif ( strfind(sessions(i).sessionCode, 'TMS5') )
                    s.TMS(i) = 5;
                elseif ( strfind(sessions(i).sessionCode, 'TMS4') )
                    s.TMS(i) = 4;
                elseif ( strfind(sessions(i).sessionCode, 'TMS3') )
                    s.TMS(i) = 3;
                elseif ( strfind(sessions(i).sessionCode, 'TMS2') )
                    s.TMS(i) = 2;
                elseif ( ~isempty(strfind(sessions(i).sessionCode, 'TMS1')) || ~isempty(strfind(sessions(i).sessionCode, 'TMS') ))
                    s.TMS(i) = 1;
                end
                if ( strfind(sessions(i).sessionCode, 'Pre') )
                    s.Pre(i) = 1;
                end
            end

            ds = struct2dataset(s);
            
            subjects = unique(ds.Subject);
            figure
            for i=1:length(subjects)
                subplot(2,length(subjects),i,'nextplot','add');
                d = ds(strcmp(ds.Subject,subjects{i}),:);
                for j=1:size(d,1)
                    data = sessions(d.SessionNumber(j)).trialDataSet;
                    plot(sgolayfilt(data.Bin100SVV,1,31), 'linewidth',2)
                end
                set(gca,'xlim',[0 500],'ylim',[-20 20])
                title(subjects{i});
                if ( i==1)
                    xlabel('Trial number');
                    ylabel('SVV');
                end
                
                subplot(2,length(subjects),i+length(subjects),'nextplot','add');
                d = ds(strcmp(ds.Subject,subjects{i}),:);
                for j=1:size(d,1)
                    data = sessions(d.SessionNumber(j)).trialDataSet;
                    plot(sgolayfilt(data.Bin100SVVth,1,31), 'linewidth',2)
                end
                set(gca,'xlim',[0 500],'ylim',[0 10])
                title(subjects{i});
                if ( i==1)
                    xlabel('Trial number');
                    ylabel('SVV threshold');
                end
            end
            
            
            PreSVV = nan(length(subjects), 10);
            figure
            for i=1:length(subjects)
                subplot(1,length(subjects),i,'nextplot','add');
                d = ds(strcmp(ds.Subject,subjects{i}),:);
                for j=1:size(d,1)
                    data = sessions(d.SessionNumber(j)).trialDataSet;
                    plot(sgolayfilt(data.Bin100Torsion,1,31), 'linewidth',2)
                    if ( d.Pre(j) == 1 )
                        PreSVV(i,j) = nanmean(data.Bin100SVV(1:250));
                    end
                end
                set(gca,'xlim',[0 500],'ylim',[-20 20])
                title(subjects{i});
                if ( i==1)
                    xlabel('Trial number');
                    ylabel('Torsion');
                end
            end
            
            Rows = max(ds.TMS);
            
            firstplot = 0;
            figure
            allData = {};
            allDataSham = {};
            allDataTMS = {};
            allDataT = {};
            for i=1:length(subjects)
                for j=1:Rows
                    if ( sum(strcmp(ds.Subject,subjects{i}) & ds.TMS == j ) >0 )
                        d = ds(strcmp(ds.Subject,subjects{i}) & ds.TMS == 0 & ds.Pre == 1 ,:);
                        shamdataPre = sessions(d.SessionNumber(1)).trialDataSet;
                        d = ds(strcmp(ds.Subject,subjects{i}) & ds.TMS == 0 & ds.Pre == 0 ,:);
                        shamdataPost = sessions(d.SessionNumber(1)).trialDataSet;
                        d = ds(strcmp(ds.Subject,subjects{i}) & ds.TMS == j & ds.Pre == 1 ,:);
                        tmsdataPre = sessions(d.SessionNumber(1)).trialDataSet;
                        d = ds(strcmp(ds.Subject,subjects{i}) & ds.TMS == j & ds.Pre == 0 ,:);
                        tmsdataPost = sessions(d.SessionNumber(1)).trialDataSet;
                        
                        subplot(Rows, length(subjects), i + (j-1)*length(subjects),'nextplot','add');
                        
                        plot(shamdataPost.Bin100SVV-nanmedian(shamdataPre.Bin100SVV(1:299)  ), 'linewidth',2)
                        plot(tmsdataPost.Bin100SVV-nanmedian(tmsdataPre.Bin100SVV(1:299)), 'linewidth',2)
%                         plot(shamdataPost.Bin100SVV(1:299)-(shamdataPre.Bin100SVV(1:299)  ))
%                         plot(tmsdataPost.Bin100SVV(1:299)-(tmsdataPre.Bin100SVV(1:299)))
                        

                        allData{j,i} = (tmsdataPost.Bin100SVV(1:490)-nanmedian(tmsdataPre.Bin100SVV(1:290))) - (shamdataPost.Bin100SVV(1:490)-nanmedian(shamdataPre.Bin100SVV(1:290)));
                        allDataSham{j,i} = (shamdataPost.Bin100SVV(1:490)-nanmedian(shamdataPre.Bin100SVV(1:290)));
                        allDataTMS{j,i} = (tmsdataPost.Bin100SVV(1:490)-nanmedian(tmsdataPre.Bin100SVV(1:290)));
                        allDataT{j,i} = (tmsdataPost.Bin100Torsion(1:490)-nanmedian(tmsdataPre.Bin100Torsion(1:290))) - (shamdataPost.Bin100Torsion(1:490)-nanmedian(shamdataPre.Bin100Torsion(1:290)));
                        
                        if( j == 1)
                            title(subjects{i})
                        end
                        
                        if ( firstplot == 0 )
                            firstplot = 1;
                            
                            legend({'Sham', 'TMS'})

                            xlabel('Trial number');
                            ylabel('SVV');
                        end
                        set(gca,'ylim',[-10 10])
                    end
                end
            end
            
            
%             firstplot = 0;
%             figure
%             allData = {};
%             allDataT = {};
%             for i=1:length(subjects)
%                 subjects{i}
%                 for j=1:Rows
%                     if ( sum(strcmp(ds.Subject,subjects{i}) & ds.TMS == j ) >0 )
%                         d = ds(strcmp(ds.Subject,subjects{i}) & ds.TMS == 0 & ds.Pre == 1 ,:);
%                         shamdataPre = sessions(d.SessionNumber(1)).trialDataSet;
%                         d = ds(strcmp(ds.Subject,subjects{i}) & ds.TMS == 0 & ds.Pre == 0 ,:);
%                         shamdataPost = sessions(d.SessionNumber(1)).trialDataSet;
%                         d = ds(strcmp(ds.Subject,subjects{i}) & ds.TMS == j & ds.Pre == 1 ,:);
%                         tmsdataPre = sessions(d.SessionNumber(1)).trialDataSet;
%                         d = ds(strcmp(ds.Subject,subjects{i}) & ds.TMS == j & ds.Pre == 0 ,:);
%                         tmsdataPost = sessions(d.SessionNumber(1)).trialDataSet;
%                         
%                         subplot(Rows, length(subjects), i + (j-1)*length(subjects),'nextplot','add');
%                         
%                         plot(shamdataPost.Bin100Torsion-nanmedian(shamdataPre.Bin100Torsion(1:299)  ), 'linewidth',2)
%                         plot(tmsdataPost.Bin100Torsion-nanmedian(tmsdataPre.Bin100Torsion(1:299)), 'linewidth',2)
% %                         plot(shamdataPost.Bin100SVV(1:299)-(shamdataPre.Bin100SVV(1:299)  ))
% %                         plot(tmsdataPost.Bin100SVV(1:299)-(tmsdataPre.Bin100SVV(1:299)))
%                         
%                         for jj=j:Rows
% %                             allData{jj,i} = (tmsdataPost.Bin100SVV(1:299)-(tmsdataPre.Bin100SVV(1:299))) - (shamdataPost.Bin100SVV(1:299)-(shamdataPre.Bin100SVV(1:299)));
%                             allData{jj,i} = (tmsdataPost.Bin100SVV(1:499)-nanmedian(tmsdataPre.Bin100SVV(1:299))) - (shamdataPost.Bin100SVV(1:499)-nanmedian(shamdataPre.Bin100SVV(1:299)));
%                             allDataT{jj,i} = (tmsdataPost.Bin100Torsion(1:499)-nanmedian(tmsdataPre.Torsion(1:299))) - (shamdataPost.Bin100Torsion(1:499)-nanmedian(shamdataPre.Torsion(1:299)));
%                         end
%                         
%                         if( j == 1)
%                             title(subjects{i})
%                         end
%                         
%                         if ( firstplot == 0 )
%                             firstplot = 1;
%                             
%                             legend({'Sham', 'TMS'})
% 
%                             xlabel('Trial number');
%                             ylabel('Torsion');
%                         end
%                         set(gca,'ylim',[-10 10])
%                     end
%                 end
%             end
            
            figure
            for i=1:Rows
                subplot(Rows,1,i)
                m = nanmean(cell2mat(allData(i,:))');
                s = nanstd(cell2mat(allData(i,:))');
                s = s./sqrt(sum(~isnan((cell2mat(allData(i,:))))'));
                
                svvtime = cell2mat(allData(i,:));
                mm = nanmean(svvtime(1:end,:));
                [h p] = ttest(mm);
                
                set(gca,'xlim',[0 500],'ylim',[-5 5])
                errorbar(m,s);
                set(gca,'xlim',[0 500],'ylim',[-5 5])
                line([0 500],[0 0],'color','k');
                xlabel('Trial number');
                ylabel('TMS-sham SVV (deg');
                text(500,0,['p-value = ' num2str(p)]);
            end
            
                        Selection.AY = 6;
                        Selection.BV = 1;
                        Selection.DO = 3;
                        Selection.HN = 5;
                        Selection.US = 2;
                        Selection.WD = 2;
                        Selection.AM = 2;
                        Selection.KC = 2;
                        Selection.ED = 2;
                        Selection.FA = 2;
                        Selection.DC = 3;
                        Selection.MU = 2;
            
%             Selection.AY = 1;
%             Selection.BV = 1;
%             Selection.DO = 1;
%             Selection.HN = 1;
%             Selection.US = 1;
%             Selection.WD = 1;
%             Selection.AM = 1;
%             Selection.KC = 1;
%             Selection.ED = 1;
            
            allDataSelected =  {};
            allDataSelectedSham =  {};
            allDataSelectedTMS =  {};
            for i=1:length(subjects)
                idx = Selection.(subjects{i});
                allDataSelected{1,i} = allData{idx,i};
                
                allDataSelectedSham{1,i} = nan(50,1);
                allDataSelectedTMS{1,i} = nan(50,1);
                for iTrial = 1:50
                    trialIdx = (1:10) + 10*(iTrial-1);
                    allDataSelectedSham{1,i}(iTrial) = nanmean(allDataSham{idx,i}(trialIdx(trialIdx<length(allDataSham{idx,i}))));
                    allDataSelectedTMS{1,i}(iTrial) = nanmean(allDataTMS{idx,i}(trialIdx(trialIdx<length(allDataTMS{idx,i}))));
                end
            end
            %%
            
            clear SelectionBARS
                        SelectionBARS.AY = [1 2 3 4     5 6];
                        SelectionBARS.BV = [1 2         3 4];
                        SelectionBARS.HN = [1 2         3 5];
                        SelectionBARS.DC = [1           2 3];
                        SelectionBARS.DO = [1           2 3];
                        SelectionBARS.ED = [3           1 2];
                        SelectionBARS.KC = [3           1 2];
                        SelectionBARS.AM = [3           1 2];
                        SelectionBARS.US = [3           1 2];
                        SelectionBARS.FA = [            1 2];
                        SelectionBARS.MU = [            1 2];
                        SelectionBARS.WD = [            1 2];
                        
%                         subjects = fieldnames(SelectionBARS)
                        IDX = 1:490;
            figure
            for i=1:length(subjects)
                subplot(2,length(subjects)/2,i,'nextplot','add')
                for k=1:length(SelectionBARS.(subjects{i}))-2
                    j = SelectionBARS.(subjects{i})(k);
                    effect = nanmean(allDataTMS{j,i}(IDX)) - nanmean(allDataSham{j,i}(IDX));
                    b = bar(k, effect); 
                    set(b,'facecolor',[1 0.7 0.3])
                end
                
                    j = SelectionBARS.(subjects{i})(end-1);
                    effect = nanmean(allDataTMS{j,i}(IDX)) - nanmean(allDataSham{j,i}(IDX));
                    b = bar(length(SelectionBARS.(subjects{i}))-1, effect); 
                    set(b,'facecolor',[1 0.7 0.3])
                            set(b,'facecolor','r')
%                             
%                     j = SelectionBARS.(subjects{i})(end);
%                     effect = nanmean(allDataTMS{j,i}(IDX)) - nanmean(allDataSham{j,i}(IDX));
%                     b = bar(length(SelectionBARS.(subjects{i})), effect); 
%                     set(b,'facecolor',[1 0.7 0.3])
%                             set(b,'facecolor','r')
                            
                set(gca,'xlim',[0 7],'ylim',[-5 10])
                set(gca,'xtick',[])
                set(gcf,'color','w')
                title(subjects{i})
            end
            
            %%
            figure
            for ii=1:length(subjects)
                
                s = fieldnames(SelectionBARS);
                i = find( strcmp(subjects,s{ii}));
                
                k = 1;
                j = SelectionBARS.(subjects{i})(end);
                subplot(6, length(subjects), ii + (k-1)*length(subjects),'nextplot','add');
                title(subjects{i})
                plot(allDataSham{j,i}(IDX), 'linewidth',2)
                plot(allDataTMS{j,i}(IDX), 'linewidth',2,'color','r')
                xlabel(' ');
                ylabel(' ');
                set(gca,'ylim',[-10 10])
                
                k = 2;
                j = SelectionBARS.(subjects{i})(end-1);
                subplot(6, length(subjects), ii + (k-1)*length(subjects),'nextplot','add');
                plot(allDataSham{j,i}(IDX), 'linewidth',2)
                plot(allDataTMS{j,i}(IDX), 'linewidth',2,'color','r')
                xlabel(' ');
                ylabel(' ');
                set(gca,'ylim',[-10 10])
                
                
                for k=1:length(SelectionBARS.(subjects{i}))-2
                    
                    subplot(6, length(subjects), ii + (k+1)*length(subjects),'nextplot','add');
                    
                    j = SelectionBARS.(subjects{i})(k);
                    plot(allDataSham{j,i}(IDX), 'linewidth',2)
                    plot(allDataTMS{j,i}(IDX), 'linewidth',2,'color',[1 0.7 0.3])
                xlabel(' ');
                ylabel(' ');
                set(gca,'ylim',[-10 10])
                end
                
                
%                 set(gca,'xlim',[0 7],'ylim',[-5 10])
%                 set(gca,'xtick',[])
                set(gcf,'color','w')
            end
            
            
            %%
            figure
            
            m = nanmean(cell2mat(allDataSelected(1,:))');
            s = nanstd(cell2mat(allDataSelected(1,:))');
            s = s./sqrt(sum(~isnan((cell2mat(allDataSelected(1,:))))'));
            
            svvtime = cell2mat(allDataSelected(1,:));
            mm = nanmean(svvtime(1:end,:))
            [h p] = ttest(mm);
            
            set(gca,'xlim',[0 500],'ylim',[-5 5])
            errorbar(m,s);
            set(gca,'xlim',[0 500],'ylim',[-5 5])
            line([0 500],[0 0],'color','k');
            xlabel('Trial number');
            ylabel('TMS-sham SVV (deg');
            text(500,0,['p-value = ' num2str(p)]);
            
            
            %%%
            
            figure
            m = nanmean(cell2mat(allDataSelectedSham(1,:))');
            s = nanstd(cell2mat(allDataSelectedSham(1,:))');
            sSham = s./sqrt(sum(~isnan((cell2mat(allDataSelectedSham(1,:))))'));
            
            svvtime = cell2mat(allDataSelectedSham(1,:));
            mmSham = nanmean(svvtime(1:end,:)')
            
            
            m = nanmean(cell2mat(allDataSelectedTMS(1,:))');
            s = nanstd(cell2mat(allDataSelectedTMS(1,:))');
            sTMS = s./sqrt(sum(~isnan((cell2mat(allDataSelectedTMS(1,:))))'));
            
            svvtime = cell2mat(allDataSelectedTMS(1,:));
            mmTMS = nanmean(svvtime(1:end,:)')
            
            
            errorbar((1:50)*10 ,mmSham,sSham);
            hold
            e = errorbar((1:50)*10 ,mmTMS,sTMS);
            set(e,'color','red')
            set(gca,'xlim',[0 500],'ylim',[-5 5])
            xlabel('Trial number');
            ylabel('SVV - baseline (deg)');
            
            
            %%
            figure
            for i=1:Rows
                subplot(Rows,1,i)
                m = nanmean(cell2mat(allData(i,:))');
                s = nanstd(cell2mat(allData(i,:))');
                s = s./sqrt(sum(~isnan((cell2mat(allData(i,:))))'));
                
                svvtime = cell2mat(allData(i,:));
                mm = nanmean(svvtime);
                [h p] = ttest(mm);
                bar(mm)
                hold
                errorbar(7,mean(mm),std(mm)/sqrt(6),'linewidth',3,'color','k')
                bar(7,mean(mm));
                text(0,3.5,['p-value = ' num2str(p)]);
            end
            
            %%
            
%             figure
%             for i=1:Rows
%                 subplot(Rows,1,i)
%                 m = nanmean(cell2mat(allDataT(i,:))');
%                 s = nanstd(cell2mat(allDataT(i,:))');
%                 s = s./sqrt(sum(~isnan((cell2mat(allDataT(i,:))))'));
%                 
%                 svvtime = cell2mat(allDataT(i,:));
%                 mm = nanmean(svvtime(200:end,:));
%                 [h p] = ttest(mm);
%                 
%                 set(gca,'xlim',[0 500],'ylim',[-5 5])
%                 errorbar(m,s);
%                 set(gca,'xlim',[0 500],'ylim',[-5 5])
%                 line([0 500],[0 0],'color','k');
%                 xlabel('Trial number');
%                 ylabel('TMS-sham Torsion (deg');
%                 text(500,0,['p-value = ' num2str(p)]);
%                 
%             end
            
        end
        
        function trialDataSet = PrepareTrialDataSet( this, ds)
            data = ds;
            if ( data.TimeStopTrial(end) == 0)
                data(end,:) = [];
            end
            
            torsionFolder = 'F:\DATATEMP\SVVTorsionTMS';
            T = nan(size(data.TimeStartTrial));
            
            if (length(dir(fullfile(torsionFolder,[this.Session.name  '*']))) == 1);
                folders = dir(fullfile(torsionFolder,[this.Session.name  '*']));
                d = GetCalibratedData(fullfile(torsionFolder,folders(1).name));
                T = CleanTorsion(d);
                T(T>10 | T<-10) = nan;

                
                
                t = data.TimeStartTrial;
                t2 = data.TimeStopTrial;
                t2 = t2-t(1);
                t = t-t(1);
%                 t(101:end)= t(101:end)-t(101)+t2(100);
%                 t2(101:end)= t2(101:end)-t(101)+t2(100);
                
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
            
            
                T(T>10 | T<-10) = nan;
            newData.Torsion = T;
            
            
            
            binSize = 30;
            stepSize = 10;
            
            newData.Bin30SVV = nan(size(data,1),1);
            newData.Bin30SVVth = nan(size(data,1),1);
            newData.Bin30Start = nan(size(data,1),1);
            newData.Bin30End = nan(size(data,1),1);
            newData.Bin30Torsion = nan(size(data,1),1);
            for j=1:ceil(size(data,1)/stepSize)
                idx = (1:binSize) + (j-1)*stepSize;
                idx(idx<1 | idx>size(data,1)) = [];
                if ( length(idx) >= 20 )
                    angles = data.Angle(idx);
                    responses = data.Response(idx);
                    [SVV1, a, p, allAngles, allResponses, trialCounts, SVVth1] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, responses);
                    
                    saveidx = floor(mean(idx) - stepSize/2 + (1:stepSize));
                    saveidx(saveidx<1 | saveidx>size(data,1)) = [];
                    
                    newData.Bin30SVV(saveidx) = SVV1;
                    newData.Bin30SVVth(saveidx) = SVVth1;
                    newData.Bin30Start(saveidx) = min(idx);
                    newData.Bin30End(saveidx) = max(idx);
                    newData.Bin30Torsion(saveidx) = nanmedian(T(idx));
                end
            end
            
            
            binSize = 100;
            stepSize = 10;
            f = binSize/stepSize;
            
            newData.Bin100SVV = nan(size(data,1),1);
            newData.Bin100SVVth = nan(size(data,1),1);
            newData.Bin100Start = nan(size(data,1),1);
            newData.Bin100End = nan(size(data,1),1);
            newData.Bin100Torsion = nan(size(data,1),1);
            for j=1:ceil(size(data,1)/stepSize)
                idx = (1:binSize) + (j-1)*stepSize;
                idx(idx<1 | idx>size(data,1)) = [];
                if ( length(idx) >= 20 )
                    angles = data.Angle(idx);
                    responses = data.Response(idx);
                    [SVV1, a, p, allAngles, allResponses, trialCounts, SVVth1] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, responses);
                    
                    
                    saveidx = floor(mean(idx) - stepSize/2 + (1:stepSize));
                    saveidx(saveidx<1 | saveidx>size(data,1)) = [];
                    
                    newData.Bin100SVV(saveidx) = SVV1;
                    newData.Bin100SVVth(saveidx) = SVVth1;
                    newData.Bin100Start(saveidx) = min(idx);
                    newData.Bin100End(saveidx) = max(idx);
                    newData.Bin100Torsion(saveidx) = nanmedian(T(idx));
                end
            end
            
            
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

