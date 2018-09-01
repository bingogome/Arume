classdef MVS < ArumeCore.ExperimentDesign & ArumeExperimentDesigns.EyeTracking
    
    properties
        
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function dlg = GetOptionsDialog( this, importing )
            if( ~exist( 'importing', 'var' ) )
                importing = 0;
            end
            
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this, importing);
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
%         
%         function trialDataSet = PrepareTrialDataSet( this, ds)
%             % Every class inheriting from SVV2AFC should override this
%             % method and add the proper PresentedAngle and
%             % LeftRightResponse variables
%             
%             trialDataSet = this.PrepareTrialDataSet@ArumeCore.ExperimentDesign(ds);
%             
%             trialDataSet.Condition(1) = 1;
%             trialDataSet.TrialNumber(1) = 1;
%             trialDataSet.TrialResult(1) = 1;
%             trialDataSet.StartTrialSample(1) = 1;
%             trialDataSet.EndTrialSample(1) = size(this.Session.samplesDataSet,1);
%         end
        
        function [eventDataTables, samplesDataTable, trialDataTable]  = PrepareEventDataTables(this, eventDataTables, samplesDataTable, trialDataTable)
            params = VOGAnalysis.GetParameters();
            
            x = { samplesDataTable.LeftX, ...
                samplesDataTable.RightX, ...
                samplesDataTable.LeftY, ...
                samplesDataTable.RightY, ...
                samplesDataTable.LeftT, ...
                samplesDataTable.RightT};
            lx = x{1};
            T = 500;
            t = 1:ceil(length(lx)/T*2);
            spv = {nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1)};
            spvPos = {nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1)};
            
            for j =1:length(x)
                v = diff(x{j})*500;
                v1 = diff(x{2})*500;
                qp = boxcar(abs(v1)>50,10)>0;
                v(qp) = nan;
                for i=1:length(x{j})/T*2
                    idx = (1:T) + (i-1)*T/2;
                    idx(idx>length(v)) = [];
                    
                    vchunk = v(idx);
                    xchunk = x{j}(idx);
                    if( nanstd(vchunk) < 20)
                        spv{j}(i) =  nanmedian(vchunk);
                        spvPos{j}(i) =  nanmedian(xchunk);
                    end
                end
            end
            
            eventDataTables.SPV = table(t', spv{1}, spv{3}, spv{5}, spv{2}, spv{4}, spv{6}, spvPos{1}, spvPos{3}, spvPos{5}, spvPos{2}, spvPos{4}, spvPos{6}, ...
                'VariableNames',{'Time' 'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'  'LeftXPos', 'LeftYPos' 'LeftTPos' 'RightXPos' 'RightYPos' 'RightTPos'});
%             samplesDataTable = VOGAnalysis.DetectQuickPhases(samplesDataTable, params);
%             samplesDataTable = VOGAnalysis.DetectSlowPhases(samplesDataTable, params);
%             [qp, sp] = VOGAnalysis.GetQuickAndSlowPhaseTable(samplesDataTable);
%             eventDataTables.QuickPhases = qp;
%             eventDataTables.SlowPhases = sp;
            
        end
        
        % ---------------------------------------------------------------------
        % Plot methods
        % ---------------------------------------------------------------------
        
        function plotResults = Plot_PlotPosition(this)
            VOG.PlotPosition(this.Session.samplesDataSet);
        end
        function plotResults = Plot_PlotPositionWithHead(this)
            VOG.PlotPositionWithHead(this.Session.samplesDataSet, this.Session.rawDataSet);
        end
        function plotResults = Plot_PlotVelocityWithHead(this)
            VOG.PlotVelocityWithHead(this.Session.samplesDataSet, this.Session.rawDataSet);
        end

        function plotResults = Plot_TestJing(this)
            this.Session.samplesDataSet
        end
        
        function plotMainSeq = Plot_PlotMainSequence(this)
            
            props = VOG.GetQuickPhaseProperties(this.Session.samplesDataSet);
