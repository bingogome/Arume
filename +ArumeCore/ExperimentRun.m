classdef ExperimentRun < matlab.mixin.Copyable
    %EXPERIMENTRUN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % IMPORTANT! all properties must be saved in the method
        % SaveRunData and loaded in LoadRunData
        
        ExperimentDesign
        
        Info
        
        pastTrialTable
        futureTrialTable
        originalFutureTrialTable
        
        Events
        LinkedFiles
        
        SessionsToRun
        CurrentSession
    end
    
    methods
        %% GetStats
        function stats = GetStats(this)
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            trialsPerSession = this.ExperimentDesign.trialsPerSession;
            
            if ( ~isempty(this.pastTrialTable) )
                stats.trialsCorrect = sum( this.pastTrialTable.TrialResult == Enum.trialResult.CORRECT );
                stats.trialsAbort   =  sum( this.pastTrialTable.TrialResult ~= Enum.trialResult.CORRECT );
                stats.totalTrials   = height(this.pastTrialTable);
                stats.sessionTrialsCorrect = sum( this.pastTrialTable.TrialResult == Enum.trialResult.CORRECT & this.pastTrialTable.Session == this.CurrentSession );
                stats.sessionTrialsAbort   =  sum( this.pastTrialTable.TrialResult ~= Enum.trialResult.CORRECT & this.pastTrialTable.Session == this.CurrentSession );
                stats.sessionTotalTrials   = length(this.pastTrialTable.Condition & this.pastTrialTable.Session == this.CurrentSession );
            else
                stats.trialsCorrect = 0;
                stats.trialsAbort   =  0;
                stats.totalTrials   = 0;
                stats.sessionTrialsCorrect = 0;
                stats.sessionTrialsAbort   =  0;
                stats.sessionTotalTrials   = 0;
            end
            
            stats.currentSession = this.CurrentSession;
            stats.SessionsToRun = this.SessionsToRun;
            stats.trialsInExperiment = size(this.originalFutureTrialTable,1);
            
            if ( ~isempty(this.futureTrialTable) )
                futcond = this.futureTrialTable.Condition;
                futblockn = this.futureTrialTable.BlockNumber;
                futblockid = this.futureTrialTable.BlockSequenceNumber;
                stats.currentBlock = futblockn(1);
                stats.currentBlockID = futblockid(1);
                stats.blocksFinished = futblockn(1)-1;
                stats.trialsToFinishSession = min(trialsPerSession - stats.sessionTrialsCorrect,length(futcond));
                stats.trialsToFinishExperiment = length(futcond);
                stats.blocksInExperiment = futblockn(end);
            else
                stats.currentBlock = 1;
                stats.currentBlockID = 1;
                stats.blocksFinished = 0;
                stats.trialsToFinishSession = 0;
                stats.trialsToFinishExperiment = 0;
                stats.blocksInExperiment = 1;
            end
        end
        
        function run = Copy(this)
            run = copy(this); 
        end
        
        function trialData = AddPastTrialData(this, trialData)
            
            % remove empty fields. This will avoid problems when adding an
            % empty or missing element to the first row.
            % It is better to wait until some none empty element is added
            % so the type of the column is stablished. Then, the trials
            % without that column will receive the proper missing value.
            fs = fieldnames(trialData);
            for i=1:length(fs)
                if ( isempty( trialData.(fs{i})) )
                    trialData = rmfield(trialData,fs{i});
                elseif ( iscell(trialData.(fs{i})) && length(trialData.(fs{i}))==1 && isempty(trialData.(fs{i}){1}) )
                    trialData = rmfield(trialData,fs{i});
                elseif ( ismissing(trialData.(fs{i})) )
                    trialData = rmfield(trialData,fs{i});
                end
            end
            
            
            trialData = struct2table(trialData,'AsArray',true);
            
            this.pastTrialTable  = VertCatTablesMissing(this.pastTrialTable,trialData);
        end
    end
    
    methods(Static=true)
        
        %% setUpNewRun
        function newRun = SetUpNewRun( experimentDesign )
            
            newRun = ArumeCore.ExperimentRun();
            
            newRun.ExperimentDesign = experimentDesign;
            
            % use predictable randomization saving state
            newRun.Info.globalStream   = RandStream.getGlobalStream;
            newRun.Info.stateRandStream     = newRun.Info.globalStream.State;
            
            newRun.pastTrialTable   = []; % conditions already run, including aborts
            newRun.futureTrialTable = []; % conditions left for running (the whole list is created a priori)
            newRun.Events           = [];
            newRun.LinkedFiles      = [];
            
            newRun.futureTrialTable = experimentDesign.GetTrialTable();
            newRun.originalFutureTrialTable = newRun.futureTrialTable;
            % TODO: check if the table has the needed columns for dealing
            % drops blockid and blockseq

            newRun.pastTrialTable = [];
            newRun.SessionsToRun  = ceil(height(newRun.futureTrialTable) / experimentDesign.trialsPerSession);
            
            newRun.CurrentSession = 1;
            
        end
        
        function run = LoadRunData( data, experiment )
            
            % create the new object
            run = ArumeCore.ExperimentRun();
            
            run.ExperimentDesign = experiment;
            
            run.Info = data.Info;
            
            run.pastTrialTable = data.pastTrialTable;
            run.futureTrialTable = data.futureTrialTable;
            run.originalFutureTrialTable = data.originalFutureTrialTable;
            
            run.Events = data.Events;
            if ( isfield( data, 'LinkedFiles' ) )
                run.LinkedFiles = data.LinkedFiles;
            else
                run.LinkedFiles = [];
            end
            
            run.SessionsToRun = data.SessionsToRun;
            run.CurrentSession = data.CurrentSession;
        end
        
        function runArray = LoadRunDataArray( runsData, experiment )
            runArray = [];
            for i=1:length(runsData)
                if ( isempty(runArray) )
                    runArray  = ArumeCore.ExperimentRun.LoadRunData( runsData(i), experiment );
                else
                    runArray(i)  = ArumeCore.ExperimentRun.LoadRunData( runsData(i), experiment );
                end
            end
        end
        
        function runData = SaveRunData( run )
            
            runData.Info = run.Info;
            
            runData.pastTrialTable = run.pastTrialTable;
            runData.futureTrialTable = run.futureTrialTable;
            runData.originalFutureTrialTable = run.originalFutureTrialTable;
            
            runData.Events = run.Events;
            runData.LinkedFiles = run.LinkedFiles;
            
            runData.SessionsToRun = run.SessionsToRun;
            runData.CurrentSession = run.CurrentSession;
        end
        
        function runDataArray = SaveRunDataArray( runs )
            runDataArray = [];
            for i=1:length(runs)
                if ( isempty(runDataArray) )
                    runDataArray = ArumeCore.ExperimentRun.SaveRunData(runs(i));
                else
                    runDataArray(i) = ArumeCore.ExperimentRun.SaveRunData(runs(i));
                end
            end
        end
        
        
    end
    
end

