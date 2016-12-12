classdef MVSNystagmusSuppression < ArumeCore.ExperimentDesign
    
    properties
        
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function dlg = GetOptionsDialog( this )
            dlg.EyeDataFile = { {['uigetfile(''' fullfile(pwd,'*.txt') ''')']} };
            dlg.EyeCalibrationFile = { {['uigetfile(''' fullfile(pwd,'*.cal') ''')']} }; 
            dlg.AssociatedControl = '';
            dlg.Events = 'struct()';
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
                qp = boxcar(abs(v)>50,10)>0;
                v(qp) = nan;
                for i=1:length(x{j})/T
                    idx = (1:T) + (i-1)*T;
                    idx(idx>length(x{j})) = [];
                    
                    vchunk = v(idx);
                    if( nanstd(vchunk) < 10)
                        spv{j}(i) =  nanmedian(vchunk);
                    end
                end
            end
            
            analysisResults = dataset(t', spv{1}, spv{3}, spv{5}, spv{2}, spv{4}, spv{6}, ...
                'varnames',{'Time' 'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'});
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

