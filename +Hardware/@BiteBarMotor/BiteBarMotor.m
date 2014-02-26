classdef BiteBarMotor
    %BITEBARMOTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        port = 'com4';
        s
    end
    
    methods
        function this = BiteBarMotor()
            this.s =  serial(this.port,'BaudRate',9600);
            fopen(this.s);
        end
        function Close(this)
            fclose(this.s);
        end
        
        function GoHome(this)
            homecmd = [1 1 0 0 0 0];
            fwrite(this.s,homecmd);
        end
        
        function TiltLeft(this, angle)
            upcmd = [1 21 0 31 0 0];
            fwrite(this.s,upcmd);
        end
        
        function TiltRight(this, angle)
            downcmd = [1 21 0 225 255 255];
            fwrite(this.s,downcmd);
        end
    end
    
end

