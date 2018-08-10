classdef ExperimentRun < matlab.mixin.Copyable
    %EXPERIMENTRUN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % IMPORTANT! all properties must be saved in the method
        % SaveRunData and loaded in LoadRunData
        
        ExperimentDesign
        
        Info
        
        pastConditions
        futureConditions
        originalFutureConditions
        
        Events
        Data
        LinkedFiles
        
        SessionsToRun
        CurrentSession
    end
    
    methods
        %% GetStats
        function stats = GetStats(this)
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            trialsPerSession = this.ExperimentDesign.trialsPerSession;
            
            if ( ~isempty(this.pastConditions) )
                cond = this.pastConditions(:,Enum.pastConditions.condition);
                res = this.pastConditions(:,Enum.pastConditions.trialResult);
                blockn = this.pastConditions(:,Enum.pastConditions.blocknumber);
                blockid = this.pastConditions(:,Enum.pastConditions.blockid);
                sess = this.pastConditions(:,Enum.pastConditions.session);
                
                stats.trialsCorrect = sum( res == Enum.trialResult.CORRECT );
                stats.trialsAbort   =  sum( res ~= Enum.trialResult.CORRECT );
                stats.totalTrials   = length(cond);
                stats.sessionTrialsCorrect = sum( res == Enum.trialResult.CORRECT & sess == this.CurrentSession );
                stats.sessionTrialsAbort   =  sum( res ~= Enum.trialResult.CORRECT & sess == this.CurrentSession );
                stats.sessionTotalTrials   = length(cond & sess == this.CurrentSession );
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
            stats.trialsInExperiment = size(this.originalFutureConditions,1);
            
            if ( ~isempty(this.futureConditions) )
                futcond = this.futureConditions(:,Enum.futureConditions.condition);
                futblockn = this.futureConditions(:,Enum.futureConditions.blocknumber);
                futblockid = this.futureConditions(:,Enum.futureConditions.blockid);
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
            
            newRun.pastConditions   = []; % conditions already run, including aborts
            newRun.futureConditions = []; % conditions left for running (the whole list is created a priori)
            newRun.Events           = [];
            newRun.Data             = [];
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
            
            newRun.futureConditions = [];
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
                newRun.futureConditions = cat(1,newRun.futureConditions, [trialSequence' ones(size(trialSequence'))*iblock  ones(size(trialSequence'))*i] );
            end
            
            newRun.pastConditions = zeros(0,5);
            newRun.SessionsToRun    = ceil(size(newRun.futureConditions,1) / experimentDesign.trialsPerSession);
            newRun.originalFutureConditions = newRun.futureConditions;
            
            newRun.CurrentSession = 1;
        end
        
        function run = LoadRunData( data, experiment )
            
            % create the new object
            run = ArumeCore.ExperimentRun();
            
            run.ExperimentDesign = experiment;
            
            run.Info = data.Info;
            
            run.pastConditions = data.pastConditions;
            run.futureConditions = data.futureConditions;
            run.originalFutureConditions = data.originalFutureConditions;
            
            run.Events = data.Events;
            run.Data = data.Data;
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
            
            runData.pastConditions = run.pastConditions;
            runData.futureConditions = run.futureConditions;
            runData.originalFutureConditions = run.originalFutureConditions;
            
            runData.Events = run.Events;
            runData.Data = run.Data;
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

