classdef OculusVR
    %OculusVR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static = true)
        
        function Open()
            ArumeHardware.ovr('init');
        end
        function [ angles] = Query()
          
            angles = ArumeHardware.ovr('query');
        end
        
        function Close()
            ArumeHardware.ovr('close', 0);
        end
    end
    
end

