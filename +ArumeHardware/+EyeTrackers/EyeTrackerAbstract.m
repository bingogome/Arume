classdef EyeTrackerAbstract
    %EYETRACKERABSTRACT Summary of this class goes here
    %   Detailed explanation goes here
    
    methods(Static)
        function eyeTracker = Initialize( trackername, exper )
            eyeTracker = feval(['EyeTrackers.EyeTracker' trackername], exper);
        end
    end
    
    methods(Abstract)
        
        [calibrationResult] = Calibration( this, graph );
        
        [driftCorrectionResult] = DriftCorrection( this, graph );
        
        StartRecording( this );
        
        StopRecording( this );
        
        error = CheckRecording( this, varargin );
        
        SendMessage( this, varargin );
        
        ChangeStatusMessage( this, varargin );
        
        time = GetCurrentTimestamp( this );
        
        [x y] = GetCurrentPosition( this );
        
        filename = GetFile( this, path);
        
        Close(this);
    end
    
end