%              [qp_props,sp_props] = VOG.GetQuickAndSlowPhaseProperties(this.Session.samplesDataSet);
             
             figure
             subplot(1,3,1,'nextplot','add') 
             plot(props.Left_X_Displacement,abs(props.Left_X_PeakVelocity),'o')
             plot(props.Right_X_Displacement,abs(props.Right_X_PeakVelocity),'o')
             line([0 0],[0 500])
             xlabel('H displacement (deg)');
             ylabel('H peak vel. (deg/s)');
             subplot(1,3,2,'nextplot','add') 
             plot(props.Left_Y_Displacement,abs(props.Left_Y_PeakVelocity),'o')
             plot(props.Right_Y_Displacement,abs(props.Right_Y_PeakVelocity),'o')
             line([0 0],[0 500])
             xlabel('V displacement (deg)');
             ylabel('V peak vel. (deg/s)');
             subplot(1,3,3,'nextplot','add') 
             plot(props.Left_T_Displacement,abs(props.Left_T_PeakVelocity),'o')
             plot(props.Right_T_Displacement,abs(props.Right_T_PeakVelocity),'o')
             line([0 0],[0 500])
             xlabel('T displacement (deg)');
             ylabel('T peak vel. (deg/s)');
             
             set(get(gcf,'children'),'xlim',[-30 30],'ylim',[0 300])

             
             figure
             subplot(1,3,1,'nextplot','add') 
             plot(props.Left_X_PeakVelocity,abs(props.Left_Y_PeakVelocity),'o')
             plot(props.Right_X_PeakVelocity,abs(props.Right_Y_PeakVelocity),'o')
             subplot(1,3,2,'nextplot','add') 
             plot(props.Left_X_PeakVelocity,abs(props.Left_T_PeakVelocity),'o')
             plot(props.Right_X_PeakVelocity,abs(props.Right_T_PeakVelocity),'o')
             subplot(1,3,3,'nextplot','add') 
             plot(props.Left_Y_PeakVelocity,abs(props.Left_T_PeakVelocity),'o')
             plot(props.Right_Y_PeakVelocity,abs(props.Right_T_PeakVelocity),'o')
             
             set(get(gcf,'children'),'xlim',[-300 300],'ylim',[0 300])
        end
        
        function plotResults = Plot_PlotSPV(this)
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
            
            
            %%
            t = this.Session.analysisResults.SPV.Time;
            pos = (this.Session.analysisResults.SPV.LeftXPos+this.Session.analysisResults.SPV.RightXPos)/2;
            pos = pos-nanmedian(pos);
            v = (this.Session.analysisResults.SPV.LeftX+this.Session.analysisResults.SPV.RightX)/2;
%             v = (this.Session.analysisResults.SPV.LeftX);
            
            leftIdx = find(pos<-10);
            rightIdx = find(pos>10);
            centerIdx =  find(pos>-5 & pos<5);
            
