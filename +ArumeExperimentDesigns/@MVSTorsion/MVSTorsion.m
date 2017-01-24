classdef MVSTorsion < ArumeCore.ExperimentDesign
    
    properties
        
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function dlg = GetOptionsDialog( this )
            dlg.EyeDataFile = { {['uigetfile(''' fullfile(pwd,'*.txt') ''')']} };
            dlg.EyeCalibrationFile = { {['uigetfile(''' fullfile(pwd,'*.cal') ''')']} };
        end
        
        function initBeforeRunning( this )
            
            % Important variables to use:
            %
            % this.ExperimentOptions.NAMEOFOPTION will contain the values
            %       from GetOptionsDialog
            %
            %
        end
        
        function cleanAfterRunning(this)
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function ImportSession( this )
        end
        
        function trialDataSet = PrepareTrialDataSet( this, ds)
            % Every class inheriting from SVV2AFC should override this
            % method and add the proper PresentedAngle and
            % LeftRightResponse variables
            
            trialDataSet = this.PrepareTrialDataSet@ArumeCore.ExperimentDesign(ds);
            
            trialDataSet.Condition(1) = 1;
            trialDataSet.TrialNumber(1) = 1;
            trialDataSet.TrialResult(1) = 1;
            trialDataSet.StartTrialSample(1) = 1;
            trialDataSet.EndTrialSample(1) = length(this.Session.samplesDataSet);
        end
        
        function samplesDataSet = PrepareSamplesDataSet(this, samplesDataSet)
            
            % load data
            rawData = VOG.LoadVOGdataset(this.ExperimentOptions.EyeDataFile);
            
            % calibrate data
            [calibratedData leftEyeCal rightEyeCal] = VOG.CalibrateData(rawData, this.ExperimentOptions.EyeCalibrationFile);
            
            % clean data
            samplesDataSet = VOG.ResampleAndCleanData(calibratedData);
        end
        
        function samplesDataSet = PrepareEventDataSet(this, eventDataset)
        end
        
        % ---------------------------------------------------------------------
        % Plot methods
        % ---------------------------------------------------------------------
        
        function plotResults = Plot_PlotPosition(this)
            VOG.PlotPosition(this.Session.samplesDataSet);
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
            plot(t,vxl,'.')
            plot(t,vxr,'.')
            ylabel('Horizontal (deg/s)')
            subplot(3,1,2,'nextplot','add')
            grid
            set(gca,'ylim',[-20 20])
            plot(t,vyl,'.')
            plot(t,vyr,'.')
            ylabel('Vertical (deg/s)')
            subplot(3,1,3,'nextplot','add')
            set(gca,'ylim',[-20 20])
            plot(t,vtl,'.')
            plot(t,vtr,'.')
            ylabel('Torsional (deg/s)')
            grid
            set(gca,'ylim',[-20 20])
            xlabel('Time (s)');
            linkaxes(get(gcf,'children'))
            
        end
    end
    
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        %         function analysisResults = Analysis_NameOfAnalysis(this) ' NO PARAMETERS
        %             analysisResults = [];
        %         end
        
        function analysisResults = Analysis_SPV(this)
            
            x = { this.Session.samplesDataSet.LeftX, ...
                this.Session.samplesDataSet.RightX, ...
                this.Session.samplesDataSet.LeftY, ...
                this.Session.samplesDataSet.RightY, ...
                this.Session.samplesDataSet.LeftT, ...
                this.Session.samplesDataSet.RightT};
            lx = x{1};
            T = 500;
            t = 1:ceil(length(lx)/T);
            spv = {nan(ceil(length(lx)/T),1), ...
                nan(ceil(length(lx)/T),1), ...
                nan(ceil(length(lx)/T),1), ...
                nan(ceil(length(lx)/T),1), ...
                nan(ceil(length(lx)/T),1), ...
                nan(ceil(length(lx)/T),1)};
            
            for j =1:length(x)
                v = diff(x{j})*500;
                v1 = diff(x{2})*500;
                qp = boxcar(abs(v1)>50,10)>0;
                v(qp) = nan;
                for i=1:length(x{j})/T
                    idx = (1:T) + (i-1)*T;
                    idx(idx>length(v)) = [];
                    
                    vchunk = v(idx);
                    if( nanstd(vchunk) < 20)
                        spv{j}(i) =  nanmedian(vchunk);
                    end
                end
            end
            
            analysisResults = dataset(t', spv{1}, spv{3}, spv{5}, spv{2}, spv{4}, spv{6}, ...
                'varnames',{'Time' 'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'});
        end
        
        
        function plotResults = Plot_PlotSPVFeetAndHead(this)
            
            t1 = this.Session.analysisResults.SPV.Time;
            vxl = this.Session.analysisResults.SPV.LeftX;
            vxl2 = interp1(find(~isnan(vxl)),vxl(~isnan(vxl)),1:1:length(vxl));
            vxr = this.Session.analysisResults.SPV.RightX;
            vxr2 = interp1(find(~isnan(vxr)),vxr(~isnan(vxr)),1:1:length(vxr));
            vx1 = nanmean([vxl2;vxr2]);
            
            
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
    
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
        %         function [anyparameters] = GeneralFunction( anyparameters)
        %         end
        
        
    end
end

