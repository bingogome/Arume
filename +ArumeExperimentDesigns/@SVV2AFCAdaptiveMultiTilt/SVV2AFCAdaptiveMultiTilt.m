classdef SVV2AFCAdaptiveMultiTilt < ArumeExperimentDesigns.SVV2AFCAdaptive
    %SVVLineAdaptiveLong Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function dlg = GetOptionsDialog( this, importing )
            if ( ~exist( 'importing', 'var') )
                importing = 0;
            end
            dlg = GetOptionsDialog@ArumeExperimentDesigns.SVV2AFCAdaptive(this,importing);
            
            dlg.PreviousTrialsForRange = { {'{All}','Previous30'} };
            dlg.RangeChanges = { {'{Slow}','Fast'} };
            dlg = rmfield(dlg, 'TotalNumberOfTrials');
            dlg = rmfield(dlg, 'HeadAngle');
            dlg = rmfield(dlg, 'TiltHeadAtBegining');
            dlg = rmfield(dlg, 'offset');
            
            dlg.Tilts = [10 20 30];
            dlg.TrialsPerTilt = {100 '* (trials)' [1 500] };
            
            if ( rand>0.5)
                dlg.FirstSide = { {'{Left}','Right'} };
            else
                dlg.FirstSide = { {'Left','{Right}'} };
            end 
            
            dlg.Prisms = { {'{No}','2020Converge'} };
        end
        
        function initExperimentDesign( this  )
            this.trialDuration = this.ExperimentOptions.fixationDuration/1000 ...
                + this.ExperimentOptions.targetDuration/1000 ...
                + this.ExperimentOptions.responseDuration/1000 ; %seconds
            
            % default parameters of any experiment
            this.trialSequence      = 'Random';      % Sequential, Random, Random with repetition, ...
            this.trialAbortAction   = 'Delay';    % Repeat, Delay, Drop
            this.trialsPerSession   = this.ExperimentOptions.TrialsPerTilt*(length(this.ExperimentOptions.Tilts)+1)*2;
            this.trialsBeforeBreak  = this.ExperimentOptions.TrialsPerTilt*(length(this.ExperimentOptions.Tilts)+1);
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence =  1;
            NblocksPerTilt = ceil(this.ExperimentOptions.TrialsPerTilt/10);
            this.blocksToRun = NblocksPerTilt*(length(this.ExperimentOptions.Tilts)+1)*2;
            
              
            this.blocks = [];
            
            if ( strcmp(this.ExperimentOptions.FirstSide,'Left') )
                offset1 = 0;
                offset2 = 30;
            else
                offset1 = 30;
                offset2 = 0;
            end
            
            % initial upright
            block = struct( 'fromCondition', 1, 'toCondition', 10, 'trialsToRun', 10);
            this.blocks = cat(1,this.blocks, repmat(block,NblocksPerTilt,1));
            
            % first side
            for j=1:length(this.ExperimentOptions.Tilts)
                block = struct( 'fromCondition', 1+j*10+offset1, 'toCondition', 10+j*10+offset1, 'trialsToRun', 10);
                this.blocks = cat(1,this.blocks, repmat(block,NblocksPerTilt,1));
            end
            
            % second upright
            block = struct( 'fromCondition', 1, 'toCondition', 10, 'trialsToRun', 10);
            this.blocks = cat(1,this.blocks, repmat(block,NblocksPerTilt,1));
            
            % second side 
            for j=1:length(this.ExperimentOptions.Tilts)
                block = struct( 'fromCondition', 1+j*10+offset2, 'toCondition', 10+j*10+offset2, 'trialsToRun', 10);
                this.blocks = cat(1,this.blocks, repmat(block,NblocksPerTilt,1));
            end
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'AnglePercentRange';
            conditionVars(i).values = ([-100:100/2.5:100-100/5]+100/5);
            
            i = i+1;
            conditionVars(i).name   = 'Position';
            conditionVars(i).values = {'Up' 'Down'};
            
            i = i+1;
            conditionVars(i).name   = 'Tilt';
            conditionVars(i).values = [0 -this.ExperimentOptions.Tilts this.ExperimentOptions.Tilts];
        end
        
        function trialResult = runPreTrial(this, variables )
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            % Change the angle of the bitebar if necessary
            if ( this.ExperimentOptions.UseBiteBarMotor )
                if ( variables.Tilt ~= this.biteBarMotor.CurrentAngle )       
                    result = 'n';
                    while( result ~= 'y' )
                        result = this.Graph.DlgSelect( ...
                            'Continue?', ...
                            { 'y' 'n'}, ...
                            { 'Yes'  'No'} , [],[]);
                    end
                                        
                    [mx, my] = RectCenter(this.Graph.wRect);
                    fixRect = [0 0 10 10];
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    Screen('FillOval', this.Graph.window,  255, fixRect);
                    Screen('Flip', this.Graph.window);
                    
                    if ( this.ExperimentOptions.UseBiteBarMotor)
                        pause(2);
                        if ( this.ExperimentOptions.UseEyeTracker )
                            this.eyeTracker.RecordEvent('Tilt begin');
                        end
                        this.biteBarMotor.SetTiltAngle(variables.Tilt);
                        if ( this.ExperimentOptions.UseEyeTracker )
                            this.eyeTracker.RecordEvent('Tilt end');
                        end
                        disp('30 s pause');
                        result = this.Graph.DlgTimer('Waiting 30s...',30);
                        if ( result < 0 )
                            trialResult =  Enum.trialResult.ABORT;
                            return;
                        end
                
                        if ( this.ExperimentOptions.UseEyeTracker )
                            this.eyeTracker.RecordEvent('Tilt 30 second pause end');
                        end
                        disp('done');
                    end
                end
            end
            
            % adaptive paradigm
            
            if ( ~isempty(this.Session.currentRun.pastTrialTable) )
                correctTrialsTable = this.Session.currentRun.pastTrialTable(this.Session.currentRun.pastTrialTable.TrialResult ==  Enum.trialResult.CORRECT ,:);
                
                idxLastDifferentTilt = find(correctTrialsTable.Tilt ~=variables.Tilt,1,'last');
                if (isempty( idxLastDifferentTilt ) )
                    idxLastDifferentTilt = 0;
                end
                previousTrialsInSameTilt = correctTrialsTable((idxLastDifferentTilt+1):end,:);
                
                this.updateRange(variables, previousTrialsInSameTilt);
            else
                this.updateRange(variables, []);
            end
            
            trialResult =  Enum.trialResult.CORRECT;
        end
    end
                
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        function trialDataSet = PrepareTrialDataSet( this, ds)
            trialDataSet = ds;
        end
        
        function sessionDataTable = PrepareSessionDataTable(this, sessionDataTable)
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
end

