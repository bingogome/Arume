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
            this.DisplayVariableSelection = {'TrialNumber' 'TrialResult' 'Range' 'RangeCenter' 'Angle' 'Response' 'ReactionTime' 'NumSlowFlips'};
            
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
        
        function [trialResult,thisTrialData] = runPreTrial(this, thisTrialData )
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            % Change the angle of the bitebar if necessary
            if ( this.ExperimentOptions.UseBiteBarMotor )
                 if (thisTrialData.Tilt ~= this.biteBarMotor.CurrentAngle )       
                    result = 'n';
                    while( result ~= 'y' )
                        result = this.Graph.DlgSelect( ...
                            sprintf('Bite bar is going to tilt to %d degrees. Continue?',thisTrialData.Tilt), ...
                            { 'y' 'n'}, ...
                            { 'Yes'  'No'} , [],[]);
                        if ( result ~= 'y' )
                            result = this.Graph.DlgSelect( ...
                                'Do you want to interrupt the experiment?', ...
                                { 'y' 'n'}, ...
                                { 'Yes'  'No'} , [],[]);
                            if ( result ~= 'n' )
                                trialResult = Enum.trialResult.QUIT;
                                return;
                            end
                        end
                    end
                                        
                    [mx, my] = RectCenter(this.Graph.wRect);
                    fixRect = [0 0 10 10];
                    fixRect = CenterRectOnPointd( fixRect, mx, my );
                    Screen('FillOval', this.Graph.window,  255, fixRect);
                    Screen('Flip', this.Graph.window);
                    
                    if ( this.ExperimentOptions.UseBiteBarMotor)
                        thisTrialData.TimeStartMotorMove = GetSecs;
                        pause(2);
                        this.biteBarMotor.SetTiltAngle(thisTrialData.Tilt);
                        thisTrialData.TimeEndMotorMove = GetSecs;
                        disp('30 s pause');
                        result = this.Graph.DlgTimer('Waiting 30s...',30);
                        if ( result < 0 )
                            trialResult =  Enum.trialResult.ABORT;
                            return;
                        end
                        thisTrialData.TimeEndMotorMovePause = GetSecs;
                        disp('done with pause');
                    end
                end
            end
            
            % adaptive paradigm
            
            if ( ~isempty(this.Session.currentRun.pastTrialTable) )
                correctTrialsTable = this.Session.currentRun.pastTrialTable(this.Session.currentRun.pastTrialTable.TrialResult ==  Enum.trialResult.CORRECT ,:);
                
                idxLastDifferentTilt = find(correctTrialsTable.Tilt ~=thisTrialData.Tilt,1,'last');
                if (isempty( idxLastDifferentTilt ) )
                    idxLastDifferentTilt = 0;
                end
                previousTrialsInSameTilt = correctTrialsTable((idxLastDifferentTilt+1):end,:);
            else
                previousTrialsInSameTilt = [];
            end
            
            thisTrialData = this.updateRange(thisTrialData, previousTrialsInSameTilt);
            
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
        
        function plotResults = Plot_SVV_SigmoidMultitilt(this)
            
            figure('position',[400 400 1000 400],'color','w','name',this.Session.name)
            ax1 = gca;
            set(ax1,'nextplot','add', 'fontsize',12);
            tilts = unique(this.Session.trialDataTable.Tilt);
            for i=1:length(tilts)
                trialIdx = find(this.Session.trialDataTable.TrialResult=='CORRECT' & this.Session.trialDataTable.Tilt == tilts(i));
                angles = this.GetAngles();
                angles = angles(trialIdx);
                
                responses = this.GetLeftRightResponses();
                responses = responses(trialIdx);
                
                %             angles = angles(101:201);
                %             respones = respones(101:201);
                [SVV, a, p, allAngles, allResponses,trialCounts, SVVth] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, responses);
                
                
                %             ax1=subplot(3,1,[1:2],'nextplot','add', 'fontsize',12);
                
%                 bar(allAngles, trialCounts/sum(trialCounts)*100, 'edgecolor','none','facecolor',[0.8 0.8 0.8])
                
                plot( allAngles, allResponses,'o', 'color', [0.4 0.4 0.4], 'markersize',15,'linewidth',2, 'markerfacecolor', [0.7 0.7 0.7])
                plot(a,p,'linewidth',3);
%                 line([SVV, SVV], [-10 110], 'color','k','linewidth',3,'linestyle','-.');
%                 line([0, 0], [-10 50], 'color','k','linewidth',2,'linestyle','-.');
%                 line([0, SVV], [50 50], 'color','k','linewidth',2,'linestyle','-.');
                
                %xlabel('Angle (deg)', 'fontsize',16);
%                 text(30, 80, sprintf('SVV: %0.2f°',SVV), 'fontsize',16,'HorizontalAlignment','right');
%                 text(30, 60, sprintf('SVV slope: %0.2f°',SVVth), 'fontsize',16,'HorizontalAlignment','right');
                
                set(gca,'xlim',[-30 30],'ylim',[-10 110])
                set(gca,'xgrid','on')
                set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
                set(gca,'ytick',[0:25:100])
                ylabel({'Percent answered' 'tilted right'}, 'fontsize',16);
                xlabel('Angle (deg)', 'fontsize',16);
            end
        end
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
    end
end

