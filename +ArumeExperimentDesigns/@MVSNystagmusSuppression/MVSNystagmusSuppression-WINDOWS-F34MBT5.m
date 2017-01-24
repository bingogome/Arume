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
            
            dlg.InitialOutsideDuration = 2;
            dlg.InsideDuration = 20;
            dlg.FinalOutsideDuration = 15;
            
            dlg.Condition = {{'{Dark}' 'Light' 'HeadMovingDark'}};
            dlg.DurationPeriodsInside1 = 1;
            dlg.DurationPeriodsInside1 = 18.5;
            dlg.DurationPeriodsInside1 = 0.5;
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
            
            trialDataSet = this.PrepareTrialDataSet@ArumeCore.ExperimentDesign(ds);
            
            trialDataSet.Condition =1;
            trialDataSet.TrialNumber(1) =1;
            trialDataSet.TrialResult(1) =1;
            trialDataSet.StartTrialSample(1) =1;
            trialDataSet.EndTrialSample(1) =length(this.Session.samplesDataSet);
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
            VOG.PlotPosition(this.Session.samplesDataSet);
        end
        
    end
    
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        %         function analysisResults = Analysis_NameOfAnalysis(this) ' NO PARAMETERS
        %             analysisResults = [];
        %         end
        
    end
    
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
        %         function [anyparameters] = GeneralFunction( anyparameters)
        %         end
        
    end
end

