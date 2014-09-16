classdef BiteBarMotor
    %BITEBARMOTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        port = '';
        
        s;
    end
    
    methods
        function this = BiteBarMotor()
            persistent ss;
            
            if ( isempty(ss) )
                serialInfo = instrhwinfo('serial');
                
                if ( length(serialInfo.SerialPorts) < 1 )
                    error('No serial ports detected');
                end
                
                this.port = serialInfo.SerialPorts{end};
                
                
                delete(instrfindall);
                ss =  serial(this.port,'BaudRate',9600);
                
                this.s = ss;
                if ( ~isequal(this.s.Status,'open') )
                    fopen(this.s);
                end
            else     
                this.s = ss;
                if ( ~isequal(this.s.Status,'open') )
                    fopen(this.s);
                end
            end
        end
        
        function Close(this)
            fclose(this.s);
        end
        
        function GoHome(this)
            homecmd = [1 1 0 0 0 0];
            fwrite(this.s,homecmd);
        end
        
        function GoUpright(this)
            bytes = ArumeHardware.BiteBarMotor.IntToBytes(380000);
            homecmd = [1 20 bytes];
            fwrite(this.s,homecmd);
        end
        
        function TiltLeft(this, angle)
            bytes = ArumeHardware.BiteBarMotor.IntToBytes(angle/90*380000);
            upcmd = [1 21 bytes];
            fwrite(this.s,upcmd);
        end
        
        function TiltRight(this, angle)
            bytes = ArumeHardware.BiteBarMotor.IntToBytes(-angle/90*380000);
            downcmd = [1 21 bytes];
            fwrite(this.s,downcmd);
        end
        
        function Stop1(this, angle)
            downcmd = [1 23 0 0 0 0 ];
            fwrite(this.s,downcmd);
        end
        
    end
    
    methods (Static = true)
        function Home()
            bitebar = ArumeHardware.BiteBarMotor;
            bitebar.GoHome();
            bitebar.Close();
        end
        
        function Upright()
            bitebar = ArumeHardware.BiteBarMotor;
            bitebar.GoUpright();
            bitebar.Close();
        end
        
        function Stop()
            bitebar = ArumeHardware.BiteBarMotor;
            bitebar.Stop1();
            bitebar.Close();
        end
        
        
        function bytes = IntToBytes(number)
            if number < 0 
                number = 256^4 + number; %Handles negative data
            end
            Cmd_Byte_6 = floor(number / 256^3);
            number   = number - 256^3 * Cmd_Byte_6;
            Cmd_Byte_5 = floor(number / 256^2);
            number   = number - 256^2 * Cmd_Byte_5;
            Cmd_Byte_4 = floor(number / 256);
            number   = number - 256   * Cmd_Byte_4;
            Cmd_Byte_3 = floor(number);
            
           bytes = [Cmd_Byte_3 Cmd_Byte_4 Cmd_Byte_5 Cmd_Byte_6];
        end
    end
end

