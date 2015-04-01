classdef GamePad
    %GAMEPAD Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods
        
        function this = GamePad()
            ArumeHardware.joymex2('open', 0);
        end
        
        function [ direction, left, right, a, b, x, y] = Query(this)
          
            gp = ArumeHardware.joymex2('query',0);
            
            direction = round(gp.axes/30000);
            direction(2) = -direction(2);
            
            left = gp.buttons(5);
            right = gp.buttons(6);
            a = gp.buttons(1);
            b = gp.buttons(2);
            x = gp.buttons(3);
            y = gp.buttons(4);
        end
        
        function Close(this)
            ArumeHardware.joymex2('close', 0);
        end
    end
    
    
end

