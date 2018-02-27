classdef HapticDevice < handle
    properties
        % add variables here
        sm % stepper motor object
        ac % accelerometer object
        ard
    end
    methods
        function [outard outsm outac]  = Singleton(this, command) %clear things
            persistent ard;
            persistent sm;
            persistent ac;
            persistent counter;
            if ( isempty(counter) )
                counter = 0;
            end
            switch(command)
                case 'check'
                    counter = counter +1;
                case 'init'
                    ard = this.ard;
                    sm = this.sm;
                    ac = this.ac;
                case 'clear'
                    counter = counter -1;
                    if ( counter == 0 )
                        
                        delete(ac)
                        clear ac;
                        clear ard;
                        clear sm;
                        clear this.ac;
                        clear this.sm;
                        clear this.ard;
                        out = [];
                        return
                    end
            end
            
            outard = ard;
            outsm = sm;
            outac = ac;
        end
        function this = HapticDevice() %initializing haptic device 
            [ard sm ac] = this.Singleton('check');
            
            if ( isempty(ard) )
                % add initialization code here
                
                openport = instrfindall('Type', 'serial','name','Serial-COM4');
                if ( ~isempty( openport)  )
                    delete(openport);
                end
                openport = instrfindall('Type', 'serial','name','Serial-COM19');
                if ( ~isempty( openport)  )
                    delete(openport);
                end
                
                this.ard = arduino('COM19', 'Uno', 'Libraries', 'Adafruit\MotorShieldV2');
                shield = this.ard.addon('Adafruit\MotorShieldV2');
                this.sm = shield.stepper(2, 200, 'stepType', 'double');
                this.sm.RPM = 50;
                
                %initialize serial port and fopen
                this.ac = serial('COM4', 'BaudRate', 9600); %ACCELEROMETER
                this.ac.InputBufferSize = 65536;
                this.ac.OutputBufferSize = 65536;
                this.ac.Timeout = 1.5;
                this.ac.Terminator = 'LF'; % New line feed
                
                this.Singleton('init');
                
                fopen(this.ac);
            else
                this.ard = ard;
                this.sm = sm;
                this.ac = ac;
            end
        end  
        function reset(this)%resetting the bar to "0 degrees"
            initialAccelerometerAngle = readAcc(this.ac);
            currentAngle = initialAccelerometerAngle;
            counterOfTurns = 0;
            TIMEOUT = 1;
            while(abs(currentAngle)>1 && counterOfTurns<4)
                counterOfTurns = counterOfTurns+1;
                diffAngle = GetAngleToMove(currentAngle,0);
                steps = -round(diffAngle/360*200,0);
                fprintf('\nMOTOR: Resetting motor from %1.1f angle with %d steps ...',currentAngle, steps);
                this.sm.move(steps);
                pause(0.2);
                currentAngle = readAcc(this.ac);
            end
            
            if ( counterOfTurns > 0 )
                fprintf('\nMOTOR: Resetting motor should have moved %1.1f but moved %1.1f to %1.1f...\n',diffAngle, currentAngle-initialAccelerometerAngle,currentAngle);
            else
                fprintf('\nMOTOR: Resetting, but no need to move from %1.1f\n' , currentAngle );
            end
        end
        function move(this, finalangle)%code for moving 90 degrees in total
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
        function directMove(this, finalangle) %moving bar to 'finalangle' accurately might take multiple tries...
            initialAccelerometerAngle = readAcc(this.ac);
            currentAngle = initialAccelerometerAngle;
            counterOfTurns = 0;
            TIMEOUT = 1.5;
            while(abs(currentAngle-finalangle)>1 && counterOfTurns<3)
                counterOfTurns = counterOfTurns+1;
                diffAngle = GetAngleToMove(currentAngle,finalangle);
                steps = -round(diffAngle/360*200,0);
                fprintf('\nMOTOR: Moving motor from %1.1f to %1.1f angle with %d steps ...',currentAngle,finalangle, steps);
                this.sm.move(steps);
                pause(0.45*counterOfTurns);
                currentAngle = readAcc(this.ac);
            end
            if ( counterOfTurns > 0 )
                fprintf('\nMOTOR: Moving motor should have moved to %1.1f but moved %1.1f to %1.1f...\n',finalangle, currentAngle-initialAccelerometerAngle,currentAngle);
            else
                fprintf('\nMOTOR: Not moving: No need to move from %1.1f\n' , currentAngle );
                pause (1);
            end
        end
        function moveStep(this, steps) %moving based on steps
            this.sm.move(steps);
        end
        function angle = getCurrentAngle(this)
            angle = readAcc(this.ac);
        end
    end
    %% Destructor
    methods (Access=protected)
        function delete(this)
            % User delete of HapticDevice objects is disabled. Use clear
            % instead.
            this.Singleton('clear');
        end
    end
end
function displayAngle = readAcc(ac,x) %reads the accelerometer only, does NOT show angle
fwrite(ac,'1');
displayAngle= str2double(fscanf(ac,'%s'));
end
function displayAngle = showAcc(ac,x) %displays the accelerometer values
fwrite(ac,'1');
displayAngle= fscanf(ac,'%s'); %angle read from the accelerometer
disp(['Accelerometer says:' displayAngle]); %this is a string
end
function angleToMove = GetAngleToMove(StartingAngle,FinalAngle)
% x = angle displacement (final angle - starting angle)
% trying to get absolute angle displacement to be less than or equal to 90
x = rem(FinalAngle,180) - rem(StartingAngle,180);
x = rem(x,180);
angleToMove = x;
end


