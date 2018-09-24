classdef MVS < ArumeCore.ExperimentDesign & ArumeExperimentDesigns.EyeTracking
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function optionsDlg = GetAnalysisOptionsDialog(this)
            optionsDlg = GetAnalysisOptionsDialog@ArumeExperimentDesigns.EyeTracking(this);
        end
        
        function [analysisResults, samplesDataTable, trialDataTable, sessionTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable,sessionTable, options)

            [analysisResults, samplesDataTable, trialDataTable, sessionTable] = RunDataAnalyses@ArumeExperimentDesigns.EyeTracking(this, analysisResults, samplesDataTable, trialDataTable,sessionTable, options);
            
            analysisResults.SPV = table();
            
            LRdataVars = {'X' 'Y' 'T'};
            
            for i=1:length(LRdataVars)
                samplesDataTable.(LRdataVars{i}) = mean([samplesDataTable.(['Left' LRdataVars{i}]),samplesDataTable.(['Right' LRdataVars{i}])],2);
            end
            
            T = samplesDataTable.Properties.UserData.sampleRate;
            analysisResults.SPV.Time = samplesDataTable.Time(T/2:T:end);
            fields = {'X' 'Y' 'T' 'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'};
            
            for j =1:length(fields)
                x = samplesDataTable.(fields{j});
                v = diff(x)*500;
                v1 = diff(samplesDataTable.RightX)*500;
                qp = boxcar(abs(v1)>50,10)>0;
                v(qp) = nan;
                analysisResults.SPV.(fields{j}) = nan(length(analysisResults.SPV.Time),1);
                analysisResults.SPV.([fields{j} 'Pos']) = nan(length(analysisResults.SPV.Time),1);
                for i=1:length(analysisResults.SPV.Time)
                    idx = (1:T) + (i-1)*T-T/2;
                    idx(idx>length(v) | idx<1) = [];
                    
                    vchunk = v(idx);
                    xchunk = x(idx);
                    if( nanstd(vchunk) < 20)
                        analysisResults.SPV.(fields{j})(i) =  nanmedian(vchunk);
                        analysisResults.SPV.([fields{j} 'Pos'])(i) =  nanmedian(xchunk);
                    end
                end
            end
            
            sessionTable.BaselineStartSec = this.ExperimentOptions.Events.EnterMagnet*60 - 30;
            sessionTable.BaselineStopSec = this.ExperimentOptions.Events.EnterMagnet*60 - 10;
            
            sessionTable.PeakStartSec = this.ExperimentOptions.Events.EnterMagnet*60 + 30;
            sessionTable.PeakStopSec = this.ExperimentOptions.Events.EnterMagnet*60 + 50;
            
            sessionTable.PeakAfterEffectStartSec = this.ExperimentOptions.Events.ExitMagnet*60 + 50;
            sessionTable.PeakAfterEffectStopSec = this.ExperimentOptions.Events.ExitMagnet*60 + 70;
            
            sessionTable.AfterEffectStartSec = this.ExperimentOptions.Events.ExitMagnet*60 + 50;
            if ( this.ExperimentOptions.Events.Finish < 20)
                sessionTable.AfterEffectStopSec = this.ExperimentOptions.Events.ExitMagnet*60 + 3*60;
            sessionTable.BeforeExitStartSec = this.ExperimentOptions.Events.ExitMagnet*60 - 10;
                sessionTable.BeforeExitStopSec = this.ExperimentOptions.Events.ExitMagnet*60;
            else
                sessionTable.AfterEffectStopSec = this.ExperimentOptions.Events.ExitMagnet*60 + 7*60;
                sessionTable.BeforeExitStartSec = this.ExperimentOptions.Events.ExitMagnet*60 - 30;
                sessionTable.BeforeExitStopSec = this.ExperimentOptions.Events.ExitMagnet*60;
            end
            
            periods = {'Baseline', 'Peak', 'PeakAfterEffect' 'AfterEffect' 'BeforeExit'};
                  
            if ( isfield( this.ExperimentOptions.Events, 'LightsOn' ) )
                sessionTable.AfterLightsONStartSec = this.ExperimentOptions.Events.LightsOn*60 + 20;
                sessionTable.AfterLightsONStopSec = this.ExperimentOptions.Events.LightsOn*60 + 80;

                sessionTable.BeforeLightsOFFStartSec = this.ExperimentOptions.Events.LightsOff*60 - 80;
                sessionTable.BeforeLightsOFFStopSec = this.ExperimentOptions.Events.LightsOn*60 -20;
                
                periods = {periods{:} 'AfterLightsON' 'BeforeLightsOFF'};
            end
            
            if ( isfield( this.ExperimentOptions.Events, 'StartHeadMov' ) )
                
                sessionTable.AfterStartHeadMovingStartSec = this.ExperimentOptions.Events.LightsOn*60 + 20;
                sessionTable.AfterStartHeadMovingStopSec = this.ExperimentOptions.Events.LightsOn*60 + 80;

                sessionTable.BeforeStopHeadMovingStartSec = this.ExperimentOptions.Events.LightsOff*60 - 80;
                sessionTable.BeforeStopHeadMovingStopSec = this.ExperimentOptions.Events.LightsOn*60 -20;
                
                periods = {periods{:} 'AfterStartHeadMoving' 'BeforeStopHeadMoving'};
            end
            
            
            for j =1:length(fields)
                x = analysisResults.SPV.(fields{j});
                for i=1:length(periods)
                    if ( ~isnan(sessionTable.([periods{i} 'StartSec'])))
                        idx = sessionTable.([periods{i} 'StartSec']):sessionTable.([periods{i} 'StopSec']);
                        sessionTable.(['SPV_' fields{j} '_' periods{i}]) = nanmedian(x(idx));
                    else
                        sessionTable.(['SPV_' fields{j} '_' periods{i}]) = nan;
                    end
                end
            end
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function Plot_MVS_SPV_Trace(this)
            if ( ~isfield(this.Session.analysisResults, 'SPV' ) )
                error( 'Need to run analysis SPV before ploting SPV');
            end
            
            t = this.Session.analysisResults.SPV.Time;
            vxl = this.Session.analysisResults.SPV.LeftX;
            vxr = this.Session.analysisResults.SPV.RightX;
            vyl = this.Session.analysisResults.SPV.LeftY;
            vyr = this.Session.analysisResults.SPV.RightY;
            vtl = this.Session.analysisResults.SPV.LeftT;
            vtr = this.Session.analysisResults.SPV.RightT;
            
            %%
            figure
            subplot(3,1,1,'nextplot','add')
            grid
            plot(t,vxl,'o')
            plot(t,vxr,'o')
            ylabel('Horizontal (deg/s)')
            subplot(3,1,2,'nextplot','add')
            grid
            set(gca,'ylim',[-20 20])
            plot(t,vyl,'o')
            plot(t,vyr,'o')
            ylabel('Vertical (deg/s)')
            subplot(3,1,3,'nextplot','add')
            set(gca,'ylim',[-20 20])
            plot(t,vtl,'o')
            plot(t,vtr,'o')
            ylabel('Torsional (deg/s)')
            grid
            set(gca,'ylim',[-20 20])
            xlabel('Time (s)');
            linkaxes(get(gcf,'children'))
            
        end
        
        
        function Plot_MVS_SPVH_Trace(this)
            if ( ~isfield(this.Session.analysisResults, 'SPV' ) )
                error( ['Need to run analysis SPV before ploting SPV. Session: ' this.Session.name]);
            end
            
            t = this.Session.analysisResults.SPV.Time/60;
            vxl = this.Session.analysisResults.SPV.LeftX;
            vxr = this.Session.analysisResults.SPV.RightX;
            
            
            %%
            figure('name', [this.Session.subjectCode '  ' this.Session.sessionCode]);
            grid
            plot(t,nanmean([vxl vxr],2),'o')
            set(gca,'nextplot','add');
            % make the y axis symmetrical around 0 and a multiple of 10
            set(gca,'ylim',[-1 1]*10*ceil(max(abs(get(gca,'ylim')))/10));
            ylabel('Horizontal (deg/s)')
            xlabel('Time (min)');
            
            if ( isfield(this.Session.experimentDesign.ExperimentOptions, 'Events') ...
                    && isstruct(this.Session.experimentDesign.ExperimentOptions.Events) )
                events = struct2array(this.Session.experimentDesign.ExperimentOptions.Events);
                for i=1:length(events)
                    line([1 1]*events(i), get(gca,'ylim'),'linestyle','--','color',0.7*[1 1 1]);
                end
                
                periods = {'Baseline', 'Peak', 'PeakAfterEffect' 'AfterEffect' 'BeforeExit' 'AfterLightsON' 'BeforeLightsOFF'};
                
                for i=1:length(periods)
                    time = this.Session.sessionDataTable.([periods{i} 'StartSec']):this.Session.sessionDataTable.([periods{i} 'StopSec']);
                    value = ones(size(time))*this.Session.sessionDataTable.(['SPV_' 'X' '_' periods{i}]);
                    plot(time/60,value,'o','color','r','linewidth',2);
                end
            end
            
            
        end
        
        function PlotAggregate_MVS_SPV_Trace_combined(this, sessions)
            
            s = table();
            s.Subject = cell(length(sessions),1);
            s.SessionCode = cell(length(sessions),1);
            s.SessionObj = sessions';
            for i=1:length(sessions)
                s.Subject{i} = sessions(i).subjectCode;
                s.SessionCode{i} = sessions(i).sessionCode ;
            end
            s = sortrows(s,'SessionCode');
            %%
            figure('color','w')
            subjects = unique(s.Subject);
            for i=1:length(subjects)
                subplot(length(subjects),1, i,'nextplot','add');
                ss = s(strcmp(s.Subject,subjects{i}),:);
                for j=1:height(ss)
                    t = ss.SessionObj(j).analysisResults.SPV.Time;
                    vxl = ss.SessionObj(j).analysisResults.SPV.LeftX;
                    vxr = ss.SessionObj(j).analysisResults.SPV.RightX;
                    spv = nanmean([vxl vxr],2);
                    if (~isempty(strfind(ss.SessionCode{j},'HeadMoving') ) )
                        spv(t>180 & t<405) = nan;
                    end
                    plot(t,spv,'.','markersize',10);
                end
                line(get(gca,'xlim'),[0 0],'color',[0.5 0.5 0.5],'linestyle','-.')
                legend(strrep(ss.SessionCode,'_',' '));
                title(subjects{i});
                xlabel('Time (s)');
                ylabel('SPV (deg/s)');
            end
        end
        
