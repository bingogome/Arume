classdef Coil
    %COIL Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static = true)
        
        function Test()
            %%
            coildata = ArumeHardware.Coil.LoadCoilData( 'C:\secure\Data\dataVOGvsCoil\raw\Amir_2013_11_01\coil\HV2', 'C:\secure\Data\dataVOGvsCoil\raw\Amir_2013_11_01\coil\SH_GAINS' );
        end
        
        function sampleDataSet = LoadCoilData( datafile, gainsfile )
            
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
            
            % load data
            [dat,params] = Coil.RexLoad(datafile);
            gains = load(gainsfile);
            
            % normalize data
            dataCoilInFrame = Coil.NormalizeData(dat,gains);
            
            % get reference (reference = eye looking straight ahead from
            % the middle of the frame)
            CoilInEye = reshape(mean(dataCoilInFrame(1:1,:,:),1),3,3);
            
            % get position relative to reference
            datEyeInFrame = dataCoilInFrame;
            for idx=1:length(dataCoilInFrame)
                datEyeInFrame(idx,:,:) = reshape(dataCoilInFrame(idx,:,:),3,3)*CoilInEye';
            end
            
            V = asin(datEyeInFrame(:,3,1));
            H = asin(datEyeInFrame(:,2,1)./cos(V));
            T = -asin(datEyeInFrame(:,3,2)./cos(V));
            
            col = enum.samples;
            datout = zeros(length(datEyeInFrame),10);
            datout(:,col.T) = 1:length(datEyeInFrame);
            datout(:,col.RH) = H*180/pi;
            datout(:,col.RV) = V*180/pi;
            datout(:,col.RT) = T*180/pi;
            
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
        
        function [datout] = NormalizeData(dat, gains)
            
            %step 1
            gdx = gains(1,1) ./ gains(3,1);
            gdy = gains(2,1) ./ gains(3,1);
            gdz = gains(3,1) ./ gains(3,1);
            gtx = gains(1,2) ./ gains(3,2);
            gty = gains(2,2) ./ gains(3,2);
            gtz = gains(3,2) ./ gains(3,2);
            
            % step 2
            dat = dat - 2048;
            
            % step 3
            datout(:,1,1) = dat(:,3) ./ gdx;
            datout(:,2,1) = dat(:,1) ./ gdy;
            datout(:,3,1) = dat(:,2) ./ gdz;
            datout(:,1,2) = dat(:,6) ./ gtx;
            datout(:,2,2) = dat(:,4) ./ gty;
            datout(:,3,2) = dat(:,5) ./ gtz;
            
            % step 4-6 ?????
            
            % step 7
            Dlengths = sqrt(datout(:,1,1).^2 + datout(:,2,1).^2 + datout(:,3,1).^2);
            Tlengths = sqrt(datout(:,1,2).^2 + datout(:,2,2).^2 + datout(:,3,2).^2);
            
            
            datout(:,1,1) = datout(:,1,1) ./ Dlengths;
            datout(:,2,1) = datout(:,2,1) ./ Dlengths;
            datout(:,3,1) = datout(:,3,1) ./ Dlengths;
            
            datout(:,1,2) = datout(:,1,2) ./ Tlengths;
            datout(:,2,2) = datout(:,2,2) ./ Tlengths;
            datout(:,3,2) = datout(:,3,2) ./ Tlengths;
            
            
            datout(:,1:3,3) = cross(datout(:,1:3,1),datout(:,1:3,2));
            
        end
        
        function [data, fp]= RexLoad(fname, subsamp, start, endd)
            
            %  [data,params] = rexload(fname, subsamp, start samp, end samp)
            %
            %  This is a convenience function that calls rexopena(),
            % rexreada(), and fclose() for you, and returns data in
            % a matrix.  It can be used to read in data all at once,
            % when the flexibility of doing the rex...() calls
            % seperately is not required.
            %
            %  You can enter anywhere from 1 to all of the parameters.
            % The defaults are subsamp=1, start=1, end=inf.
            %
            %  The "params" return value is the structure returned from the
            % call to rexopena().  See rexopena() for details.
            
            fp=rexopena(fname);
            
            if nargin == 1
                data = rexreada(fp, 0, inf);
            elseif nargin == 2
                data = rexreada(fp, 0, inf, subsamp);
            elseif nargin == 3
                data = rexreada(fp, start, inf, subsamp);
            else
                data = rexreada(fp, start, endd, subsamp);
            end
            
            fclose(fp.handle);
        end
        
    end
    
end

