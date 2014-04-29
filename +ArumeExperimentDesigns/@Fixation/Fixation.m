classdef Fixation < ArumeCore.ExperimentDesign
    %OPTOKINETICTORSION Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        eyeTracker
        
        fixRad = 20;
        fixColor = [255 0 0];
    end
    
    % ---------------------------------------------------------------------
    % Options to set at runtime
    % ---------------------------------------------------------------------
    methods ( Static = true )
        function dlg = GetOptionsStructDlg( this )
            dlg.TrialDuration = 30;
            dlg.NumberOfTrials = 10;
        end
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function initExperimentDesign( this  )
            
            this.HitKeyBeforeTrial = 1;
            
            this.trialDuration = this.ExperimentOptions.TrialDuration; %seconds
            
            % default parameters of any experiment
            this.trialSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            this.trialsPerSession = this.ExperimentOptions.NumberOfTrials;
            
                %%-- Blocking
                this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
                this.numberOfTimesRepeatBlockSequence = 1;
                this.blocksToRun = 1;
                this.blocks = [ struct( 'fromCondition', 1, 'toCondition', 1, 'trialsToRun', this.ExperimentOptions.NumberOfTrials ) ];
        end
        
        function initBeforeRunning( this )
            try
                asm = NET.addAssembly('C:\secure\Code\EyeTracker\bin\Debug\VOGLib.dll');
                this.eyeTracker = OculomotorLab.VOG.Remote.EyeTrackerClient('localhost',9000);
                this.eyeTracker.SetDataFileName(this.Session.name);
            catch
                disp('NO EYE TRACKER');
                this.eyeTracker = [];
            end
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Fixation';
            conditionVars(i).values = {'Center'};
        end
        
        function [ randomVars] = getRandomVariables( this )
            randomVars = [];
        end
        
        function trialResult = runPreTrial(this, variables )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            % Add stuff here
            
            trialResult =  Enum.trialResult.CORRECT;
        end
        
        function trialResult = runTrial( this, variables )
            
            if ( ~isempty(this.eyeTracker) )
                this.eyeTracker.StartRecording();
            end
           
            try                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                
                
                graph = this.Graph;
                
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
                
                lastFlipTime        = GetSecs;
                secondsRemaining    = this.trialDuration;
                
                startLoopTime = lastFlipTime;
                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - startLoopTime;
                    secondsRemaining    = this.trialDuration - secondsElapsed;
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    %-- Find the center of the screen
                    [mx, my] = RectCenter(graph.wRect);
                    
                    %-- Draw fixation spot
                    fixRect = [0 0 5 5];
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    Screen('FillOval', graph.window, this.fixColor, fixRect);
                    
                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------
                    
                    % -----------------------------------------------------------------
                    % -- Flip buffers to refresh screen -------------------------------
                    % -----------------------------------------------------------------
                    this.Graph.Flip();
                    % -----------------------------------------------------------------
                    
                    
                    % -----------------------------------------------------------------
                    % --- Collecting responses  ---------------------------------------
                    % -----------------------------------------------------------------
                    
                    % -----------------------------------------------------------------
                    % --- END Collecting responses  -----------------------------------
                    % -----------------------------------------------------------------
                    
                end
            catch ex
                if ( ~isempty(this.eyeTracker) )
                    this.eyeTracker.StopRecording();
                end
                rethrow(ex)
            end
            
            if ( ~isempty(this.eyeTracker) )
                this.eyeTracker.StopRecording();
            end
            
        end
        
        function trialOutput = runPostTrial(this)
            trialOutput = [];   
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
    end
    
    % ---------------------------------------------------------------------
    % Plot  methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
    end
    
    % ---------------------------------------------------------------------
    % Plot Aggregate methods
    % ---------------------------------------------------------------------
    methods ( Static = true, Access = public )
    end
    
    % ---------------------------------------------------------------------
    % Other methods
    % ---------------------------------------------------------------------
    methods( Access = public )
    end
end