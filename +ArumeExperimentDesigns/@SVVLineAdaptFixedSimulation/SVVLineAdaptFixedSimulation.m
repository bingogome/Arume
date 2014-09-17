classdef SVVLineAdaptFixedSimulation < ArumeExperimentDesigns.SVVdotsAdaptFixed
    
    properties
    end
    
    % ---------------------------------------------------------------------
    % Options to set at runtime
    % ---------------------------------------------------------------------
    methods ( Static = true )
        function dlg = GetOptionsStructDlg( this )
            dlg.UseGamePad = { {'0','{1}'} };
            dlg.UseEyeTracker = { {'{0}','1'} };
            dlg.FixationDiameter = { 12.5 '* (pix)' [3 50] };
            dlg.TargetDiameter = { 12.5 '* (pix)' [3 50] };
            dlg.targetDistance = { 125 '* (pix)' [10 500] };
            dlg.fixationDuration = { 1000 '* (ms)' [1 3000] };
            dlg.targetDuration = { 300 '* (ms)' [100 30000] };
            dlg.responseDuration = { 1500 '* (ms)' [100 3000] };
            dlg.SVV = 0;
            dlg.SVVstd = 1;
            
            dlg.SVVWaveFreq = 0;
            dlg.SVVWaveAmplitude = 0;
            dlg.SVVWavePhase = 0;
        end
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        function trialResult = runTrial( this, variables )
            
            try
                this.lastResponse = -1;
                this.reactionTime = -1;
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                                
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
              
                this.currentAngle;
                
                ntrials = size(this.Session.CurrentRun.pastConditions,1);
                SVV = this.ExperimentOptions.SVV + this.ExperimentOptions.SVVWaveAmplitude*sin(ntrials*this.ExperimentOptions.SVVWaveFreq*2*pi + this.ExperimentOptions.SVVWavePhase);
                
                t = 1./(1+exp(-(this.currentAngle-SVV)/this.ExperimentOptions.SVVstd));
                
                this.lastResponse = (rand(1)>t);
                
            catch ex
                %  this.eyeTracker.StopRecording();
                rethrow(ex)
            end
            
            
            if ( this.lastResponse < 0)
                trialResult =  Enum.trialResult.ABORT;
            end
            
            % this.eyeTracker.StopRecording();
            
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
end

