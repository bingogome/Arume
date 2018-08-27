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
             
            dlg = GetOptionsDialog@ArumeExperimentDesigns.SVV2AFCAdaptive(this);
            
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
                previousTrialsInSameTilt = correctTrialsTable((idxLastDifferentTilt+1):end);
                
                this.updateRange(variables, previousTrialsInSameTilt.Angle, previousTrialsInSameTilt.Response);
            else
                this.updateRange(variables, [], []);
            end
            
            trialResult =  Enum.trialResult.CORRECT;
        end
        
        function trialResult = runTrial( this, variables )
                        
            try
                this.lastResponse = -1;
                this.reactionTime = -1;
                
                Enum = ArumeCore.ExperimentDesign.getEnum();
                
                graph = this.Graph;
                
                trialResult = Enum.trialResult.CORRECT;
                
                
                %-- add here the trial code
                Screen('FillRect', graph.window, 0);
                lastFlipTime        = Screen('Flip', graph.window);
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

                    t1 = this.ExperimentOptions.fixationDuration/1000;
                    t2 = this.ExperimentOptions.fixationDuration/1000 +this.ExperimentOptions.targetDuration/1000;
                    
%                     if ( secondsElapsed > t1 && secondsElapsed < t2 )
                    if ( secondsElapsed > t1)
                        %-- Draw target
                        
                        this.DrawLine(variables);
                    end
                    
%                     if (secondsElapsed < t2)
%                         % black patch to block part of the line
                        
                        fixRect = [0 0 10 10];
                        fixRect = CenterRectOnPointd( fixRect, mx, my );
                        Screen('FillOval', graph.window,  this.targetColor, fixRect);
%                     end
                    % -----------------------------------------------------------------
                    % --- END Drawing of stimulus -------------------------------------
                    % -----------------------------------------------------------------
                    
                    
                % -----------------------------------------------------------------
                % DEBUG
                % -----------------------------------------------------------------
                if (0)
                    % TODO: it would be nice to have some call back system here
                    Screen('DrawText', graph.window, sprintf('%i seconds remaining...', round(secondsRemaining)), 20, 50, graph.white);
                    currentline = 50 + 25;
                    vNames = fieldnames(variables);
                    for iVar = 1:length(vNames)
                        if ( ischar(variables.(vNames{iVar})) )
                            s = sprintf( '%s = %s',vNames{iVar},variables.(vNames{iVar}) );
                        else
                            s = sprintf( '%s = %s',vNames{iVar},num2str(variables.(vNames{iVar})) );
                        end
                        Screen('DrawText', graph.window, s, 20, currentline, graph.white);
                        
                        currentline = currentline + 25;
                    end
                end
                % -----------------------------------------------------------------
                % END DEBUG
                % -----------------------------------------------------------------
                
                    
                    % -----------------------------------------------------------------
                    % -- Flip buffers to refresh screen -------------------------------
                    % -----------------------------------------------------------------
                    this.Graph.Flip();
                    % -----------------------------------------------------------------
                    
                    
                    % -----------------------------------------------------------------
                    % --- Collecting responses  ---------------------------------------
                    % -----------------------------------------------------------------
                    
                    if ( secondsElapsed > max(t1,0.200)  )
                        reverse = isequal(variables.Position,'Down');
                        response = this.CollectLeftRightResponse(reverse);
                        if ( ~isempty( response) )
                            this.lastResponse = response;
                        end
                    end
                    
                    if ( this.lastResponse >= 0 )
                        this.reactionTime = secondsElapsed-1;
                        disp(num2str(this.lastResponse));
                        break;
                    end
                    
                    % -----------------------------------------------------------------
                    % --- END Collecting responses  -----------------------------------
                    % -----------------------------------------------------------------
                    
                end
            catch ex
                if ( ~isempty( this.eyeTracker ) )
                    this.eyeTracker.StopRecording();
                end
                
                rethrow(ex)
            end
            
            
            if ( this.lastResponse < 0)
                trialResult =  Enum.trialResult.ABORT;
            end
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

