classdef SVVCWCCWRandom < ArumeExperimentDesigns.SVVCWCCW
    
    
    properties
        
    end
    
    % ---------------------------------------------------------------------
    % Options to set at runtime
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function initExperimentDesign( this  )
            
            this.trialDuration = 3; %seconds
            
            % default parameters of any experiment
            this.trialSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            this.trialsPerSession = sum(21:-2:15)*4;
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 1;
            this.blocksToRun              = 16;
            
            n = Shuffle(1:4);
            
            this.blocks(n(1)).fromCondition  = 1;
            this.blocks(n(1)).toCondition    = 21;
            this.blocks(n(1)).trialsToRun    = 21;
            
            this.blocks(n(2)).fromCondition  = 2;
            this.blocks(n(2)).toCondition    = 20;
            this.blocks(n(2)).trialsToRun    = 19;
            
            this.blocks(n(3)).fromCondition  = 3;
            this.blocks(n(3)).toCondition    = 19;
            this.blocks(n(3)).trialsToRun    = 17;
            
            this.blocks(n(4)).fromCondition  = 4;
            this.blocks(n(4)).toCondition    = 18;
            this.blocks(n(4)).trialsToRun    = 15;
            
            n = Shuffle(5:8);
            
            this.blocks(n(1)).fromCondition  = 1;
            this.blocks(n(1)).toCondition    = 21;
            this.blocks(n(1)).trialsToRun    = 21;
            
            this.blocks(n(2)).fromCondition  = 2;
            this.blocks(n(2)).toCondition    = 20;
            this.blocks(n(2)).trialsToRun    = 19;
            
            this.blocks(n(3)).fromCondition  = 3;
            this.blocks(n(3)).toCondition    = 19;
            this.blocks(n(3)).trialsToRun    = 17;
            
            this.blocks(n(4)).fromCondition  = 4;
            this.blocks(n(4)).toCondition    = 18;
            this.blocks(n(4)).trialsToRun    = 15;
            
            n = Shuffle(9:12);
            
            this.blocks(n(1)).fromCondition  = 22;
            this.blocks(n(1)).toCondition    = 42;
            this.blocks(n(1)).trialsToRun    = 21;
            
            this.blocks(n(2)).fromCondition  = 23;
            this.blocks(n(2)).toCondition    = 41;
            this.blocks(n(2)).trialsToRun    = 19;
            
            this.blocks(n(3)).fromCondition  = 24;
            this.blocks(n(3)).toCondition    = 40;
            this.blocks(n(3)).trialsToRun    = 17;
            
            this.blocks(n(4)).fromCondition  = 25;
            this.blocks(n(4)).toCondition    = 39;
            this.blocks(n(4)).trialsToRun    = 15;
            
            n = Shuffle(13:16);
            
            this.blocks(n(1)).fromCondition  = 22;
            this.blocks(n(1)).toCondition    = 42;
            this.blocks(n(1)).trialsToRun    = 21;
            
            this.blocks(n(2)).fromCondition  = 23;
            this.blocks(n(2)).toCondition    = 41;
            this.blocks(n(2)).trialsToRun    = 19;
            
            this.blocks(n(3)).fromCondition  = 24;
            this.blocks(n(3)).toCondition    = 40;
            this.blocks(n(3)).trialsToRun    = 17;
            
            this.blocks(n(4)).fromCondition  = 25;
            this.blocks(n(4)).toCondition    = 39;
            this.blocks(n(4)).trialsToRun    = 15;
            
        end
        
        %% run initialization before the first trial is run
        function initBeforeRunning( this )
            if ( this.ExperimentOptions.UseGamePad )
                ArumeHardware.GamePad.Open
            end
        end
        
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Angle';
            conditionVars(i).values = [-20:2:20];
            
            i = i+1;
            conditionVars(i).name   = 'Direction';
            conditionVars(i).values = {'CW' 'CCW'};
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
    end
    
    % ---------------------------------------------------------------------
    % Other methods
    % ---------------------------------------------------------------------
    methods( Access = public )
    end
end