%         function Plot_PlotPositionWithHead(this)
%             VOG.PlotPositionWithHead(this.Session.samplesDataSet, this.Session.rawDataSet);
%         end
%         function Plot_PlotVelocityWithHead(this)
%             VOG.PlotVelocityWithHead(this.Session.samplesDataSet, this.Session.rawDataSet);
%         end
%         
%         function Plot_PlotSPVFeetAndHead(this)
%             
%             t1 = this.Session.analysisResults.SPV.Time;
%             vxl = this.Session.analysisResults.SPV.LeftX;
%             vxl2 = interp1(find(~isnan(vxl)),vxl(~isnan(vxl)),1:1:length(vxl));
%             vxr = this.Session.analysisResults.SPV.RightX;
%             vxr2 = interp1(find(~isnan(vxr)),vxr(~isnan(vxr)),1:1:length(vxr));
%             vx1 = nanmean([vxl2;vxr2]);
%             
%             %$ TODO fix the finding session
%             control = this.Project.findSession('MVSNystagmusSuppression',this.ExperimentOptions.AssociatedControl);
%             
%             t2 = control.analysisResults.SPV.Time;
%             vxl = control.analysisResults.SPV.LeftX;
%             vxl2 = interp1(find(~isnan(vxl)),vxl(~isnan(vxl)),1:1:length(vxl));
%             vxr = control.analysisResults.SPV.RightX;
%             vxr2 = interp1(find(~isnan(vxr)),vxr(~isnan(vxr)),1:1:length(vxr));
%             vx2 = nanmean([vxl2;vxr2]);
%             
%             events =  fields(this.ExperimentOptions.Events);
%             eventTimes = zeros(size(events));
%             for i=1:length(events)
%                 eventTimes(i) = this.ExperimentOptions.Events.(events{i});
%             end
%             
%             if ( strfind(this.Session.sessionCode,'Head')>0)
%                 if ( isfield( this.ExperimentOptions.Events, 'StartMoving' ) )
%                     tstartMoving = this.ExperimentOptions.Events.StartMoving*60;
%                     tstopMoving = this.ExperimentOptions.Events.StopMoving*60;
%                 else
%                     tstartMoving = this.ExperimentOptions.Events.LightsOn*60;
%                     tstopMoving = this.ExperimentOptions.Events.LightsOff*60;
%                 end
%                 vx1(tstartMoving:tstopMoving) = nan;
%             end
%             
%             figure
%             plot(t1/60, vx1,'.');
%             hold
%             plot(t2/60, vx2,'.');
%             title([this.Session.subjectCode ' ' this.Session.sessionCode])
%             
%             ylim = [-50 50];
%             xlim = [0 max(eventTimes)];
%             set(gca,'ylim',ylim,'xlim',xlim);
%             
%             for i=1:length(events)
%                 line(eventTimes(i)*[1 1], ylim,'color',[0.5 0.5 0.5]);
%                 text( eventTimes(i), ylim(2)-mod(i,2)*5-5, events{i});
%             end
%             line(xlim, [0 0],'color',[0.5 0.5 0.5])
%         end
        
    end
    
end

