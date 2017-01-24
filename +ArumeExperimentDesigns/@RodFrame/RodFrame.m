classdef RodFrame < ArumeCore.ExperimentDesign
    %SVVdotsAdaptFixed Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        eyeTracker = [];
        
        lastResponse = '';
        reactionTime = '';
        
        fixColor = [255 0 0];
        
        targetColor = [255 0 0];
        
        currentAngle = 0;
        currentCenterRange = 0;
        currentRange = 180;
    end
    
    % ---------------------------------------------------------------------
    % Options to set at runtime
    % ---------------------------------------------------------------------
    methods ( Static = true )
        function dlg = GetOptionsStructDlg( this )
            dlg.UseLine = { {'{0}','1'} };
            dlg.FrameAngle ={ 20 '* (deg)' [-90 90] };
            dlg.FixationDiameter = { 12.5 '* (pix)' [3 50] };
            dlg.TargetDiameter = { 12.5 '* (pix)' [3 50] };
            dlg.targetDistance = { 125 '* (pix)' [10 500] };
            dlg.fixationDuration = { 1000 '* (ms)' [100 3000] };
            dlg.targetDuration = { 300 '* (ms)' [100 30000] };
            dlg.responseDuration = { 1500 '* (ms)' [100 3000] };
        end
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
            this.trialsPerSession   = 170;
            
            %%-- Blocking
            this.blockSequence = 'Sequential';	% Sequential, Random, Random with repetition, ...
            this.numberOfTimesRepeatBlockSequence = 5;
            this.blocksToRun = 1;
            this.blocks = [ struct( 'fromCondition', 1, 'toCondition', 17, 'trialsToRun', 17) ];
        end
        
        function initBeforeRunning( this )
        end
        
        function [conditionVars] = getConditionVariables( this )
            %-- condition variables ---------------------------------------
            i= 0;
            
            i = i+1;
            conditionVars(i).name   = 'Angle';
            conditionVars(i).values = [-16:2:16];
        end
        
        function trialResult = runPreTrial(this, variables )
            Enum = ArumeCore.ExperimentDesign.getEnum();
            % Add stuff here
            
            this.currentAngle = variables.Angle;
            
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
                    
                    if (secondsElapsed < t2)
                        %-- Draw fixation spot
                        fixRect = [0 0 this.ExperimentOptions.FixationDiameter this.ExperimentOptions.FixationDiameter];
                        fixRect = CenterRectOnPointd( fixRect, mx, my );
                        Screen('FillOval', graph.window, this.fixColor, fixRect);
                        
                        
                        drawFrame(graph, 20, [255 0 0]);
                    end
                    
                    if ( secondsElapsed > t1 && secondsElapsed < t2 )
                        
                        fromH = mx - this.ExperimentOptions.targetDistance*sin(this.currentAngle/180*pi);
                        fromV = my + this.ExperimentOptions.targetDistance*cos(this.currentAngle/180*pi);
                        toH = mx + this.ExperimentOptions.targetDistance*sin(this.currentAngle/180*pi);
                        toV = my - this.ExperimentOptions.targetDistance*cos(this.currentAngle/180*pi);
                        
                        Screen('DrawLine', graph.window, this.targetColor, fromH, fromV, toH, toV, 4);
                    end
                    
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
                    
                    if ( secondsElapsed > t1  )
                        
                            [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                            if ( keyIsDown )
                                keys = find(keyCode);
                                for i=1:length(keys)
                                    KbName(keys(i))
                                    switch(KbName(keys(i)))
                                        case 'RightArrow'
                                            this.lastResponse = 1;
                                        case 'LeftArrow'
                                            this.lastResponse = 0;
                                    end
                                end
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
                %  this.eyeTracker.StopRecording();
                rethrow(ex)
            end
            
            
            if ( this.lastResponse < 0)
                trialResult =  Enum.trialResult.ABORT;
            end
            
            % this.eyeTracker.StopRecording();
            
        end
        
        function trialOutput = runPostTrial(this)
            trialOutput = [];
            trialOutput.Response = this.lastResponse;
            trialOutput.ReactionTime = this.reactionTime;
            trialOutput.Angle = this.currentAngle;
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
      function plotResults = Plot_ExperimentTimeCourse(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];
            NtrialPerBlock = 10;
%             figure
%             set(gca,'nextplot','add')
%             colors = jet(length(ds)/NtrialPerBlock);
            
            Nblocks = ceil(length(ds)/NtrialPerBlock/2)*2;
            
%             for i=NtrialPerBlock:NtrialPerBlock:length(ds)
%                 nplot = ceil(i/NtrialPerBlock);
%                 subplot(ceil(length(colors)/2),2,mod(((nplot*2)-1+floor((nplot-1)/(Nblocks/2)))-1,Nblocks)+1,'nextplot','add')
%                 modelspec = 'Response ~ Angle';
%                 subds = ds(1:i,:);
%                 subds((subds.Response==1 & subds.Angle<-50) | (subds.Response==0 & subds.Angle>50),:) = [];
%                 
%                 [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
%                 
%                 plot(a,p, 'color', colors(nplot,:),'linewidth',2);
%                 xlabel('Angle (deg)');
%                 ylabel('Percent answered right');
%                 
%                 [svvr svvidx] = min(abs( p-50));
%                 line([a(svvidx),a(svvidx)], [0 100], 'color', colors(nplot,:),'linewidth',2);
%                 set(gca,'xlim',[-20 20])
%                 
%                 allAngles = -90:90;
%                 allResponses = nan(size(allAngles));
%                 for ia=1:length(allAngles)
%                     allResponses(ia) = mean(responses(angles==allAngles(ia))*100);
%                 end
%                 
%                 plot( allAngles,allResponses,'o')
%                 text(3, 40, sprintf('SVV: %0.2f',a(svvidx)));
%             end
            
            figure('position',[400 200 700 400],'color','w','name',this.Session.name)
            axes('nextplot','add');
            plot(ds(ds.Response==0 & strcmp(ds.Position,'Up'),'TrialNumber'), ds(ds.Response==0 & strcmp(ds.Position,'Up'),'Angle'),'^','MarkerEdgeColor',[0.3 0.3 0.3],'linewidth',2);
            plot(ds(ds.Response==1 & strcmp(ds.Position,'Up'),'TrialNumber'), ds(ds.Response==1 & strcmp(ds.Position,'Up'),'Angle'),'^','MarkerEdgeColor','r','linewidth',2);
            plot(ds(ds.Response==0 & strcmp(ds.Position,'Down'),'TrialNumber'), ds(ds.Response==0 & strcmp(ds.Position,'Down'),'Angle'),'v','MarkerEdgeColor',[0.3 0.3 0.3],'linewidth',2);
            plot(ds(ds.Response==1 & strcmp(ds.Position,'Down'),'TrialNumber'), ds(ds.Response==1 & strcmp(ds.Position,'Down'),'Angle'),'v','MarkerEdgeColor','r','linewidth',2);
            
            legend({'Answered tilted to the right', 'Answered tilted to the left'},'fontsize',16)
            legend('boxoff')
            set(gca,'xlim',[-3 103],'ylim',[-90 90])
            ylabel('Angle (deg)', 'fontsize',16);
            xlabel('Trial number', 'fontsize',16);
            set(gca,'ygrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
      end
        
      function plotResults = Plot_Sigmoid(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataSet;
            ds(ds.TrialResult>0,:) = [];
            ds(ds.Response<0,:) = [];

            subds = ds(:,:);
            
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
            
                
           
            figure('position',[400 400 1000 400],'color','w','name',this.Session.name)
            subplot(1,1,1,'nextplot','add', 'fontsize',12);
            
            plot( allAngles, allResponses,'o', 'color', [0.7 0.7 0.7], 'markersize',10,'linewidth',2)
            plot(a,p, 'color', 'k','linewidth',2);
            line([SVV, SVV], [0 100], 'color','k','linewidth',2);
            
               
            
            
            %xlabel('Angle (deg)', 'fontsize',16);
            ylabel({'Percent answered' 'tilted right'}, 'fontsize',16);
            text(20, 80, sprintf('SVV: %0.2f°',SVV), 'fontsize',16);
            
            set(gca,'xlim',[-30 30],'ylim',[-10 110])
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca,'xticklabel',[])
            
            
      end
    
        
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
        
        function [SVV, a, p, allAngles, allResponses, trialCounts] = FitAngleResponses( angles, responses)
            ds = dataset;
            ds.Response = responses;
            ds.Angle = angles;

            outliers = find((ds.Response==0 & ds.Angle<-50) | (ds.Response==1 & ds.Angle>50));

            ds(outliers,:) = [];

            modelspec = 'Response ~ Angle';
            mdl = fitglm(ds(:,{'Response', 'Angle'}), modelspec, 'Distribution', 'binomial');

            ds(mdl.Diagnostics.CooksDistance>0.3,:) = [];
            modelspec = 'Response ~ Angle';
            mdl = fitglm(ds(:,{'Response', 'Angle'}), modelspec, 'Distribution', 'binomial');

            angles = ds.Angle;
            responses = ds.Response;

            a = min(angles):0.1:max(angles);
            p = predict(mdl,a')*100;

            [svvr svvidx] = min(abs( p-50));

            SVV = a(svvidx);
            
            allAngles = -90:90;
            allResponses = nan(size(allAngles));
            trialCounts = nan(size(allAngles));
            for ia=1:length(allAngles)
                allResponses(ia) = mean(responses(angles==allAngles(ia))*100);
                trialCounts(ia) = sum(angles==allAngles(ia));
            end
            
        end
    end
end

function drawFrame( graph, angle, color)

lineLength = 250;
[mx, my] = RectCenter(graph.wRect);

centerLeft = mx;

width = 10;

fromH = +cos(angle/180*pi)*lineLength+centerLeft - lineLength*sin(angle/180*pi);
fromV = sin(angle/180*pi)*lineLength+my + lineLength*cos(angle/180*pi);
toH = +cos(angle/180*pi)*lineLength+centerLeft+ lineLength*sin(angle/180*pi);
toV = sin(angle/180*pi)*lineLength+my - lineLength*cos(angle/180*pi);
Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, width);

fromH = -cos(angle/180*pi)*lineLength+centerLeft - lineLength*sin(angle/180*pi);
fromV = -sin(angle/180*pi)*lineLength+my + lineLength*cos(angle/180*pi);
toH = -cos(angle/180*pi)*lineLength+centerLeft+ lineLength*sin(angle/180*pi);
toV = -sin(angle/180*pi)*lineLength+my - lineLength*cos(angle/180*pi);
Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, width);


fromH = +cos(angle/180*pi)*lineLength+centerLeft - lineLength*sin(angle/180*pi);
fromV = sin(angle/180*pi)*lineLength+my + lineLength*cos(angle/180*pi);
toH = -cos(angle/180*pi)*lineLength+centerLeft - lineLength*sin(angle/180*pi);
toV = -sin(angle/180*pi)*lineLength+my + lineLength*cos(angle/180*pi);
Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, width);

fromH = +cos(angle/180*pi)*lineLength+centerLeft+ lineLength*sin(angle/180*pi);
fromV = sin(angle/180*pi)*lineLength+my - lineLength*cos(angle/180*pi);
toH = -cos(angle/180*pi)*lineLength+centerLeft+ lineLength*sin(angle/180*pi);
toV = -sin(angle/180*pi)*lineLength+my - lineLength*cos(angle/180*pi);
Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, width);

