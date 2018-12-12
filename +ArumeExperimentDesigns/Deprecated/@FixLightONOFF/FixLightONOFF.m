classdef FixLightONOFF < ArumeCore.ExperimentDesign
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
            dlg.UseEyeTracker = { {'{0}' '1'} };
            dlg.FixationDuration = { 2 '* (seconds)' [1 100] };
            dlg.NumberOfTrials = { 1 '* (N)' [1 100] };
        end
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function initExperimentDesign( this  )
            
            this.HitKeyBeforeTrial = 1;
            
            this.trialDuration = this.ExperimentOptions.FixationDuration*2*8+2; %seconds
            
            % default parameters of any experiment
            this.trialSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.trialAbortAction = 'Repeat';     % Repeat, Delay, Drop
            this.trialsPerSession = this.ExperimentOptions.NumberOfTrials;
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 1;
            this.blocksToRun = 1;
            this.blocks = [ struct( 'fromCondition', 1, 'toCondition', 2, 'trialsToRun', this.ExperimentOptions.NumberOfTrials ) ];
        end
        
        function initBeforeRunning( this )
%             try
%                 asm = NET.addAssembly('C:\secure\Code\EyeTracker\bin\Debug\VOGLib.dll');
%                 this.eyeTracker = OculomotorLab.VOG.Remote.EyeTrackerClient('localhost',9000);
%                 this.eyeTracker.SetDataFileName(this.Session.name);
%             catch
%                 disp('NO EYE TRACKER');
%                 this.eyeTracker = [];
%             end
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Fixation';
            conditionVars(i).values = {'Center'};
            
            conditionVars(i).name   = 'Direction';
            conditionVars(i).values = {'CW' 'CCW'};
        end
        
        function trialResult = runPreTrial(this, variables )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            % Add stuff here
            
            if ( this.ExperimentOptions.UseEyeTracker )
                asm = NET.addAssembly('C:\secure\Code\EyeTracker\bin\Debug\EyeTrackerRemoteClient.dll');
                %this.eyeTracker = OculomotorLab.VOG.Remote.EyeTrackerClient('10.17.101.13',9000);
                this.eyeTracker = OculomotorLab.VOG.Remote.EyeTrackerClient('localhost',9000);
                this.eyeTracker.SetDataFileName(this.Session.name);
            end
            
            trialResult =  Enum.trialResult.CORRECT;
        end
        
        function trialResult = runTrial( this, variables )
                       
            try                
                
                if ( this.ExperimentOptions.UseEyeTracker )
                    if ( ~this.eyeTracker.recording )
                        this.eyeTracker.StartRecording();
                        pause(1);
                    end
                end
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                
                
                graph = this.Graph;
                
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
                
                lastFlipTime        = GetSecs;
                secondsRemaining    = this.trialDuration;
                
                startLoopTime = lastFlipTime;
                
                timeLastTarget = 0;
                secondsInTarget = 0;
                OnOrOff = 0;
                                
                while secondsRemaining > 0
                    
                    secondsElapsed      = GetSecs - startLoopTime;
                    secondsRemaining    = this.trialDuration - secondsElapsed;
                    
                    secondsInTarget = secondsElapsed - timeLastTarget;
                    if ( secondsInTarget > 2 )
                        if ( OnOrOff == 0 )
                            OnOrOff = 1;
                        else
                            OnOrOff = 0;
                        end
                        timeLastTarget = secondsElapsed;
                    end
                    
                    
                    % -----------------------------------------------------------------
                    % --- Drawing of stimulus -----------------------------------------
                    % -----------------------------------------------------------------
                    
                    %-- Find the center of the screen
                    [mx, my] = RectCenter(graph.wRect);
                    
                    if ( OnOrOff == 0 )
                        Screen('FillRect', graph.window, 0);
                    else
                        Screen('FillRect', graph.window, 128);
                    end
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
                if ( this.ExperimentOptions.UseEyeTracker )
                    if ( this.eyeTracker.recording )
                        this.eyeTracker.StopRecording();
                        pause(1);
                    end
                end
                rethrow(ex)
            end
            
            if ( this.ExperimentOptions.UseEyeTracker )
                if ( this.eyeTracker.recording )
                    this.eyeTracker.StopRecording();
                    pause(1);
                end
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