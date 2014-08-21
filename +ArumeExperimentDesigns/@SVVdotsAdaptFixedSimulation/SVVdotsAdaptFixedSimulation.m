classdef SVVdotsAdaptFixedSimulation < ArumeCore.ExperimentDesign
    %SVVdotsStairCase Summary of this class goes here
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
            dlg.SVV = 0;
            dlg.SVVstd = 1;
        end
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function initExperimentDesign( this  )
            
            % default parameters of any experiment
            this.trialSequence      = 'Random';      % Sequential, Random, Random with repetition, ...
            this.trialAbortAction   = 'Delay';    % Repeat, Delay, Drop
            this.trialsPerSession   = 128;
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 16;
            this.blocksToRun = 1;
            this.blocks = [ struct( 'fromCondition', 1, 'toCondition', 16, 'trialsToRun', 16) ];
        end
        
        function initBeforeRunning( this )

        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'AnglePercentRange';
            conditionVars(i).values = ([-100:100/4:100-100/8]+100/8);
            
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
            
            NtrialPerBlock = 16;
            
            Ranges = [90 45 16 8 8 8 8 8 8 8 8 8 8 8 8 8 8 8 8 8 8 8 8 ];
            
            % recalculate every 10 trials
            N = mod(length(previousValues),NtrialPerBlock);
            Nblocks = ceil(length(previousValues)/NtrialPerBlock);
            
            if ( length(previousValues)>0 )
                if ( N == 0 )
                    ds = dataset;
                    ds.Response = previousResponses(1:end);
                    ds.Angle = previousValues(1:end);
                    subds = ds;
                    
                    SVV = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);

                    this.currentCenterRange = SVV;            

                    this.currentRange = Ranges(Nblocks);
                end
            else
                this.currentCenterRange = (rand(1)*2-1)*Ranges(1)/NtrialPerBlock*4;
                this.currentRange = 90;
            end
            
            this.currentAngle = (variables.AnglePercentRange/100*this.currentRange) + this.currentCenterRange;
            this.currentAngle = mod(this.currentAngle+90,180)-90;
            
            this.currentAngle = round(this.currentAngle/2)*2;
            trialResult =  Enum.trialResult.CORRECT;
        end
        
        function trialResult = runTrial( this, variables )
            
            try
                this.lastResponse = -1;
                this.reactionTime = -1;
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                                
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
              
                this.currentAngle;
                
                t = 1./(1+exp(-(this.currentAngle-this.ExperimentOptions.SVV)/this.ExperimentOptions.SVVstd));
                
                this.lastResponse = rand(1)>t;
                
            catch ex
                %  this.eyeTracker.StopRecording();
                rethrow(ex)
            end
            
            
            if ( this.lastResponse < 0)
                trialResult =  Enum.trialResult.ABORT;
            end
            
            % this.eyeTracker.StopRecording();
            
        end
        
        function trialOutput = runPostTrial(this)
            trialOutput = [];
            trialOutput.Response = this.lastResponse;
            trialOutput.ReactionTime = this.reactionTime;
            trialOutput.Angle = this.currentAngle;
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
      function plotResults = Plot_ExperimentTimeCourse(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];
            NtrialPerBlock = 10;
            figure
            set(gca,'nextplot','add')
            colors = jet(length(ds)/NtrialPerBlock);
            
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
            plot(ds(ds.Response==0,'TrialNumber'), ds(ds.Response==0,'Angle'),'o','MarkerEdgeColor',[0.3 0.3 0.3],'linewidth',2);
            hold
            plot(ds(ds.Response==1,'TrialNumber'), ds(ds.Response==1,'Angle'),'o','MarkerEdgeColor','r','linewidth',2);
            
            legend({'Ansered tilted to the right', 'Answered tilted to the left'},'fontsize',16)
            legend('boxoff')
            set(gca,'xlim',[-3 103],'ylim',[-90 90])
            ylabel('Angle (deg)', 'fontsize',16);
            xlabel('Trial number', 'fontsize',16);
            set(gca,'ygrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
      end
        
      function plotResults = Plot_Sigmoid(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];

            subds = ds(:,:);
            
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
            
                
           
            figure('position',[400 400 1000 400],'color','w','name',this.Session.name)
            subplot(3,1,[1:2],'nextplot','add', 'fontsize',12);
            
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
            
            
            subplot(3,1,[3],'nextplot','add', 'fontsize',12);
            bar(allAngles, trialCounts, 'edgecolor','none','facecolor',[0.5 0.5 0.5])
                
            set(gca,'xlim',[-30 30],'ylim',[0 15])
            xlabel('Angle (deg)', 'fontsize',16);
            ylabel('Number of trials', 'fontsize',16);
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca, 'YAxisLocation','right')
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
      
      function plotResults = Plot_AmirTest(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            
            ds
      end
        
      function plotResults = PlotAggregate_SigmoidCombined(this, sessions)
          
            ds = this.Session.trialDataSet;
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];

            subds = ds(:,:);
            
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
      end
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
        
        function [SVV, a, p, allAngles, allResponses, trialCounts] = FitAngleResponses( angles, responses)
            ds = dataset;
            ds.Response = responses;
            ds.Angle = angles;

            outliers = find((ds.Response==0 & ds.Angle<-50) | (ds.Response==1 & ds.Angle>50));

            ds(outliers,:) = [];

            modelspec = 'Response ~ Angle';
            mdl = fitglm(ds(:,{'Response', 'Angle'}), modelspec, 'Distribution', 'binomial');

            ds(mdl.Diagnostics.CooksDistance>0.3,:) = [];
            modelspec = 'Response ~ Angle';
            mdl = fitglm(ds(:,{'Response', 'Angle'}), modelspec, 'Distribution', 'binomial');

            angles = ds.Angle;
            responses = ds.Response;

            a = min(angles):0.1:max(angles);
            p = predict(mdl,a')*100;

            [svvr svvidx] = min(abs( p-50));

            SVV = a(svvidx);
            
            allAngles = -90:90;
            allResponses = nan(size(allAngles));
            trialCounts = nan(size(allAngles));
            for ia=1:length(allAngles)
                allResponses(ia) = mean(responses(angles==allAngles(ia))*100);
                trialCounts(ia) = sum(angles==allAngles(ia));
            end
            
        end
    end
end