lineLength = 150;

fromH = +cos(angle/180*pi)*lineLength+centerLeft - lineLength*sin(angle/180*pi);
fromV = sin(angle/180*pi)*lineLength+my + lineLength*cos(angle/180*pi);
toH = +cos(angle/180*pi)*lineLength+centerLeft+ lineLength*sin(angle/180*pi);
toV = sin(angle/180*pi)*lineLength+my - lineLength*cos(angle/180*pi);
Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, width);

fromH = -cos(angle/180*pi)*lineLength+centerLeft - lineLength*sin(angle/180*pi);
fromV = -sin(angle/180*pi)*lineLength+my + lineLength*cos(angle/180*pi);
toH = -cos(angle/180*pi)*lineLength+centerLeft+ lineLength*sin(angle/180*pi);
toV = -sin(angle/180*pi)*lineLength+my - lineLength*cos(angle/180*pi);
Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, width);


fromH = +cos(angle/180*pi)*lineLength+centerLeft - lineLength*sin(angle/180*pi);
fromV = sin(angle/180*pi)*lineLength+my + lineLength*cos(angle/180*pi);
toH = -cos(angle/180*pi)*lineLength+centerLeft - lineLength*sin(angle/180*pi);
toV = -sin(angle/180*pi)*lineLength+my + lineLength*cos(angle/180*pi);
Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, width);

fromH = +cos(angle/180*pi)*lineLength+centerLeft+ lineLength*sin(angle/180*pi);
fromV = sin(angle/180*pi)*lineLength+my - lineLength*cos(angle/180*pi);
toH = -cos(angle/180*pi)*lineLength+centerLeft+ lineLength*sin(angle/180*pi);
toV = -sin(angle/180*pi)*lineLength+my - lineLength*cos(angle/180*pi);
Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, width);


end
