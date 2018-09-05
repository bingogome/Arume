classdef MVS < ArumeCore.ExperimentDesign & ArumeExperimentDesigns.EyeTracking
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function optionsDlg = GetAnalysisOptionsDialog(this)
            optionsDlg = GetAnalysisOptionsDialog@ArumeExperimentDesigns.EyeTracking(this);
        end
        
        function [analysisResults, samplesDataTable, trialDataTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable, options)

            [analysisResults, samplesDataTable, trialDataTable] = RunDataAnalyses@ArumeExperimentDesigns.EyeTracking(this, analysisResults, samplesDataTable, trialDataTable, options);
            
            analysisResults.SPV = table();
            
            T = samplesDataTable.Properties.UserData.sampleRate;
            analysisResults.SPV.Time = samplesDataTable.Time(T/2:T:end);
            fields = {'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'};
            
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
            
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function Plot_MVS_SPVTrace(this)
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
        
        function Plot_PlotPositionWithHead(this)
            VOG.PlotPositionWithHead(this.Session.samplesDataSet, this.Session.rawDataSet);
        end
        function Plot_PlotVelocityWithHead(this)
            VOG.PlotVelocityWithHead(this.Session.samplesDataSet, this.Session.rawDataSet);
        end
        
        function Plot_PlotSPVFeetAndHead(this)
            
            t1 = this.Session.analysisResults.SPV.Time;
            vxl = this.Session.analysisResults.SPV.LeftX;
            vxl2 = interp1(find(~isnan(vxl)),vxl(~isnan(vxl)),1:1:length(vxl));
            vxr = this.Session.analysisResults.SPV.RightX;
            vxr2 = interp1(find(~isnan(vxr)),vxr(~isnan(vxr)),1:1:length(vxr));
            vx1 = nanmean([vxl2;vxr2]);
            
            %$ TODO fix the finding session
            control = this.Project.findSession('MVSNystagmusSuppression',this.ExperimentOptions.AssociatedControl);
            
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
            
            for i=1:length(events)
                line(eventTimes(i)*[1 1], ylim,'color',[0.5 0.5 0.5]);
                text( eventTimes(i), ylim(2)-mod(i,2)*5-5, events{i});
            end
            line(xlim, [0 0],'color',[0.5 0.5 0.5])
        end
        
    end
    
end

