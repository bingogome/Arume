classdef HapticDevice
    
    
    properties
        % add variables here
        
    end
    
    methods
        
        function this = HapticDevice()
            persistent active;
            
            if ( isempty(active) )
                
                % add initialization code here
                
                active = 1;
            else
                return;
            end
        end
        
        function Move(this, angle)
            
            % add code to move the motor here
            
        end
        
        function Close(this)
            
            % add clean up code here
        end
    end
    
    
end

