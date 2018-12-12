classdef EyeTrackingOtosuite  < ArumeExperimentDesigns.EyeTracking
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods (Access=protected)
        function dlg = GetOptionsDialog( this, importing )
            dlg = [];
            if ( exist('importing','var') && importing )
                dlg.RawDataFile = { {['uigetfile(''' fullfile(pwd,'*.txt') ''',''MultiSelect'', ''on'')']} };
                dlg.SpvDataFile = { {['uigetfile(''' fullfile(pwd,'*.txt') ''',''MultiSelect'', ''on'')']} };
                dlg.Test = '';
            end
        end
    end
    
    % --------------------------------------------------------------------
    % Analysis methods --------------------------------------------------
    % --------------------------------------------------------------------
    methods ( Access = public )
        %% ImportSession
        function ImportSession( this )
            
            
            % FOR SAI do not delete
            newRun = ArumeCore.ExperimentRun.SetUpNewRun( this );
            vars = newRun.futureTrialTable;
            vars.TrialResult = categorical(cellstr('CORRECT'));
            vars.TrialNumber = 1;
            newRun.AddPastTrialData(vars);
            newRun.futureTrialTable(:,:) = [];
            this.Session.importCurrentRun(newRun);
            % END FOR SAI
            
            
            % FOR SAI should have code to copy files into the session folder using this.Session.addFile
            
            rawFile = this.ExperimentOptions.RawDataFile;
            spvFile = this.ExperimentOptions.SpvDataFile;
            
            if (exist(rawFile,'file') )
                this.Session.addFile('vogRawDataFile', rawFile);
            end
            
            if (exist(spvFile,'file') )
                this.Session.addFile('vogSpvDataFile', spvFile);
            end
            
        end
        
        function [rawData, rawPixelData] = PrepareSamplesDataTable(this)
            rawData = table();
            rawPixelData = table();
            
            if ( ~isprop(this.Session.currentRun, 'LinkedFiles' ) || ~isfield(this.Session.currentRun.LinkedFiles,  'vogRawDataFile') )
                return;
            end
            
            % FOR SAI load the file that you added in import using Linkedfiles
            rawFile = this.Session.currentRun.LinkedFiles.vogRawDataFile;
            
            cprintf('blue','ARUME :: PreparingDataTable::Reading data File %s ...\n',rawFile);
            
            rawFilePath = fullfile(this.Session.dataPath, rawFile);
            
            % load and preprocess data
            
            % FOR SAI create a new function that loads the data and
            % puts it in this format:
            %
            %             calibratedData = table(t, f, fr, lx, ly, lt, rx, ry, rt, lel,rel,lell,rell, lp, rp, ...
            %                 'VariableNames',{'Time' 'FrameNumber', 'FrameNumberRaw', 'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT' 'LeftUpperLid' 'RightUpperLid'  'LeftLowerLid' 'RightLowerLid' 'LeftPupil' 'RightPupil'});
            %
            %             headData = table( rawData.AccelerometerX, rawData.AccelerometerY, rawData.AccelerometerZ, rawData.GyroX, rawData.GyroY, rawData.GyroZ, ...
            %                 'VariableNames', {'HeadRoll', 'HeadPitch', 'HeadYaw', 'HeadRollVel', 'HeadPitchVel', 'HeadYawVel'});
            %
            %             calibratedData = [calibratedData headData];
            
            [calibratedData, rawPixelData] = LoadRawData(rawFilePath);
            inds  = find(diff(calibratedData.Time)==0);
            if numel(inds)>1
                error('Timing Overlap');
            end
            % FOR SAI do not change this creates the nice cleaned data
            params   = VOGAnalysis.GetParameters();
            rawData  = VOGAnalysis.ResampleAndCleanData(calibratedData,params);
            
        end
        
        function optionsDlg = GetAnalysisOptionsDialog(this)
            optionsDlg = GetAnalysisOptionsDialog@ArumeExperimentDesigns.EyeTracking(this);
            optionsDlg.SPV_Simple = { {'{0}','1'} };
            optionsDlg.SPV_QP_SP = { {'{0}','1'} };
            % add options for analysis
        end
        
        function [analysisResults, samplesDataTable, trialDataTable, sessionTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable, sessionTable, options)
            
            [analysisResults, samplesDataTable, trialDataTable, sessionTable]  =  RunDataAnalyses@ArumeExperimentDesigns.EyeTracking(this, analysisResults, samplesDataTable, trialDataTable, sessionTable, options);
            
            %%%%%%%%%%%% For SPV_Simple : Without Saccade detection %%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if ( options.SPV_Simple )
                analysisResults.SPV_Simple = table();
                
                T = samplesDataTable.Properties.UserData.sampleRate;
                analysisResults.SPV_Simple.Time = samplesDataTable.Time(T/2:T:end);
                fields = {'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'};
                
                t = samplesDataTable.Time;
                %
                % calculate monocular spv
                %
                for j =1:length(fields)
                    if ismember(fields{j}, samplesDataTable.Properties.VariableNames)
                        
                        [vmed, xmed] = VOGAnalysis.GetSPV_Simple(t, samplesDataTable.(fields{j}));
                        
                        analysisResults.SPV_Simple.(fields{j}) = vmed(T/2:T:end);
                        analysisResults.SPV_Simple.([fields{j} 'Pos']) = xmed(T/2:T:end);
                        
                    end
                end
                %
                % calculate binocular spv
                %
                LRdataVars = {'X', 'Y', 'T'};
                for j =1:length(LRdataVars)
                    if ismember(fields{j}, samplesDataTable.Properties.VariableNames) && ismember(fields{j+3}, samplesDataTable.Properties.VariableNames)
                        
                        [vleft, xleft] = VOGAnalysis.GetSPV_Simple(t, samplesDataTable.(['Left' LRdataVars{j}]));
                        [vright, xright] = VOGAnalysis.GetSPV_Simple(t, samplesDataTable.(['Right' LRdataVars{j}]));
                        
                        vmed = nanmedfilt(nanmean([vleft, vright],2),T,1/2);
                        xmed = nanmedfilt(nanmean([xleft, xright],2),T,1/2);
                        
                        analysisResults.SPV_Simple.(LRdataVars{j}) = vmed(T/2:T:end);
                        analysisResults.SPV_Simple.([LRdataVars{j} 'Pos']) = xmed(T/2:T:end);
                        
                    elseif ismember(fields{j}, samplesDataTable.Properties.VariableNames) && ~ismember(fields{j+3}, samplesDataTable.Properties.VariableNames)
                        
                        analysisResults.SPV_Simple.(LRdataVars{j}) = analysisResults.SPV_Simple.(['Left' LRdataVars{j}]);
                        analysisResults.SPV_Simple.([LRdataVars{j} 'Pos']) = analysisResults.SPV_Simple.(['Left' LRdataVars{j} 'Pos']);
                        
                    elseif ~ismember(fields{j}, samplesDataTable.Properties.VariableNames) && ismember(fields{j+3}, samplesDataTable.Properties.VariableNames)
                        
                        analysisResults.SPV_Simple.(LRdataVars{j}) = analysisResults.SPV_Simple.(['Right' LRdataVars{j}]);
                        analysisResults.SPV_Simple.([LRdataVars{j} 'Pos']) = analysisResults.SPV_Simple.(['Right' LRdataVars{j} 'Pos']);
                        
                    end
                end
                
            end
            
            %%%%%%%%%%%% For SPV_QP_SP : Using Saccade detection %%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            if ( options.SPV_QP_SP )
                
                analysisResults.SPV_QP_SP = table();
                
                T = samplesDataTable.Properties.UserData.sampleRate;
                analysisResults.SPV_QP_SP.Time = samplesDataTable.Time(T/2:T:end);
                fields = {'LeftX', 'LeftY', 'LeftT', 'RightX', 'RightY', 'RightT'};
                
                for j = 1:length(fields)
                    if ismember(fields{j}, samplesDataTable.Properties.VariableNames)
                        
                        % calculate SPV using the QP and SP detection
                        spv = diff(samplesDataTable.(fields{j}))./diff(samplesDataTable.Time);
                        
                        spv(analysisResults.QuickPhases.StartIndex:analysisResults.QuickPhases.EndIndex) = nan;
                        
                        secondPassMedfiltWindow         = 1;    %s
                        secondPassMedfiltNanFraction    = 0.5;   %
                        spv = nanmedfilt(spv,T*secondPassMedfiltWindow,secondPassMedfiltNanFraction);
                        spv = spv(T/2:T:end);
                        
                        analysisResults.SPV_QP_SP.(fields{j}) = spv;
                        clear spv
                    end
                end
                %
                % calculate binocular spv
                %
                LRdataVars = {'X', 'Y', 'T'};
                for j =1:length(LRdataVars)
                    if ismember(fields{j}, samplesDataTable.Properties.VariableNames) && ismember(fields{j+3}, samplesDataTable.Properties.VariableNames)
                        
                        vleft = diff(samplesDataTable.(['Left' LRdataVars{j}]))./diff(samplesDataTable.Time);
                        vright = diff(samplesDataTable.(['Right' LRdataVars{j}]))./diff(samplesDataTable.Time);
                        
                        vleft(analysisResults.QuickPhases.StartIndex:analysisResults.QuickPhases.EndIndex) = nan;
                        vright(analysisResults.QuickPhases.StartIndex:analysisResults.QuickPhases.EndIndex) = nan;
                        
                        vmed = nanmedfilt(nanmean([vleft, vright],2),T,1/2);
                        vmed = vmed(T/2:T:end);
                        
                        analysisResults.SPV_QP_SP.(LRdataVars{j}) = vmed;                        
                        
                    elseif ismember(fields{j}, samplesDataTable.Properties.VariableNames) && ~ismember(fields{j+3}, samplesDataTable.Properties.VariableNames)
                        
                        analysisResults.SPV_QP_SP.(LRdataVars{j}) = analysisResults.SPV_Simple.(['Left' LRdataVars{j}]);
                        
                    elseif ~ismember(fields{j}, samplesDataTable.Properties.VariableNames) && ismember(fields{j+3}, samplesDataTable.Properties.VariableNames)
                        
                        analysisResults.SPV_QP_SP.(LRdataVars{j}) = analysisResults.SPV_Simple.(['Right' LRdataVars{j}]);
                        
                    end
                end
                
            end
            
            
            load(sessionTable.Option_SpvDataFile);
            analysisResults.SPV_Otosuite = spv;
            if ismember('TR',analysisResults.SPV_Otosuite.Properties.VariableNames)
                analysisResults.SPV_Otosuite.Properties.VariableNames = {'Time','X','Y','T'};
            else
                analysisResults.SPV_Otosuite.Properties.VariableNames = {'Time','X','Y'};
            end
            
            %% Adding info to sessionTable
            typeOfSPV = {'SPV_Simple','SPV_QP_SP','SPV_Otosuite'};
            signals1 = {'X', 'Y', 'T'};
            signals2 = {'H', 'V', 'T'};
            for i=1:length(typeOfSPV)
                for j=1:length(signals1)
                    
                    sessionTable.([typeOfSPV{i} '_PeakSPV' signals2{j} 'R']) = nanmean(abs(analysisResults.(typeOfSPV{i}).([signals1{j}])));  
                    sessionTable.([typeOfSPV{i} '_MaxSPV' signals2{j} 'R']) = max((analysisResults.(typeOfSPV{i}).([signals1{j}])));
                    sessionTable.([typeOfSPV{i} '_MinSPV' signals2{j} 'R']) = min((analysisResults.(typeOfSPV{i}).([signals1{j}])));
                    sessionTable.([typeOfSPV{i} '_AvgSPV' signals2{j} 'R']) = nanmean((analysisResults.(typeOfSPV{i}).([signals1{j}])));
                    sessionTable.([typeOfSPV{i} '_PeakSPVTime' signals2{j} 'Rms']) = nanmean((analysisResults.(typeOfSPV{i}).([signals1{j}]))); 
                    
                end
            end
        end
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function Plot_Example(this)
            a=1;
        end
    end
    
end



