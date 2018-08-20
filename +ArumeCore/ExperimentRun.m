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
            
            if ( ~isempty( this.pastTrialTable ) )
                % deal with the possibility that different trials have
                % different columns
                t1 = this.pastTrialTable;
                t2 = trialData;
                t1colmissing = setdiff(t2.Properties.VariableNames, t1.Properties.VariableNames);
                t2colmissing = setdiff(t1.Properties.VariableNames, t2.Properties.VariableNames);
                t1 = [t1 array2table(nan(height(t1), numel(t1colmissing)), 'VariableNames', t1colmissing)];
                t2 = [t2 array2table(nan(height(t2), numel(t2colmissing)), 'VariableNames', t2colmissing)];
                for colname = t1colmissing
                    if iscell(t2.(colname{1}))
                        t1.(colname{1}) = cell(height(t1), 1);
                    end
                end
                for colname = t2colmissing
                    if iscell(t1.(colname{1}))
                        t2.(colname{1}) = cell(height(t2), 1);
                    end
                end
                this.pastTrialTable = [t1; t2];
            else
                this.pastTrialTable = trialData;
            end
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

