classdef SVV2AFCAdaptiveLong < ArumeExperimentDesigns.SVV2AFCAdaptive
    %SVVLineAdaptiveLong Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function dlg = GetOptionsDialog( this )
            dlg = GetOptionsDialog@ArumeExperimentDesigns.SVV2AFCAdaptive(this);
            dlg.PreviousTrialsForRange = { {'All','{Previous30}'} }; % change the default
            dlg.TotalNumberOfTrials = 1000; % change the default
        end
    end
        
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
end

