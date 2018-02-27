classdef ReboundNystagmus < ArumeCore.ExperimentDesign
    
    properties
    end
    
    
    methods( Access = public)
        
        %% ImportSession
        function [] = ImportSession( this )
            data = GetCalibratedData();
            
            trialStartIdx = [];
            trialEndIdx = [];
            condition = [];
            Saccade1Idx = [];
            Saccade2Idx = [];
            
            
            trialDataSet = [];
            sampleDataSet = data;
        end
    end
    
    methods (Access=protected)
        % Gets the options that be set in the UI when creating a new
        % session of this experiment (in structdlg format)
        % Some common options will be added
        function dlg = GetOptionsDialog( this )
            dlg.DataFile = { {'uigetfile(''*.txt'')'} };
            dlg.CalibrationFile = { {'uigetfile(''*.cal'')'} };
            dlg.Condition = {{'{SaccadeFlashing}','SaccadeFlashingShort','SaccadeContinuos','Pursuit','StepSaccades'}};
            dlg.OrderNumber = 1;
            dlg.WhichSideFirst = { {'{Right}', 'Left'} };
            dlg.TargetEccentricity = 40;
            dlg.InitialFixationDuration = 10;
            dlg.AwayFromFixationDuration = 30;
            dlg.PursuitDuration = 10;
            dlg.NumberOfSteps = 10;
            dlg.BreakBetweenLeftAndRight = 0;
        end
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        
        function plotResults = Plot_EyeTraces(this)
            
            data = this.Session.samplesDataSet;
            trials= this.Session.trialDataSet;
            
            t = nan(size(data.Time))';
            for i=1:length(trials)
                idx = trials.StartTrialSample(i):trials.StartEccentricSample(i);
                t(idx) =10;
                idx = trials.StartEccentricSample(i):trials.StartReboundSample(i);
                t(idx) =20;
                idx = trials.StartReboundSample(i):trials.EndTrialSample(i);
                t(idx) =30;
                idx = trials.StartTrialSample(i):(trials.StartEccentricSample(i)-2500);
                t(idx) =0;
            end
            
            figure
            time = data.Time/1000;
            
            data.LeftX(t==0) = nan;
            data.RightX(t==0) = nan;
            
            subplot(1,1,1,'nextplot','add')
            plot(time, data.LeftX)
            plot(time, data.RightX)
            plot(time,t);
            ylabel('Horizontal (deg)','fontsize', 16);
            title(this.ExperimentOptions.Condition); 
            
