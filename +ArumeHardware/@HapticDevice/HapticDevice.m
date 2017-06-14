classdef HapticDevice < handle
    properties
        % add variables here
        sm
        currentAngle
        ac
    end
    methods
        function this = HapticDevice()
            persistent active;
            persistent motor;
            if ( isempty(active))
                % add initialization code here
                serialInfo = instrhwinfo('serial');
                %                 if( length(serialInfo.SerialPorts) < 3)
                %                     error( 'No port found for arduino');
                %                 end
                %                 comport = serialInfo.SerialPorts{4};
                %                 fprintf('Opening arduino in %s\n', comport);
                %                 a = arduino(comport, 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
                a = arduino('COM4', 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
                shield = a.addon('Adafruit\MotorShieldV2');
                this.sm = shield.stepper(2, 200, 'stepType', 'double');
                motor = this.sm;
                this.sm.RPM = 30;
                active =1;
                
                %initialize serial port and fopen
                this.ac = serial('COM19', 'BaudRate', 9600); %ACCELEROMETER
                this.ac.InputBufferSize = 65536;
                this.ac.OutputBufferSize = 65536;
                this.ac.Timeout = 1.5;
                this.ac.Terminator = 'LF'; % New line feed
                fopen(this.ac);
            else
                this.sm = motor;
            end
        end
        function reset(this)
            showAcc(this.ac);
            diffAngle = GetAngleToMove(readAcc(this.ac),0);
            steps = -round(diffAngle/360*200,0);
            this.sm.move(steps);
            pause(2);
            while ( readAcc(this.ac) > 1 ) || ( -1 > readAcc(this.ac))
                diffAngle = GetAngleToMove(readAcc(this.ac),0);
                steps = -round(diffAngle/360*200,0);
                this.sm.move(steps);
                pause (.2);
            end
            showAcc(this.ac);
        end
        
        function move(this, finalangle)
            % this.currentAngle = readAcc(this.ac); %initial angle taken from acc
            showAcc(this.ac);
            diffAngle = GetAngleToMove(readAcc(this.ac), finalangle);
            steps = -round(diffAngle/360*200);
            % add code to move the motor here
            if ( steps > 0 )
                s = -round((-steps+50)/2,0);
                t = round((steps+50)/2,0);
            else
                s = round((steps-50)/2,0);
                t = -round((-steps-50)/2,0);
            end
            fprintf('\nMOTOR: Moving motor %1.1f steps with two jumps %1.1f and %1.1f (%1.1f)..\n', steps, s, t, s+t);
            fprintf('MOTOR: Starting angle %1.1f deg, moving %1.1f, final angle %1.1f..',readAcc(this.ac), diffAngle, finalangle);
            this.sm.move(s);
            pause(.5);
            this.sm.move(t); %the motor moves a total of 50 steps!
            %           this.sm.move(steps);
            %             pause (.2);
            %             this.currentAngle = readAcc(this.ac); %initial angle taken from acc
            %             diffAngle = GetAngleToMove(this.currentAngle, finalangle);
            %             steps = -round(diffAngle/360*200);
            %             this.sm.move(steps);
            fprintf('\nDone Moving motor...\n');
            pause (1.2);
            %             this.sm.move(1) %what is this?? Does this move anything????
            %             this.currentAngle = this.currentAngle - (s+t)*1.8;
            % taking the shortest line of path - do not use because of
            % accelerometer !!
            %             if ( this.currentAngle > 90 )
            %                 this.currentAngle = this.currentAngle -180;
            %             elseif( this.currentAngle < -90)
            %                 this.currentAngle = this.currentAngle+180;
            %             end
            showAcc(this.ac);
        end
        function directMove(this, finalangle)
            showAcc(this.ac);
            diffAngle = GetAngleToMove(readAcc(this.ac), finalangle);
            steps = -round(diffAngle/360*200);
            % add code to move the motor here
            fprintf('\nMOTOR:: Moving motor %1.1f steps', steps);
            fprintf('\nMOTOR:: Starting angle %1.1f deg, moving %1.1f, final angle %1.1f', readAcc(this.ac), diffAngle,finalangle);
            this.sm.move(steps);
            fprintf('\nDone Moving motor...\n');
            pause (1.2);
            showAcc(this.ac);
        end
        function moveStep(this, steps)
            this.sm.move(steps);
        end
        
        function angle = getCurrentAngle(this)
            angle = readAcc(this.ac);
        end
        function Close(this)
            % add clean up code here
            %             this.sm.release();
            %             clear this.a;
            %             clear this.shield;
            %             clear active;
        end
    end
    %% Destructor
    methods (Access=protected)
        function delete(this)
            % User delete of Arduino objects is disabled. Use clear
            % instead.
            if ~isempty(this.ac) % Delete the serial object arduino creates
                %                 fclose(this.ac);
                delete(this.ac);
                clear this.ac;
            end
            %             if ~isempty(this.sm)
            %                 this.sm.release();
            %             end
            %             clear this.a;
            %             clear this.shield;
        end
    end
end
function displayAngle = readAcc(ac,x) %reads the accelerometer only, does NOT show angle
% ac =  serial('COM16','BaudRate',9600);
% fopen(ac);
% set(ac, 'TimeOut', 5);
% pause(2);
fwrite(ac,'1');
displayAngle= str2double(fscanf(ac,'%s'));
% angleStr = fscanf(ac,'%s');
% displayAngle= str2double(angleStr); %angle read from the accelerometer
% disp(['Accelerometer says:' angleStr]); %this is a string
% fclose(ac);
end
function displayAngle = showAcc(ac,x) %displays the accelerometer values
% ac =  serial('COM16','BaudRate',9600);
% fopen(ac);
% set(ac, 'TimeOut', 5);
% pause(2);
fwrite(ac,'1');
displayAngle= fscanf(ac,'%s'); %angle read from the accelerometer
disp(['Accelerometer says:' displayAngle]); %this is a string
% fclose(ac);
end
function angleToMove = GetAngleToMove(StartingAngle,FinalAngle)
% x = angle displacement (final angle - starting angle)
% trying to get absolute angle displacement to be less than or equal to 90
x = rem(FinalAngle,180) - rem(StartingAngle,180);
x = rem(x,180);
% if (x > 90)
%     x = x-180;
% else(x < -90)
%     x = -x+180;
% end
angleToMove = x;
% steps = round(x/360*200);
% % sm.move(steps);
% if (abs(steps)>50)
%     disp('error, make angle displacement less than 450 degrees')
% else
%     disp(steps)
% end
% % StartingAngle = FinalAngle + x;
end


