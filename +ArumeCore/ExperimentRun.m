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
            
            % create the new object
            newRun = ArumeCore.ExperimentRun();
            
            newRun.ExperimentDesign = experimentDesign;
            
            % use predictable randomization saving state
            newRun.Info.globalStream   = RandStream.getGlobalStream;
            newRun.Info.stateRandStream     = newRun.Info.globalStream.State;
            
            newRun.pastTrialTable   = []; % conditions already run, including aborts
            newRun.futureTrialTable = []; % conditions left for running (the whole list is created a priori)
            newRun.Events           = [];
            newRun.LinkedFiles      = [];
            
            % generate the sequence of blocks, a total of
            % parameters.blocksToRun blocks will be run
            nBlocks = length(experimentDesign.blocks);
            blockSequence = [];
            switch(experimentDesign.blockSequence)
                case 'Sequential'
                    blockSequence = mod( (1:experimentDesign.blocksToRun)-1,  nBlocks ) + 1;
                case 'Random'
                    [~, blocks] = sort( rand(1,experimentDesign.blocksToRun) ); % get a random shuffle of 1 ... blocks to run
                    blockSequence = mod( blocks-1,  nBlocks ) + 1; % limit the random sequence to 1 ... nBlocks
                case 'Random with repetition'
                    blockSequence = ceil( rand(1,experimentDesign.blocksToRun) * nBlocks ); % just get random block numbers
                case 'Manual'
                    blockSequence = [];
                    
                    while length(blockSequence) ~= experimentDesign.blocksToRun
                        S.Block_Sequence = [1:experimentDesign.blocksToRun];
                        S = StructDlg( S, ['Block Sequence'], [],  CorrGui.get_default_dlg_pos() );
                        blockSequence =  S.Block_Sequence;
                    end
                    %                     if length(parameters.manualBlockSequence) == parameters.blocksToRun;
                    %                         %                         blockSequence = parameters.manualBlockSequence;
                    %
                    %                     else
                    %                         disp(['Error with the manual block sequence. Please fix.']);
                    %                     end
            end
            blockSequence = repmat( blockSequence,1,experimentDesign.numberOfTimesRepeatBlockSequence);
            
            futureConditions = [];
            for iblock=1:length(blockSequence)
                i = blockSequence(iblock);
                possibleConditions = experimentDesign.blocks(i).fromCondition : experimentDesign.blocks(i).toCondition; % the possible conditions to select from in this block
                nConditions = length(possibleConditions);
                nTrials = experimentDesign.blocks(i).trialsToRun;
                
                switch( experimentDesign.trialSequence )
                    case 'Sequential'
                        trialSequence = possibleConditions( mod( (1:nTrials)-1,  nConditions ) + 1 );
                    case 'Random'
                        [junk conditions] = sort( rand(1,nTrials) ); % get a random shuffle of 1 ... nTrials
                        conditionIndexes = mod( conditions-1,  nConditions ) + 1; % limit the random sequence to 1 ... nConditions
                        trialSequence = possibleConditions( conditionIndexes ); % limit the random sequence to fromCondition ... toCondition for this block
                    case 'Random with repetition'
                        trialSequence = possibleConditions( ceil( rand(1,nTrials) * nConditions ) ); % nTrialss numbers between 1 and nConditions
                end
                futureConditions = cat(1,futureConditions, [trialSequence' ones(size(trialSequence'))*iblock  ones(size(trialSequence'))*i] );
            end
            
            newRun.pastTrialTable = [];
            newRun.SessionsToRun  = ceil(size(futureConditions,1) / experimentDesign.trialsPerSession);
            
            newRun.CurrentSession = 1;
            
            f2 = table();
            f2.TrialNumber = (1:length(futureConditions(:,1)))';
            f2.Condition = futureConditions(:,1);
            f2.BlockNumber = futureConditions(:,2);
            f2.BlockSequenceNumber = futureConditions(:,3);
            
            t2 = table();
            for i=1:height(f2)
                vars = experimentDesign.getVariablesCurrentCondition( f2.Condition(i) );
                t2 = cat(1,t2,struct2table(vars,'AsArray',true));
            end
            
            newRun.futureTrialTable = [f2 t2];
            newRun.originalFutureTrialTable = newRun.futureTrialTable;

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

