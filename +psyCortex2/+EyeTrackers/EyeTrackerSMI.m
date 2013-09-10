classdef EyeTrackerSMI  < EyeTrackers.EyeTrackerAbstract
    %EyeTrackerSMI Summary of this class goes here
    %   Detailed explanation goes here
    
    methods 
    end
    
    methods
        
        function [calibrationResult] = Calibration( this, graph )
            calibrationResult = 0;
        end
        
        
        function [driftCorrectionResult] = DriftCorrection( this, graph )
            driftCorrectionResult = 0;
        end
        
        
        function StartRecording( this )
            
        end
        
        
        function StopRecording( this )
            
        end
        
        
        function error = CheckRecording( this, varargin )
            error =0;
        end
        
        
        function SendMessage( this, varargin )
        end
        
        
        function filename = GetFile( this, path)
            filename = 0;
        end
        
        
        function Close(this)
            
        end
    end
    
end

