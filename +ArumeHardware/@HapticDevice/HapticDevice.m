classdef HapticDevice
    
    
    properties
        % add variables here
        sm
        
    end
    
    methods
        
        function this = HapticDevice()
            persistent active;
            
            if ( isempty(active) )
                
                % add initialization code here
                a = arduino('COM5', 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
                shield = a.addon('Adafruit\MotorShieldV2');
                this.sm = shield.stepper(2, 200, 'stepType', 'microstep');
                
                this.sm.RPM = 20;
                active = 1;
            else
                return;
            end
        end
        
        function move(this, angle)
            
            steps = angle/360*200;
            
            % add code to move the motor here
            this.sm.move(round(steps));
            
        end
        
        function Close(this)
            % add clean up code here
            
            release(this.sm)
        end
    end
    
    
end

