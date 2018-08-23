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
    end
    
    methods(Static=true)
        
        %% setUpNewRun
        function newRun = SetUpNewRun( experimentDesign )
            
            trialTable = experimentDesign.GetTrialTable();
            % TODO: check if the table has the needed columns for dealing
            % drops blockid and blockseq
            
            newRun.futureTrialTable = trialTable;
            newRun.originalFutureTrialTable = trialTable;

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
            
            if ( isfield(run,'info') )
                runData.Info = run.Info;
            end
            
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

