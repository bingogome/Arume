classdef SVV2AFCAdaptiveLongSim < ArumeExperimentDesigns.SVV2AFCAdaptiveLong
    %SVVLineAdaptiveLong Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        
        function initExperimentDesign( this  )
            this.trialDuration = this.ExperimentOptions.fixationDuration/1000 ...
                + this.ExperimentOptions.targetDuration/1000 ...
                + this.ExperimentOptions.responseDuration/1000 ; %seconds
            
            % default parameters of any experiment
            this.trialSequence      = 'Random';      % Sequential, Random, Random with repetition, ...
            this.trialAbortAction   = 'Delay';    % Repeat, Delay, Drop
            this.trialsPerSession   = 500;
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 100;
            this.blocksToRun = 1;
            this.blocks = [ struct( 'fromCondition', 1, 'toCondition', 10, 'trialsToRun', 10) ];
        end
        
        
        function trialResult = runTrial( this, variables )
                        
            try
                this.lastResponse = -1;
                this.reactionTime = -1;
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                trialResult = Enum.trialResult.CORRECT;
               
                n = size(this.Session.currentRun.pastConditions,1);
                
                if ( n <100)
                    svv = 0;
                else
                    svv = (n-100)/2;
                end
                
                t = 1./(1+exp(-(this.currentAngle-svv)/2));
                
                if ( rand(1)<t )
                    this.lastResponse = 'R';
                else
                      this.lastResponse = 'L';
                end
                
            end
                
        end
    end
end

