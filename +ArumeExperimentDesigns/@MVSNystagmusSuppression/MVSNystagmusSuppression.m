classdef MVSNystagmusSuppression < ArumeCore.ExperimentDesign
    
    properties
        
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function dlg = GetOptionsDialog( this )
            dlg.InitialOutsideDuration = 2;
            dlg.InsideDuration = 20;
            dlg.FinalOutsideDuration = 15;
            
            dlg.Condition = {{'Dark'} 'Light' 'HeadMovingDark'};
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
        
        function trialDataSet = PrepareTrialDataSet( this, ds)
            % Every class inheriting from SVV2AFC should override this
            % method and add the proper PresentedAngle and
            % LeftRightResponse variables
            
            trialDataSet = this.PrepareTrialDataSet@ArumeCore.ExperimentDesign(ds);
            
        end
        
        
        % ---------------------------------------------------------------------
        % Plot methods
        % ---------------------------------------------------------------------
        
        
        %         function plotResults = Plot_PlotName(this) - no parameters
        %         end
        
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

