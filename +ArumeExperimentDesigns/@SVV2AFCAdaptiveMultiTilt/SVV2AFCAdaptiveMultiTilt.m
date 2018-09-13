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
            
            if ( rand>0.5)
                dlg.Tilts = [0 -10 -20 -30 0 10 20 30];
            else
                dlg.Tilts = [0 10 20 30 0 -10 -20 -30];
            end
            
            dlg.TrialsPerTilt = {100 '* (trials)' [1 500] };
            
            dlg.Prisms = { {'{No}','2020Converge'} };
        end
        
        function initExperimentDesign( this  )
            this.DisplayVariableSelection = {'TrialNumber' 'TrialResult' 'Range' 'RangeCenter' 'Angle' 'Response' 'ReactionTime' 'NumSlowFlips'};
            
            this.trialDuration = this.ExperimentOptions.fixationDuration/1000 ...
                + this.ExperimentOptions.targetDuration/1000 ...
                + this.ExperimentOptions.responseDuration/1000 ; %seconds
            
            Ntilts = length(this.ExperimentOptions.Tilts);
            NTrialsPerTilt = this.ExperimentOptions.TrialsPerTilt;
            NAnglesInRange = length(this.ConditionVars(1).values)*2;
            NblocksPerTilt = ceil(NTrialsPerTilt/NAnglesInRange);
            
            % default parameters of any experiment
            this.trialSequence      = 'Random';      % Sequential, Random, Random with repetition, ...
            this.trialAbortAction   = 'Delay';    % Repeat, Delay, Drop
            this.trialsPerSession   = NTrialsPerTilt*Ntilts;
            this.trialsBeforeBreak  = NTrialsPerTilt*Ntilts/2;
            
            %%-- Blocking
            
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence =  1;
            this.blocksToRun = NblocksPerTilt*Ntilts;
            
            this.blocks = [];
            for j=1:Ntilts
                block = struct( 'fromCondition', 1+(j-1)*NAnglesInRange, 'toCondition', j*NAnglesInRange, 'trialsToRun', NAnglesInRange);
                this.blocks = cat(1,this.blocks, repmat(block,NblocksPerTilt,1));
                if ( rem(NTrialsPerTilt,NAnglesInRange)>0)
                    this.blocks(end).trialsToRun = rem(NTrialsPerTilt,NAnglesInRange);
                end
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
            conditionVars(i).values = this.ExperimentOptions.Tilts;
        end
        
        function [trialResult,thisTrialData] = runPreTrial(this, thisTrialData )
            
            Enum = ArumeCore.ExperimentDesign.getEnum();
            
            % Change the angle of the bitebar if necessary
            if ( this.ExperimentOptions.UseBiteBarMotor )
                 if (thisTrialData.Tilt ~= this.biteBarMotor.CurrentAngle )       
                    [trialResult, thisTrialData] = this.TiltBiteBar(thisTrialData.Tilt, thisTrialData);
                    if (trialResult ~= 'CORRECT' )
                        return
                    end
                end
            end
            
            % adaptive paradigm
            
            previousTrialsInSameTilt = [];
            if ( ~isempty(this.Session.currentRun.pastTrialTable) )
                correctTrialsTable = this.Session.currentRun.pastTrialTable(this.Session.currentRun.pastTrialTable.TrialResult ==  Enum.trialResult.CORRECT ,:);
                
                idxLastDifferentTilt = find(correctTrialsTable.Tilt ~=thisTrialData.Tilt,1,'last');
                if (isempty( idxLastDifferentTilt ) )
                    idxLastDifferentTilt = 0;
                end
                previousTrialsInSameTilt = correctTrialsTable((idxLastDifferentTilt+1):end,:);
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
            tdata = this.Session.trialDataTable;
            tilts = unique(this.Session.trialDataTable.Tilt);
            for i=1:length(tilts)
                tidx = tdata.Tilt==tilts(i);
                angles = tdata{tidx,'Angle'};
                responses = tdata{tidx,'Response'};
                [SVV, a, p, allAngles, allResponses, trialCounts, SVVth] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, responses);
                
                sessionDataTable{1,['SVV_' strrep(num2str(tilts(i)),'-','N')]} = SVV;
                sessionDataTable{1,['SVVth_' strrep(num2str(tilts(i)),'-','N')]} = SVVth;
                sessionDataTable{1,['Torsion_' strrep(num2str(tilts(i)),'-','N')]} = nanmean(nanmean(tdata{(tidx),{'AverageLeftT' 'AverageRightT'}},2));
                sessionDataTable{1,['Vergence_' strrep(num2str(tilts(i)),'-','N')]} = nanmean(tdata.AverageLeftX(tidx)-tdata.AverageRightX(tidx));
                sessionDataTable{1,['Skew_' strrep(num2str(tilts(i)),'-','N')]} = nanmean(tdata.AverageLeftX(tidx)-tdata.AverageRightX(tidx));
                sessionDataTable{1,['HeadRoll_' strrep(num2str(tilts(i)),'-','N')]} = nanmean(tdata.AverageLeftX(tidx)-tdata.AverageRightX(tidx));
                sessionDataTable{1,['HeadPitch_' strrep(num2str(tilts(i)),'-','N')]} = nanmean(tdata.AverageLeftX(tidx)-tdata.AverageRightX(tidx));
            end
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

