classdef VOG  < handle
    %VOG Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        eyeTracker
    end
    
    methods
        
        function Connect(this, ip, port)
           
            if ( ~exist('port','var') )
                port = 9000;
            end
            
%             if ( exist('C:\secure\Code\EyeTracker\bin\x64\Debug','file') )
%                 asm = NET.addAssembly('C:\secure\Code\EyeTracker\bin\x64\Debug\EyeTrackerRemoteClient.dll');
% 
%                 if ( ~exist('ip','var') )
%                     ip = '127.0.0.1';
%                 end
%             else
                asm = NET.addAssembly('C:\secure\code\Debug\EyeTrackerRemoteClient.dll');
                
                if ( ~exist('ip','var') )
                    ip = '10.17.101.12';
                end
%             end
            
            this.eyeTracker = VORLab.VOG.Remote.EyeTrackerClient(ip, port);
        end
        
        function result = IsRecording(this)
            status = this.eyeTracker.Status;
            result = status.Recording;
        end
        
        function SetSessionName(this, sessionName)
            if ( ~isempty( this.eyeTracker) )
                this.eyeTracker.ChangeSetting('SessionName',sessionName);
            end
        end
        
        function StartRecording(this)
            if ( ~isempty( this.eyeTracker) )
                this.eyeTracker.StartRecording();
            end
        end
        
        function StopRecording(this)
            if ( ~isempty( this.eyeTracker) )
                this.eyeTracker.StopRecording();
            end
        end
        
        function RecordEvent(this, message)
            if ( ~isempty( this.eyeTracker) )
                this.eyeTracker.RecordEvent([num2str(GetSecs) ' ' message]);
            end
        end
        
        function [files]= DownloadFile(this, path)
            files = [];
            if ( ~isempty( this.eyeTracker) )
                try
                    files = this.eyeTracker.DownloadFile();
                catch ex
                    ex
                end
                files = cell(files.ToArray)';
            end
        end
                
    end
    
    methods(Static = true)
        
        function Test()
            %%
            file = 'AmirAmir_2013_11_01_Calibration2.txt';
            vogdata = ArumeHardware.VOG.LoadVOGData( ['C:\secure\Data\dataVOGvsCoil\reprocessed\' file]);
        end
        
        function sampleDataSet = LoadVOGDataV3( datafile)
            
            import ArumeHardware.*;
            
            
        end
        
        function sampleDataSet = LoadVOGData( datafile)
            
            import ArumeHardware.*;
            
            enum.samples.T = 1;
            enum.samples.LH = 2;
            enum.samples.LV = 3;
            enum.samples.LT = 4;
            enum.samples.RH = 5;
            enum.samples.RV = 6;
            enum.samples.RT = 7;
            enum.samples.HH = 8;
            enum.samples.HV = 9;
            enum.samples.HT = 10;
            
            d = load(datafile);
            dat = VOG.FixData(d);
            
            col = enum.samples;
            
            timel = dat(:,1)*1000;
            timer = dat(:,2)*1000;
            
            t1 = min(timel(1),timer(1));
            t2 = max(timel(end),timer(end));
            
            newTimes = t1:t2;
            
            datout = zeros(length(newTimes),10);
            datout(:,col.T) = interp1(timel, timel, newTimes);
            datout(:,col.LH) = interp1(timel, dat(:,3), newTimes);
            datout(:,col.LV) = interp1(timel, dat(:,4), newTimes);
            datout(:,col.LT) = interp1(timel, dat(:,6), newTimes);
            datout(:,col.RH) = interp1(timer, dat(:,7), newTimes);
            datout(:,col.RV) = interp1(timer, dat(:,8), newTimes);
            datout(:,col.RT) = interp1(timer, dat(:,10), newTimes);
            
            sampleDataSet = dataset;
            
            sampleDataSet.TimeStamp = datout(:,col.T);
            sampleDataSet.LeftHorizontal = datout(:,col.LH);
            sampleDataSet.LeftVertical = datout(:,col.LV);
            sampleDataSet.LeftTorsion = datout(:,col.LT);
            sampleDataSet.RightHorizontal = datout(:,col.RH);
            sampleDataSet.RightVertical = datout(:,col.RV);
            sampleDataSet.RightTorsion = datout(:,col.RT);
            sampleDataSet.HeadYaw = datout(:,col.HH);
            sampleDataSet.HeadPitch = datout(:,col.HV);
            sampleDataSet.HeadRollTilt = datout(:,col.HT);
        end
        
        
        
        
        function [dat b] =  FixData(dat)
            
            import ArumeHardware.*;
            
            % remove weird samples
             dat = dat(diff(dat(:,1))~=0 & diff(dat(:,2))~=0,:);
            
            dat = VOG.FixTimestamps(dat);
             dat = VOG.Calibrate(dat);
            %% [dat b] = VOG.RemoveBlinks(dat);
        end
        
        function dat = FixTimestamps(dat)
            
%             % for old version 
%             tl = (dat(:,1) + dat(:,2)/1000/1000);
%             tr = tl;
%             dat(:,1) = tl;
%             dat(:,2) = tr;
%             return
            
            % for new version
            tl = dat(:,1) - dat(1);
            dt = diff(tl);
             dt(dt<0) = dt(dt<0)+128;
%             dt(dt<0) = 0;
            dt(dt>10) = 0;
            tl = [0;cumsum(dt)];
            
            
            tr = dat(:,2) - dat(1);
            dt = diff(tr);
            dt(dt<0) = dt(dt<0)+128;
%             dt(dt<0) = 0;
            dt(dt>10) = 0;
            tr = [0;cumsum(dt)];
            
            dat(:,1) = tl;
            dat(:,2) = tr;
        end
        
        function [dat blinks] = RemoveBlinks(dat)
            
            blinks = zeros(length(dat),2);
            
            b = abs(diff([dat(:,3);0])) > 5 | abs(dat(:,3)) > 90;
            b = boxcar(b,10);
            b = b>0;
            dat(b,[3 4 6 ]) = 1000;
            
            blinks(:,1) = b;
            
            b = abs(diff([dat(:,7);0])) > 5 | abs(dat(:,3)) > 90;
            b = boxcar(b,10);
            b = b>0;
            dat(b,[7 8 10 ]) = 1000;
            
            
            blinks(:,2) = b;
        end
        
        function dat = Calibrate(dat)
            
%             olx = 138;
%             orx = 131;
%            
%             oly = 132;
%             ory = 106;
%             
%             glx = 40/(208-68);
%             grx = 40/(208-68);
%             
%             gly = 20/(133-70);
%             gry = 20/(133-70);
%             
%             dat(:,3) = -(dat(:,3)-olx)*glx;
%             dat(:,7) = -(dat(:,7)-orx)*grx;
%             
%             dat(:,4) = -(dat(:,4)-oly)*gly;
%             dat(:,8) = -(dat(:,8)-ory)*gry;
            
            rlx = median(dat(~isnan(dat(:,3)),3));
            rrx = median(dat(~isnan(dat(:,7)),7));
            
            rly = median(dat(~isnan(dat(:,4)),4));
            rry = median(dat(~isnan(dat(:,8)),8));
            
            
            dat(:,3) = -asin((dat(:,3)-rlx)/160)/pi*180;
            dat(:,7) = -asin((dat(:,7)-rrx)/160)/pi*180;
            
            dat(:,4) = -asin((dat(:,4)-rly)/160)/pi*180;
            dat(:,8) = -asin((dat(:,8)-rry)/160)/pi*180;
            
        end
        
    end
    
end



