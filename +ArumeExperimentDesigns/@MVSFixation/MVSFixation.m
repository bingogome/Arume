classdef MVSFixation < ArumeExperimentDesigns.MVS
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        %        function [samplesDataTable, rawDataTable] = PrepareSamplesDataTable(this)
        %             samplesDataTable= [];
        %             rawDataTable = [];
        %         end
        %         function trialDataTable = PrepareTrialDataTable( this, trialDataTable)
        %         end
        %         function [analysisResults, samplesDataTable, trialDataTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable)
        %         end
        %         function sessionDataTable = PrepareSessionDataTable(this, sessionDataTable)
        %         end
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
                
        function Plot_MVS_SPVwithControl(this)
            
            t1 = this.Session.analysisResults.SPV.Time;
            vxl = this.Session.analysisResults.SPV.LeftX;
            vxl2 = interp1(find(~isnan(vxl)),vxl(~isnan(vxl)),1:1:length(vxl));
            vxr = this.Session.analysisResults.SPV.RightX;
            vxr2 = interp1(find(~isnan(vxr)),vxr(~isnan(vxr)),1:1:length(vxr));
            vx1 = nanmean([vxl2;vxr2]);
            a=Arume;
            control = a.currentProject.findSession(this.Session.subjectCode,this.ExperimentOptions.AssociatedControl);
            
            t2 = control.analysisResults.SPV.Time;
            vxl = control.analysisResults.SPV.LeftX;
            vxl2 = interp1(find(~isnan(vxl)),vxl(~isnan(vxl)),1:1:length(vxl));
            vxr = control.analysisResults.SPV.RightX;
            vxr2 = interp1(find(~isnan(vxr)),vxr(~isnan(vxr)),1:1:length(vxr));
            vx2 = nanmean([vxl2;vxr2]);
            
            events =  fields(this.ExperimentOptions.Events);
            eventTimes = zeros(size(events));
            for i=1:length(events)
                eventTimes(i) = this.ExperimentOptions.Events.(events{i});
            end
            
            if ( strfind(this.Session.sessionCode,'Head')>0)
                if ( isfield( this.ExperimentOptions.Events, 'StartMoving' ) )
                    tstartMoving = this.ExperimentOptions.Events.StartMoving*60;
                    tstopMoving = this.ExperimentOptions.Events.StopMoving*60;
                else
                    tstartMoving = this.ExperimentOptions.Events.LightsOn*60;
                    tstopMoving = this.ExperimentOptions.Events.LightsOff*60;
                end
                vx1(tstartMoving:tstopMoving) = nan;
            end
            
            figure
            plot(t1/60, vx1,'.');
            hold
            plot(t2/60, vx2,'.');
            title([this.Session.subjectCode ' ' this.Session.sessionCode])
            
            ylim = [-50 50];
            xlim = [0 max(eventTimes)];
            set(gca,'ylim',ylim,'xlim',xlim);
            xlabel('Time (min)');
            
            for i=1:length(events)
                line(eventTimes(i)*[1 1], ylim,'color',[0.5 0.5 0.5]);
                text( eventTimes(i), ylim(2)-mod(i,2)*5-5, events{i});
            end
            line(xlim, [0 0],'color',[0.5 0.5 0.5])
        end
        
        
        function Plot_MVS_FixationAverages(this)
            
            experiment = 'MVSNystagmusSuppression';
            longsubjects = {'SP' 'BW' };
            conditions = {'DarkLong' 'LightLong'};
            
            allspvlong = nan(37*60,2,2,3);
            allspvlongraw = nan(37*60,2,2,3);
            for i=1:length(longsubjects)
                for j=1:2
                    for k=1:3
                        subject = longsubjects{i};
                        sessionCode = [conditions{j} num2str(k)];
                        session = this.Project.findSession(subject, sessionCode);
                        if ( isempty(session) )
                            continue;
                        end
                        
                        vxl = session.analysisResults.SPV.LeftX;
                        vxl2 = interp1(find(~isnan(vxl)),vxl(~isnan(vxl)),1:1:length(vxl));
                        vxr = session.analysisResults.SPV.RightX;
                        vxr2 = interp1(find(~isnan(vxr)),vxr(~isnan(vxr)),1:1:length(vxr));
                        spv = nanmean([vxl2;vxr2]);
                        
                        t1 = round(session.experiment.ExperimentOptions.Events.EnterMagnet*60);
                        t2 = round(session.experiment.ExperimentOptions.Events.ExitMagnet*60);
                        disp( sprintf( 'session %s %s t1=%d t2=%d',subject, sessionCode,t1,t2));
                        idxto1 = (t1-2*60+1):(t1+19*60);
                        idxfrom1 = 1:21*60;
                        remidx = find(idxto1<1 | idxto1>length(spv));
                        idxto1(remidx) = [];
                        idxfrom1(remidx) = [];
                        allspvlong(idxfrom1,i,j,k) = spv(idxto1);
                        
                        idxto2 = ((t2-1*60)+1):(t2+15*60);
                        idxfrom2 = ((21*60)+1):37*60;
                        remidx = find(idxto2<1 | idxto2>length(spv));
                        idxto2(remidx) = [];
                        idxfrom2(remidx) = [];
                        allspvlong(idxfrom2,i,j,k) = spv(idxto2);
                        
                        allspvlongraw(1:min(length(spv),37*60),i,j,k) = spv(1:min(length(spv),37*60));
                        
                        allspvlong(:,i,j,k) = allspvlong(:,i,j,k) / abs(mean(allspvlong(160:170,i,j,k)));
                    end
                end
            end
            
            subjects = {'AW' 'SP' 'DS' 'BW' 'MS' };
            conditions = {'Dark' 'Light'};
            
            allspv = zeros(11*60,5,2,2);
            allspvNotNorm = zeros(11*60,5,2,2);
            allspvraw = zeros(11*60,5,2,2);
            for i=1:length(subjects)
                for j=1:2
                    for k=1:2
                        subject = subjects{i};
                        sessionCode = [conditions{j} num2str(k)];
                        session = this.Project.findSession(subject, sessionCode);
                        
                        vxl = session.analysisResults.SPV.LeftX;
                        vxl2 = interp1(find(~isnan(vxl)),vxl(~isnan(vxl)),1:1:length(vxl));
                        vxr = session.analysisResults.SPV.RightX;
                        vxr2 = interp1(find(~isnan(vxr)),vxr(~isnan(vxr)),1:1:length(vxr));
                        spv = nanmean([vxl2;vxr2]);
                        
                        t1 = round(session.experiment.ExperimentOptions.Events.EnterMagnet*60);
                        t2 = round(session.experiment.ExperimentOptions.Events.ExitMagnet*60);
                        disp( sprintf( 'session %s %s t1=%d t2=%d',subject, sessionCode,t1,t2));
                        idxto1 = (t1-2*60+1):(t1+4*60);
                        idxfrom1 = 1:6*60;
                        remidx = find(idxto1<1 | idxto1>length(spv));
                        idxto1(remidx) = [];
                        idxfrom1(remidx) = [];
                        allspv(idxfrom1,i,j,k) = spv(idxto1);
                        
                        idxto2 = ((t2-1*60)+1):(t2+4*60);
                        idxfrom2 = ((6*60)+1):11*60;
                        remidx = find(idxto2<1 | idxto2>length(spv));
                        idxto2(remidx) = [];
                        idxfrom2(remidx) = [];
                        allspv(idxfrom2,i,j,k) = spv(idxto2);
                        
                        allspvraw(1:min(length(spv),11*60),i,j,k) = spv(1:min(length(spv),11*60));
                        
                        allspvNotNorm(:,i,j,k) = allspv(:,i,j,k);
                        allspv(:,i,j,k) = allspv(:,i,j,k) / abs(mean(allspv(160:170,i,j,k)));
                    end
                end
            end
            
            %% Individual sessions
            f = figure('color','w','name','Individual sessions');
            for i=1:length(subjects)
                for j=1:2
                    subplot(5,5,i+5*(j-1));
                    plot((1:11*60)/60,squeeze(allspv(:,i,:,j)),'.')
                    title(['Short ' subjects{i}])
                    xlabel('Time (min)')
                    ylabel('SPV (Normalized)');
                    set(gca,'ylim',[-1.3 1.3])
                end
            end
            cols = [2 4];
            for i=1:length(longsubjects)
                for j=1:3
                    if ( sum(~isnan(squeeze(allspvlong(:,i,:,j)))) == 0 )
                        continue;
                    end
                    subplot(5,5,cols(i)+5*(j+1));
                    plot((1:37*60)/60,squeeze(allspvlong(:,i,:,j)),'.')
                    title(['Long ' longsubjects{i}])
                    xlabel('Time (min)')
                    ylabel('SPV (Normalized)');
                    set(gca,'ylim',[-1.3 1.3])
                end
            end
            pos = f.Position;
            pos(2) = -50;
            pos(3) = pos(3)*2;
            pos(4) = pos(4)*2;
            set(f,'Position',pos);
            
            
            
            %%  individual subjects
            f = figure('color','w','name','Individual subjects');
            for i=1:length(subjects)
                subplot(2,length(subjects),i)
                plot((1:11*60)/60,squeeze(nanmean(allspv(:,i,:,:),4)),'.')
                title(subjects{i})
                xlabel('Time (min)')
                ylabel('SPV (Normalized)');
                set(gca,'ylim',[-1.3 1.3])
            end
            
            
            cols = [2 4];
            for i=1:length(longsubjects)
                subplot(2,length(subjects),cols(i)+5)
                plot((1:37*60)/60,squeeze(nanmean(allspvlong(:,i,:,:),4)),'.')
                title(['Long ' longsubjects{i}])
                xlabel('Time (min)')
                ylabel('SPV (Normalized)');
                set(gca,'ylim',[-1.3 1.3])
            end
            pos = f.Position;
            pos(3) = pos(3)*3;
            set(f,'Position',pos);
            
            
            
            
            %%
            f = figure('color','w','name','Individual sessions by condition');
            for i=1:2
                subplot(2,2,i)
                plot((1:11*60)/60,squeeze(mean(allspvNotNorm(:,:,i,:),4)),'.')
                ylabel('SPV (deg/s)');
                
                subplot(2,2,2+i)
                plot((1:11*60)/60,squeeze(mean(allspv(:,:,i,:),4)),'.')
                ylabel('SPV (Normalized)');
                xlabel('Time (min)')
                set(gca,'ylim',[-1.3 1.3])
            end
            pos = f.Position;
            pos(2) = -50;
            pos(3) = pos(3)*2;
            pos(4) = pos(4)*2;
            set(f,'Position',pos);
            
            %% AVERAGES
            f = figure('color','w','name','Averages');
            subplot(1,3,1)
            plot((1:length(allspv))/60,squeeze(mean(nanmean(allspv,4),2)),'.');
            title('Short Average 5 subjects');
            ylabel('SPV (Normalized)');
            xlabel('Time (min)')
            
            subplot(1,3,2)
            plot((1:length(allspv))/60,squeeze(mean(nanmean(allspv(:,[2 4],:,:),4),2)),'.');
            title('Short Average 2 subjects');
            ylabel('SPV (Normalized)');
            xlabel('Time (min)')
            
            subplot(1,3,3)
            plot((1:length(allspvlong))/60,squeeze(mean(nanmean(allspvlong,4),2)),'.');
            title('Long Average 2 subjects');
            ylabel('SPV (Normalized)');
            xlabel('Time (min)')
            
            pos = f.Position;
            pos(3) = pos(3)*3;
            set(f,'Position',pos);
            
            
            d = squeeze(mean(nanmean(allspv(:,[2 4],:,:),4),2));
            dlong = squeeze(mean(nanmean(allspvlong(:,:,:,:),4),2));
            dlong(dlong(:)<0) = nan;
            figure
            b = [];
            b(1) = nansum(d(450:650,2)-d(450:650,1)) / nansum(d(450:550,1))*100;
            b(2) = nansum(dlong(1350:1550,2)-dlong(1350:1550,1)) / nansum(dlong(1350:1550,1))*100;
            bar(b)
            set(gca,'xticklabel',{'Short' 'Long'},'xlim',[0 3])
            ylabel('% increase in aftereffect');
            
            %%
            figure
            c = [];
            c(1) = nansum(dlong(1350:1550,1))/ nansum(d(450:550,1))/length(1350:1550)*length(450:550)*100;
            c(2) = nansum(dlong(1350:1550,2)-dlong(1350:1550,1))/nansum(d(450:650,2)-d(450:650,1))/length(1350:1550)*length(450:550)*100;
            bar(c)
            set(gca,'xticklabel',{'aftereffect' 'light effect'},'xlim',[0 3])
            ylabel('% increase in aftereffect');
        end
    end
    
    
    
end

