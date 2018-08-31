classdef BiteBarMotor < handle
    %BITEBARMOTOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
    end
      
    properties
        s;
        
        ID = 952;
        degPerStep = 0.015;
        
        COMMMAND_Home = 1;
        COMMMAND_MoveAbsolute = 20;
        COMMMAND_Return_Device_Id = 50;
        COMMMAND_Stop = 23;
        
        COMMAND_SetHoldCurrent = 39;
        COMMAND_SetTargetSpeed = 42;
        
        COMMMAND_ReadMicrostepResolution = 37;
        
        HomeAngle = 90;
        CurrentAngle = 0;
    end
    
    methods
        function out = Singleton(this, command)
            persistent ss;
            persistent counter;
            if ( isempty(counter) )
                counter = 0;
            end
            switch(command)
                case 'check'
                    counter = counter +1;
                case 'init'
                    ss = this.s;
                case 'clear'
                    counter = counter -1;
                    if ( counter == 0 )
                        delete(ss)
                        clear ss;
                        clear this.s;
                        this.s = [];
                        out = [];
                        return
                    end
            end
            
            out = ss;
        end
        
        function this = BiteBarMotor()
            ss = this.Singleton('check');
            
            if ( isempty(ss) || ~isvalid(ss) )
                % close all serial ports
                
                disp('Querying available serial ports');
                serialInfo = instrhwinfo('serial');
                
                if ( length(serialInfo.AvailableSerialPorts) < 1 )
                    error('No serial ports detected');
                end
                
                disp('Testing available serial ports');
                %                 for i=length(serialInfo.AvailableSerialPorts):-1:1
                %
                port = 'COM3';
                openport = instrfindall('Type', 'serial','name','Serial-COM3');
                if ( ~isempty( openport)  )
                    delete(openport);
                end
                
                disp(['Testing ' port]);
                
                this.s = serial(port,'BaudRate',9600);
                
                this.Singleton('init');
                
                if ( this.CheckID )
                    this.Init();
                end
                %                 end
            else     
                this.s = ss;
            end
            
            if (~isempty(this.s) && strcmp(class(this.s),'serial') && strcmp(this.s.Status, 'open'))
                disp('Serial port should be OK');
            else
                error('!!!!!!!!! PROBLEM WITH BITEBAR SERIAL PORT !!!!');
            end
        end
        
        
        function Init(this)
             disp('Setting target speed');
             speed = 10; % deg per second
             data =  speed/(9.375*(0.015/64));
             id = this.SendCommand( this.COMMAND_SetTargetSpeed, data);
        end
        
        function Close(this)
        end
        
        function result = CheckID(this)
            
            id = this.SendCommand( this.COMMMAND_Return_Device_Id, 0, 2);
            
            if ( id == this.ID )
                result = 1;
            else
                result = 0;
            end
        end
        
        function GoHome(this)
            out = this.SendCommand( this.COMMMAND_Home, 0);
            this.CurrentAngle = -90;
        end
        
        function GoUpright(this)
            
            angle = this.GetAngleMotorRef(0);
            microsteps = this.GetMicrosteps(angle);
            out = this.SendCommand( this.COMMMAND_MoveAbsolute, microsteps);
            
            this.CurrentAngle = 0;
        end
        
        function TiltLeft(this, angle)
            angle2 = this.GetAngleMotorRef(-abs(angle));
            microsteps = this.GetMicrosteps(angle2);
            out = this.SendCommand( this.COMMMAND_MoveAbsolute, microsteps);
            
            this.CurrentAngle = -angle;
        end
        
        function TiltRight(this, angle)
            angle2 = this.GetAngleMotorRef(abs(angle));
            microsteps = this.GetMicrosteps(angle2);
            out = this.SendCommand( this.COMMMAND_MoveAbsolute, microsteps);
            
            this.CurrentAngle = angle;
        end
        
        function SetTiltAngle(this, angle)
            angle2 = this.GetAngleMotorRef(angle);
            microsteps = this.GetMicrosteps(angle2);
            out = this.SendCommand( this.COMMMAND_MoveAbsolute, microsteps);
            
            this.CurrentAngle = angle;
        end
                
    end
    
    %% Destructor
    methods (Access=protected)
        function delete(this)
            % User delete of BiteBarMotor objects is disabled. Use clear
            % instead.
            this.Singleton('clear');
        end
    end
    
    methods(Access = private)
        
        function dataOut = SendCommand(this, command,  dataIn, timeOut)
            if ( ~exist('timeOut','var') )
                timeOut = 30;
            end
            
            if ( ~isequal(this.s.Status,'open') )
                fopen(this.s);
            end
                    
                    
            bytes = this.IntToBytes(dataIn);
            command = [1 command bytes];
            
            % clear the port
            if ( this.s.BytesAvailable > 0 )
                out = fread(this.s, this.s.BytesAvailable);
            end
            
            fwrite(this.s,command);
            
            tic;
            while(this.s.BytesAvailable < 6)
                pause(0.001);
                t = toc;
                if ( t > timeOut )
                    dataOut = -1;
                    disp('TIMEOUT');
                    return;
                end
            end
            
            out = fread(this.s, this.s.BytesAvailable);
            
            dataOut = this.BytesToInt(out(end-3:end));
            
        end
        
        function angleMotorRef = GetAngleMotorRef(this, angle)
            angleMotorRef = -angle + this.HomeAngle;
        end
        
        function microsteps =  GetMicrosteps(this, angleDeg)
            microsteps = angleDeg/this.degPerStep*64;
        end
        
        function bytes = IntToBytes(this, number)
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
        
        function number = BytesToInt(this, bytes)
            number = 256^3 * bytes(4) + 256^2 * bytes(3) + 256 * bytes(2) + bytes(1);
            if bytes(4) > 127 %       'Handles negative data
                number = Reply_Data - 256^4;
            end
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
            bitebar.SendCommand( this.COMMMAND_Stop, 0);
            bitebar.Close();
        end
        
        
    end
end