%             subplot(3,1,2,'nextplot','add')
%             plot(time, data.LeftY)
%             plot(time, data.RightY)
%             plot(time,t);
%             ylabel('Vertical (deg)','fontsize', 16);
%             
%             subplot(3,1,3,'nextplot','add')
%             plot(time, data.LeftT)
%             plot(time, data.RightT)
%             plot(time,t);
%             ylabel('Torsion (deg)','fontsize', 16);
            xlabel('Time (s)');

        end
        
        function plotResults = PlotAggregate_PlotAUC(this, sessions)
            
            s.Subject = cell(length(sessions),1);
            s.SessionNumber = (1:length(sessions))';
            s.Condition = nan(length(sessions),1);
            s.OrderNumber = nan(length(sessions),1);
            s.LeftFirst = nan(length(sessions),1);
            for i=1:length(sessions)
                s.Subject{i} = sessions(i).subjectCode;
                s.Condition(i) = str2num(sessions(i).sessionCode(2:end));
                s.LeftFirst(i) = strcmp(sessions(i).experiment.ExperimentOptions.WhichSideFirst,'Left');
            end

            ds = struct2dataset(s);
            
            subjects = unique(ds.Subject);
            AUC = nan(length(subjects),4,10);
            AUCecc = nan(length(subjects),4,10);
            SPV = cell(length(subjects),4);
            for i=1:length(subjects)
                subjects(i)
                for kk=1:4
                    if ( kk>1)
                        k = kk+1;
                    else
                        k = kk;
                    end
                    d = ds(strcmp(ds.Subject,subjects{i}) & ds.Condition==k,:);
                    if ( length(d) > 0 )
                        trials = sessions(d.SessionNumber(1)).trialDataSet;
                        [lspv rspv lspvt rspvt] = this.GetSlowPhaseVelocities(sessions(d.SessionNumber(1)).samplesDataSet);
                        for j=1:10
                            
                            idx = find(lspvt>trials.StartReboundSample(j) & lspvt<trials.StartReboundSample(j)+15*500);
                            lspvFixt{j} = lspvt(idx)- trials.StartReboundSample(j) ;
                            lspvFix{j} = lspv(idx);
                            x = lspvFixt{j};
                            y = lspvFix{j};
                            if ( sum(~isnan(y)) >= 5 )
                                lauc = nansum(diff(x).*(y(1:end-1)+y(2:end))/2)/(max(x)-min(x));
                            else
                                lauc = nan;
                            end
                            
                            
                            idx = find(rspvt>trials.StartReboundSample(j) & rspvt<trials.StartReboundSample(j)+15*500);
                            rspvFixt{j} = rspvt(idx) - trials.StartReboundSample(j) ;
                            rspvFix{j} = rspv(idx);
                            x = rspvFixt{j};
                            y = rspvFix{j};
                            if ( sum(~isnan(y)) >= 5 )
                                rauc = nansum(diff(x).*(y(1:end-1)+y(2:end))/2)/(max(x)-min(x));
                            else
                                rauc = nan;
                            end
                            
                            if ( strcmp(subjects{i},'GK') )
                                jj = mod(j+4,10)+1;
                                AUC(i,kk,jj) = nanmean([lauc rauc]);
                            else
                                AUC(i,kk,j) = nanmean([lauc rauc]);
                            end
                            
                        end
                        
                        %%
                        tbins = 0:0.5:15;
                        spvsubj = nan(10, length(tbins)-2);
                        for j=1:10
                            spvt = [lspvFixt{j}/500;rspvFixt{j}/500;];
                            spvv = [lspvFix{j};rspvFix{j}];
                            for tt=1:length(tbins)-2
                                idx = spvt>tbins(tt) & spvt<tbins(tt+2);
                                
                                jj = j;
                                if ( strcmp(subjects{i},'GK') )
                                    jj = mod(j+4,10)+1;
                                end
                                
                                if ( jj>5)
                                    spvsubj(jj,tt) = -nanmedian(spvv(idx));
                                else
                                    spvsubj(jj,tt) = nanmedian(spvv(idx));
                                end
                            end
                        end
                        SPV{i,kk} = nanmedian(spvsubj);
                        
                        %% ECCENTRIC SPV
                        for j=1:10
                             
                            idx = find(lspvt>trials.StartEccentricSample(j)+10*500 & lspvt<trials.StartEccentricSample(j)+20*500);
                            lspvFixt{j} = lspvt(idx) - trials.StartReboundSample(j) ;
                            lspvFix{j} = lspv(idx);
                            x = lspvFixt{j};
                            y = lspvFix{j};
                            if ( sum(~isnan(y)) >= 5 )
                                lauc = nansum(diff(x).*(y(1:end-1)+y(2:end))/2)/(max(x)-min(x));
                            else
                                lauc = nan;
                            end
                            
                            
                            idx = find(rspvt>trials.StartEccentricSample(j)+10*500 & rspvt<trials.StartEccentricSample(j)+20*500);
                            rspvFixt{j} = rspvt(idx) - trials.StartReboundSample(j) ;
                            rspvFix{j} = rspv(idx);
                            x = rspvFixt{j};
                            y = rspvFix{j};
                            if ( sum(~isnan(y)) >= 5 )
                                rauc = nansum(diff(x).*(y(1:end-1)+y(2:end))/2)/(max(x)-min(x));
                            else
                                rauc = nan;
                            end
                            
                            if ( strcmp(subjects{i},'GK') )
                                jj = mod(j+4,10)+1;
                                AUCecc(i,kk,jj) = nanmean([lauc rauc]);
                            else
                                AUCecc(i,kk,j) = nanmean([lauc rauc]);
                            end
                        end
                        
                        %%
                        
                        
                    end
                end
            end
            %%
            tbins = 0:0.5:15;
            m1 = mean(cell2mat(SPV(:,1)));
            m2 = mean(cell2mat(SPV(:,2)));
            m3 = mean(cell2mat(SPV(:,3)));
            m4 = mean(cell2mat(SPV(:,4)));
            ss1 = std(cell2mat(SPV(:,1)))/sqrt(6);
            ss2 = std(cell2mat(SPV(:,2)))/sqrt(6);
            ss3 = std(cell2mat(SPV(:,3)))/sqrt(6);
            ss4 = std(cell2mat(SPV(:,4)))/sqrt(6);
            
            figure('color','w','position', [116         446        1490         420])
            
            subplot(1,8,[1:2],'nextplot','add','fontsize',14);
            errorbar(tbins(2:end-1),m1,ss1,'linewidth',2);
            errorbar(tbins(2:end-1),m2,ss2,'linewidth',2);
            set(gca,'ylim',[-1 6],'xlim',[0 15])
            xlabel('Time after returning to center (s)')
            ylabel('Slow-phase velocity (deg/s)');
            legend({'Flashing target' 'Continuos target'},'box','off');
               
            amp = [];
            tau = [];
            for i=1:6
                subplot(1,8,i+2,'nextplot','add')
                for j=1:2
                    plot(tbins(2:end-1), SPV{i,j},'-o');
                end
                for j=1:2
                    x = tbins(2:end-1)';
                    y =SPV{i,j}';
                    f = fit(x,y,'exp1','StartPoint',[5,5], 'Lower',[0 -1],'upper',[10 -0.05]);
                    plot(x,f(x),'color',[0.5 0.5 0.5])
                    
                    c = coeffvalues(f);
                    tau(i,j) = -1/c(2);
                    amp(i,j) = c(1);
                end
                set(gca,'ylim',[-1 6],'xlim',[0 15],'xticklabel',[],'yticklabel',[]);
                title(sprintf('S%d',i));
                legend({sprintf('\\tau = %0.2f',tau(i,1)), sprintf('\\tau = %0.2f',tau(i,2))},'box','off');
            end
            
            figure('color','w','position', [116         456        1490         420])
            subplot(1,8,[1:2],'nextplot','add')
            errorbar(tbins(2:end-1),m1,ss1,'linewidth',2);
            errorbar(tbins(2:end-1),m3,ss3,'linewidth',2);
            errorbar(tbins(2:end-1),m4,ss4,'linewidth',2);
            set(gca,'ylim',[-1 6],'xlim',[0 15],'fontsize',14);
            xlabel('Time after returning to center (s)')
            ylabel('Slow-phase velocity (deg/s)');
            legend({'Single saccade' 'Smooth pursuit' 'Step saccades'},'box','off');
            
            for i=1:6
                subplot(1,8,i+2,'nextplot','add')
                for j=[1 3 4]
                    plot(tbins(2:end-1),SPV{i,j},'-o');
                end
                for j=[1 3 4]
                    x = tbins(2:end-1)';
                    y =SPV{i,j}';
                    f = fit(x,y,'exp1','StartPoint',[5,5], 'Lower',[0 -1],'upper',[10 -0.05]);
                    plot(x,f(x),'color',[0.5 0.5 0.5])
                    
                    c = coeffvalues(f);
                    tau(i,j) = -1/c(2);
                    amp(i,j) = c(1);
                end
                set(gca,'ylim',[-1 6],'xlim',[0 15],'xticklabel',[],'yticklabel',[]);
                title(sprintf('S%d',i));
                legend({sprintf('\\tau = %0.2f',tau(i,1)), sprintf('\\tau = %0.2f',tau(i,3)), sprintf('\\tau = %0.2f',tau(i,4))},'box','off');
            end
            
            %%
            
            figure
            plot(AUCecc(:),AUC(:),'o')
            
            figure
            for i=1:length(subjects)
                subplot(2,length(subjects)/2,i);
                bar(squeeze(AUC(i,:,:))','LineStyle','none');
                set(gca,'ylim',[-10 10])
                set(gca,'xlim',[0 11])
                title(subjects{i})
                xlabel('Trial');
                ylabel('Avg SPV');
            end
            
            figure
            for i=1:length(subjects)
                subplot(2,length(subjects)/2,i);
                bar(squeeze(AUCecc(i,:,:))','LineStyle','none');
                set(gca,'ylim',[-10 10])
                set(gca,'xlim',[0 11])
                title(subjects{i})
                xlabel('Trial');
                ylabel('Avg SPV');
            end
            %%
            figure
            subplot(1,2,1,'fontsize',14);
            m = squeeze(nanmedian(AUC(:,:,:),1))';
            s = squeeze(nanstd(AUC(:,:,:),1))';
            errorbar(m(1:5,:),s(1:5,:)./sqrt(squeeze(sum(~isnan((AUC(:,:,1:5))),1))'),'linewidth',2);
            hold
            errorbar(m(6:10,:),s(6:10,:)./sqrt(squeeze(sum(~isnan((AUC(:,:,6:10))),1))'),'linewidth',2);
%             legend({'F1' 'F3' 'F4' 'F5' 'F1' 'F3' 'F4' 'F5'})
%                 title('Average')
                xlabel('Trial');
                ylabel('Avg SPV');
                set(gca,'ylim',[-10 10])
                
            subplot(1,2,2,'fontsize',14);
            AUCr = (AUC(:,:,1:5) - AUC(:,:,6:10))/2;
            m = squeeze(nanmedian(AUCr(:,:,:),1))';
            s = squeeze(nanstd(AUCr(:,:,:),1))';
            errorbar(m,s./sqrt(squeeze(sum(~isnan((AUCr(:,:,:))),1))'),'linewidth',2);
            legend({'Single saccade (flashing)' 'Single saccade (continuos)' 'Smooth pursuit' 'Step saccades'},'box','off');
%                 title('Average')
                xlabel('Trial');
                ylabel('Avg SPV');
                set(gca,'ylim',[0 3])
                
                
                figure
                AUCr2 = squeeze(mean(AUCr,2));
            m = squeeze(nanmedian(AUCr2,1))';
            s = squeeze(nanstd(AUCr2,1))';
            errorbar(m,s./sqrt(squeeze(sum(~isnan((AUCr2)),1))'),'linewidth',2);
            legend({'Single saccade (flashing)' 'Single saccade (continuos)' 'Smooth pursuit' 'Step saccades'},'box','off');
%                 title('Average')
                xlabel('Trial');
                ylabel('Avg SPV');
                set(gca,'ylim',[0 3])
                %%
                
            figure
            subplot(1,2,1,'fontsize',14);
            m = squeeze(nanmean(AUCecc(:,:,:),1))';
            s = squeeze(nanstd(AUCecc(:,:,:),1))';
            errorbar(m(1:5,:),s(1:5,:)./sqrt(squeeze(sum(~isnan((AUCecc(:,:,1:5))),1))'),'linewidth',2);
            hold
            errorbar(m(6:10,:),s(6:10,:)./sqrt(squeeze(sum(~isnan((AUCecc(:,:,6:10))),1))'),'linewidth',2);
            legend({'F1' 'F3' 'F4' 'F5' 'F1' 'F3' 'F4' 'F5'})
                title('Average')
                xlabel('Trial');
                ylabel('Avg SPV');
                set(gca,'ylim',[-10 10])
                
            subplot(1,2,2,'fontsize',14);
            AUCeccr = (-AUCecc(:,:,1:5) + AUCecc(:,:,6:10))/2;
            m = squeeze(nanmean(AUCeccr(:,:,:),1))';
            s = squeeze(nanstd(AUCeccr(:,:,:),1))';
            errorbar(m,s./sqrt(squeeze(sum(~isnan((AUCeccr(:,:,:))),1))'),'linewidth',2);
            legend({'Single saccade (flashing)' 'Single saccade (continuos)' 'Smooth pursuit' 'Step saccades'},'box','off');
                title('Average')
                xlabel('Trial');
                ylabel('Avg SPV');
                set(gca,'ylim',[-1 5])
                
                figure
                
                AUCeccr2 = squeeze(mean(AUCeccr,2));
            m = squeeze(nanmedian(AUCeccr2,1))';
            s = squeeze(nanstd(AUCeccr2,1))';
            errorbar(m,s./sqrt(squeeze(sum(~isnan((AUCeccr2)),1))'),'linewidth',2);
            legend({'Single saccade (flashing)' 'Single saccade (continuos)' 'Smooth pursuit' 'Step saccades'},'box','off');
%                 title('Average')
                xlabel('Trial');
                ylabel('Avg SPV');
                set(gca,'ylim',[0 3])
        end
        
        
        function plotResults = Plot_SlowPhaseTracesBaseline(this)
            t = this.Session.samplesDataSet.Time/1000;
            lx = this.Session.samplesDataSet.LeftX;
            lxx= lx;
            ls = (abs(boxcar(diff(lx),10)*500)>10);
            lx(boxcar(ls,5)>0) = nan;
            
            rx = this.Session.samplesDataSet.RightX;
            rxx= rx;
            rs = (abs(boxcar(diff(rx),10)*500)>10);
            rx(boxcar(ls,5)>0) = nan;
            
            [lspv rspv lspvt rspvt] = this.GetSlowPhaseVelocities(this.Session.samplesDataSet);
            
            trials = this.Session.trialDataSet;
            
            lspvFix = {};
            lspvtFix = {};
            for i=1:size(trials,1)
                idx = find(lspvt>(trials.StartEccentricSample(i)-4*500) & lspvt<trials.StartEccentricSample(i));
                lspvFixt{i} = lspvt(idx);
                lspvFix{i} = lspv(idx);
                lspvFixt{i} = lspvFixt{i} - (trials.StartEccentricSample(i)-4*500) ;
            end
        
            rspvFix = {};
            rspvtFix = {};
            for i=1:size(trials,1)
                idx = find(rspvt>(trials.StartEccentricSample(i)-4*500) & rspvt<trials.StartEccentricSample(i));
                rspvFixt{i} = rspvt(idx);
                rspvFix{i} = rspv(idx);
                rspvFixt{i} = rspvFixt{i} - (trials.StartEccentricSample(i)-4*500) ;
            end
            
            figure
            for i=1:10
                idx = max((trials.StartEccentricSample(i)-4*500),1):trials.StartEccentricSample(i);
                subplot(2,5,i,'nextplot','add')
                plot(t(idx)-t(idx(1)),lxx(idx));
                plot(t(idx)-t(idx(1)),lx(idx),'r','linewidth',2);
                plot(t(idx)-t(idx(1)),rxx(idx),'k');
                plot(t(idx)-t(idx(1)),rx(idx),'m','linewidth',2);
                set(gca,'ylim',[-5 5])
                set(gca,'xlim',[0 5])
            end
            
            figure
            for i=1:10
                subplot(2,5,i,'nextplot','add')
                grid
                x = lspvFixt{i};
                y = lspvFix{i};
                bad = isnan(x) | isnan(y);
                x(bad) = [];
                y(bad) = [];
                plot(lspvFixt{i}/500, lspvFix{i},'bo')
                plot(rspvFixt{i}/500, rspvFix{i},'ro')
                set(gca,'ylim',[-15 15])
                set(gca,'xlim',[0 5])
            end
            
            figure
            AUC = nan(1,10);
            for i=1:10
                
                x = lspvFixt{i};
                y = lspvFix{i};
                x = x(x<2000);
                y = y(x<2000);
                
                if ( length(x) < 2 )
                    continue;
                end
                lauc = sum(diff(x).*(y(1:end-1)+y(2:end))/2)/(max(x)-min(x));
                
                x = rspvFixt{i};
                y = rspvFix{i};
                x = x(x<2000);
                y = y(x<2000);
                
                if ( length(x) < 2 )
                    continue;
                end
                rauc = sum(diff(x).*(y(1:end-1)+y(2:end))/2)/(max(x)-min(x));

                AUC(i) = (lauc+rauc)/2;
            end
            bar(AUC);
            set(gca,'ylim',[-5 5])
        end
        
        function plotResults = Plot_SlowPhaseTracesRebound(this)
            t = this.Session.samplesDataSet.Time/1000;
            lx = this.Session.samplesDataSet.LeftX;
            lxx= lx;
            ls = (abs(boxcar(diff(lx),10)*500)>10);
            lx(boxcar(ls,5)>0) = nan;
            
            rx = this.Session.samplesDataSet.RightX;
            rxx= rx;
            rs = (abs(boxcar(diff(rx),10)*500)>10);
            rx(boxcar(ls,5)>0) = nan;
            
            [lspv rspv lspvt rspvt] = this.GetSlowPhaseVelocities(this.Session.samplesDataSet);
            
            trials = this.Session.trialDataSet;
            
            lspvFix = {};
            lspvtFix = {};
            for i=1:size(trials,1)
                idx = find(lspvt>trials.StartEccentricSample(i) & lspvt<trials.EndTrialSample(i));
                lspvFixt{i} = lspvt(idx);
                lspvFix{i} = lspv(idx);
                lspvFixt{i} = lspvFixt{i} - trials.StartReboundSample(i) ;
            end
        
            rspvFix = {};
            rspvtFix = {};
            for i=1:size(trials,1)
                idx = find(rspvt>trials.StartEccentricSample(i) & rspvt<trials.EndTrialSample(i));
                rspvFixt{i} = rspvt(idx);
                rspvFix{i} = rspv(idx);
                rspvFixt{i} = rspvFixt{i} - trials.StartReboundSample(i) ;
            end
            
            figure('position',[100 100 1400 600]);
            for i=1:10
                idx = trials.StartReboundSample(i):trials.EndTrialSample(i);
                subplot(2,5,i,'nextplot','add','fontsize',14)
                plot(t(idx)-t(idx(1)),lxx(idx));
                plot(t(idx)-t(idx(1)),lx(idx),'r','linewidth',2);
                plot(t(idx)-t(idx(1)),rxx(idx),'k');
                plot(t(idx)-t(idx(1)),rx(idx),'m','linewidth',2);
                set(gca,'ylim',[-5 5])
                set(gca,'xlim',[0 15])
                if ( i==1)
                    xlabel('Time (s)');
                    ylabel('Horiz. pos. (deg)');
                end
            end
            
            figure('position',[100 100 1400 600]);
            for i=1:10
                subplot(2,5,i,'nextplot','add','fontsize',14)
                grid
                x = lspvFixt{i};
                y = lspvFix{i};
                bad = isnan(x) | isnan(y);
                x(bad) = [];
                y(bad) = [];
                plot(lspvFixt{i}/500, lspvFix{i},'bo')
                plot(rspvFixt{i}/500, rspvFix{i},'ro')
                set(gca,'ylim',[-15 15])
                set(gca,'xlim',[0 15])
                if ( i==1)
                    xlabel('Time (s)');
                    ylabel('spv (deg/s)');
                    legend({'Left','Right'});
                end
            end
            
            
            %%
            figure
            tbins = 0:0.5:15;
            spv = nan(length(tbins)-2,10);
            for j=1:10
                for i=1:length(tbins)-2
                    spvt = [lspvFixt{j}/500;rspvFixt{j}/500;];
                    spvv = [lspvFix{j};rspvFix{j}];
                    idx = spvt>tbins(i) & spvt<tbins(i+2);
                    
                    if ( j>5)
                        spv(i,j) = -nanmedian(spvv(idx));
                    else
                        spv(i,j) = nanmedian(spvv(idx));
                    end
                end
            end
            plot(tbins(2:end-1),nanmedian(spv,2),'o')
            
            %%
%             
%             figure
%             AUC = nan(1,10);
%             for i=1:10
%                 
%                 x = lspvFixt{i};
%                 y = lspvFix{i};
%                 x = x(x<2000);
%                 y = y(x<2000);
%                 
%                 if ( length(x) < 2 )
%                     continue;
%                 end
%                 lauc = sum(diff(x).*(y(1:end-1)+y(2:end))/2)/(max(x)-min(x));
%                 
%                 x = rspvFixt{i};
%                 y = rspvFix{i};
%                 x = x(x<2000);
%                 y = y(x<2000);
%                 
%                 if ( length(x) < 2 )
%                     continue;
%                 end
%                 rauc = sum(diff(x).*(y(1:end-1)+y(2:end))/2)/(max(x)-min(x));
% 
%                 AUC(i) = (lauc+rauc)/2;
%             end
%             bar(AUC);
%             set(gca,'ylim',[-5 5])
        end
                
        function [lspv rspv lspvt rspvt] = GetSlowPhaseVelocities(this, data)
            lx = data.LeftX;
            lxx= lx;
            ls = (abs(boxcar(diff(lx),10)*500)>10);
            lx(boxcar(ls,5)>0) = nan;
            
            T = 50;
            lspv = nan(ceil(length(lx)/T*2),1);
            lspvt = nan(ceil(length(lx)/T*2),1);
            
            for i=1:length(lx)/T*2
                idx = (1:T) + i*T/2;
                if ( max(idx) < length(lx) )
                    %                     if ( sum(isnan(x(idx))) == 0 )
                    %                         Xdata = [ones(length(idx),1) idx'];
                    %                         Ydata = x(idx);
                    %                         b = Xdata\Ydata;
                    %                         spv(i) =  b(2)*100;
                    %                         spvt(i) =  mean(idx);
                    %                     end
                    if( std(diff(lx(idx))*500) < 10 )
                        lspv(i) =  median(diff(lx(idx)))*500;
                        lspvt(i) =  mean(idx);
                    end
                end
            end
            
            rx = data.RightX;
            rxx= rx;
            rs = (abs(boxcar(diff(rx),10)*500)>10);
            rx(boxcar(ls,5)>0) = nan;
            
            T = 50;
            rspv = nan(ceil(length(rx)/T*2),1);
            rspvt = nan(ceil(length(rx)/T*2),1);
            
            for i=1:length(lx)/T*2
                idx = (1:T) + i*T/2;
                if ( max(idx) < length(rx) )
                    %                     if ( sum(isnan(x(idx))) == 0 )
                    %                         Xdata = [ones(length(idx),1) idx'];
                    %                         Ydata = x(idx);
                    %                         b = Xdata\Ydata;
                    %                         spv(i) =  b(2)*100;
                    %                         spvt(i) =  mean(idx);
                    %                     end
                    if( std(diff(rx(idx))*500) < 10 )
                        rspv(i) =  median(diff(rx(idx)))*500;
                        rspvt(i) =  mean(idx);
                    end
                end
            end
        end
        
        function plotResults = PlotAggregate_SlowPhaseVelocity(this, sessions)
            figure
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        function trialDataSet = PrepareTrialDataSet( this, ds)
            trialDataSet = ds;
            data = this.Session.samplesDataSet;
%             s = (abs(boxcar(diff(x),10)*100)>4);
%             x(boxcar(s,5)>0) = nan;
            
            ecc = double(abs(nanmean([data.LeftX data.RightX]')') < 20);
            ecc( isnan(data.LeftX) & isnan(data.RightX) ) = nan;
            
            ecc5 = double(abs(nanmean([data.LeftX data.RightX]')') < 5);
            ecc5( isnan(data.LeftX) & isnan(data.RightX) ) = nan;
            
            fix = ~(boxcar(ecc,2000)<boxcar(1-ecc,2000));
            
            samplerate = 500;
            
            baselineDuration = 5;
            if ( strcmp(this.Session.experiment.ExperimentOptions.Condition, 'SaccadeFlashingShort') )
                awayDuration = 20;
            else
                awayDuration = 30;
            end
            reboundDuration = 15;
            breakDuration = 10;
            trialDuration = baselineDuration + awayDuration + reboundDuration + breakDuration;
            
            expReboundStarts = zeros(10,1);
            expEcc = nan(60*10*500,1);
            for i=1:10
                ts = ((i-1)*60*500);
                
                if ( i>5 )
                    ts = ts + this.Session.experiment.ExperimentOptions.BreakBetweenLeftAndRight*samplerate;
                end
                
                expEcc(ts+(1:baselineDuration*samplerate)) = 1;
                expEcc(ts+(baselineDuration*samplerate:(baselineDuration+awayDuration)*samplerate)) = 0;
                expEcc(ts+((baselineDuration+awayDuration)*500:(baselineDuration+awayDuration+reboundDuration)*samplerate)) = 1;
                
                expReboundStarts(i) = ts + (baselineDuration+awayDuration)*samplerate;
            end
            
            decc = diff(ecc);
            decc(isnan(decc)) = 0;
            dxecc = diff(expEcc);
            dxecc(isnan(dxecc)) = 0;
            
            [x c] = xcorr(boxcar(decc,1000),boxcar(dxecc,1000),20*samplerate);
            [m i] = max(x);
            lag = c(i);
            
            startfix = zeros(10,1);
            for i=1:10
                startfix(i) = find(ecc5(expReboundStarts(i)+lag + (-samplerate:samplerate)), 1,'first')-samplerate+expReboundStarts(i)+lag;
            end
                        
            trials = [];
            for i=1:1:length(startfix)
                trial = [];
                trial.TrialNumber = i;
                trial.Condition = 1;
                trial.StartTrialSample = max(1,startfix(i)-(baselineDuration+awayDuration)*samplerate);
                trial.EndTrialSample =  min(startfix(i)+reboundDuration*samplerate,length(ecc));
                trial.StartEccentricSample = startfix(i)-awayDuration*samplerate;
                trial.StartReboundSample = startfix(i);
                if ( ~isfield( trials, 'TrialNumber') )
                    trials = trial
                else
                    trials(i) = trial;
                end
            end
            
            trialDataSet = struct2dataset(trials');
        end
        
        function data = CleanAndResample(this, data)
            
            f  = data.Framenumber-data.Framenumber(1)+1;
            fidx = find([1;diff(f)>0]);
            
            t  = interp1(f(fidx),data.Time(fidx),  1:max(f));
            lx  = interp1(f(fidx),data.LeftX(fidx),  1:max(f));
            ly  = interp1(f(fidx),data.LeftY(fidx),  1:max(f));
            lt = interp1(f(fidx),data.LeftT(fidx),  1:max(f));
            rx  = interp1(f(fidx),data.RightX(fidx),  1:max(f));
            ry  = interp1(f(fidx),data.RightY(fidx),  1:max(f));
            rt  = interp1(f(fidx),data.RightT(fidx),  1:max(f));
            lel  = interp1(f(fidx),data.LeftUpperLid(fidx),  1:max(f));
            rel  = interp1(f(fidx),data.RightUpperLid(fidx),  1:max(f));
            lp  = interp1(f(fidx),data.LeftPupil(fidx),  1:max(f));
            rp  = interp1(f(fidx),data.RightPupil(fidx),  1:max(f));
            
            data = dataset(t', lx', ly', lt', rx', ry', rt', lel',rel', lp', rp', ...
                'varnames',{'Time' 'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT' 'LeftUpperLid' 'RightUpperLid' 'LeftPupil' 'RightPupil'});
            
            t = zeros(length(data.Time)*5,1);
            t(1:5:end) = data.Time-4;
            t(2:5:end) = data.Time-2;
            t(3:5:end) = data.Time;
            t(4:5:end) = data.Time+2;
            t(5:5:end) = data.Time+4;
            
            t1 = [0;max(diff(t),2)];
            t = cumsum(t1);
            
            
            x = data.LeftX;
            b = abs(x)>50 | [0;diff(x)*100]>1000;
            x = boxcar(x,3);
            x(boxcar(b,10)>0) = nan;
            lx = resample(x,5,1);
            
            x = data.RightX;
            b = abs(x)>50 | [0;diff(x)*100]>1000;
            x = boxcar(x,3);
            x(boxcar(b,10)>0) = nan;
            rx = resample(x,5,1);
            
            x = data.LeftY;
            b = abs(x)>50 | [0;diff(x)*100]>1000;
            x = boxcar(x,3);
            x(boxcar(b,10)>0) = nan;
            ly = resample(x,5,1);
           
            x = data.RightY;
            b = abs(x)>50 | [0;diff(x)*100]>1000;
            x = boxcar(x,3);
            x(boxcar(b,10)>0) = nan;
            ry = resample(x,5,1);
            
            x = data.LeftT;
            b = abs(x)>50 | [0;diff(x)*100]>1000;
            x = boxcar(x,3);
            x(boxcar(b,10)>0) = nan;
            lt = resample(x,5,1);
            
            x = data.RightT;
            b = abs(x)>50 | [0;diff(x)*100]>1000;
            x = boxcar(x,3);
            x(boxcar(b,10)>0) = nan;
            rt = resample(x,5,1);
            
            lel = resample(data.LeftUpperLid,5,1);
            rel = resample(data.RightUpperLid,5,1);
            lp = resample(data.LeftPupil,5,1);
            rp = resample(data.RightPupil,5,1);
            
            data = dataset(t, lx, ly, lt, rx, ry, rt, lel,rel, lp, rp, ...
                'varnames',{'Time' 'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT' 'LeftUpperLid' 'RightUpperLid' 'LeftPupil' 'RightPupil'});
        end
        
        function [xCal offset gain] = Calibrate(this, x)
            
            [xi xc] = kmeans(x,3);
            [zeroabs izero] = min(abs(xc));
            [minval imin] = min(xc);
            [maxval imax] = max(xc);
            
            offset = nanmedian(x(xi==izero));
            gain = 80 / (nanmedian(x(xi==imax)) - nanmedian(x(xi==imin)));
            
            xCal = (x -  offset) * gain;
        end
        
        function sampleDataset = PrepareSamplesDataSet(this, ds)
            ds = GetCalibratedData(this.ExperimentOptions.DataFile, this.ExperimentOptions.CalibrationFile);
            
            sampleDataset = this.CleanAndResample(ds);
            
            [sampleDataset.LeftX offset gain] = Calibrate(this, sampleDataset.LeftX);
            sampleDataset.LeftY = (sampleDataset.LeftY-nanmedian(sampleDataset.LeftY))*gain;
            
            [sampleDataset.RightX offset gain] = Calibrate(this, sampleDataset.RightX);
            sampleDataset.RightY = (sampleDataset.LeftY-nanmedian(sampleDataset.RightY))*gain;
        end
    end
    
    
    methods
        function b = findBlinks(this, data)
%             b = 
        end
    end
end