%             figure
%             subplot(2,1,1,'nextplot','add')
%             plot(t(leftIdx),pos(leftIdx),'.','markersize',6)
%             plot(t(rightIdx),pos(rightIdx),'.','markersize',6)
%             plot(t(centerIdx),pos(centerIdx),'.','markersize',6)
%             subplot(2,1,2,'nextplot','add')
%             plot(t(leftIdx),v(leftIdx),'.','markersize',6)
%             plot(t(rightIdx),v(rightIdx),'.','markersize',6)
%             plot(t(centerIdx),v(centerIdx),'.','markersize',6)
            
            VbinLeft = [];
            VbinRight = [];
            VbinCenter = [];
            VbinLeftPos = [];
            VbinRightPos = [];
            VbinCenterPos = [];
            
            D  = 11;
            for i=1:D*6
                idx = (1:20) + (i-1)*20;
                Pchunk = pos(idx);
                Vchunk = v(idx); 
                VbinRight(i) = nanmedian(Vchunk(Pchunk>10));
                VbinLeft(i) = nanmedian(Vchunk(Pchunk<-10));
                VbinCenter(i) = nanmedian(Vchunk(Pchunk>-5 & Pchunk<5));
                VbinRightPos(i) = nanmedian(Pchunk(Pchunk>10));
                VbinLeftPos(i) = nanmedian(Pchunk(Pchunk<-10));
                VbinCenterPos(i) = nanmedian(Pchunk(Pchunk>-5 & Pchunk<5));
            end
            %%
            figure
            subplot(3,1,1,'nextplot','add')
            plot((1:D*6)/6,VbinLeftPos,'o','markerSize',10);
            plot((1:D*6)/6,VbinRightPos,'o','markerSize',10);
            plot((1:D*6)/6,VbinCenterPos,'o','markerSize',10);
            xlabel('Time (min)');
            ylabel('Eye position (deg)');
            legend({'Left gaze', 'Right gaze', 'Center gaze'});
            grid
            
            subplot(3,1,2,'nextplot','add')
            plot((1:D*6)/6,VbinLeft,'o','markerSize',10);
            plot((1:D*6)/6,VbinRight,'o','markerSize',10);
            plot((1:D*6)/6,VbinCenter,'o','markerSize',10);
            xlabel('Time (min)');
            ylabel('Slow phase velocity (deg/s)');
            legend({'Left gaze', 'Right gaze', 'Center gaze'});
            grid
                        
            subplot(3,1,3,'nextplot','add')
            plot((1:D*6)/6,VbinLeft-VbinCenter,'o','markerSize',10);
            plot((1:D*6)/6,VbinRight-VbinCenter,'o','markerSize',10);
            plot((1:D*6)/6,VbinCenter-VbinCenter,'o','markerSize',10);
            xlabel('Time (min)');
            ylabel('Slow phase velocity - Left-Right (deg/s)');
            grid
            
            %%
            figure
            subplot(2,1,1,'nextplot','add')
            plot(VbinLeftPos, VbinLeft-VbinCenter,'.')
            plot(VbinRightPos, VbinRight-VbinCenter,'.')
            ylabel('SPV difference eccentric-center (deg/s)')
            xlabel('Eye position (deg)');
            subplot(2,1,2,'nextplot','add')
            plot(abs(VbinCenter), abs(VbinLeft-VbinRight),'.')
            xlabel('Abs Eye velocity at center (deg/s)');
            ylabel('Abs SPV difference left-right (deg/s)')
            
            
            
        end
    end
    
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        %         function analysisResults = Analysis_NameOfAnalysis(this) ' NO PARAMETERS
        %             analysisResults = [];
        %         end
        
        function analysisResults = Analysis_SlowPhaseQuickPhase(this)
            
            [qp_props,sp_props] = VOG.GetQuickAndSlowPhaseProperties(this.Session.samplesDataSet);
                        
            analysisResults.SlowPhases = sp_props;
            analysisResults.QuickPhases = qp_props;
            
        end
        
        function analysisResults = Analysis_SPV(this)
            
            x = { this.Session.samplesDataSet.LeftX, ...
                this.Session.samplesDataSet.RightX, ...
                this.Session.samplesDataSet.LeftY, ...
                this.Session.samplesDataSet.RightY, ...
                this.Session.samplesDataSet.LeftT, ...
                this.Session.samplesDataSet.RightT};
            lx = x{1};
            T = 500;
            t = 1:ceil(length(lx)/T*2);
            spv = {nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1)};
            spvPos = {nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1), ...
                nan(ceil(length(lx)/T*2),1)};
            
            for j =1:length(x)
                v = diff(x{j})*500;
                v1 = diff(x{2})*500;
                qp = boxcar(abs(v1)>50,10)>0;
                v(qp) = nan;
                for i=1:length(x{j})/T*2
                    idx = (1:T) + (i-1)*T/2;
                    idx(idx>length(v)) = [];
                    
                    vchunk = v(idx);
                    xchunk = x{j}(idx);
                    if( nanstd(vchunk) < 20)
                        spv{j}(i) =  nanmedian(vchunk);
                        spvPos{j}(i) =  nanmedian(xchunk);
                    end
                end
            end
            
            analysisResults = dataset(t', spv{1}, spv{3}, spv{5}, spv{2}, spv{4}, spv{6}, spvPos{1}, spvPos{3}, spvPos{5}, spvPos{2}, spvPos{4}, spvPos{6}, ...
                'varnames',{'Time' 'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'  'LeftXPos', 'LeftYPos' 'LeftTPos' 'RightXPos' 'RightYPos' 'RightTPos'});
        end
                
        function plotResults = Plot_PlotSPVFeetAndHead(this)
            
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
        
        
        function  plotResults = Plot_RawDataDebug(this)
            VOG.PlotCleanAndResampledData(this.Session.rawDataSet, this.Session.samplesDataSet);
            plotResults = [];
        end
        
        function  plotResults = Plot_SaccadeDetectionDebug(this)
            VOG.PlotQuickPhaseDebug(this.Session.samplesDataSet);
            plotResults = [];
        end
        
        function  plotResults = Plot_SaccadeTraces(this)
            VOG.PlotSaccades(this.Session.samplesDataSet);
            plotResults = [];
        end
    end
    
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
        %         function [anyparameters] = GeneralFunction( anyparameters)
        %         end
        
        
    end
end

