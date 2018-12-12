classdef VOGAnalysis < handle
    
    methods (Static)
        function data = LoadVOGdata(dataFile)
            % LOAD VOG DATA loads the data recorded from the eye tracker
            %   into a matlab table
            %
            %   data = LoadVOGDataset(dataFile)
            %
            %   Inputs:
            %       - dataFile: full path of the file with the data.
            %
            %   Outputs:
            %       - data: eye data table
            
            if ( ~exist(dataFile, 'file') )
                error( ['Data file ' dataFile ' does not exist.']);
            end
            
            data =  readtable(dataFile);
            
            % new versions of the datafile have headers in the columns.
            % However old versions don't. If the number of columns matches
            % this list it means that the data file was recorded with a
            % version of the eye tracker previous to having headers.
            varnames = {
                'LeftFrameNumberRaw' 'LeftSeconds' 'LeftX' 'LeftY' 'LeftPupilWidth' 'LeftPupilHeight' 'LeftPupilAngle' 'LeftIrisRadius' 'LeftTorsionAngle' 'LeftUpperEyelid' 'LeftLowerEyelid' 'LeftDataQuality' ...
                'RightFrameNumberRaw' 'RightSeconds' 'RightX' 'RightY' 'RightPupilWidth' 'RightPupilHeight' 'RightPupilAngle' 'RightIrisRadius' 'RightTorsionAngle'  'RightUpperEyelid' 'RightLowerEyelid' 'RightDataQuality' ...
                'AccelerometerX' 'AccelerometerY' 'AccelerometerZ' 'GyroX' 'GyroY' 'GyroZ' 'MagnetometerX' 'MagnetometerY' 'MagnetometerZ' ...
                'KeyEvent' ...
                'Int0' 'Int1' 'Int2' 'Int3' 'Int4' 'Int5' 'Int6' 'Int7' ...
                'Double0' 'Double1' 'Double2' 'Double3' 'Double4' 'Double5' 'Double6' 'Double7' };
            if ( length(data.Properties.VariableNames) == length(varnames) )
                data.Properties.VariableNames = varnames;
            else
                data.LeftX = data.LeftPupilX;
                data.LeftY = data.LeftPupilY;
                data.LeftTorsionAngle = data.LeftTorsion;
                data.RightX = data.RightPupilX;
                data.RightY = data.RightPupilY;
                data.RightTorsionAngle = data.RightTorsion;
            end
            
            % fix the timestamps in case they are not always growing
            % (did happen in some old files because of a bug in the eye
            % tracking software).
            timestampVars = {'LeftSeconds' 'RightSeconds' 'Seconds' 'TimeStamp' 'timestamp' 'Time'};
            for i=1:length(timestampVars)
                if ( sum(strcmp(timestampVars{i},data.Properties.VariableNames))>0)
                    
                    cprintf('Yellow', sprintf('VOGAnalysis :: LoadVOGdata :: fixing some timestamps that were not always growing in %s\n', timestampVars{i}));
                    
                    t = data.(timestampVars{i});
                    dt = diff(t);
                    if ( min(dt) < 0 )
                        % replace the samples with negative time change
                        % with the typical (median) time between samples.
                        dt(dt<=0) = nanmedian(dt(dt>0));
                        % go back from diff to real time starting on the
                        % first timestamp.
                        t = cumsum([t(1);dt]);
                    end
                    data.(['UNCOCRRECTED_' timestampVars{i}]) = data.(timestampVars{i}) ;
                    data.(timestampVars{i}) = t;
                end
            end
        end
        
        function [calibrationTable] = ReadCalibration(file)
            % READ CALIBRATION Reads the XML file containing calibration
            % information about a VOG recording
            %
            %   [leftEye, rightEye] = ReadCalibration(file)
            %
            %   Inputs:
            %       - file: full path of the file with the calibration.
            %
            %   Outputs:
            %       - calibrationTable: table with all the parameters
            %       necessary to calibrate the data
            
            theStruct = [];
            
            % check if the file is an xml file
            f = fopen(file);
            S = fscanf(f,'%s');
            fclose(f);
            if ( strcmpi(S(1:5),'<?xml') )
                theStruct = parseXML(file);
            end
            
            calibrationTable = table();
            calibrationTable{'LeftEye', 'GlobeX'} = nan;
            calibrationTable{'LeftEye', 'GlobeY'} = nan;
            calibrationTable{'LeftEye', 'GlobeRadiusX'} = nan;
            calibrationTable{'LeftEye', 'GlobeRadiusY'} = nan;
            calibrationTable{'LeftEye', 'RefX'} = nan;
            calibrationTable{'LeftEye', 'RefY'} = nan;
            calibrationTable{'LeftEye', 'SignX'} = -1;
            calibrationTable{'LeftEye', 'SignY'} = -1;
            
            calibrationTable{'RightEye',:} = missing;
            calibrationTable{'RightEye', 'SignX'} = -1;
            calibrationTable{'RightEye', 'SignY'} = -1;
            
            if ~(isempty(theStruct) )
                calibrationTable{'LeftEye', 'GlobeX'}       = str2double(theStruct.Children(2).Children(2).Children(6).Children(2).Children(2).Children.Data);
                calibrationTable{'LeftEye', 'GlobeY'}       = str2double(theStruct.Children(2).Children(2).Children(6).Children(2).Children(4).Children.Data);
                calibrationTable{'LeftEye', 'GlobeRadiusX'} = str2double(theStruct.Children(2).Children(2).Children(6).Children(4).Children.Data);
                calibrationTable{'LeftEye', 'GlobeRadiusY'} = str2double(theStruct.Children(2).Children(2).Children(6).Children(4).Children.Data);
                calibrationTable{'LeftEye', 'RefX'}         = str2double(theStruct.Children(2).Children(2).Children(8).Children(6).Children(2).Children(2).Children.Data);
                calibrationTable{'LeftEye', 'RefY'}         = str2double(theStruct.Children(2).Children(2).Children(8).Children(6).Children(2).Children(4).Children.Data);
                
                calibrationTable{'RightEye', 'GlobeX'}    	= str2double(theStruct.Children(2).Children(4).Children(6).Children(2).Children(2).Children.Data);
                calibrationTable{'RightEye', 'GlobeY'}     	= str2double(theStruct.Children(2).Children(4).Children(6).Children(2).Children(4).Children.Data);
                calibrationTable{'RightEye', 'GlobeRadiusX'}= str2double(theStruct.Children(2).Children(4).Children(6).Children(4).Children.Data);
                calibrationTable{'RightEye', 'GlobeRadiusY'}= str2double(theStruct.Children(2).Children(4).Children(6).Children(4).Children.Data);
                calibrationTable{'RightEye', 'RefX'}        = str2double(theStruct.Children(2).Children(4).Children(8).Children(6).Children(2).Children(2).Children.Data);
                calibrationTable{'RightEye', 'RefY'}        = str2double(theStruct.Children(2).Children(4).Children(8).Children(6).Children(2).Children(4).Children.Data);
                
            else
                % LEGACY
                % loading calibrations for files recorded with the old
                % version of the eye tracker (the one that did not combine
                % all the files in a folder).
                [res, text] = system(['C:\secure\Code\EyeTrackerTests\TestLoadCalibration\bin\Debug\TestLoadCalibration.exe "' file ' "']);
                
                if ( res  ~= 0 )
                    disp(text);
                    return;
                end
                [dat] = sscanf(text,'LEFT EYE: %f %f %f %f %f RIGHT EYE: %f %f %f %f %f');
                
                calibrationTable{'LeftEye', 'GlobeX'} = dat(1);
                calibrationTable{'LeftEye', 'GlobeY'} = dat(2);
                calibrationTable{'LeftEye', 'GlobeRadiusX'} = dat(3);
                calibrationTable{'LeftEye', 'GlobeRadiusY'} = dat(3);
                calibrationTable{'LeftEye', 'RefX'} = dat(4);
                calibrationTable{'LeftEye', 'RefY'} = dat(5);
                
                calibrationTable{'RightEye', 'GlobeX'} = dat(6);
                calibrationTable{'RightEye', 'GlobeY'} = dat(7);
                calibrationTable{'RightEye', 'GlobeRadiusX'} = dat(8);
                calibrationTable{'RightEye', 'GlobeRadiusY'} = dat(8);
                calibrationTable{'RightEye', 'RefX'} = dat(9);
                calibrationTable{'RightEye', 'RefY'} = dat(10);
            end
            
            DEFAULT_RADIUS = 85*2;
            if ( calibrationTable{'LeftEye', 'GlobeX'} == 0 )
                disp( ' WARNING LEFT GLOBE NOT SET' )
                calibrationTable{'LeftEye', 'GlobeX'} = calibrationTable{'LeftEye', 'RefX'};
                calibrationTable{'LeftEye', 'GlobeY'} = calibrationTable{'LeftEye', 'RefY'};
                calibrationTable{'LeftEye', 'GlobeRadiusX'} = DEFAULT_RADIUS;
                calibrationTable{'LeftEye', 'GlobeRadiusY'} = DEFAULT_RADIUS;
            end
            if ( calibrationTable{'RightEye', 'GlobeX'} == 0 )
                disp( ' WARNING RIGHT GLOBE NOT SET' )
                calibrationTable{'RightEye', 'GlobeX'} = calibrationTable{'RightEye', 'RefX'};
                calibrationTable{'RightEye', 'GlobeY'} = calibrationTable{'RightEye', 'RefY'};
                calibrationTable{'RightEye', 'GlobeRadiusX'} = DEFAULT_RADIUS;
                calibrationTable{'RightEye', 'GlobeRadiusY'} = DEFAULT_RADIUS;
            end
        end
        
        function [calibrationTable] = CalculateCalibration(rawCalibrationData, targetPosition)
            
            % regress target and data to get coefficients of calibraiton
            
            calibrationTable = table();
            
            bLeftX = robustfit(targetPosition.LeftX(~isnan(targetPosition.LeftX)),rawCalibrationData.LeftX(~isnan(targetPosition.LeftX)));
            bLeftY = robustfit(targetPosition.LeftY(~isnan(targetPosition.LeftY)),rawCalibrationData.LeftY(~isnan(targetPosition.LeftY)));
            bRightX = robustfit(targetPosition.RightX(~isnan(targetPosition.RightX)),rawCalibrationData.RightX(~isnan(targetPosition.RightX)));
            bRightY = robustfit(targetPosition.RightY(~isnan(targetPosition.RightY)),rawCalibrationData.RightY(~isnan(targetPosition.RightY)));
            
            calibrationTable{'LeftEye', 'GlobeX'} = bLeftX(1);
            calibrationTable{'LeftEye', 'GlobeY'} = bLeftY(1);
            calibrationTable{'LeftEye', 'GlobeRadiusX'} = abs(60*bLeftX(2));
            calibrationTable{'LeftEye', 'GlobeRadiusY'} = abs(60*bLeftY(2));
            calibrationTable{'LeftEye', 'SignX'} = sign(bLeftX(2));
            calibrationTable{'LeftEye', 'SignY'} = sign(bLeftY(2));
            calibrationTable{'LeftEye', 'RefX'} = bLeftX(1);
            calibrationTable{'LeftEye', 'RefY'} = bLeftY(1);
            
            calibrationTable{'RightEye', 'GlobeX'} = bRightX(1);
            calibrationTable{'RightEye', 'GlobeY'} = bRightY(1);
            calibrationTable{'RightEye', 'GlobeRadiusX'} = abs(60*bRightX(2));
            calibrationTable{'RightEye', 'GlobeRadiusY'} = abs(60*bRightY(2));
            calibrationTable{'RightEye', 'SignX'} = sign(bRightX(2));
            calibrationTable{'RightEye', 'SignY'} = sign(bRightY(2));
            calibrationTable{'RightEye', 'RefX'} = bRightX(1);
            calibrationTable{'RightEye', 'RefY'} = bRightY(1);
            
            calibrationTable{'LeftEye', 'OffsetX'}  = bLeftX(1);
            calibrationTable{'LeftEye', 'GainX'}    = bLeftX(2);
            calibrationTable{'LeftEye', 'OffsetY'}  = bLeftY(1);
            calibrationTable{'LeftEye', 'GainY'}    = bLeftY(2);
            calibrationTable{'RightEye', 'OffsetX'}  = bRightX(1);
            calibrationTable{'RightEye', 'GainX'}    = bRightX(2);
            calibrationTable{'RightEye', 'OffsetY'}  = bRightY(1);
            calibrationTable{'RightEye', 'GainY'}    = bRightY(2);
            
        end
        
        function [calibrationTable] = CalculateCalibrationCR(rawCalibrationData, targetPosition)
            
            % regress target and data to get coefficients of calibraiton
            
            calibrationTable = table();
            rawCalibrationData.LeftCR1X(rawCalibrationData.LeftCR1X==0) = nan;
            rawCalibrationData.LeftCR1Y(rawCalibrationData.LeftCR1Y==0) = nan;
            rawCalibrationData.RightCR1X(rawCalibrationData.RightCR1X==0) = nan;
            rawCalibrationData.RightCR1Y(rawCalibrationData.RightCR1Y==0) = nan;
            
            lx = rawCalibrationData.LeftX - rawCalibrationData.LeftCR1X;
            ly = rawCalibrationData.LeftY - rawCalibrationData.LeftCR1Y;
            rx = rawCalibrationData.RightX - rawCalibrationData.RightCR1X;
            ry = rawCalibrationData.RightY - rawCalibrationData.RightCR1Y;
            bLeftX = robustfit(targetPosition.LeftX(~isnan(targetPosition.LeftX)),lx(~isnan(targetPosition.LeftX)));
            bLeftY = robustfit(targetPosition.LeftY(~isnan(targetPosition.LeftY)),ly(~isnan(targetPosition.LeftY)));
            bRightX = robustfit(targetPosition.RightX(~isnan(targetPosition.RightX)),rx(~isnan(targetPosition.RightX)));
            bRightY = robustfit(targetPosition.RightY(~isnan(targetPosition.RightY)),ry(~isnan(targetPosition.RightY)));
            
            calibrationTable{'LeftEye', 'GlobeX'} = bLeftX(1);
            calibrationTable{'LeftEye', 'GlobeY'} = bLeftY(1);
            calibrationTable{'LeftEye', 'GlobeRadiusX'} = abs(60*bLeftX(2));
            calibrationTable{'LeftEye', 'GlobeRadiusY'} = abs(60*bLeftY(2));
            calibrationTable{'LeftEye', 'SignX'} = sign(bLeftX(2));
            calibrationTable{'LeftEye', 'SignY'} = sign(bLeftY(2));
            calibrationTable{'LeftEye', 'RefX'} = bLeftX(1);
            calibrationTable{'LeftEye', 'RefY'} = bLeftY(1);
            
            calibrationTable{'RightEye', 'GlobeX'} = bRightX(1);
            calibrationTable{'RightEye', 'GlobeY'} = bRightY(1);
            calibrationTable{'RightEye', 'GlobeRadiusX'} = abs(60*bRightX(2));
            calibrationTable{'RightEye', 'GlobeRadiusY'} = abs(60*bRightY(2));
            calibrationTable{'RightEye', 'SignX'} = sign(bRightX(2));
            calibrationTable{'RightEye', 'SignY'} = sign(bRightY(2));
            calibrationTable{'RightEye', 'RefX'} = bRightX(1);
            calibrationTable{'RightEye', 'RefY'} = bRightY(1);
            
            calibrationTable{'LeftEye', 'OffsetX'}  = bLeftX(1);
            calibrationTable{'LeftEye', 'GainX'}    = bLeftX(2);
            calibrationTable{'LeftEye', 'OffsetY'}  = bLeftY(1);
            calibrationTable{'LeftEye', 'GainY'}    = bLeftY(2);
            calibrationTable{'RightEye', 'OffsetX'}  = bRightX(1);
            calibrationTable{'RightEye', 'GainX'}    = bRightX(2);
            calibrationTable{'RightEye', 'OffsetY'}  = bRightY(1);
            calibrationTable{'RightEye', 'GainY'}    = bRightY(2);
            
        end
        
        function [calibratedData] = CalibrateDataCR(rawData, calibrationTable )
            % CALIBRATE DATA calibrates the raw data from pixels to degrees
            %
            %  [calibratedData] = CalibrateData(rawData, calibrationTable, [targetOnForDriftCorrection])
            %
            %   Inputs:
            %       - rawData: raw data table
            %       - calibrationTable: table with the calibration parameters
            %
            %   Outputs:
            %       - calibratedData: calibrated data
            
            
            if ( calibrationTable{'LeftEye', 'GlobeX'} == 0 )
                disp( ' WARNING GLOBE NOT SET' )
                calibrationTable{'LeftEye', 'GlobeX'} = calibrationTable{'LeftEye', 'RefX'};
                calibrationTable{'LeftEye', 'GlobeY'} = calibrationTable{'LeftEye', 'RefY'};
                calibrationTable{'LeftEye', 'GlobeRadiusX'} = 85*2;
                calibrationTable{'LeftEye', 'GlobeRadiusY'} = 85*2;
                calibrationTable{'LeftEye', 'SignX'} = -1;
                calibrationTable{'LeftEye', 'SignY'} = -1;
            end
            if ( calibrationTable{'RightEye', 'GlobeX'} == 0 )
                disp( ' WARNING GLOBE NOT SET' )
                calibrationTable{'RightEye', 'GlobeX'} = calibrationTable{'RightEye', 'RefX'};
                calibrationTable{'RightEye', 'GlobeY'} = calibrationTable{'RightEye', 'RefY'};
                calibrationTable{'RightEye', 'GlobeRadiusX'} = 85*2;
                calibrationTable{'RightEye', 'GlobeRadiusY'} = 85*2;
                calibrationTable{'RightEye', 'SignX'} = -1;
                calibrationTable{'RightEye', 'SignY'} = -1;
            end
            
            
            lx = rawData.LeftX - rawData.LeftCR1X;
            ly = rawData.LeftY - rawData.LeftCR1Y;
            rx = rawData.RightX - rawData.RightCR1X;
            ry = rawData.RightY - rawData.RightCR1Y;
            
            
            t = (rawData.LeftSeconds-rawData.LeftSeconds(1))*1000;
            lx = calibrationTable{'LeftEye', 'SignX'}*(lx- calibrationTable{'LeftEye', 'RefX'})/calibrationTable{'LeftEye', 'GlobeRadiusX'}*60;
            ly = calibrationTable{'LeftEye', 'SignY'}*(ly - calibrationTable{'LeftEye', 'RefY'})/calibrationTable{'LeftEye', 'GlobeRadiusY'}*60;
            rx = calibrationTable{'RightEye', 'SignX'}*(rx - calibrationTable{'RightEye', 'RefX'})/calibrationTable{'RightEye', 'GlobeRadiusX'}*60;
            ry = calibrationTable{'RightEye', 'SignY'}*(ry - calibrationTable{'RightEye', 'RefY'})/calibrationTable{'RightEye', 'GlobeRadiusY'}*60;
            
            lt = rawData.LeftTorsionAngle;
            rt = rawData.RightTorsionAngle;
            
            lel = rawData.LeftUpperEyelid;
            rel = rawData.RightUpperEyelid;
            
            lell = rawData.LeftLowerEyelid;
            rell = rawData.RightLowerEyelid;
            
            lp = (rawData.LeftPupilWidth+rawData.LeftPupilHeight)/2;
            rp = (rawData.RightPupilWidth+rawData.RightPupilHeight)/2;
            
            if ( any(strcmp(rawData.Properties.VariableNames,'LeftFrameNumber') ) )
                f = rawData.LeftFrameNumber;
            else
                f = rawData.LeftFrameNumberRaw;
            end
            fr = rawData.LeftFrameNumberRaw;
            
            calibratedData = table(t, f, fr, lx, ly, lt, rx, ry, rt, lel,rel,lell,rell, lp, rp, ...
                'VariableNames',{'Time' 'FrameNumber', 'FrameNumberRaw', 'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT' 'LeftUpperLid' 'RightUpperLid'  'LeftLowerLid' 'RightLowerLid' 'LeftPupil' 'RightPupil'});
            
            headData = table( rawData.AccelerometerX, rawData.AccelerometerY, rawData.AccelerometerZ, rawData.GyroX, rawData.GyroY, rawData.GyroZ, ...
                'VariableNames', {'HeadRoll', 'HeadPitch', 'HeadYaw', 'HeadRollVel', 'HeadPitchVel', 'HeadYawVel'});
            
            calibratedData = [calibratedData headData];
            
            % TODO: drift correction
            
        end
        
        function [calibratedData] = CalibrateData(rawData, calibrationTable )
            % CALIBRATE DATA calibrates the raw data from pixels to degrees
            %
            %  [calibratedData] = CalibrateData(rawData, calibrationTable, [targetOnForDriftCorrection])
            %
            %   Inputs:
            %       - rawData: raw data table
            %       - calibrationTable: table with the calibration parameters
            %
            %   Outputs:
            %       - calibratedData: calibrated data
            
            geomCorrected = 0;
            
            % TODO: deal with corneal reflections...
            
            if ( ~geomCorrected )
                t = (rawData.LeftSeconds-rawData.LeftSeconds(1));
                lx = calibrationTable{'LeftEye', 'SignX'}*(rawData.LeftX - calibrationTable{'LeftEye', 'RefX'})/calibrationTable{'LeftEye', 'GlobeRadiusX'}*60;
                ly = calibrationTable{'LeftEye', 'SignY'}*(rawData.LeftY - calibrationTable{'LeftEye', 'RefY'})/calibrationTable{'LeftEye', 'GlobeRadiusY'}*60;
                rx = calibrationTable{'RightEye', 'SignX'}*(rawData.RightX - calibrationTable{'RightEye', 'RefX'})/calibrationTable{'RightEye', 'GlobeRadiusX'}*60;
                ry = calibrationTable{'RightEye', 'SignY'}*(rawData.RightY - calibrationTable{'RightEye', 'RefY'})/calibrationTable{'RightEye', 'GlobeRadiusY'}*60;
                
                lt = rawData.LeftTorsionAngle;
                rt = rawData.RightTorsionAngle;
                
                lel = rawData.LeftUpperEyelid;
                rel = rawData.RightUpperEyelid;
                
                lell = rawData.LeftLowerEyelid;
                rell = rawData.RightLowerEyelid;
                
                lp = (rawData.LeftPupilWidth+rawData.LeftPupilHeight)/2;
                rp = (rawData.RightPupilWidth+rawData.RightPupilHeight)/2;
                
                if ( any(strcmp(rawData.Properties.VariableNames,'LeftFrameNumber') ) )
                    f = rawData.LeftFrameNumber;
                else
                    f = rawData.LeftFrameNumberRaw;
                end
                fr = rawData.LeftFrameNumberRaw;
                
            else
                
                t = (rawData.LeftSeconds-rawData.LeftSeconds(1));
                
                referenceXDeg = asin((calibrationTable{'LeftEye', 'RefX'} - calibrationTable{'LeftEye', 'GlobeX'}) / calibrationTable{'LeftEye', 'GlobeRadiusX'}) * 180 / pi;
                referenceYDeg = asin((calibrationTable{'LeftEye', 'RefY'} - calibrationTable{'LeftEye', 'GlobeY'}) / calibrationTable{'LeftEye', 'GlobeRadiusY'}) * 180 / pi;
                
                lx = asin((rawData.LeftX - calibrationTable{'LeftEye', 'GlobeX'}) / calibrationTable{'LeftEye', 'GlobeRadiusX'}) * 180 / pi;
                ly = asin((rawData.LeftY - calibrationTable{'LeftEye', 'GlobeY'}) / calibrationTable{'LeftEye', 'GlobeRadiusY'}) * 180 / pi;
                
                lx = -(lx - referenceXDeg) ;
                ly = -(ly - referenceYDeg);
                
                referenceXDeg = asin((calibrationTable{'RightEye', 'RefX'} - calibrationTable{'RightEye', 'GlobeX'}) / calibrationTable{'RightEye', 'GlobeRadiusX'}) * 180 / pi;
                referenceYDeg = asin((calibrationTable{'RightEye', 'RefY'} - calibrationTable{'RightEye', 'GlobeY'}) / calibrationTable{'RightEye', 'GlobeRadiusY'}) * 180 / pi;
                
                rx = asin((rawData.RightX - calibrationTable{'RightEye', 'GlobeX'}) / calibrationTable{'RightEye', 'GlobeRadiusX'}) * 180 / pi;
                ry = asin((rawData.RightY - calibrationTable{'RightEye', 'GlobeY'}) / calibrationTable{'RightEye', 'GlobeRadiusY'}) * 180 / pi;
                
                rx = -(rx - referenceXDeg) ;
                ry = -(ry - referenceYDeg);
                
                lt = rawData.LeftTorsionAngle;
                rt = rawData.RightTorsionAngle;
                
                if ( sum(rawData.LeftFrameNumberRaw) > 0 )
                    f = rawData.LeftFrameNumberRaw;
                else
                    f = rawData.RightFrameNumberRaw;
                end
                
                lel = rawData.LeftUpperEyelid;
                rel = rawData.RightUpperEyelid;
                lell = rawData.LeftLowerEyelid;
                rell = rawData.RightLowerEyelid;
                
                lp = rawData.LeftPupilWidth;
                rp = rawData.RightPupilWidth;
            end
            
            calibratedData = table(t, f, fr, lx, ly, lt, rx, ry, rt, lel,rel,lell,rell, lp, rp, ...
                'VariableNames',{'Time' 'FrameNumber', 'FrameNumberRaw', 'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT' 'LeftUpperLid' 'RightUpperLid'  'LeftLowerLid' 'RightLowerLid' 'LeftPupil' 'RightPupil'});
            
            headData = table( rawData.AccelerometerX, rawData.AccelerometerY, rawData.AccelerometerZ, rawData.GyroX, rawData.GyroY, rawData.GyroZ, ...
                'VariableNames', {'HeadRoll', 'HeadPitch', 'HeadYaw', 'HeadRollVel', 'HeadPitchVel', 'HeadYawVel'});
            
            calibratedData = [calibratedData headData];
            
            % TODO: drift correction
            
        end
        
        function [detrendedData, trend] = DetrendData(data, targetOnForDriftCorrection, windowSize)
            % DETREND DATA perfoms drift correction using samples where
            % we can asume the subject was looking at a central (0,0)
            % target.
            %
            %  [detrendedData] = DetrendData(rawData, targetOnForDriftCorrection)
            %
            %   Inputs:
            %       - rawData: raw data table
            %       - targetOnForDriftCorrection: variable of the same
            %       length as rawData with ones on the samples where the we
            %       can asume the subject was looking at a central (0,0)
            %       and zero or nan otherwise.
            %       - windowSize: size of the window for the trending
            %       filter. In samples.
            %
            %   Outputs:
            %       - detrendedData: detrended data
            
            
            fields = {'LeftX' 'LeftY' 'RightX' 'RightY'};
            
            detrendedData = data;
            trend = table();
            % detrend the data
            for field = fields
                field = field{1};
                x = data{:,field};
                x(targetOnForDriftCorrection) = nan;
                trend.(field) = nanmedfilt(x,windowSize);
                trend.(field) = trend.(field) - nanmedian(trend{1:min(50000,end), field});
                detrendedData{:,field} = data{:,field} - trend{:,field};
            end
        end
        
        function params = GetParameters()
            % GET RESAMPLE AND CLEAN DATA PARAMS gets the default
            % parameters for the cleaning and resampling of eye data.
            %
            %  params = GetResampleAndCleanDataParams()
            %
            %   Inputs:
            %
            %   Outputs:
            %       - params: parameters for the processing.
            %
            
            %% PARAMETERS
            params = [];
            params.smoothRloessSpan = 5;
            params.blinkSpan = 200; % ms
            params.pupilSizeTh = 10; % in percent of smooth pupil size
            params.pupilSizeChangeTh = 10000;
            params.HMaxRange = 1000; %60;
            params.VMaxRange = 1000; %60;
            params.TMaxRange = 20;
            params.HVelMax = 500;
            params.VVelMax = 500;
            params.TVelMax = 200;
            params.DETECT_FLAT_PERIODS = 1;
            params.VFAC = 4; % saccade detection threshold factor
            params.HFAC = 4;
            params.InterPeakMinInterval = 50; % ms
            params.units = 'seconds'; % could also be miliseconds
            params.Remove_Bad_Data = 1;
            params.Interpolate_Spikes_of_Bad_Data = 1;
        end
        
        function [eyes, eyeSignals, headSignals] = GetEyesAndSignals(calibratedData)
            
            eyes = {};
            if ( sum(strcmp('RightX',calibratedData.Properties.VariableNames))>0 )
                eyes{end+1} = 'Right';
            end
            if ( sum(strcmp('LeftX',calibratedData.Properties.VariableNames))>0 )
                eyes{end+1} = 'Left';
            end
            
            eyeSignals = {};
            if ( sum(strcmp('RightX',calibratedData.Properties.VariableNames))>0 || sum(strcmp('LeftX',calibratedData.Properties.VariableNames))>0 )
                eyeSignals{end+1} = 'X';
            end
            if ( sum(strcmp('RightY',calibratedData.Properties.VariableNames))>0 || sum(strcmp('LeftY',calibratedData.Properties.VariableNames))>0 )
                eyeSignals{end+1} = 'Y';
            end
            if ( sum(strcmp('RightT',calibratedData.Properties.VariableNames))>0 || sum(strcmp('LeftT',calibratedData.Properties.VariableNames))>0 )
                eyeSignals{end+1} = 'T';
            end
            if ( sum(strcmp('RightPupil',calibratedData.Properties.VariableNames))>0 || sum(strcmp('LeftPupil',calibratedData.Properties.VariableNames))>0 )
                eyeSignals{end+1} = 'Pupil';
            end
            if ( sum(strcmp('RightLowerLid',calibratedData.Properties.VariableNames))>0 || sum(strcmp('LeftLowerLid',calibratedData.Properties.VariableNames))>0 )
                eyeSignals{end+1} = 'LowerLid';
                eyeSignals{end+1} = 'UpperLid';
            end
            
            headSignals = {};
            if ( sum(strcmp('Q1',calibratedData.Properties.VariableNames))>0 || sum(strcmp('HeadQ1',calibratedData.Properties.VariableNames))>0 )
                headSignals{end+1} = 'Q1';
                headSignals{end+1} = 'Q2';
                headSignals{end+1} = 'Q3';
                headSignals{end+1} = 'Q4';
            end
        end
        
        function [resampledData, cleanedData] = ResampleAndCleanData(calibratedData, params)
            % RESAMPLE AND CLEAN DATA Resampes eye data to 500 Hz and
            % cleans all the data that may be blinks or bad tracking
            %
            %   [resampledData] = ResampleAndCleanData(calibratedData, params)
            %
            %   Inputs:
            %       - calibratedData: calibrated data
            %       - params: parameters for the processing.
            %
            %   Outputs:
            %       - resampledData: 500Hz resampled and clean data
            
            try
                tic
                
                % Create frame number if not available
                if ( sum(strcmp('FrameNumber',calibratedData.Properties.VariableNames))>0)
                    calibratedData.FrameNumber = calibratedData.FrameNumber;
                else
                    frameNumber = cumsum(round(diff(calibratedData.Time)/median(diff(calibratedData.Time))));
                    calibratedData.FrameNumber = [0;frameNumber];
                end
                
                % Make sure timestamps are in seconds from now on
                switch(params.units)
                    case 'seconds'
                        calibratedData.Time = calibratedData.Time;
                    case 'miliseconds'
                        calibratedData.Time = calibratedData.Time/1000;
                end
                
                % find what signals are present in the data
                [eyes, eyeSignals, headSignals] = VOGAnalysis.GetEyesAndSignals(calibratedData);
                
                % ---------------------------------------------------------
                % Interpolate missing frames
                %----------------------------------------------------------
                % Find missing frames and intorpolate them
                % It is possible that some frames were dropped during the
                % recording. We will interpolate them. But only if they are
                % just a few in a row. If there are many we will fill with
                % NaNs. The fram numbers and the timestamps will be
                % interpolated regardless. From now on frame numbers and
                % timestamps cannot be NaN and they must follow a continued
                % growing interval
                
                cleanedData = table;    % cleaned data
                resampledData = table;  % resampled data at 500Hz
                
                % calcualte the samplerate
                totalNumberOfFrames = calibratedData.FrameNumberRaw(end) - calibratedData.FrameNumberRaw(1)+1;
                totalTime           = calibratedData.Time(end) - calibratedData.Time(1);
                rawSampleRate       = (totalNumberOfFrames-1)/totalTime;
                
                % find dropped and not dropped frames
                notDroppedFrames = calibratedData.FrameNumber - calibratedData.FrameNumber(1) + 1;
                droppedFrames = ones(max(notDroppedFrames),1);
                droppedFrames(notDroppedFrames) = 0;
                interpolableFrames = droppedFrames-imopen(droppedFrames,ones(3)); % 1 or 2 frames in a row, not more
                
                % create the new continuos FrameNumber and Time variables 
                % but also save the original raw frame numbers and time
                % stamps with NaNs in the dropped frames.
                cleanedData.FrameNumber     = (1:max(notDroppedFrames))';
                cleanedData.Time            = (cleanedData.FrameNumber-1)/rawSampleRate;
                cleanedData.RawFrameNumber  = nan(height(cleanedData), 1);
                cleanedData.RawCameraFrameNumber         = nan(height(cleanedData), 1);
                cleanedData.RawTime         = nan(height(cleanedData), 1);
                cleanedData.RawFrameNumber(notDroppedFrames)        = calibratedData.FrameNumber;
                cleanedData.RawCameraFrameNumber(notDroppedFrames)  = calibratedData.FrameNumberRaw;
                cleanedData.RawTime(notDroppedFrames)        = calibratedData.Time;
                cleanedData.DroppedFrame    = droppedFrames;
                
                % interpolate signals
                signalsToInterpolate = {};
                for i=1:length(eyes)
                    for j=1:length(eyeSignals)
                        signalsToInterpolate{end+1} = [eyes{i} eyeSignals{j}];
                    end
                end
                for j=1:length(headSignals)
                    signalsToInterpolate{end+1} = ['Head' headSignals{j}];
                end
                
                for i=1:length(signalsToInterpolate)
                    signalName = signalsToInterpolate{i};
                    
                    cleanedData.(signalName)            = nan(height(cleanedData), 1); % signal that will be cleaned
                    cleanedData.([signalName 'Raw'])    = nan(height(cleanedData), 1); % raw signal with nans in dropped frames
                    cleanedData.([signalName 'RawInt']) = nan(height(cleanedData), 1); % almost raw signal with some interpolated dropped frames
                    
                    cleanedData.([signalName 'Raw'])(notDroppedFrames)  = calibratedData.(signalName);
                    
                    % interpolate missing frames but only if they are
                    % 2 or less in a row. Otherwise put nans in there.
                    datInterp = interp1(notDroppedFrames, cleanedData.([signalName 'Raw'])(notDroppedFrames),  cleanedData.FrameNumber );
                    datInterp(droppedFrames & ~interpolableFrames) = nan;
                    cleanedData.([signalName 'RawInt']) = datInterp;
                    
                    cleanedData.(signalName) = datInterp;
                end
                
                % ---------------------------------------------------------
                % End interpolate missing samples
                %----------------------------------------------------------
                
                
                % ---------------------------------------------------------
                % Find bad samples
                %----------------------------------------------------------
                % We will use multiple heuristics to determine portions of
                % data that may not be good. Then we will interpolate short
                % spikes of bad data while removing everything else bad
                % plus some padding around
                % Find bad samples
                for i=1:length(eyes)
                    
                    % collect signals
                    dt = diff(cleanedData.Time);
                    x = cleanedData.([eyes{i} 'X']);
                    y = cleanedData.([eyes{i} 'Y']);
                    t = cleanedData.([eyes{i} 'T']);
                    vx = [0;diff(x)./dt];
                    vy = [0;diff(y)./dt];
                    vt = [0;diff(t)./dt];
                    accx = [0;diff(vx)./dt];
                    accy = [0;diff(vy)./dt];
                    acct = [0;diff(vt)./dt];
                    acc = sqrt(accx.^2+accy.^2);
                    
                    
                    badData = isnan(x) | isnan(y);
                    badPupil = nan(size(badData));
                    
                    % Calculate a smooth version of the pupil size to detect changes in
                    % pupil size that are not normal. Thus, must be blinks or errors in
                    % tracking. Downsample the signal to speed up the smoothing.
                    if ( ismember('Pupil', eyeSignals) && length( cleanedData.([eyes{i} 'Pupil'])) > 200)
                        pupil = cleanedData.([eyes{i} 'Pupil']);
                        pupilDecimated = pupil(1:25:end); %decimate the pupil signal
                        if ( exist('smooth','file') )
                            pupilSmooth = smooth(pupilDecimated,params.smoothRloessSpan*rawSampleRate/25/length(pupilDecimated),'rloess');
                        else
                            pupilSmooth = nanmedfilt(pupilDecimated,round(params.smoothRloessSpan*rawSampleRate/25));
                        end
                        pupilSmooth = interp1((1:25:length(pupil))',pupilSmooth,(1:length(pupil))');
                        
                        cleanedData.([eyes{i} 'Pupil']) = pupilSmooth;
                        
                        % find blinks and other abnormal pupil sizes or eye movements
                        pth = nanmean(pupilSmooth)*params.pupilSizeTh/100;
                        badPupil = abs(pupilSmooth-pupil) > pth ...                 % pupil size far from smooth pupil size
                            | abs([0;diff(pupil)*rawSampleRate]) > params.pupilSizeChangeTh;        % pupil size changes too suddenly from sample to sample
                        
                        badData = badData | badPupil;
                    end
                    
                    % find blinks and other abnormal pupil sizes or eye movements
                    
                    badPosition = abs(x) > params.HMaxRange ...	% Horizontal eye position out of range
                        | abs(y) > params.VMaxRange;         	% Vertical eye position out of range
                    
                    badVelocity = abs(vx) > params.HVelMax ...	% Horizontal eye velocity out of range
                        | abs(vy) > params.VVelMax;             % Vertical eye velocity out of range
                    
                    badAcceleration = acc>50000;
                    
                    badData = badData | badPosition | badVelocity | badAcceleration;
                    
                    badFlatPeriods = nan(size(badData));
                    if ( params.DETECT_FLAT_PERIODS )
                        % if three consecutive samples are the same value this main they
                        % are interpolated
                        badFlatPeriods =  boxcar([nan;abs(diff(x))],2) == 0 ...
                            | boxcar([nan;abs(diff(y))],2) == 0;
                        
                        badData = badData | badFlatPeriods;
                    end
                    
                    % spikes of good data in between bad data are probably bad
                    badData = imclose(badData,ones(10));
                    badDataT = badData | abs(t) > params.TMaxRange | abs(vt) > params.TVelMax;
                    badDataT = imclose(badDataT,ones(10));
                    
                    % but spikes of bad data in between good data can be
                    % interpolated
                    % find spikes of bad data. Single bad samples surrounded by at least 2
                    % good samples to each side
                    spikes  = badData & ( boxcar(~badData, 3)*3 >= 2 );
                    spikest = badDataT & ( boxcar(~badData, 3)*3 >= 2 );
                    
                    % TODO: maybe better than blink span find the first N samples
                    % around the blink that are within a more stringent criteria
                    badData  = boxcar( badData  & ~spikes, round(params.blinkSpan/1000*rawSampleRate))>0;
                    badDataT = boxcar( badDataT & ~spikest, round(params.blinkSpan/1000*rawSampleRate))>0;
                    
                    cleanedData.([eyes{i} 'Spikes']) = spikes;
                    cleanedData.([eyes{i} 'BadData']) = badData;
                    cleanedData.([eyes{i} 'SpikesT']) = spikest;
                    cleanedData.([eyes{i} 'BadDataT']) = badDataT;
                    
                    cleanedData.([eyes{i} 'BadPupil'])          = badPupil;
                    cleanedData.([eyes{i} 'BadPosition'])       = badPosition;
                    cleanedData.([eyes{i} 'BadVelocity'])       = badVelocity;
                    cleanedData.([eyes{i} 'BadAcceleration'])   = badAcceleration;
                    cleanedData.([eyes{i} 'BadFlatPeriods'])    = badFlatPeriods;
                    
                    % Clean up data
                    for j=1:length(eyeSignals)
                        if ( ~strcmp(eyeSignals{j},'T') )
                            badData = cleanedData.([eyes{i} 'BadData']);
                            spikes = cleanedData.([eyes{i} 'Spikes']);
                            
                            if ( params.Remove_Bad_Data )
                                % put nan on bad samples of data (blinks)
                                cleanedData.([eyes{i} eyeSignals{j}])(badData) = nan;
                            end
                            if ( params.Interpolate_Spikes_of_Bad_Data )
                                % interpolate single spikes of bad data
                                cleanedData.([eyes{i} eyeSignals{j}])(spikes)  = interp1(find(~spikes),cleanedData.([eyes{i} eyeSignals{j}])(~spikes),  find(spikes));
                            end
                        else
                            badDataT = cleanedData.([eyes{i} 'BadDataT']);
                            spikest = cleanedData.([eyes{i} 'SpikesT']);
                            
                            if ( params.Remove_Bad_Data )
                                % put nan on bad samples of data (blinks)
                                cleanedData.([eyes{i} eyeSignals{j}])(badDataT) = nan;
                            end
                            if ( params.Interpolate_Spikes_of_Bad_Data )
                                % interpolate single spikes of bad data
                                cleanedData.([eyes{i} eyeSignals{j}])(spikest)  = interp1(find(~spikest),cleanedData.([eyes{i} eyeSignals{j}])(~spikest),  find(spikest));
                            end
                        end
                    end
                    
                end
                
                %% Upsample to 500Hz
                resampleRate = 500;
                t = cleanedData.Time;
                
                rest = (0:1/resampleRate:max(t))';
                resampledData.Time = rest;
                resampledData.RawFrameNumber = interp1(t(~isnan(cleanedData.RawFrameNumber) & ~isnan(t)),cleanedData.RawFrameNumber(~isnan(cleanedData.RawFrameNumber) & ~isnan(t)),rest,'nearest');
                resampledData.RawCameraFrameNumber = interp1(t(~isnan(cleanedData.RawCameraFrameNumber) & ~isnan(t)),cleanedData.RawCameraFrameNumber(~isnan(cleanedData.RawCameraFrameNumber) & ~isnan(t)),rest,'nearest');
                resampledData.FrameNumber = interp1(t(~isnan(cleanedData.FrameNumber) & ~isnan(t)),cleanedData.FrameNumber(~isnan(cleanedData.FrameNumber) & ~isnan(t)),rest,'nearest');
                for i=1:length(eyes)
                    for j=1:length(eyeSignals)
                        signalName = [eyes{i} eyeSignals{j}];
                        x = cleanedData.(signalName);
                        
                        resampledData.(signalName) = nan(size(rest));
                        if ( sum(~isnan(x)) > 100 ) % if not everything is nan
                            % interpolate nans so the resampling does not
                            % propagate nans
                            xNoNan = interp1(find(~isnan(x)),x(~isnan(x)),1:length(x),'spline');
                            % upsample
                            resampledData.(signalName) = interp1(t, xNoNan,rest,'pchip');
                            % set nans in the upsampled signal
                            xnan = interp1(t, double(isnan(x)),rest);
                            resampledData.(signalName)(xnan>0) = nan;
                        end
                    end
                end
                
                
                resampledData.Properties.UserData.sampleRate = resampleRate;
                resampledData.Properties.UserData.params = params;
                if (1) % TODO: this may need to be optional eventually for memory issues
                    resampledData.Properties.UserData.cleanedData = cleanedData;
                    resampledData.Properties.UserData.calibratedData = calibratedData;
                end
                
                timeCleaning = toc;
                cprintf('blue', sprintf('VOGAnalysis :: ResampleAndCleanData :: Data has %d dropped frames, %d were interpolated.\n', ...
                    sum(cleanedData.DroppedFrame), sum(interpolableFrames)) );
                
                Lbad = nan;
                Rbad = nan;
                LbadT = nan;
                RbadT = nan;
                
                if ( any(contains(eyes,'Left') ))
                    Lbad = round(mean(~cleanedData.LeftBadData)*100);
                    LbadT = round(mean(~cleanedData.LeftBadDataT)*100);
                end
                if ( any(contains(eyes,'Right') ))
                    Rbad = round(mean(~cleanedData.RightBadData)*100);
                    RbadT = round(mean(~cleanedData.RightBadDataT)*100);
                end
                cprintf('blue', sprintf('VOGAnalysis :: ResampleAndCleanData :: Data cleaned in %0.1f s: LXY %d%%%% RXY %d%%%% LT %d%%%% RT %d%%%% is good data.\n', ...
                    timeCleaning, Lbad, Rbad, LbadT, RbadT ));
                
            catch ex
                getReport(ex)
            end
        end
        
        function [data] = DetectQuickPhases(data, params)
            
            [eyes, eyeSignals] = VOGAnalysis.GetEyesAndSignals(data);
            eyeSignals = setdiff(eyeSignals, {'Pupil', 'LowerLid' 'UpperLid'});
            LEFT = any(strcmp(eyes,'Left'));
            RIGHT = any(strcmp(eyes,'Right'));
            
            
            
            %% FIND SACCADES in each component
            cprintf('blue','Finding saccades in each component...\n');
            for k=1:length(eyes)
                for j=1:length(eyeSignals)
                    % position
                    xx = data.([eyes{k} eyeSignals{j}]);
                    
                    % velocity
                    v = [0;diff(xx)*500];
                    
                    % TODO: think if data should be filtered prior to peak
                    % detection. I think probably yes. To remove
                    % uncertaintly given different levels of noise and
                    % frame rate of recording
                    
                    % find velocity peaks as points where acceleration
                    % changes sign or changes to nan
                    allpeaksp = find( (diff(v(1:end-1))>=0 | diff(isnan(v(1:end-1)))<0) & (diff(v(2:end))<0 | diff(isnan(v(2:end)))>0))+1;
                    allpeaksn = find( (diff(v(1:end-1))<=0 | diff(isnan(v(1:end-1)))<0) & (diff(v(2:end))>0 | diff(isnan(v(2:end)))>0))+1;
                    
                    % create signal with only the peaks
                    vp = nan(size(v));
                    vp(allpeaksn) = v(allpeaksn);
                    vp(allpeaksp) = v(allpeaksp);
                    
                    % get the low pass velocity (~slow phase velocity) as the
                    % median filter of the peaks signal
                    % Then, the high pass velocity is the raw vel. minus the low
                    % pass velocity.
                    vp = [zeros(200,1);nan(100,1);vp;nan(100,1);zeros(200,1);];
                    vlp = boxcar(nanmedfilt(vp,500),250);
                    vlp = vlp(301:end-300);
                    vhp = v - vlp;
                    vlp(isnan(v)) = nan;
                    vhp(isnan(v)) = nan;
                    % A band pass filter of the high pass filtered velocity is
                    % useful to find beginnings and ends
                    vbp = sgolayfilt(vhp,1,7);
                    vhp = vbp;
                    % acceleration
                    accx = sgolayfilt([0;diff(v)]*500,1,11);
                    
                    % find velocity peaks as points where acceleration changes sign
                    allpeaksp = find( (diff(vhp(1:end-1))>=0 | diff(isnan(vhp(1:end-1)))<0) & (diff(vhp(2:end))<0 | diff(isnan(vhp(2:end)))>0))+1;
                    allpeaksn = find( (diff(vhp(1:end-1))<=0 | diff(isnan(vhp(1:end-1)))<0) & (diff(vhp(2:end))>0 | diff(isnan(vhp(2:end)))>0))+1;
                    
                    
                    % remove high peaks with negative velocity and
                    % low peaks with positive velocities
                    allpeaksp(vhp(allpeaksp) <= 0 ) = [];
                    allpeaksn(vhp(allpeaksn) >= 0 ) = [];
                    
                    % Thresholds TODO: use clustering instead
                    vpth = min(median(vhp(allpeaksp(vhp(allpeaksp)<20)))*params.VFAC, 20);
                    vnth = max(median(vhp(allpeaksn(vhp(allpeaksn)>-20)))*params.VFAC, -20);
                    
                    % Merge positive and negate peaks and sort peaks by absolute value of
                    % peak velocity
                    
                    peakidxNotSorted = sort([allpeaksp;allpeaksn]);
                    peakvelNotSorted = vhp(peakidxNotSorted);
                    [pv, peakSortIdx] = sort(abs(peakvelNotSorted),'descend');
                    peakidx = peakidxNotSorted(peakSortIdx);
                    peakvel = vhp(peakidx);
                    peakRemove = zeros(size(peakidx));
                    peakStarts = zeros(size(peakidx));
                    peakEnds = zeros(size(peakidx));
                    currpeak = 1;
                    
                    msg = '';
                    % Starting on the largest peak find the limits of the peak and
                    % remove nearby peaks
                    % then, remove all peaks below threshold. TODO: go until a fixed
                    % rate of peaks then use cluster to separate.
                    while(currpeak < length(peakidx) && (peakvel(currpeak) > vpth || peakvel(currpeak) < vnth) )
                        if ( rem(currpeak,50)==0)
                            if (~isempty(msg))
                                fprintf(repmat('\b', 1, length(msg)));
                            end
                            msg = sprintf('Analyzing %d of %d peaks...\n',currpeak,length(peakidx));
                            fprintf(msg);
                        end
                        
                        if ( peakRemove(currpeak))
                            currpeak = currpeak+1;
                            continue;
                        end
                        
                        % peak velocity of the current peak
                        vp = peakvel(currpeak);
                        
                        % findt the begining and the end of the peak as the first
                        % sample that changes sign, i.e. crosses zero
                        
                        start = find(vbp(1:peakidx(currpeak))*sign(vp)<0 | isnan(vbp(1:peakidx(currpeak))) ,1,'last')+1;
                        finish = find(vbp(peakidx(currpeak):end)*sign(vp)<0 | isnan(vbp(peakidx(currpeak):end)) ,1,'first') + peakidx(currpeak)- 2;
                        
                        %TODO: deal with NANS
                        if ( ~isempty(start) )
                            peakStarts(currpeak) = start;
                        else
                            peakStarts(currpeak) = 1;
                        end
                        if ( ~isempty(finish))
                            peakEnds(currpeak) = finish;
                        else
                            peakEnds(currpeak) = length(vhp);
                        end
                        
                        % remove peaks within 50 ms o this end or begining of the peak
                        idx = find(abs(peakidx-peakEnds(currpeak))< params.InterPeakMinInterval/2 | abs(peakidx-peakStarts(currpeak))< params.InterPeakMinInterval/2);
                        peakRemove(setdiff(idx, currpeak)) = 1;
                        
                        currpeak = currpeak+1;
                    end
                    % mark as to be removed all peaks below threshold
                    peakRemove(currpeak:end) = 1;
                    
                    sac = [peakStarts peakEnds peakidx];
                    sac(peakRemove>0,:) = [];
                    sac = sort(sac);
                    
                    l = length(xx);
                    starts = sac(:,1);
                    stops = sac(:,2);
                    yesNo = zeros(l,1);
                    [us ius] = unique(starts);
                    yesNo(us) = yesNo(us)+ diff([ius;length(starts)+1]);
                    [us ius] = unique(stops);
                    yesNo(us) = yesNo(us)- diff([ius;length(stops)+1]);
                    yesNo = cumsum(yesNo)>0;
                    
                    
                    data.([eyes{k} 'Vel' eyeSignals{j}]) = v;
                    data.([eyes{k} 'VelHP' eyeSignals{j}]) = vhp;
                    data.([eyes{k} 'VelLP' eyeSignals{j}]) = vlp;
                    data.([eyes{k} 'VelBP' eyeSignals{j}]) = vbp;
                    data.([eyes{k} 'Accel' eyeSignals{j}]) = accx;
                    data.([eyes{k} 'QuikPhase' eyeSignals{j}]) = yesNo;
                    peaks = zeros(size(yesNo));
                    peaks(sac(:,3)) = 1;
                    data.([eyes{k} 'QuikPhasePeak' eyeSignals{j}]) = peaks>0; % make it logical
                    
                    peaks = zeros(size(yesNo));
                    peaks(peakidx) = 1;
                    data.([eyes{k} 'PeakRaw' eyeSignals{j}]) = peaks>0; % make it logical
                end
            end
            toc
            %% Finding limits of QP combining all components
            disp('Finding QP');
            tic
            if ( RIGHT )
                rqpx = data.RightQuikPhaseX;
                rqpy = data.RightQuikPhaseY;
                rpeakx = data.RightQuikPhasePeakX;
                rpeaky = data.RightQuikPhasePeakY;
                rvxhp = data.RightVelHPX;
                rvyhp = data.RightVelHPY;
                rvmax = max(abs(rvxhp), abs(rvyhp));
            end
            
            if ( LEFT )
                lqpx = data.LeftQuikPhaseX;
                lqpy = data.LeftQuikPhaseY;
                lpeakx = data.LeftQuikPhasePeakX;
                lpeaky = data.LeftQuikPhasePeakY;
                lvxhp = data.LeftVelHPX;
                lvyhp = data.LeftVelHPY;
                lvmax = max(abs(lvxhp), abs(lvyhp));
            end
            
            if ( RIGHT && LEFT )
                vmax = max(rvmax,lvmax);
                qp = rqpy | rqpx | lqpy | lqpx; % TODO!! this is not great...
            elseif ( RIGHT )
                vmax = rvmax;
                qp = rqpy | rqpx ;
            elseif (LEFT )
                vmax = lvmax;
                qp = lqpy | lqpx;
            end
            
            qp1 = find(diff([0;qp])>0);
            qp2 = find(diff([qp;0])<0);
            
            sac = zeros(length(qp1),3);
            for i=1:length(qp1)
                qpidx = qp1(i):qp2(i);
                % find the sample within the quickphase with highest velocity
                [m, imax] = max(vmax(qpidx));
                
                if ( RIGHT)
                    [rvmaxx, rimaxx] = max(abs(rvxhp(qpidx)));
                    [rvmaxy, rimaxy] = max(abs(rvyhp(qpidx)));
                    rimaxx = qp1(i)-1 + rimaxx;
                    rimaxy = qp1(i)-1 + rimaxy;
                    
                    ridx1x = find(rvxhp(1:rimaxx)*sign(rvxhp(rimaxx))<0 | isnan(rvxhp(1:rimaxx)) ,1,'last')+1;
                    ridx2x = find(rvxhp(rimaxx:end)*sign(rvxhp(rimaxx))<0 | isnan(rvxhp(rimaxx:end)),1,'first') + rimaxx - 2;
                    ridx1y = find(rvyhp(1:rimaxy)*sign(rvyhp(rimaxy))<0 | isnan(rvyhp(1:rimaxy)),1,'last')+1;
                    ridx2y = find(rvyhp(rimaxy:end)*sign(rvyhp(rimaxy))<0 | isnan(rvyhp(rimaxy:end)),1,'first') + rimaxy - 2;
                    
                    if ( isempty(ridx1x) )
                        ridx1x = 1;
                    end
                    if ( isempty(ridx2x) )
                        ridx2x = length(qp);
                    end
                    if ( isempty(ridx1y) )
                        ridx1y = 1;
                    end
                    if ( isempty(ridx2y) )
                        ridx2y = length(qp);
                    end
                end
                
                if (LEFT)
                    [lvmaxx, limaxx] = max(abs(lvxhp(qpidx)));
                    [lvmaxy, limaxy] = max(abs(lvyhp(qpidx)));
                    limaxx = qp1(i)-1 + limaxx;
                    limaxy = qp1(i)-1 + limaxy;
                    
                    lidx1x = find(lvxhp(1:limaxx)*sign(lvxhp(limaxx))<0 | isnan(lvxhp(1:limaxx)),1,'last')+1;
                    lidx2x = find(lvxhp(limaxx:end)*sign(lvxhp(limaxx))<0 | isnan(lvxhp(limaxx:end)),1,'first') + limaxx - 2;
                    lidx1y = find(lvyhp(1:limaxy)*sign(lvyhp(limaxy))<0 | isnan(lvyhp(1:limaxy)),1,'last')+1;
                    lidx2y = find(lvyhp(limaxy:end)*sign(lvyhp(limaxy))<0 | isnan(lvyhp(limaxy:end)),1,'first') + limaxy - 2;
                    
                    if ( isempty(lidx1x) )
                        lidx1x = 1;
                    end
                    if ( isempty(lidx2x) )
                        lidx2x = length(qp);
                    end
                    if ( isempty(lidx1y) )
                        lidx1y = 1;
                    end
                    if ( isempty(lidx2y) )
                        lidx2y = length(qp);
                    end
                    
                end
                
                imax = qp1(i)-1 + imax;
                
                
                
                if ( LEFT && RIGHT )
                    sac(i,:) = [min([ridx1x, ridx1y, lidx1x, lidx1y]) max([ridx2x,ridx2y,lidx2x,lidx2y]) imax];
                elseif (LEFT)
                    sac(i,:) = [min([lidx1x,lidx1y]) max([lidx2x,lidx2y]) imax];
                elseif (RIGHT)
                    sac(i,:) = [min([ridx1x,ridx1y,]) max([ridx2x,ridx2y,]) imax];
                end
            end
            
            l = height(data);
            starts = sac(:,1);
            stops = sac(:,2);
            yesNo = zeros(l,1);
            [us ius] = unique(starts);
            yesNo(us) = yesNo(us)+ diff([ius;length(starts)+1]);
            [us ius] = unique(stops);
            yesNo(us) = yesNo(us)- diff([ius;length(stops)+1]);
            yesNo = cumsum(yesNo)>0;
            
            data.QuikPhase = yesNo;
            peaks = zeros(size(yesNo));
            peaks(sac(:,3)) = 1;
            data.QuikPhasePeak = peaks>0; % make it logical
            toc
        end
        
        function [data] = DetectSlowPhases(data, params)
            
            [eyes, eyeSignals] = VOGAnalysis.GetEyesAndSignals(data);
            eyeSignals = setdiff(eyeSignals, {'Pupil', 'LowerLid' 'UpperLid'});
            LEFT = any(strcmp(eyes,'Left'));
            RIGHT = any(strcmp(eyes,'Right'));
            
            
            %%  find slow phases
            tic
            cprintf('blue','Finding slows phases on each component...\n');
            
            qp = data.QuikPhase;
            for k=1:length(eyes)
                for j=1:length(eyeSignals)
                    xx = data.([eyes{k} eyeSignals{j}]);
                    vx = data.([eyes{k} 'Vel' eyeSignals{j}]);
                    vxlp = data.([eyes{k} 'VelLP' eyeSignals{j}]);
                    spYesNo = (~qp & ~isnan(vx));
                    sp = [find(diff([0;spYesNo])>0) find(diff([spYesNo;0])<0)];
                    spdur = sp(:,2) - sp(:,1);
                    sp(spdur<20,:) = [];
                    
                    l = length(vx);
                    starts = sp(:,1);
                    stops = sp(:,2);
                    yesNo = zeros(l,1);
                    [us ius] = unique(starts);
                    yesNo(us) = yesNo(us)+ diff([ius;length(starts)+1]);
                    [us ius] = unique(stops);
                    yesNo(us) = yesNo(us)- diff([ius;length(stops)+1]);
                    yesNo = cumsum(yesNo)>0;
                    
                    data.([eyes{k} 'SlowPhase' eyeSignals{j}]) = boxcar(~yesNo,2)==0;
                end
            end
            
            if ( RIGHT)
                rspx = data.RightSlowPhaseX;
                rspy = data.RightSlowPhaseY;
            end
            if ( LEFT)
                lspx = data.LeftSlowPhaseX;
                lspy = data.LeftSlowPhaseY;
            end
            
            if ( LEFT && RIGHT )
                sp = rspy | rspx | lspy | lspx;
            elseif (LEFT)
                sp = lspy | lspx;
            elseif(RIGHT)
                sp = rspy | rspx;
            end
            data.SlowPhase = sp;
            
            if ( RIGHT )
                data.RightSPVX = data.RightVelX;
                data.RightSPVX(~data.SlowPhase) = nan;
                data.RightSPVY = data.RightVelY;
                data.RightSPVY(~data.SlowPhase) = nan;
            end
            
            if ( LEFT )
                data.LeftSPVX = data.LeftVelX;
                data.LeftSPVX(~data.SlowPhase) = nan;
                data.LeftSPVY = data.LeftVelY;
                data.LeftSPVY(~data.SlowPhase) = nan;
            end
            toc
        end
        
        function [spv] = GetSPV(data)
            
            % TODO:
            
            % Find portions where the head was moving too fast
            % (Maybe this should only be done at the spv
            % calculations. Not necesssary here
            if ( ismember('Q1', headSignals) )
                dQ1 = [0;diff(cleanedData.HeadQ1)];
                dQ2 = [0;diff(cleanedData.HeadQ2)];
                dQ3 = [0;diff(cleanedData.HeadQ3)];
                dQ4 = [0;diff(cleanedData.HeadQ4)];
                dQ1(dQ1==0) = nan;
                dQ2(dQ2==0) = nan;
                dQ3(dQ3==0) = nan;
                dQ4(dQ4==0) = nan;
                % find head movements in Quaternion data if available
                head =  sum(abs(boxcar([dQ1  dQ2 dQ3 dQ4],10)),2)*100;
                cleanedData.HeadMotion = head;
            end
            badHeadMoving = nan(size(b));
            if ( ismember('Q1', headSignals) )
                badHeadMoving = boxcar(cleanedData.HeadMotion > nanmedian(cleanedData.HeadMotion)*params.HFAC,10)>0;
                b = b | badHeadMoving;
            end
            
            tr = table;
            tr.x = data.RightX;
            tr.x(~data.SlowPhase) = nan;
            tr.y = data.RightY;
            tr.y(~data.SlowPhase) = nan;
            tr.t = data.Time;
            tr.n = categorical(cumsum([0;diff(data.SlowPhase)>0]));
            
            warning('off','stats:LinearModel:RankDefDesignMat')
            
            spvt = (250:500:length(data.RightSPVX))/500;
            spvx = nan(size(spvt));
            spvy = nan(size(spvt));
            spvxe = nan(size(spvt));
            spvye = nan(size(spvt));
            for k=1:length(spvt)
                idx = round(spvt(k)*500) + [-500:500];
                idx(idx<=0) = [];
                idx(idx>length(data.RightSPVX)) = [];
                
                
                if ( mean(~isnan(tr.x(idx)) & ~isnan(tr.y(idx))) > 0.3 )
                    lmx = fitlm(tr(idx,:),'x~t+n');
                    lmy = fitlm(tr(idx,:),'y~t+n');
                    badidx = sqrt((diff(tr.x(idx))*500-lmx.Coefficients.Estimate(2)).^2+(diff(tr.y(idx))*500-lmy.Coefficients.Estimate(2)).^2)>50;
                    
                    tr.t(idx(badidx)) = nan;
                    tr.x(idx(badidx)) = nan;
                    tr.y(idx(badidx)) = nan;
                    tr.n = categorical(cumsum(abs([0;diff(isnan(tr.x))])));
                    
                    if ( mean(~isnan(tr.x(idx)) & ~isnan(tr.y(idx))) > 0.2 )
                        lmx2 = fitlm(tr(idx,:),'x~t+n');
                        lmy2 = fitlm(tr(idx,:),'y~t+n');
                        
                        
                        spvx(k) = lmx2.Coefficients('t',:).Estimate;
                        spvxe(k) = lmx2.Coefficients('t',:).SE;
                        spvy(k) = lmy2.Coefficients('t',:).Estimate;
                        spvye(k) = lmy2.Coefficients('t',:).SE;
                    end
                end
            end
            warning('on','stats:LinearModel:RankDefDesignMat')
            
            spvjom = table;
            spvjom.Time = spvt';
            spvjom.RightX = spvx';
            spvjom.RightY = spvy';
            spvjom.RightXSE = spvxe';
            spvjom.RightYSE = spvye';
        end
        
        function [quickPhaseTable, slowPhaseTable] = GetQuickAndSlowPhaseTable(data)
            [quickPhaseTable] = VOGAnalysis.GetQuickPhaseTable(data);
            [slowPhaseTable] = VOGAnalysis.GetSlowPhaseTable(data);
%             [qpPrevNextTable, spPrevNextTable] = VOGAnalysis.GetQuickAndSlowPhasesPrevNext(data, quickPhaseTable, slowPhaseTable);
%             quickPhaseTable = [quickPhaseTable qpPrevNextTable];
%             slowPhaseTable = [slowPhaseTable spPrevNextTable];
        end
        
        function [quickPhaseTable] = GetQuickPhaseTable(data)
            [eyes, eyeSignals] = VOGAnalysis.GetEyesAndSignals(data);
            %% get QP properties
            rows = eyeSignals;
            SAMPLERATE = 500;
            qp = data.QuikPhase;
            qp = [find(diff([0;qp])>0) find(diff([qp;0])<0)];
            
            % properties common for all eyes and components
            quickPhaseTable = [];
            quickPhaseTable.StartIndex = qp(:,1);
            quickPhaseTable.EndIndex = qp(:,2);
            quickPhaseTable.DurationMs = (qp(:,2) - qp(:,1)) * 1000 / SAMPLERATE;
            
            props = [];
            for k=1:length(eyes)
                for j=1:length(rows)
                    pos = data.([eyes{k} rows{j}]);
                    vel = data.([eyes{k} 'Vel' rows{j}]);
                    
                    
                    % properties specific for each component
                    qp1_props.GoodBegining = nan(size(qp(:,1)));
                    qp1_props.GoodEnd = nan(size(qp(:,1)));
                    qp1_props.GoodTrhought = nan(size(qp(:,1)));
                    
                    qp1_props.Amplitude = nan(size(qp(:,1)));
                    qp1_props.StartPosition = pos(qp(:,1));
                    qp1_props.EndPosition = pos(qp(:,2));
                    qp1_props.MeanPosition = nan(size(qp(:,1)));
                    qp1_props.Displacement = pos(qp(:,2)) - pos(qp(:,1));
                    
                    qp1_props.PeakVelocity = nan(size(qp(:,1)));
                    qp1_props.PeakVelocityIdx = nan(size(qp(:,1)));
                    qp1_props.MeanVelocity = nan(size(qp(:,1)));
                    
                    for i=1:size(qp,1)
                        qpidx = qp(i,1):qp(i,2);
                        qp1_props.GoodBegining(i)   = qpidx(1)>1 && ~isnan(vel(qpidx(1)-1));
                        qp1_props.GoodEnd(i)        = qpidx(end)<length(vel) && ~isnan(vel(qpidx(1)+1));
                        qp1_props.GoodTrhought(i)   = sum(isnan(vel(qpidx))) == 0;
                        
                        qp1_props.Amplitude(i)      = max(pos(qpidx)) - min(pos(qpidx));
                        qp1_props.MeanPosition(i)   = nanmean(pos(qpidx));
                        
                        [m,mi] = max(abs(vel(qpidx)));
                        qp1_props.PeakVelocity(i)   = m*sign(vel(qpidx(mi)));
                        qp1_props.PeakVelocityIdx(i)= qpidx(1) -1 + mi;
                        qp1_props.MeanVelocity(i)   = nanmean(vel(qpidx));
                    end
                    
                    props.(eyes{k}).(rows{j}) = qp1_props;
                end
                
                pos = [data.([eyes{k} 'X']) data.([eyes{k} 'Y'])];
                speed = sqrt( data.([eyes{k} 'VelX']).^2 +  data.([eyes{k} 'VelY']).^2 );
                qp2_props.Amplitude = sqrt( props.(eyes{k}).X.Amplitude.^2 + props.(eyes{k}).Y.Amplitude.^2);
                qp2_props.Displacement = sqrt( (pos(qp(:,2),1) - pos(qp(:,1),1) ).^2 + ( pos(qp(:,2),2) - pos(qp(:,1),2) ).^2 );
                qp2_props.PeakSpeed = nan(size(qp(:,1)));
                qp2_props.MeanSpeed = nan(size(qp(:,1)));
                for i=1:size(qp,1)
                    qpidx = qp(i,1):qp(i,2);
                    qp2_props.PeakSpeed(i) = max(speed(qpidx));
                    qp2_props.MeanSpeed(i) = nanmean(speed(qpidx));
                end
                props.(eyes{k}).XY = qp2_props;
            end
            
            % properties common for all eyes and components
            if ( any(contains(eyes,'Left')) && any(contains(eyes,'Right')) )
                quickPhaseTable.Amplitude      = nanmean([ props.Left.XY.Amplitude props.Right.XY.Amplitude],2);
                quickPhaseTable.Displacement   = nanmean([ props.Left.XY.Displacement props.Right.XY.Displacement],2);
                quickPhaseTable.PeakSpeed      = nanmean([ props.Left.XY.PeakSpeed props.Right.XY.PeakSpeed],2);
                quickPhaseTable.MeanSpeed      = nanmean([ props.Left.XY.MeanSpeed props.Right.XY.MeanSpeed],2);
            elseif(any(contains(eyes,'Left')))
                quickPhaseTable.Amplitude      = props.Left.XY.Amplitude;
                quickPhaseTable.Displacement   = props.Left.XY.Displacement;
                quickPhaseTable.PeakSpeed      = props.Left.XY.PeakSpeed;
                quickPhaseTable.MeanSpeed      = props.Left.XY.MeanSpeed;
            elseif(any(contains(eyes,'Right')))
                quickPhaseTable.Amplitude      = props.Right.XY.Amplitude;
                quickPhaseTable.Displacement   = props.Right.XY.Displacement;
                quickPhaseTable.PeakSpeed      = props.Right.XY.PeakSpeed;
                quickPhaseTable.MeanSpeed      = props.Right.XY.MeanSpeed;
            end
            fieldsToAverageAcrossEyes = {...
                'Amplitude'...
                'StartPosition'...
                'EndPosition'...
                'MeanPosition'...
                'Displacement'...
                'PeakVelocity'...
                'MeanVelocity'};
            for i=1:length(fieldsToAverageAcrossEyes)
                field  = fieldsToAverageAcrossEyes{i};
                for j=1:3
                    if ( any(contains(eyes,'Left')) && any(contains(eyes,'Right')) )
                        quickPhaseTable.([rows{j} '_' field ]) = nanmean([ props.Left.(rows{j}).(field) props.Right.(rows{j}).(field)],2);
                    elseif(any(contains(eyes,'Left')))   
                        quickPhaseTable.([rows{j} '_' field ]) = props.Left.(rows{j}).(field);
                    elseif(any(contains(eyes,'Right'))) 
                        quickPhaseTable.([rows{j} '_' field ]) = props.Right.(rows{j}).(field);
                    end
                end
            end
            
            
            
            % merge props
            for k=1:length(eyes)
                fields = fieldnames(props.(eyes{k}).XY);
                for i=1:length(fields)
                    quickPhaseTable.([ eyes{k} '_' fields{i}]) = props.(eyes{k}).XY.(fields{i});
                end
                
                for j=1:3
                    fields = fieldnames(props.(eyes{k}).(rows{j}));
                    for i=1:length(fields)
                        quickPhaseTable.([ eyes{k} '_' rows{j} '_' fields{i}]) = props.(eyes{k}).(rows{j}).(fields{i});
                    end
                end
            end
            
            quickPhaseTable = struct2table(quickPhaseTable);
        end
        
        function [slowPhaseTable] = GetSlowPhaseTable(data)
            [eyes, eyeSignals] = VOGAnalysis.GetEyesAndSignals(data);
            %% get SP properties
            rows = eyeSignals;
            SAMPLERATE = 500;
            sp = data.SlowPhase;
            sp = [find(diff([0;sp])>0) find(diff([sp;0])<0)];
            
            % properties common for all eyes and components
            slowPhaseTable = [];
            slowPhaseTable.StartIndex = sp(:,1);
            slowPhaseTable.EndIndex = sp(:,2);
            slowPhaseTable.DurationMs = (sp(:,2) - sp(:,1)) * 1000 / SAMPLERATE;
            
            props = [];
            for k=1:length(eyes)
                for j=1:3
                    pos = data.([eyes{k} rows{j}]);
                    vel = data.([eyes{k} 'Vel' rows{j}]);
                    
                    
                    % properties specific for each component
                    sp1_props.GoodBegining = nan(size(sp(:,1)));
                    sp1_props.GoodEnd = nan(size(sp(:,1)));
                    sp1_props.GoodTrhought = nan(size(sp(:,1)));
                    
                    sp1_props.Amplitude = nan(size(sp(:,1)));
                    sp1_props.StartPosition = pos(sp(:,1));
                    sp1_props.EndPosition = pos(sp(:,2));
                    sp1_props.MeanPosition = nan(size(sp(:,1)));
                    sp1_props.Displacement = pos(sp(:,2)) - pos(sp(:,1));
                    
                    sp1_props.PeakVelocity = nan(size(sp(:,1)));
                    sp1_props.PeakVelocityIdx = nan(size(sp(:,1)));
                    sp1_props.MeanVelocity = nan(size(sp(:,1)));
                    
                    
                    sp1_props.Slope = nan(size(sp(:,1)));
                    sp1_props.TimeConstant = nan(size(sp(:,1)));
                    sp1_props.ExponentialBaseline = nan(size(sp(:,1)));
                    
                    opts = optimset('Display','off');
                    for i=1:size(sp,1)
                        spidx = sp(i,1):sp(i,2);
                        sp1_props.GoodBegining(i)   = spidx(1)>1 && ~isnan(vel(spidx(1)-1));
                        sp1_props.GoodEnd(i)        = spidx(end)<length(vel) && ~isnan(vel(spidx(1)+1));
                        sp1_props.GoodTrhought(i)   = sum(isnan(vel(spidx))) == 0;
                        
                        sp1_props.Amplitude(i)      = max(pos(spidx)) - min(pos(spidx));
                        sp1_props.MeanPosition(i)   = nanmean(pos(spidx));
                        
                        [m,mi] = max(vel(spidx));
                        sp1_props.PeakVelocity(i)   = m;
                        sp1_props.PeakVelocityIdx(i)= spidx(1) -1 + mi;
                        sp1_props.MeanVelocity(i)   = nanmean(vel(spidx));
                        
                        if ( sp1_props.GoodTrhought(i) )
                            fun = @(x,xdata)(-x(1) + x(1)*exp(-1/x(2)*xdata)+xdata*x(3));
                            t = (0:length(spidx)-1)'*2;
                            [x,RESNORM,RESIDUAL,EXITFLAG]  = lsqcurvefit(fun,[1 1 0] ,t,pos(spidx)-pos(spidx(1)),[-40 0 -200],[40 1000 200],opts);
                            
                            if ( EXITFLAG>0)
                                sp1_props.Slope(i) = x(3)*500;
                                sp1_props.TimeConstant(i) = x(2);
                                sp1_props.ExponentialBaseline(i) = pos(spidx(1))+x(1);
                            end
                        end
                    end
                    
                    props.(eyes{k}).(rows{j}) = sp1_props;
                end
                
                pos = [data.([eyes{k} 'X']) data.([eyes{k} 'Y'])];
                speed = sqrt( data.([eyes{k} 'VelX']).^2 +  data.([eyes{k} 'VelY']).^2 );
                sp2_props.Amplitude = sqrt( props.(eyes{k}).X.Amplitude.^2 + props.(eyes{k}).Y.Amplitude.^2);
                sp2_props.Displacement = sqrt( (pos(sp(:,2),1) - pos(sp(:,1),1) ).^2 + ( pos(sp(:,2),2) - pos(sp(:,1),2) ).^2 );
                sp2_props.PeakSpeed = nan(size(sp(:,1)));
                sp2_props.MeanSpeed = nan(size(sp(:,1)));
                for i=1:size(sp,1)
                    spidx = sp(i,1):sp(i,2);
                    sp2_props.PeakSpeed(i) = max(speed(spidx));
                    sp2_props.MeanSpeed(i) = nanmean(speed(spidx));
                end
                props.(eyes{k}).XY = sp2_props;
            end
            
            % properties common for all eyes and components
             % properties common for all eyes and components
            if ( any(contains(eyes,'Left')) && any(contains(eyes,'Right')) )
                slowPhaseTable.Amplitude      = nanmean([ props.Left.XY.Amplitude props.Right.XY.Amplitude],2);
                slowPhaseTable.Displacement   = nanmean([ props.Left.XY.Displacement props.Right.XY.Displacement],2);
                slowPhaseTable.PeakSpeed      = nanmean([ props.Left.XY.PeakSpeed props.Right.XY.PeakSpeed],2);
                slowPhaseTable.MeanSpeed      = nanmean([ props.Left.XY.MeanSpeed props.Right.XY.MeanSpeed],2);
            elseif(any(contains(eyes,'Left')))
                slowPhaseTable.Amplitude      = props.Left.XY.Amplitude;
                slowPhaseTable.Displacement   = props.Left.XY.Displacement;
                slowPhaseTable.PeakSpeed      = props.Left.XY.PeakSpeed;
                slowPhaseTable.MeanSpeed      = props.Left.XY.MeanSpeed;
            elseif(any(contains(eyes,'Right')))
                slowPhaseTable.Amplitude      = props.Right.XY.Amplitude;
                slowPhaseTable.Displacement   = props.Right.XY.Displacement;
                slowPhaseTable.PeakSpeed      = props.Right.XY.PeakSpeed;
                slowPhaseTable.MeanSpeed      = props.Right.XY.MeanSpeed;
            end
            
            fieldsToAverageAcrossEyes = {...
                'Amplitude'...
                'StartPosition'...
                'EndPosition'...
                'MeanPosition'...
                'Displacement'...
                'PeakVelocity'...
                'MeanVelocity'...
                'Slope'...
                'TimeConstant'...
                'ExponentialBaseline'};
            for i=1:length(fieldsToAverageAcrossEyes)
                field  = fieldsToAverageAcrossEyes{i};
                for j=1:3
                    if ( any(contains(eyes,'Left')) && any(contains(eyes,'Right')) )
                        slowPhaseTable.([rows{j} '_' field ]) = nanmean([ props.Left.(rows{j}).(field) props.Right.(rows{j}).(field)],2);
                    elseif(any(contains(eyes,'Left')))   
                        slowPhaseTable.([rows{j} '_' field ]) = props.Left.(rows{j}).(field);
                    elseif(any(contains(eyes,'Right'))) 
                        slowPhaseTable.([rows{j} '_' field ]) = props.Right.(rows{j}).(field);
                    end
                end
            end
            
            
            % merge props
            for k=1:length(eyes)
                fields = fieldnames(props.(eyes{k}).XY);
                for i=1:length(fields)
                    slowPhaseTable.([ eyes{k} '_' fields{i}]) = props.(eyes{k}).XY.(fields{i});
                end
                
                for j=1:3
                    fields = fieldnames(props.(eyes{k}).(rows{j}));
                    for i=1:length(fields)
                        slowPhaseTable.([ eyes{k} '_' rows{j} '_' fields{i}]) = props.(eyes{k}).(rows{j}).(fields{i});
                    end
                end
            end
            
            slowPhaseTable = struct2table(slowPhaseTable);
        end
        
        function [qpPrevNextTable, spPrevNextTable] = GetQuickAndSlowPhasesPrevNext(data, quickPhaseTable, slowPhaseTable)
            
            [eyes, eyeSignals] = VOGAnalysis.GetEyesAndSignals(data);
            
            qpPrevNextTable = table();
            spPrevNextTable = table();
            
            % for each slow phase
            for i=1:size(slowPhaseTable)
                prevQP1 = find( quickPhaseTable.EndIndex<=slowPhaseTable.StartIndex(i), 1, 'last');
                nextQP1 = find( quickPhaseTable.StartIndex>=slowPhaseTable.EndIndex(i), 1, 'first');
                
                prevIntervalIdx = quickPhaseTable.EndIndex(prevQP1):slowPhaseTable.StartIndex(i);
                nextIntervalIdx = slowPhaseTable.EndIndex(i):quickPhaseTable.StartIndex(nextQP1);
                
                
                if ( any(contains(eyes,'Left')) && any(contains(eyes,'Right')) )
                    goodSamples.X = ~isnan(data.LeftVelX) | ~isnan(data.RightVelX);
                    goodSamples.Y = ~isnan(data.LeftVelY) | ~isnan(data.RightVelY);
                    goodSamples.T = ~isnan(data.LeftVelT) | ~isnan(data.RightVelT);
                elseif any(contains(eyes,'Left'))
                    goodSamples.X = ~isnan(data.LeftVelX);
                    goodSamples.Y = ~isnan(data.LeftVelY);
                    goodSamples.T = ~isnan(data.LeftVelT);
                elseif any(contains(eyes,'Right'))
                    goodSamples.X = ~isnan(data.RightVelX);
                    goodSamples.Y = ~isnan(data.RightVelY);
                    goodSamples.T = ~isnan(data.RightVelT);
                end
                
                % for each variable in quick phase table
                for k=1:length(quickPhaseTable.Properties.VariableNames)
                    var = quickPhaseTable.Properties.VariableNames{k};
                    if ( strcmp(var(1:5),'Left_') || strcmp(var(1:6),'Right_'))
                        continue;
                    end
                    
                    if ( strcmp(var(1:2),'X_') || strcmp(var(1:2),'Y_') || strcmp(var(1:2),'T_') )
                        row = var(1);
                        badSamples = ~goodSamples.(row);
                    else
                        badSamples = ~goodSamples.X & ~goodSamples.Y & ~goodSamples.T;
                    end
                    
                    % look for the previous quick phase that has continuos
                    % good data in between
                    if (~isempty(prevQP1) && sum(badSamples(prevIntervalIdx)) == 0)
                        
                        newVarName = ['PrevQP_' var];
                        % if the field is already in there
                        if (~sum(strcmp(spPrevNextTable.Properties.VariableNames,newVarName)) )
                            spPrevNextTable.(newVarName) = nan(size(slowPhaseTable.StartIndex));
                        end
                        spPrevNextTable.(newVarName)(i) = quickPhaseTable.(var)(prevQP1);
                    end
                    
                    % look for the next quick phase that has continuos
                    % good data in between
                    if (~isempty(nextQP1) && sum(badSamples(nextIntervalIdx)) == 0)
                        
                        newVarName = ['NextQP_' var];
                        % if the field is already in there
                        if ( ~sum(strcmp(spPrevNextTable.Properties.VariableNames,newVarName)) )
                            spPrevNextTable.(newVarName) = nan(size(slowPhaseTable.StartIndex));
                        end
                        spPrevNextTable.(newVarName)(i) = quickPhaseTable.(var)(nextQP1);
                    end
                end
                
            end
            
            for i=1:size(quickPhaseTable)
                prevSP1 = find( slowPhaseTable.EndIndex<=quickPhaseTable.StartIndex(i), 1, 'last');
                nextSP1 = find( slowPhaseTable.StartIndex>=quickPhaseTable.EndIndex(i), 1, 'first');
                
                prevIntervalIdx = slowPhaseTable.EndIndex(prevSP1):quickPhaseTable.StartIndex(i);
                nextIntervalIdx = quickPhaseTable.EndIndex(i):slowPhaseTable.StartIndex(nextSP1);
                
                
                if ( any(contains(eyes,'Left')) && any(contains(eyes,'Right')) )
                    goodSamples.X = ~isnan(data.LeftVelX) | ~isnan(data.RightVelX);
                    goodSamples.Y = ~isnan(data.LeftVelY) | ~isnan(data.RightVelY);
                    goodSamples.T = ~isnan(data.LeftVelT) | ~isnan(data.RightVelT);
                elseif any(contains(eyes,'Left'))
                    goodSamples.X = ~isnan(data.LeftVelX);
                    goodSamples.Y = ~isnan(data.LeftVelY);
                    goodSamples.T = ~isnan(data.LeftVelT);
                elseif any(contains(eyes,'Right'))
                    goodSamples.X = ~isnan(data.RightVelX);
                    goodSamples.Y = ~isnan(data.RightVelY);
                    goodSamples.T = ~isnan(data.RightVelT);
                end
                
                %                 if ( ~isempty(prevSP1) )
                %                     qp.PrevspIdx(i) = prevSP1;
                %                 end
                %
                %                 if ( ~isempty(nextSP1) )
                %                     qp.NextspIdx(i) = nextSP1;
                %                 end
                
                
                for k=1:length(slowPhaseTable.Properties.VariableNames)
                    var = slowPhaseTable.Properties.VariableNames{k};
                    if ( strcmp(var(1:5),'Left_') || strcmp(var(1:6),'Right_'))
                        continue;
                    end
                    
                    if ( strcmp(var(1:2),'X_') || strcmp(var(1:2),'Y_') || strcmp(var(1:2),'T_') )
                        row = var(1);
                        badSamples = ~goodSamples.(row);
                    else
                        badSamples = ~goodSamples.X & ~goodSamples.Y & ~goodSamples.T;
                    end
                    
                    if (~isempty(prevSP1) && sum(badSamples(prevIntervalIdx)) == 0)
                        
                        newVarName = ['PrevSP_' var];
                        % if the field is already in there
                        if ( ~sum(strcmp(qpPrevNextTable.Properties.VariableNames,newVarName)) )
                            qpPrevNextTable.(newVarName) = nan(height(qpPrevNextTable));
                        end
                        qpPrevNextTable.(newVarName)(i) = slowPhaseTable.(var)(prevSP1);
                    end
                    
                    if (~isempty(nextSP1) && sum(badSamples(nextIntervalIdx)) == 0)
                        
                        newVarName = ['NextSP_' var];
                        % if the field is already in there
                        if ( ~sum(strcmp(qpPrevNextTable.Properties.VariableNames,newVarName)) )
                            qpPrevNextTable.(newVarName) = nan(height(qpPrevNextTable));
                        end
                        qpPrevNextTable.(newVarName)(i) = slowPhaseTable.(var)(nextSP1);
                    end
                end
                
            end
        end
        
        function [spv, positionFiltered] = GetSPV_Simple(timeSec, position)
            % GET SPV SIMPLE Calculates slow phase velocity (SPV) from a
            % position signal with a simple algorithm. No need to have
            % detected the quickphases before.
            % This function does a two pass median filter with thresholding
            % to eliminate quick-phases. First pass eliminates very clear
            % quick phases. Second pass (after correcting for a first
            % estimate of the spv, eliminates much smaller quick-phases.
            % Asumes slow-phases cannot go above 100 deg/s
            %
            %   [spv, positionFiltered] = GetSPV_Simple(timeSec, position)
            %
            %   Inputs:
            %       - timeSec: timestamps of the data (column vector) in seconds.
            %       - position: position data (must be same size as timeSec).
            %
            %   Outputs:
            %       - spv: instantaneous slow phase velocity.
            %       - positionFiltered: corresponding filtered position signal.
            
            firstPassVThrehold              = 100;  %deg/s
            firstPassMedfiltWindow          = 4;    %s
            firstPassMedfiltNanFraction     = 0.25;   %
            firstPassPadding                = 30;   %ms
            
            secondPassVThrehold             = 10;   %deg/s
            secondPassMedfiltWindow         = 1;    %s
            secondPassMedfiltNanFraction    = 0.5;   %
            secondPassPadding               = 30;   %ms
            
            
            samplerate = round(mean(1./diff(timeSec)));
            
            % get the velocity
            spv = [0;(diff(position)./diff(timeSec))];
            
            % first past at finding quick phases (>100 deg/s)
            qp = boxcar(abs(spv)>firstPassVThrehold | isnan(spv), firstPassPadding*samplerate/1000)>0;
            spv(qp) = nan;
            
            % used the velocity without first past of quick phases
            % to get a estimate of the spv and substract it from
            % the velocity
            v2 = spv-nanmedfilt(spv,samplerate*firstPassMedfiltWindow,firstPassMedfiltNanFraction);
            
            % do a second pass for the quick phases (>10 deg/s)
            qp2 = boxcar(abs(v2)>secondPassVThrehold, secondPassPadding*samplerate/1000)>0;
            spv(qp2) = nan;
            
            % get a filted and decimated version of the spv at 1
            % sample per second only if one fifth of the samples
            % are not nan for the 1 second window
            spv = nanmedfilt(spv,samplerate*secondPassMedfiltWindow,secondPassMedfiltNanFraction);
            positionFiltered = nanmedfilt(position,samplerate,secondPassMedfiltNanFraction);
        end
    end
    
    methods (Static)
        function PlotTraces(data)
            COLOR_LEFT =  [0.1000 0.5000 0.8000];
            COLOR_RIGHT = [0.9000 0.2000 0.2000];
            FONTSIZE = 14;
            
            figure('color','w')
            [h, pos] = tight_subplot(3, 2);%, gap, marg_h, marg_w)
            set(h,'nextplot','add','yticklabelmode','auto');
            set(h(5:6),'xticklabelmode','auto');
            
            data.Time = data.Time;
            
            axes(h(1));
            plot(data.Time, data.LeftX, 'color', COLOR_LEFT)
            plot(data.Time, data.RightX, 'color', COLOR_RIGHT)
            ylabel('Horizontal','fontsize', FONTSIZE);
            title('Position (deg) vs. time (s)')
            
            axes(h(3));
            plot(data.Time, data.LeftY, 'color', COLOR_LEFT)
            plot(data.Time, data.RightY, 'color', COLOR_RIGHT)
            ylabel('Vertical','fontsize', FONTSIZE);
            
            axes(h(5));
            plot(data.Time, data.LeftT, 'color', COLOR_LEFT)
            plot(data.Time, data.RightT, 'color', COLOR_RIGHT)
            ylabel('Torsion','fontsize', FONTSIZE);
            
            axes(h(2));
            plot(data.Time(2:end), diff(data.LeftX)./diff(data.Time), 'color', COLOR_LEFT)
            plot(data.Time(2:end), diff(data.RightX)./diff(data.Time), 'color', COLOR_RIGHT)
            title('Velocity (deg/s) vs. time (s)')
            
            axes(h(4));
            plot(data.Time(2:end), diff(data.LeftY)./diff(data.Time), 'color', COLOR_LEFT)
            plot(data.Time(2:end), diff(data.RightY)./diff(data.Time), 'color', COLOR_RIGHT)
            
            axes(h(6));
            plot(data.Time(2:end), diff(data.LeftT)./diff(data.Time), 'color', COLOR_LEFT)
            plot(data.Time(2:end), diff(data.RightT)./diff(data.Time), 'color', COLOR_RIGHT)
            
            set(h(1:2:5),'ylim',[-50 50],'xlim',[min(data.Time) max(data.Time)])
            set(h(2:2:6),'ylim',[-200 200],'xlim',[min(data.Time) max(data.Time)])
            
            linkaxes(h,'x')
        end
        
        function PlotRawTraces(data)
            
            MEDIUM_BLUE =  [0.1000 0.5000 0.8000];
            MEDIUM_RED = [0.9000 0.2000 0.2000];
            
            figure
            timeL = data.LeftSeconds;
            timeR = data.RightSeconds;
            
            subplot(3,1,1,'nextplot','add')
            plot(timeL, data.LeftX, 'color', [ MEDIUM_BLUE ])
            plot(timeR, data.RightX, 'color', [ MEDIUM_RED])
            ylabel('Horizontal (deg)','fontsize', 16);
            
            subplot(3,1,2,'nextplot','add')
            plot(timeL, data.LeftY, 'color', [ MEDIUM_BLUE ])
            plot(timeR, data.RightY, 'color', [ MEDIUM_RED])
            ylabel('Vertical (deg)','fontsize', 16);
            
            subplot(3,1,3,'nextplot','add')
            plot(timeL, data.LeftTorsionAngle, 'color', [ MEDIUM_BLUE ])
            plot(timeR, data.RightTorsionAngle, 'color', [ MEDIUM_RED])
            ylabel('Torsion (deg)','fontsize', 16);
            xlabel('Time (s)');
        end
        
        function PlotCleanAndResampledData(rawData, resData)
            %%
            pupilSizeTh = resData.Properties.UserData.params.pupilSizeTh;
            FS = resData.Properties.UserData.sampleRate;
            rawData = resData.Properties.UserData.calibratedData;
            resData = resData.Properties.UserData.cleandData;
            
            
            if ( any(strcmp(rawData.Properties.VariableNames,'Time')))
                rawDataTime = rawData.Time;
            elseif ( any(strcmp(rawData.Properties.VariableNames,'LeftSeconds')))
                rawDataTime = rawData.LeftSeconds - rawData.LeftSeconds(1);
            elseif ( any(strcmp(rawData.Properties.VariableNames,'RightSeconds')))
                rawDataTime = rawData.RightSeconds - rawData.RightSeconds(1);
            end
            
            if ( any(strcmp(rawData.Properties.VariableNames,'LeftTorsionAngle')))
                rawData.LeftT = rawData.LeftTorsionAngle;
            end
            if ( any(strcmp(rawData.Properties.VariableNames,'RightTorsionAngle')))
                rawData.LeftT = rawData.RightTorsionAngle;
            end
            
            eyes = {'Left' 'Right'};
            rows = {'X' 'Y' 'T'};
            figure
            h = tight_subplot(4,2,0,[0.05 0],[0.05 0]);
            set(h,'nextplot','add')
            for i=1:2
                axes(h(i))
                %                 plot(rawDataTime, rawData.([eyes{i} 'PupilRaw']))
                plot(rawDataTime, rawData.([eyes{i} 'Pupil']),'linewidth',2);
                pth = nanmean(rawData.([eyes{i} 'Pupil']))*pupilSizeTh/100;
                plot(rawDataTime, rawData.([eyes{i} 'Pupil'])+pth,'linewidth',1);
                plot(rawDataTime, rawData.([eyes{i} 'Pupil'])-pth,'linewidth',1);
                plot(rawDataTime, abs([0;diff(rawData.([eyes{i} 'Pupil']))]))
                
                plot(resData.Time, resData.([eyes{i} 'Spikes'])*50)
                plot(resData.Time, resData.([eyes{i} 'Blinks'])*30,'k');
                if ( i==1)
                    ylabel( 'Pupil size');
                    set(gca,'yticklabelmode','auto')
                end
                
                for j=1:3
                    axes(h(i+(j)*2))
                    plot(rawDataTime, rawData.([eyes{i} rows{j}]))
                    plot(resData.Time, resData.([eyes{i} rows{j}]),'linewidth',2)
                    if ( i==1)
                        ylabel([ rows{j} ' pos']);
                        set(gca,'yticklabelmode','auto')
                    end
                    if ( j==3)
                        xlabel('Time');
                        set(gca,'xticklabelmode','auto')
                    end
                    set(gca,'ylim',[-50 50])
                end
            end
            linkaxes(get(gcf,'children'),'x')
            legend({'Rawa data (calibrated)','Cleaned data'})
        end
        
        function PlotQuickPhaseDebug(resData)
            
            eyes = {};
            if ( sum(strcmp('LeftX',resData.Properties.VariableNames))>0 )
                eyes{end+1} = 'Left';
            end
            if ( sum(strcmp('RightX',resData.Properties.VariableNames))>0 )
                eyes{end+1} = 'Right';
            end
            rows = {'X' 'Y' 'T'};
            
            for j=1:length(rows)
                figure
                h = tight_subplot(3,2,0,[0.05 0],[0.05 0]);
                set(h,'nextplot','add')
                for k=1:length(eyes)
                    t = resData.Time;
                    
                    xx = resData.([eyes{k} rows{j}]);
                    yesNo = resData.([eyes{k} 'QuikPhase' rows{j}]);
                    yesNoSP = resData.([eyes{k} 'SlowPhase' rows{j}]);
                    vx = resData.([eyes{k} 'Vel' rows{j}]);
                    vxhp = resData.([eyes{k} 'VelHP' rows{j}]);
                    vxlp = resData.([eyes{k} 'VelLP' rows{j}]);
                    peaks = resData.([eyes{k} 'QuikPhasePeak' rows{j}]);
                    peaksRaw = resData.([eyes{k} 'PeakRaw' rows{j}]);
                    
                    accx = resData.([eyes{k} 'Accel' rows{j}]);
                    
                    xxsac = nan(size(xx));
                    xxsac(yesNo) = xx(yesNo);
                    xxsacSP = nan(size(xx));
                    xxsacSP(yesNoSP) = xx(yesNoSP);
                    
                    vxsac = nan(size(xx));
                    vxsac(yesNo) = vx(yesNo);
                    vxsacp = nan(size(xx));
                    vxsacp(peaks) = vx(peaks);
                    vxsacp1 = nan(size(xx));
                    vxsacp1(peaksRaw) = vx(peaksRaw);
                    
                    
                    accxsac = nan(size(xx));
                    accxsac(yesNo) = accx(yesNo);
                    accxsacp = nan(size(xx));
                    accxsacp(peaks) = accx(peaks);
                    
                    axes(h(k));
                    plot(t, xx)
                    plot(t, xxsac,'r-o','markersize',2)
                    plot(t, xxsacSP,'bo','markersize',2)
                    set(gca,'ylim',[-40 40])
                    ylabel([ rows{j} ' pos'])
                    set(gca,'yticklabelmode','auto')
                    grid
                    
                    axes(h(k+2));
                    plot(t, vx)
                    plot(t, vxlp)
                    plot(t, vxhp)
                    plot(t, vxsac,'r-o','markersize',2)
                    plot(t, vxsacp1,'go','linewidth',1,'markersize',2)
                    plot(t, vxsacp,'bo','linewidth',2,'markersize',2)
                    grid
                    set(gca,'ylim',[-400 400])
                    ylabel([ rows{j} ' vel'])
                    set(gca,'yticklabelmode','auto')
                    
                    
                    axes(h(k+4));
                    plot(t, accx)
                    plot(t, accxsac,'r-o','markersize',2)
                    plot(t, accxsacp,'bo','linewidth',2,'markersize',2)
                    ylabel([ rows{j} ' acc'])
                    set(gca,'yticklabelmode','auto')
                    grid
                    %         set(gca,'ylim',[-400 400])
                    
                    xlabel('Time');
                    set(gca,'xticklabelmode','auto')
                end
                linkaxes(get(gcf,'children'),'x')
            end
        end
        
        function PlotSaccades(resData)
            figure
            h = tight_subplot(3,1,0,[0.05 0],[0.05 0]);
            set(h,'nextplot','add');
            eyes= {'Left' 'Right'};
            rows = {'X' 'Y' 'T'};
            for j=1:3
                axes(h(j));
                for k=1:2
                    t = resData.Time;
                    xx = resData.([eyes{k} rows{j}]);
                    vx = resData.([eyes{k} 'Vel' rows{j}]);
                    yesNo = resData.QuikPhase;
                    spYesNo = resData.SlowPhase;
                    peaks = resData.QuikPhasePeak;
                    
                    xxsac = nan(size(xx));
                    xxsac(yesNo) = xx(yesNo);
                    xxsacp = nan(size(xx));
                    xxsacp(peaks) = xx(peaks);
                    xxsp = nan(size(xx));
                    xxsp(spYesNo) = xx(spYesNo);
                    
                    
                    plot(t, xx)
                    set(gca,'ylim',[-40 40])
                    plot(t, xxsacp,'bo','linewidth',1)
                    plot(t, xxsac,'r','linewidth',2)
                    plot(t, xxsp,'g','linewidth',2)
                    
                    if ( k==1)
                        ylabel([ rows{j} ' pos']);
                        set(gca,'yticklabelmode','auto')
                    end
                    if ( j==3)
                        xlabel('Time');
                        set(gca,'xticklabelmode','auto')
                    end
                end
                linkaxes(get(gcf,'children'),'x')
            end
        end
        
        function PlotPosition(data)
            
            MEDIUM_BLUE =  [0.1000 0.5000 0.8000];
            MEDIUM_RED = [0.9000 0.2000 0.2000];
            
            figure
            time = data.Time/1000/60;
            subplot(3,1,1,'nextplot','add')
            plot(time, data.LeftX-nanmedian(data.LeftX), 'color', [ MEDIUM_BLUE ])
            plot(time, data.RightX-nanmedian(data.RightX), 'color', [ MEDIUM_RED])
            ylabel('Horizontal (deg)','fontsize', 16);
            
            subplot(3,1,2,'nextplot','add')
            plot(time, data.LeftY-nanmedian(data.LeftY), 'color', [ MEDIUM_BLUE ])
            plot(time, data.RightY-nanmedian(data.RightY), 'color', [ MEDIUM_RED])
            ylabel('Vertical (deg)','fontsize', 16);
            
            subplot(3,1,3,'nextplot','add')
            plot(time, data.LeftT, 'color', [ MEDIUM_BLUE ])
            plot(time, data.RightT, 'color', [ MEDIUM_RED])
            ylabel('Torsion (deg)','fontsize', 16);
            xlabel('Time (min)');
            
            
            linkaxes(get(gcf,'children'),'x')
            set(get(gcf,'children'), 'ylim',[-40 40], 'fontsize',14);
        end
        
        function PlotPositionWithHead(data,rawData)
            
            MEDIUM_BLUE =  [0.1000 0.5000 0.8000];
            MEDIUM_RED = [0.9000 0.2000 0.2000];
            
            figure
            
            time = (1:length(data.RightT))/500;
            
            subplot(8,1,[1 2],'nextplot','add')
            plot(time, data.LeftX, 'color', [ MEDIUM_BLUE ])
            plot(time, data.RightX, 'color', [ MEDIUM_RED])
            ylabel('Horizontal (deg)','fontsize', 16);
            set(gca,'xticklabel',[])
            
            subplot(8,1,[3 4],'nextplot','add')
            plot(time, data.LeftY, 'color', [ MEDIUM_BLUE ])
            plot(time, data.RightY, 'color', [ MEDIUM_RED])
            ylabel('Vertical (deg)','fontsize', 16);
            set(gca,'xticklabel',[])
            
            subplot(8,1,[5 6],'nextplot','add')
            plot(time, data.LeftT, 'color', [ MEDIUM_BLUE ])
            plot(time, data.RightT, 'color', [ MEDIUM_RED])
            set(gca,'xticklabel',[])
            
            
            subplot(8,1,[5 6],'nextplot','add')
            plot(time, data.LeftT, 'color', [ MEDIUM_BLUE ])
            plot(time, data.RightT, 'color', [ MEDIUM_RED])
            ylabel('Torsion (deg)','fontsize', 16);
            set(gca,'xticklabel',[])
            
            subplot(8,1,7)
            plot(rawData.LeftSeconds-rawData.LeftSeconds(1), [rawData.GyroX rawData.GyroY rawData.GyroZ])
            set(gca,'xticklabel',[])
            h =subplot(8,1,8)
            plot(rawData.LeftSeconds-rawData.LeftSeconds(1),[rawData.AccelerometerX rawData.AccelerometerY rawData.AccelerometerZ])
            
            xlabel('Time (s)');
            
            linkaxes(get(gcf,'children'),'x')
            set(get(gcf,'children'), 'ylim',[-20 20], 'fontsize',14);
            set(h,'ylim',[-2 2])
        end
        
        function PlotVelocityWithHead(data, rawData)
            
            MEDIUM_BLUE =  [0.1000 0.5000 0.8000];
            MEDIUM_RED = [0.9000 0.2000 0.2000];
            
            figure
            
            time = (1:length(data.RightT))/500;
            
            
            
            
            subplot(8,1,[1 2],'nextplot','add')
            plot(time(2:end), diff(data.LeftX)*500, 'color', [ MEDIUM_BLUE ])
            plot(time(2:end), diff(data.RightX)*500, 'color', [ MEDIUM_RED])
            ylabel('Horizontal (deg/s)','fontsize', 16);
            
            subplot(8,1,[3 4],'nextplot','add')
            plot(time(2:end), diff(data.LeftY)*500, 'color', [ MEDIUM_BLUE ])
            plot(time(2:end), diff(data.RightY)*500, 'color', [ MEDIUM_RED])
            ylabel('Vertical (deg/s)','fontsize', 16);
            
            subplot(8,1,[5 6],'nextplot','add')
            plot(time(2:end), diff(data.LeftT)*500, 'color', [ MEDIUM_BLUE ])
            plot(time(2:end), diff(data.RightT)*500, 'color', [ MEDIUM_RED])
            ylabel('Torsion (deg/s)','fontsize', 16);
            xlabel('Time (s)');
            
            
            
            h1= subplot(8,1,7)
            plot(rawData.LeftSeconds-rawData.LeftSeconds(1), [rawData.GyroX rawData.GyroY rawData.GyroZ])
            set(gca,'xticklabel',[])
            h =subplot(8,1,8)
            plot(rawData.LeftSeconds-rawData.LeftSeconds(1),[rawData.AccelerometerX rawData.AccelerometerY rawData.AccelerometerZ])
            
            xlabel('Time (s)');
            
            linkaxes(get(gcf,'children'),'x')
            set(get(gcf,'children'), 'ylim',[-400 400], 'fontsize',14);
            set(h,'ylim',[-2 2])
            set(h1,'ylim',[-20 20])
        end
        
        function PlotMainsequence(QucikPhaseProps)
            
            figure
            subplot(1,3,1,'nextplot','add')
            plot(QucikPhaseProps.Left_X_Displacement,abs(QucikPhaseProps.Left_X_PeakVelocity),'o')
            plot(QucikPhaseProps.Right_X_Displacement,abs(QucikPhaseProps.Right_X_PeakVelocity),'o')
            line([0 0],[0 500])
            xlabel('H displacement (deg)');
            ylabel('H peak vel. (deg/s)');
            subplot(1,3,2,'nextplot','add')
            plot(QucikPhaseProps.Left_Y_Displacement,abs(QucikPhaseProps.Left_Y_PeakVelocity),'o')
            plot(QucikPhaseProps.Right_Y_Displacement,abs(QucikPhaseProps.Right_Y_PeakVelocity),'o')
            line([0 0],[0 500])
            xlabel('V displacement (deg)');
            ylabel('V peak vel. (deg/s)');
            subplot(1,3,3,'nextplot','add')
            plot(QucikPhaseProps.Left_T_Displacement,abs(QucikPhaseProps.Left_T_PeakVelocity),'o')
            plot(QucikPhaseProps.Right_T_Displacement,abs(QucikPhaseProps.Right_T_PeakVelocity),'o')
            line([0 0],[0 500])
            xlabel('T displacement (deg)');
            ylabel('T peak vel. (deg/s)');
            
            set(get(gcf,'children'),'xlim',[-30 30],'ylim',[0 300])
            
            
            figure
            subplot(1,3,1,'nextplot','add')
            plot(QucikPhaseProps.Left_X_PeakVelocity,abs(QucikPhaseProps.Left_Y_PeakVelocity),'o')
            plot(QucikPhaseProps.Right_X_PeakVelocity,abs(QucikPhaseProps.Right_Y_PeakVelocity),'o')
            subplot(1,3,2,'nextplot','add')
            plot(QucikPhaseProps.Left_X_PeakVelocity,abs(QucikPhaseProps.Left_T_PeakVelocity),'o')
            plot(QucikPhaseProps.Right_X_PeakVelocity,abs(QucikPhaseProps.Right_T_PeakVelocity),'o')
            subplot(1,3,3,'nextplot','add')
            plot(QucikPhaseProps.Left_Y_PeakVelocity,abs(QucikPhaseProps.Left_T_PeakVelocity),'o')
            plot(QucikPhaseProps.Right_Y_PeakVelocity,abs(QucikPhaseProps.Right_T_PeakVelocity),'o')
            
            set(get(gcf,'children'),'xlim',[-300 300],'ylim',[0 300])
        end
    end
end

function theStruct = parseXML(filename)
% PARSEXML Convert XML file to a MATLAB structure.
try
    tree = xmlread(filename);
catch
    theStruct = [];
    return;
end

% Recurse over child nodes. This could run into problems
% with very deeply nested trees.
try
    theStruct = parseChildNodes(tree);
catch
    error('Unable to parse XML file %s.',filename);
end
end


% ----- Local function PARSECHILDNODES -----
function children = parseChildNodes(theNode)
% Recurse over node children.
children = [];
if theNode.hasChildNodes
    childNodes = theNode.getChildNodes;
    numChildNodes = childNodes.getLength;
    allocCell = cell(1, numChildNodes);
    
    children = struct(             ...
        'Name', allocCell, 'Attributes', allocCell,    ...
        'Data', allocCell, 'Children', allocCell);
    
    for count = 1:numChildNodes
        theChild = childNodes.item(count-1);
        children(count) = makeStructFromNode(theChild);
    end
end
end

% ----- Local function MAKESTRUCTFROMNODE -----
function nodeStruct = makeStructFromNode(theNode)
% Create structure of node info.

nodeStruct = struct(                        ...
    'Name', char(theNode.getNodeName),       ...
    'Attributes', parseAttributes(theNode),  ...
    'Data', '',                              ...
    'Children', parseChildNodes(theNode));

if any(strcmp(methods(theNode), 'getData'))
    nodeStruct.Data = char(theNode.getData);
else
    nodeStruct.Data = '';
end
end

% ----- Local function PARSEATTRIBUTES -----
function attributes = parseAttributes(theNode)
% Create attributes structure.
attributes = [];
if theNode.hasAttributes
    theAttributes = theNode.getAttributes;
    numAttributes = theAttributes.getLength;
    allocCell = cell(1, numAttributes);
    attributes = struct('Name', allocCell, 'Value', ...
        allocCell);
    
    for count = 1:numAttributes
        attrib = theAttributes.item(count-1);
        attributes(count).Name = char(attrib.getName);
        attributes(count).Value = char(attrib.getValue);
    end
end
end