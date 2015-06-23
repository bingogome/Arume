classdef TiltOvemps < ArumeCore.ExperimentDesign
    %OPTOKINETICTORSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        bitebar
        eyeTracker
        
        fixRad = 20;
        fixColor = [255 0 0];
        
        tiltTime = 20;
        tiltDuration = 60;
        tiltAngle = 30;
    end
    
    % ---------------------------------------------------------------------
    % Options to set at runtime
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function dlg = GetOptionsDialog( this )
            dlg.FirstLeftEarDown = { {'0','{1}'} };
            dlg.Alternate = { {'{0}','1'} };
            dlg.UseEyeTracker = { {'0','{1}'} };
        end
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function initExperimentDesign( this  )
            
            this.HitKeyBeforeTrial = 1;
            this.DisplayToUse = 'cmdline';
            
            this.trialDuration = 180; %seconds
            
            % default parameters of any experiment
            this.trialSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            this.trialsPerSession = 6;
            
            if ( ~isfield( this.ExperimentOptions, 'Alternate') )
                this.ExperimentOptions.Alternate = 0;
            end
            
            if ( this.ExperimentOptions.Alternate )
                %%-- Blocking
                this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
                this.numberOfTimesRepeatBlockSequence = 3;
                this.blocksToRun = 2;
                if ( this.ExperimentOptions.FirstLeftEarDown )
                    this.blocks =  [ ...
                        struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 1) ...
                        struct( 'fromCondition', 2, 'toCondition', 2, 'trialsToRun', 1) ];
                else
                    this.blocks =  [ ...
                        struct( 'fromCondition', 2, 'toCondition', 2, 'trialsToRun', 1) ...
                        struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 1) ];
                end
            else
                %%-- Blocking
                this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
                this.numberOfTimesRepeatBlockSequence = 1;
                this.blocksToRun = 2;
                if ( this.ExperimentOptions.FirstLeftEarDown )
                    this.blocks =  [ ...
                        struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 3) ...
                        struct( 'fromCondition', 2, 'toCondition', 2, 'trialsToRun', 3) ];
                else
                    this.blocks =  [ ...
                        struct( 'fromCondition', 2, 'toCondition', 2, 'trialsToRun', 3) ...
                        struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', 3) ];
                end
            end
            
        end
        
        function initBeforeRunning( this )
            this.bitebar = ArumeHardware.BiteBarMotor();
                
            if ( this.ExperimentOptions.UseEyeTracker )
               
                this.eyeTracker = ArumeHardware.VOG();
                this.eyeTracker.Connect();
                
                this.eyeTracker.SetSessionName(this.Session.name);
            end
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'TiltDirection';
            conditionVars(i).values = {'Left' 'Right'};
            
            i = i+1;
            conditionVars(i).name   = 'TiltAngle';
            conditionVars(i).values = 30;
        end
        
        function [ randomVars] = getRandomVariables( this )
            randomVars = [];
        end
        
        function trialResult = runPreTrial(this, variables )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            % Add stuff here
            
            trialResult =  Enum.trialResult.CORRECT;
            
           % this.bitebar.GoUpright();
           
            if ( ~isempty(this.eyeTracker) )
                if ( ~this.eyeTracker.IsRecording())
                    this.eyeTracker.StartRecording();
                    pause(1);
                end
            end
        end
        
        function trialResult = runTrial( this, variables )
            
            try                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                
                
                graph = this.Graph;
                
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
                
                lastFlipTime        = GetSecs;
                secondsRemaining    = 140;
                
                startLoopTime = lastFlipTime;
                
                isTilted = 0;
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - startLoopTime;
                    secondsRemaining    = 140 - secondsElapsed;
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
%                     %-- Find the center of the screen
%                     [mx, my] = RectCenter(graph.wRect);
%                     
%                     %-- Draw fixation spot
%                     fixRect = [0 0 5 5];
%                     fixRect = CenterRectOnPointd( fixRect, mx-graph.wRect(3)/4, my );
%                     Screen('FillOval', graph.window, this.fixColor, fixRect);
%                     
%                     if ( secondsElapsed > 1 && secondsElapsed < 1.1 )
%                         %-- Draw target
%                         fixRect = [0 0 7 7];
%                         mx = mx-graph.wRect(3)/4;
%                         switch(variables.Position)
%                             case 'Up'
%                                 fixRect = CenterRectOnPointd( fixRect, mx + this.targetDistance*sin(variables.Angle/180*pi), my + this.targetDistance*cos(variables.Angle/180*pi) );
%                             case 'Down'
%                                 fixRect = CenterRectOnPointd( fixRect, mx + this.targetDistance*sin(variables.Angle/180*pi), my - this.targetDistance*cos(variables.Angle/180*pi) );
%                         end
%                         Screen('FillOval', graph.window, this.targetColor, fixRect);
%                     end
                    
                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------
                    
                    if ( secondsElapsed > this.tiltTime && secondsElapsed < this.tiltTime + this.tiltDuration )
                        if ( ~isTilted ) 
                            disp('Tilt');
                            switch(variables.TiltDirection)
                                case 'Left'
                                       this.bitebar.TiltLeft(this.tiltAngle);
                                case 'Right'
                                       this.bitebar.TiltRight(this.tiltAngle);
                            end
                            isTilted = 1;
                        end
                    end
                    
                    if ( secondsElapsed > this.tiltTime + this.tiltDuration)
                        if ( isTilted ) 
                            this.bitebar.GoUpright();
                            isTilted = 0;
                        end
                    end
                    
                    
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
                if ( ~isempty(this.eyeTracker) )
                    this.eyeTracker.StopRecording();
                end
                rethrow(ex)
            end
            
            
        end
        
        function trialOutput = runPostTrial(this)
            
            if ( ~isempty(this.eyeTracker) )
                this.eyeTracker.StopRecording();
            end
            
            trialOutput = [];   
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
    end
    
    % ---------------------------------------------------------------------
    % Plot methods for individual sessions
    % ---------------------------------------------------------------------
    methods ( Access = public )
        function plotHandles = Plot_TracesRawTorsionHeadVel(this)
            dsTrials =  this.Session.trialDataSet;
            dsSamples =  this.Session.samplesDataSet;
            
            tiltDuration = this.tiltDuration;
            tiltduration = 60;
            
            n = length(dsTrials);
            plotHandles.figure = figure('name',this.Session.name, 'color','w','position',[100 100 1000 800]);
            ax = zeros(n,1);
            for i=1:n
                idx = dsTrials.TrialStartIdx(i):dsTrials.TrialEndIdx(i);
                t = (idx-idx(i))/100;
                ax(i) = subplot(n,1,i);
                plot(t,[dsSamples.LeftTorsion(idx), dsSamples.RightTorsion(idx), boxcar(sgolayfilt(100*[diff(dsSamples.HeadRollTilt(idx));0],1,51),30)]);
                
                title(dsTrials.TiltDirection(i));
            end
            
            set(ax,'ylim',[-10 10])
            linkaxes(ax,'xy');
            
            xlabel('Time (s)');
            ylabel('Torsion (deg) / Head vel. (deg/s)')
            
            legend( {'Left Torsion', 'Right Torsion', 'HeadVelocity'});
            
        end
        
        function plotHandles = Plot_TracesRawVertical(this)
            dsTrials =  this.Session.trialDataSet;
            dsSamples =  this.Session.samplesDataSet;
            
            tiltDuration = this.tiltDuration;
            tiltduration = 60;
            
            n = length(dsTrials);
            plotHandles.figure = figure('name',this.Session.name, 'color','w','position',[100 100 1000 800]);
            ax = zeros(n,1);
            for i=1:n
                idx = dsTrials.TrialStartIdx(i):dsTrials.TrialEndIdx(i);
                t = (idx-idx(i))/100;
                ax(i) = subplot(n,1,i);
                plot(t,[dsSamples.LeftVertical(idx)-nanmean(dsSamples.LeftVertical(idx(1:200))), dsSamples.RightVertical(idx)-nanmean(dsSamples.RightVertical(idx(1:200))), boxcar(sgolayfilt(100*[diff(dsSamples.HeadRollTilt(idx));0],1,51),30)]);
                
                title(dsTrials.TiltDirection(i));
            end
            
            set(ax,'ylim',[-10 10])
            linkaxes(ax,'xy');
            
            xlabel('Time (s)');
            ylabel('Torsion (deg) / Head vel. (deg/s)')
            
            legend( {'Left Torsion', 'Right Torsion', 'HeadVelocity'});
            
        end
    end
    
    % ---------------------------------------------------------------------
    % Plot Aggregate methods
    % ---------------------------------------------------------------------
    methods ( Static = true, Access = public )
        
        function plotHandles = PlotAggregate_TorsionAverageTraces( sessions)
            
            trialDuration = 180;    % seconds
            frameRate = 100;        % frames per second
            totalFrames = trialDuration*frameRate;
            binsize = 300;          % frames
            
            dataLeft = zeros( length(sessions),3,25);
            dataRight = zeros( length(sessions),3,25);
            
            legendNames = {};
            %%
            for i=1: length(sessions)
                legendNames{end+1} = sessions(i).name;
                
                session = sessions(i);
                
                dsTrials =  session.trialDataSet;
                dsSamples =  session.samplesDataSet;
                
                torsion = nanmean([dsSamples.LeftTorsion, dsSamples.RightTorsion]');
                torsion = [dsSamples.LeftTorsion]';
                
                leftEarDownTrials = find(strcmp(dsTrials.TiltDirection,'Left'));
                rightEarDownTrials = find(strcmp(dsTrials.TiltDirection,'Right'));
                
%                 if ( dsTrials.
                
                for j=1:length(leftEarDownTrials)
                    imax = dsTrials.TrialStartIdx(leftEarDownTrials(j));
                    imin = dsTrials.TrialEndIdx(leftEarDownTrials(j));
                    
                    
                    for t=1:binsize:totalFrames
                        idx = imax + t + (1:binsize);
                        if ( max(idx) < length(torsion) )
                            dataLeft(i,j,ceil(t/binsize)) = nanmedian(torsion(idx));
                        end
                    end
                    % fix baseline
                    %dataLeft(i,j,:) = dataLeft(i,j,:) - nanmedian(dataLeft(i,j,5:15));
                    dataLeft(i,j,:) = dataLeft(i,j,:) ;
                end
                
                for j=1:length(rightEarDownTrials)
                    imax = dsTrials.TrialStartIdx(rightEarDownTrials(j));
                    imin = dsTrials.TrialEndIdx(rightEarDownTrials(j));
                    
                    for t=1:binsize:totalFrames
                        idx = imax + t + (1:binsize);
                        if ( max(idx) < length(torsion) )
                            dataRight(i,j,ceil(t/binsize)) = nanmedian(torsion(idx));
                        end
                    end
                    % fix baseline
%                     dataRight(i,j,:) = dataRight(i,j,:) - nanmedian(dataRight(i,j,5:15));
                    dataRight(i,j,:) = dataRight(i,j,:);
                end
            end
            
            %% Traces
            [c colors] = CorrGui.get_nice_colors;
            
            figure('color','w','position',[100 100 1000 500])
            
            subplot(2,1,1,'nextplot','add','fontsize',14)
            
            for i=1:length(sessions)
                plot((1:length(dataLeft))*3,squeeze( dataLeft(i,:,:)),'color',colors(i,:), 'linewidth',1);
            end
            for i=1:length(sessions)
                pretty_errorbar((1:length(dataLeft))*3,nanmean(squeeze( dataLeft(i,:,:))),nanstd(squeeze( dataLeft(i,:,:)))/sqrt(2),'color',colors(i,:), 'linewidth',2);
            end
            line([0 180], [0 0],'color',[0.5 0.5 0.5], 'linewidth',2,'LineStyle','-.')
            line([60 60], [-10 10],'color',[0.5 0.5 0.5], 'linewidth',2,'LineStyle','-.')
            line([120 120], [-10 10],'color',[0.5 0.5 0.5], 'linewidth',2,'LineStyle','-.')
            set(gca,'xlim',[0 180], 'ylim', [-10 10]);
            xlabel('Time (s)');
            ylabel('Torsion (deg)')
            
            subplot(2,1,2,'nextplot','add','fontsize',14)
             for i=1:length(sessions)
                plot((1:length(dataRight))*3,squeeze( dataRight(i,:,:)),'color',colors(i,:), 'linewidth',1);
            end
            for i=1:length(sessions)
                pretty_errorbar((1:length(dataLeft))*3,nanmean(squeeze( dataRight(i,:,:))),nanstd(squeeze( dataRight(i,:,:)))/sqrt(2),'color',colors(i,:), 'linewidth',2);
            end
            line([0 180], [0 0],'color',[0.5 0.5 0.5], 'linewidth',2,'LineStyle','-.')
            line([60 60], [-10 10],'color',[0.5 0.5 0.5], 'linewidth',2,'LineStyle','-.')
            line([120 120], [-10 10],'color',[0.5 0.5 0.5], 'linewidth',2,'LineStyle','-.')
            set(gca,'xlim',[0 180], 'ylim', [-10 10]);
            xlabel('Time (s)');
            ylabel('Torsion (deg)')
            
            assignin('base', 'dataLeft', squeeze(nanmean( dataLeft(:,:,:),2))');
            assignin('base', 'dataRight', squeeze(nanmean( dataRight(:,:,:),2))');
            legend(legendNames)
        end
        
        function plotHandles = PlotAggregate_TorsionNormalizedTraces( sessions)
            
            onsetData = zeros( length(sessions),6,25);
            offsetData = zeros( length(sessions),6,25);
            
            onsetDataNorm = zeros( length(sessions),6,25);
            offsetDataNorm = zeros( length(sessions),6,25);
            
            onsetDataNormLeft = nan( length(sessions),6,25);
            onsetDataNormRight = nan( length(sessions),6,25);
            
            offsetDataNormLeft = nan( length(sessions),6,25);
            offsetDataNormRight = nan( length(sessions),6,25);
            
            headonsetData = zeros( length(sessions),6,25);
            headoffsetData = zeros( length(sessions),6,25);
            %%
            for i=1: length(sessions)
                
                session = sessions(i);
                
                dsTrials =  session.trialDataSet;
                dsSamples =  session.samplesDataSet;
                
                torsion = nanmean([dsSamples.LeftTorsion, dsSamples.RightTorsion]');
                head = dsSamples.HeadRollTilt;
                
                for j=1:6
                    imax = dsTrials.TiltStartIdx(j);
                    imin = dsTrials.TiltEndIdx(j);
                    headtilt = dsTrials.TiltAngle(j);
                    
                    for t=1:25
                        idx = imax+(((t-6)*300):((t-5)*300));
                        onsetData(i,j,t) = nanmedian(torsion(idx));
                        onsetDataNorm(i,j,t) = nanmedian(torsion(idx))/headtilt*100;
                        if ( headtilt > 0 )
                            onsetDataNormLeft(i,j,t) = nanmedian(torsion(idx))/headtilt*100;
                        else
                            onsetDataNormRight(i,j,t) = -nanmedian(torsion(idx))/headtilt*100;
                        end
                        headonsetData(i,j,t) = nanmedian(head(idx));
                        
                        idx = imin+(((t-7)*300):((t-6)*300));
                        if ( max(idx) < length(torsion) )
                            offsetData(i,j,t) = nanmedian(torsion(idx));
                            offsetDataNorm(i,j,t) = nanmedian(torsion(idx))/headtilt*100;
                            headoffsetData(i,j,t) = nanmedian(head(idx));
                            
                            if ( headtilt > 0 )
                                offsetDataNormLeft(i,j,t) = nanmedian(torsion(idx))/headtilt*100;
                            else
                                offsetDataNormRight(i,j,t) = -nanmedian(torsion(idx))/headtilt*100;
                            end
                        end
                    end
                    
                end
            end
            
            
            %% Raw traces with head
            figure('color','w','position',[100 100 1000 500])
            [c colors] = CorrGui.get_nice_colors
            subplot(1,2,1,'nextplot','add','fontsize',14)
            for i=1:length(sessions)
                plot((i*0.2-5+(1:25))*3,squeeze( onsetData(i,:,:))','color',colors(i,:), 'linewidth',2);
                plot((i*0.2-5+(1:25))*3,squeeze( headonsetData(i,:,:))', 'color',colors(i,:));
            end
            
            set(gca,'xlim',[-5 55]);
            xlabel('Time (s)');
            ylabel('Torsion (percentage of head tilt')
            
            subplot(1,2,2,'nextplot','add','fontsize',14)
            hleg = [];
            for i=1:length(sessions)
                h = plot((i*0.2-6+(1:25))*3,squeeze( offsetData(i,:,:))','color',colors(i,:), 'linewidth',2);
                hleg(i) = h(1);
                plot((i*0.2-6+(1:25))*3,squeeze( headoffsetData(i,:,:))','color',colors(i,:));
            end
            
            set(gca,'xlim',[-5 55]);
            legend(hleg,{'AK', 'SS', 'JOM'})
            xlabel('Time (s)');
            ylabel('Torsion (percentage of head tilt')
            
            %% Normalized traces
            figure('color','w','position',[100 100 1000 500])
            [c colors] = CorrGui.get_nice_colors
            subplot(1,2,1,'nextplot','add','fontsize',14)
            for i=1:length(sessions)
                errorbar((i*0.2-6+(1:25))*3,nanmean(squeeze( onsetDataNorm(i,:,:))),nanstd(squeeze( onsetDataNorm(i,:,:)))/sqrt(6),'color',colors(i,:), 'linewidth',2);
            end
            set(gca,'xlim',[-5 55]);
            xlabel('Time (s)');
            ylabel('Torsion (percentage of head tilt')
            
            subplot(1,2,2,'nextplot','add','fontsize',14)
            for i=1:length(sessions)
                errorbar((i*0.2-7+(1:25))*3,nanmean(squeeze( offsetDataNorm(i,:,:))),nanstd(squeeze( onsetDataNorm(i,:,:)))/sqrt(6),'color',colors(i,:), 'linewidth',2);
            end
            
            set(gca,'xlim',[-5 55]);
            legend({'AK', 'SS', 'JOM'})
            xlabel('Time (s)');
            ylabel('Torsion (percentage of head tilt')
            
            
            %% Normalized traces
            figure('color','w','position',[100 100 1000 500])
            [c colors] = CorrGui.get_nice_colors
            subplot(2,2,1,'nextplot','add','fontsize',14)
            for i=1:length(sessions)
                errorbar((i*0.2-6+(1:25))*3,nanmean(squeeze( onsetDataNormLeft(i,:,:))),nanstd(squeeze( onsetDataNormLeft(i,:,:)))/sqrt(6),'color',colors(i,:), 'linewidth',2);
            end
            set(gca,'xlim',[-5 55]);
            xlabel('Time (s)');
            ylabel('Torsion (percentage of head tilt')
            
            subplot(2,2,2,'nextplot','add','fontsize',14)
            for i=1:length(sessions)
                errorbar((i*0.2-7+(1:25))*3,nanmean(squeeze( offsetDataNormLeft(i,:,:))),nanstd(squeeze( onsetDataNormLeft(i,:,:)))/sqrt(6),'color',colors(i,:), 'linewidth',2);
            end
            
            set(gca,'xlim',[-5 55]);
            legend({'AK', 'SS', 'JOM'})
            xlabel('Time (s)');
            ylabel('Torsion (percentage of head tilt')
            
            subplot(2,2,3,'nextplot','add','fontsize',14)
            for i=1:length(sessions)
                errorbar((i*0.2-6+(1:25))*3,nanmean(squeeze( onsetDataNormRight(i,:,:))),nanstd(squeeze( onsetDataNormRight(i,:,:)))/sqrt(6),'color',colors(i,:), 'linewidth',2);
            end
            set(gca,'xlim',[-5 55]);
            xlabel('Time (s)');
            ylabel('Torsion (percentage of head tilt')
            
            subplot(2,2,4,'nextplot','add','fontsize',14)
            for i=1:length(sessions)
                errorbar((i*0.2-7+(1:25))*3,nanmean(squeeze( offsetDataNormRight(i,:,:))),nanstd(squeeze( onsetDataNormRight(i,:,:)))/sqrt(6),'color',colors(i,:), 'linewidth',2);
            end
            
            set(gca,'xlim',[-5 55]);
            legend({'AK', 'SS', 'JOM'})
            xlabel('Time (s)');
            ylabel('Torsion (percentage of head tilt')
        end
    end
    
    % ---------------------------------------------------------------------
    % Other methods
    % ---------------------------------------------------------------------
    methods( Access = public )
        
        function trialDataSet = PrepareTrialDataSet( this, ds)
            if ( exist([this.Session.dataRawPath '\postproc']) )
                path = [this.Session.dataRawPath '\postproc'];
            else
                path = this.Session.dataRawPath;
            end
            pathHead = this.Session.dataRawPath;
            name = this.Session.name;
            
             pathHead = 'N:\RAW_DATA\TorsionVemps\DI20140725';
             path = 'N:\RAW_DATA\TorsionVemps\DI20140725';
            
            samplerate = 100;
            
            d = dir([pathHead '\' name '*.txt']);
            filesHead  = {d.name};
            
            % remove aborts
%             ds = ds(ds.TrialResult==0,:);
            
            ds = ds(1:6,:);
            
            ntrials = length(ds);
            
            ds.TiltAngle = zeros(ntrials,1);
            ds.Direction = cell(ntrials,1);
            ds.TrialRecordingStartIdx = zeros(ntrials,1);
            ds.TrialRecordingEndIdx = zeros(ntrials,1);
            ds.TrialStartIdx = zeros(ntrials,1);
            ds.TrialEndIdx = zeros(ntrials,1);
            ds.TiltStartIdx = zeros(ntrials,1);
            ds.TiltEndIdx = zeros(ntrials,1);
            
            nsamples  = 0;
            for j=1:length(filesHead)
                % load head da  ta
                file = filesHead{j};
                rawdatahead = load([pathHead '\' file]);
                head = asin(min(159, max(-159, rawdatahead(:,16) - 9230.0)) / 160.0) / pi * 180;

                titlStart = this.tiltTime*samplerate;
                tiltEnd = (this.tiltTime+this.tiltDuration)*samplerate;
                
                ds.TrialRecordingStartIdx(j) = nsamples + 1;
                ds.TrialRecordingEndIdx(j) = nsamples + length(head);
                ds.TrialStartIdx(j) = nsamples + max(1, titlStart - 6000);
                ds.TrialEndIdx(j) = nsamples +  min(length(head), tiltEnd + 6000);
                ds.TiltStartIdx(j) = nsamples + titlStart;
                ds.TiltEndIdx(j) = nsamples + tiltEnd;
                
                nsamples = nsamples + length(head);
            end
            
            trialDataSet = ds;
        end
            
        function samplesDataSet = PrepareSamplesDataSet(this, dsTrials)
            if ( exist([this.Session.dataRawPath '\postproc']) )
                path = [this.Session.dataRawPath '\postproc'];
            else
                path = this.Session.dataRawPath;
            end
            pathHead = this.Session.dataRawPath;
            
             pathHead = 'N:\RAW_DATA\TorsionVemps\DI20140725';
             path = 'N:\RAW_DATA\TorsionVemps\DI20140725';
             
            name = this.Session.name;
            
            d = dir([path '\' name '*.txt']);
            
            filesEyeMovements  = {d.name};
            d = dir([pathHead '\' name '*.txt']);
            filesHead  = {d.name};
            
            nsamples  = 0;
            for j=1:length(filesHead)
                % load head da  ta
                file = filesHead{j};
                rawdatahead = load([pathHead '\' file]);
                head = asin(min(159, max(-159, rawdatahead(:,16) - 9230.0)) / 160.0) / pi * 180;
                
                nsamples = nsamples + length(head);
            end
            
            % go through head data to create the samples dataset
            dsSamples = dataset;
            
            dsSamples.TimeStamp = zeros(nsamples,1);
            dsSamples.LeftHorizontal = zeros(nsamples,1);
            dsSamples.LeftVertical = zeros(nsamples,1);
            dsSamples.LeftTorsion = zeros(nsamples,1);
            dsSamples.RightHorizontal = zeros(nsamples,1);
            dsSamples.RightVertical = zeros(nsamples,1);
            dsSamples.RightTorsion = zeros(nsamples,1);
            dsSamples.HeadRollTilt = zeros(nsamples,1);
            
            for j=1:length(filesEyeMovements)
                file = filesHead{j};
                rawdatahead = load([pathHead '\' file]);
                head = asin(min(159, max(-159, rawdatahead(:,16) - 9230.0)) / 160.0) / pi * 180;
                
                file = filesEyeMovements{j};
                rawdata = load([path '\' file]);
                [dat b] = plotData.FixData(rawdata);
                
                qs = [70];
                
                badright = dat(:,18) <qs | b(:,2);
                badleft = dat(:,19) <qs | b(:,1);
                
                dat(boxcar(badleft>0,2)>0,3) = nan;
                dat(boxcar(badleft>0,2)>0,4) = nan;
                dat(boxcar(badleft>0,2)>0,6) = nan;
                dat(boxcar(badright>0,2)>0,7) = nan;
                dat(boxcar(badright>0,2)>0,8) = nan;
                dat(boxcar(badright>0,2)>0,10) = nan;
                                
                sampleIdx = (dsTrials.TrialRecordingStartIdx(j):dsTrials.TrialRecordingEndIdx(j));
                datIdx = 1:length(dat(:,1));
                if (length(sampleIdx) > length(datIdx) )
                    sampleIdx = sampleIdx(1:length(datIdx));
                end
                if (length(datIdx) > length(sampleIdx) )
                    datIdx = datIdx(1:length(sampleIdx));
                end
                
                dsSamples.TimeStamp(sampleIdx) = dat(datIdx,1);
                dsSamples.LeftHorizontal(sampleIdx) = dat(datIdx,3);
                dsSamples.LeftVertical(sampleIdx) = dat(datIdx,4);
                dsSamples.LeftTorsion(sampleIdx) = dat(datIdx,6);
                dsSamples.RightHorizontal(sampleIdx) = dat(datIdx,7);
                dsSamples.RightVertical(sampleIdx) = dat(datIdx,8);
                dsSamples.RightTorsion(sampleIdx) = dat(datIdx,10);
                dsSamples.HeadRollTilt(sampleIdx) = head(datIdx);
                
            end
            
            samplesDataSet = dsSamples;
        end
        
        function [dsTrials, dsSamples] = ImportSession( this )
            %%
            path = 'D:\vemps\postproc';
            pathHead = 'D:\vemps';
            
            isubj = 1;
            filesEyeMovements = {'vempsAmir-2014Feb12-153216-.txt' 'vempsAmir-2014Feb12-153644-.txt' 'vempsAmir-2014Feb12-154205-.txt' 'vempsAmir-2014Feb12-154605-.txt' 'vempsAmir-2014Feb12-155114-.txt' 'vempsAmir-2014Feb12-155601-.txt'};
            filesHead = {'Amir-2014Feb12-153216.txt' 'Amir-2014Feb12-153644.txt' 'Amir-2014Feb12-154205.txt' 'Amir-2014Feb12-154605.txt' 'Amir-2014Feb12-155114.txt' 'Amir-2014Feb12-155601.txt'};
            %
            
            %             isubj = 2;
            %             filesEyeMovements = { 'vempsSave-2014Feb12-161224-.txt' 'vempsSave-2014Feb12-161702-.txt' 'vempsSave-2014Feb12-162146-.txt' 'vempsSave-2014Feb12-162537-.txt' 'vempsSave-2014Feb12-162939-.txt' 'vempsSave-2014Feb12-163324-.txt' };
            %             filesHead = { 'Save-2014Feb12-161224.txt' 'Save-2014Feb12-161702.txt' 'Save-2014Feb12-162146.txt' 'Save-2014Feb12-162537.txt' 'Save-2014Feb12-162939.txt' 'Save-2014Feb12-163324.txt' };
            
            %             isubj = 3;
            %             filesEyeMovements = {'vempsjorge-2014Feb12-164203-.txt' 'vempsjorge-2014Feb12-164642-.txt' 'vempsjorge-2014Feb12-165039-.txt' 'vempsjorge-2014Feb12-165602-.txt' 'vempsjorge-2014Feb12-170002-.txt' 'vempsjorge-2014Feb12-170336-.txt' };
            %             filesHead = {'jorge-2014Feb12-164203.txt' 'jorge-2014Feb12-164642.txt' 'jorge-2014Feb12-165039.txt' 'jorge-2014Feb12-165602.txt' 'jorge-2014Feb12-170002.txt' 'jorge-2014Feb12-170336.txt' };
            
            
            % go through head data to create the trial dataset
            dsTrials = dataset;
            dsTrials.TiltAngle = zeros(6,1);
            dsTrials.Direction = cell(6,1);
            dsTrials.TrialRecordingStartIdx = zeros(6,1);
            dsTrials.TrialRecordingEndIdx = zeros(6,1);
            dsTrials.TrialStartIdx = zeros(6,1);
            dsTrials.TrialEndIdx = zeros(6,1);
            dsTrials.TiltStartIdx = zeros(6,1);
            dsTrials.TiltEndIdx = zeros(6,1);
            
            nsamples  = 0;
            for j=1:length(filesHead)
                % load head da  ta
                file = filesHead{j};
                rawdatahead = load([pathHead '\' file]);
                head = asin(min(159, max(-159, rawdatahead(:,16) - 9230.0)) / 160.0) / pi * 180;
                
                [m titlStart] = max(boxcar(diff(head(1:18000)),100));
                [m tiltEnd] = min(boxcar(diff(head(1:18000)),100));
                
                if ( titlStart > tiltEnd )
                    temp = titlStart;
                    titlStart = tiltEnd;
                    tiltEnd = temp;
                end
                
                dsTrials.TiltAngle(j) = mean(head(titlStart+1000:tiltEnd-1000));
                dirs = {'LeftEarDown' 'RightEarDown' };
                dsTrials.Direction{j} = dirs{(sign(-dsTrials.TiltAngle(j))/2)+1.5};
                
                dsTrials.TrialRecordingStartIdx(j) = nsamples + 1;
                dsTrials.TrialRecordingEndIdx(j) = nsamples + length(head);
                dsTrials.TrialStartIdx(j) = nsamples + max(1, titlStart - 6000);
                dsTrials.TrialEndIdx(j) = nsamples +  min(length(head), tiltEnd + 6000);
                dsTrials.TiltStartIdx(j) = nsamples + titlStart;
                dsTrials.TiltEndIdx(j) = nsamples + tiltEnd;
                
                nsamples = nsamples + length(head);
            end
            
            % go through head data to create the samples dataset
            dsSamples = dataset;
            
            dsSamples.TimeStamp = zeros(nsamples,1);
            dsSamples.LeftHorizontal = zeros(nsamples,1);
            dsSamples.LeftVertical = zeros(nsamples,1);
            dsSamples.LeftTorsion = zeros(nsamples,1);
            dsSamples.RightHorizontal = zeros(nsamples,1);
            dsSamples.RightVertical = zeros(nsamples,1);
            dsSamples.RightTorsion = zeros(nsamples,1);
            dsSamples.HeadRollTilt = zeros(nsamples,1);
            
            for j=1:length(filesEyeMovements)
                
                file = filesHead{j};
                rawdatahead = load([pathHead '\' file]);
                head = asin(min(159, max(-159, rawdatahead(:,16) - 9230.0)) / 160.0) / pi * 180;
                
                file = filesEyeMovements{j};
                rawdata = load([path '\' file]);
                [dat b] = plotData.FixData(rawdata);
                
                qs = [70 68 65];
                
                badright = dat(:,18) <qs(isubj) | b(:,2);
                badleft = dat(:,19) <qs(isubj) | b(:,1);
                
                dat(boxcar(badleft>0,5)>0,3) = nan;
                dat(boxcar(badleft>0,5)>0,4) = nan;
                dat(boxcar(badleft>0,5)>0,6) = nan;
                dat(boxcar(badright>0,5)>0,7) = nan;
                dat(boxcar(badright>0,5)>0,8) = nan;
                dat(boxcar(badright>0,5)>0,10) = nan;
                
                
                if ( isubj == 1 && j == 2 )
                    dat(1:150,:) = [];
                end
                
                sampleIdx = (dsTrials.TrialRecordingStartIdx(j):dsTrials.TrialRecordingEndIdx(j));
                datIdx = 1:length(dat(:,1));
                if (length(sampleIdx) > length(datIdx) )
                    sampleIdx = sampleIdx(1:length(datIdx));
                end
                if (length(datIdx) > length(sampleIdx) )
                    datIdx = datIdx(1:length(sampleIdx));
                end
                
                dsSamples.TimeStamp(sampleIdx) = dat(datIdx,1);
                dsSamples.LeftHorizontal(sampleIdx) = dat(datIdx,3);
                dsSamples.LeftVertical(sampleIdx) = dat(datIdx,4);
                dsSamples.LeftTorsion(sampleIdx) = dat(datIdx,6);
                dsSamples.RightHorizontal(sampleIdx) = dat(datIdx,7);
                dsSamples.RightVertical(sampleIdx) = dat(datIdx,8);
                dsSamples.RightTorsion(sampleIdx) = dat(datIdx,10);
                dsSamples.HeadRollTilt(sampleIdx) = head(datIdx);
                
            end
            
        end
    end
end

function hh = pretty_errorbar(varargin)

herr = errorbar(varargin{:});

hh = get(herr,'children');
x = get(hh(2),'xdata');
w = 0;
x(4:9:end) = x(1:9:end)-w/2;	% Change xdata with respect to ratio
x(7:9:end) = x(1:9:end)-w/2;
x(5:9:end) = x(1:9:end)+w/2;
x(8:9:end) = x(1:9:end)+w/2;
set(hh(2),'xdata',x);


end