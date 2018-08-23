classdef SVV2AFC < ArumeCore.ExperimentDesign & ArumeExperimentDesigns.EyeTracking
    %SVV2AFC Parent experiment design for designs of SVV experiments
    % using 2AFC two alternative forced choice task
    % all the experiments will have a variable called angle which is the
    % angle tested relative to true vertical and a response variable that
    % can 'R' or 'L'.
    
    properties
        gamePad = [];
        biteBarMotor = [];
        
        lastResponse = '';
        reactionTime = '';
        
        fixColor = [255 0 0];
        
        targetColor = [255 0 0];
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
        function dlg = GetOptionsDialog( this, importing)
            
            dlg = GetOptionsDialog@ArumeExperimentDesigns.EyeTracking(this);
            
            dlg.UseGamePad = { {'0','{1}'} };
            dlg.UseMouse = { {'{0}','1'} };
            
            
            dlg.Type_of_line = { {'{Radius}','Diameter'} };
            dlg.Length_of_line = 300;
            dlg.FixationDiameter = { 12.5 '* (pix)' [3 50] };
            
            dlg.TargetDiameter = { 12.5 '* (pix)' [3 50] };
            dlg.targetDistance = { 125 '* (pix)' [10 500] };
            
            dlg.fixationDuration = { 1000 '* (ms)' [1 3000] };
            dlg.targetDuration = { 300 '* (ms)' [100 30000] };
            dlg.responseDuration = { 1500 '* (ms)' [100 3000] };
            
            dlg.UseBiteBarMotor = { {'0','{1}'} };
            dlg.HeadAngle = { 0 '* (deg)' [-40 40] };
            dlg.TiltHeadAtBegining = { {'0','{1}'} };
            
            dlg.offset = {0 '* (deg)' [-20 20] };
        end
        
        function initBeforeRunning( this )
            
            % Initialize eyetracker
            initBeforeRunning@ArumeExperimentDesigns.EyeTracking(this);
            
            % Initialize gamepad
            if ( this.ExperimentOptions.UseGamePad )
                
                this.gamePad = ArumeHardware.GamePad();
                
            end
            
            % Initialize bitebar
            if ( this.ExperimentOptions.UseBiteBarMotor)
                clear this.biteBarMotor;
                this.biteBarMotor = ArumeHardware.BiteBarMotor();
                
                if (isfield(this.ExperimentOptions, 'TiltHeadAtBegining') && this.ExperimentOptions.TiltHeadAtBegining )
                    if ( isempty(this.Session.currentRun.pastConditions) )
                        this.biteBarMotor.SetTiltAngle(this.ExperimentOptions.HeadAngle);
                        pause(2);
                        disp('30 s pause');
                        pause(30);
                        disp('done');
                    end
                end
            end
            
            if ( 0) % this was for the EEG experiment to output something with the parallel port
                %initialize the inpoutx64 low-level I/O driver
                config_io;
                %optional step: verify that the inpoutx64 driver was successfully installed
                global cogent;
                if( cogent.io.status ~= 0 )
                    error('inp/outp installation failed');
                end
            end
            
        end
        
        function cleanAfterRunning(this)
            
            % Close eyetracker
            cleanAfterRunning@ArumeExperimentDesigns.EyeTracking(this);
            
            % close gamepad
            if ( this.ExperimentOptions.UseGamePad )
            end
                        
            % Close bitebar
            if ( this.ExperimentOptions.UseBiteBarMotor ~= 0 )
                if ( ~isempty(this.biteBarMotor))
                    % this.biteBarMotor.SetTiltAngle(0);
                    this.biteBarMotor.Close();
                end
            end
        end
        
        function response = CollectLeftRightResponse(this, reverse)
            response = [];
            
            if ( this.ExperimentOptions.UseMouse )
                [x,y,buttons] = GetMouse();
%                 if any(buttons) %wait for release
%                     if (buttons(1) ==1 && buttons(3)==1)
%                         disp('both buttons pressed');
%                     end
                    if any(buttons) % wait for release
                        if buttons(1) == 1
                            response = 'L';
                        elseif  buttons(3) == 1
                            response = 'R';
                        end
                    end
                elseif ( this.ExperimentOptions.UseGamePad )
                [d, l, r] = this.gamePad.Query();
                if ( l == 1)
                    response = 'L';
                elseif( r == 1)
                    response = 'R';
                end
            else
                [keyIsDown, secs, keyCode, deltaSecs] = KbCheck();
                if ( keyIsDown )
                    keys = find(keyCode);
                    for i=1:length(keys)
                        KbName(keys(i));
                        switch(KbName(keys(i)))
                            case 'RightArrow'
                                response = 'R';
                            case 'LeftArrow'
                                response = 'L';
                        end
                    end
                end
            end
            
            % only reverse (for bottom trials) if the line is a radius
            % not if it is a diameter
            switch(this.ExperimentOptions.Type_of_line)
                case 'Radius'
                    if ( ~isempty( response) )
                        if ( reverse )
                            switch(response)
                                case 'L'
                                    response = 'R';
                                case 'R'
                                    response = 'L';
                            end
                        end
                    end
                case 'Diameter'
            end
        end
        
        function DrawLine(this,variables)
            
            switch(this.ExperimentOptions.Type_of_line)
                case 'Radius'
                    lineLength = this.ExperimentOptions.Length_of_line;
                    [mx, my] = RectCenter(this.Graph.wRect);
                    
                    switch(variables.Position)
                        case 'Up'
                            fromH = mx;
                            fromV = my;
                            toH = mx + lineLength*sin(this.currentAngle/180*pi);
                            toV = my - lineLength*cos(this.currentAngle/180*pi);
                        case 'Down'
                            fromH = mx;
                            fromV = my;
                            toH = mx - lineLength*sin(this.currentAngle/180*pi);
                            toV = my + lineLength*cos(this.currentAngle/180*pi);
                    end
                    
                    Screen('DrawLine', this.Graph.window, this.targetColor, fromH, fromV, toH, toV, 4);
                case 'Diameter'
                    lineLength = this.ExperimentOptions.Length_of_line;
                    [mx, my] = RectCenter(this.Graph.wRect);
                    
                    fromH = mx - lineLength*sin(this.currentAngle/180*pi);
                    fromV = my + lineLength*cos(this.currentAngle/180*pi);
                    toH = mx + lineLength*sin(this.currentAngle/180*pi);
                    toV = my - lineLength*cos(this.currentAngle/180*pi);
                    
                    Screen('DrawLine', this.Graph.window, this.targetColor, fromH, fromV, toH, toV, 4);
            end
        end
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function trialDataTable = PrepareTrialDataTable( this, ds)
            % Every class inheriting from SVV2AFC should override this
            % method and add the proper PresentedAngle and
            % LeftRightResponse variables
            
            trialDataTable = this.PrepareTrialDataTable@ArumeCore.ExperimentDesign(ds);
            
            trialDataTable.PresentedAngle = trialDataTable.Angle;
            trialDataTable.LeftRightResponse = trialDataTable.Response;
        end
        
        function sessionDataTable = PrepareSessionDataTable(this, sessionDataTable)
            
            
            angles = this.GetAngles();
            angles(this.Session.trialDataTable.TrialResult>0) = [];
            
            respones = this.GetLeftRightResponses();
            respones(this.Session.trialDataTable.TrialResult>0) = [];
            
%             angles = angles(101:201);
%             respones = respones(101:201);
            [SVV, a, p, allAngles, allResponses,trialCounts, SVVth] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, respones);
            
            
            data = sessionDataTable;
            if ( contains(this.Session.sessionCode,'LED') )
                data.TiltSide = 'LeftTilt';
            elseif (contains(this.Session.sessionCode,'RED'))
                data.TiltSide = 'RightTilt';
            elseif (contains(this.Session.sessionCode,'Upright'))
                data.TiltSide = 'Upright';
            end
            data.TiltSide =categorical(cellstr(data.TiltSide));
            
            data.SVV = SVV;
            data.SVVth = SVVth;
            
            sessionDataTable = data;
        end
        
        % Function that gets the angles of each trial with 0 meaning
        % upright, positive tilted CW and negative CCW.
        function angles = GetAngles( this )
            angles = this.Session.trialDataTable.Angle;
        end
        
        % Function that gets the left and right responses with 1 meaning
        % right and 0 meaning left.
        function responses = GetLeftRightResponses( this )
            responses = this.Session.trialDataTable.Response;
        end
        
    end
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        function plotResults = Plot_Sigmoid(this)
            
            angles = this.GetAngles();
            angles(this.Session.trialDataTable.TrialResult>0) = [];
            
            respones = this.GetLeftRightResponses();
            respones(this.Session.trialDataTable.TrialResult>0) = [];
            
%             angles = angles(101:201);
%             respones = respones(101:201);
            [SVV, a, p, allAngles, allResponses,trialCounts, SVVth] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, respones);
            
            
            figure('position',[400 400 1000 400],'color','w','name',this.Session.name)
%             ax1=subplot(3,1,[1:2],'nextplot','add', 'fontsize',12);
            ax1 = gca;
            set(ax1,'nextplot','add', 'fontsize',12);
            
             bar(allAngles, trialCounts/sum(trialCounts)*100, 'edgecolor','none','facecolor',[0.8 0.8 0.8])
            
            plot( allAngles, allResponses,'o', 'color', [0.4 0.4 0.4], 'markersize',15,'linewidth',2, 'markerfacecolor', [0.7 0.7 0.7])
            plot(a,p, 'color', 'k','linewidth',3);
            line([SVV, SVV], [-10 110], 'color','k','linewidth',3,'linestyle','-.');
            line([0, 0], [-10 50], 'color','k','linewidth',2,'linestyle','-.');
            line([0, SVV], [50 50], 'color','k','linewidth',2,'linestyle','-.');
            
            %xlabel('Angle (deg)', 'fontsize',16);
            text(30, 80, sprintf('SVV: %0.2f°',SVV), 'fontsize',16,'HorizontalAlignment','right');
            text(30, 60, sprintf('SVV slope: %0.2f°',SVVth), 'fontsize',16,'HorizontalAlignment','right');
            
            set(gca,'xlim',[-30 30],'ylim',[-10 110])
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca,'ytick',[0:25:100])
            ylabel({'Percent answered' 'tilted right'}, 'fontsize',16);
            xlabel('Angle (deg)', 'fontsize',16);
        end
        
        function plotResults = Plot_Sigmoid_Tilt_Aftereffect(this)
            angles = this.GetAngles();
            
            dangles = diff(angles);
            
            angles = angles(2:end);
            angles1 = angles(dangles>0);
            angles2 = angles(dangles<0);
            
            respones = this.GetLeftRightResponses();
            respones = respones(2:end);
            respones1 = respones(dangles>0);
            respones2 = respones(dangles<0);
            
            
            figure('position',[400 400 1000 400],'color','w','name',this.Session.name)
            ax1=axes('nextplot','add', 'fontsize',12);
            
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles1, respones1);
            plot( allAngles, allResponses,'o', 'color', [1 0 0], 'markersize',10,'linewidth',2,'markerfacecolor',[1 0.7 0.7])
            plot(a,p, 'color', [1 0 0],'linewidth',2);
            line([SVV, SVV], [0 100], 'color',[1 0 0],'linewidth',2);
            
            %xlabel('Angle (deg)', 'fontsize',16);
            ylabel({'Percent answered' 'tilted right'}, 'fontsize',16);
            text(30, 80, sprintf('SVV: %0.2f°',SVV), 'fontsize',16,'HorizontalAlignment','right');
            
            set(gca,'xlim',[-30 30],'ylim',[-10 110])
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca,'xticklabel',[])
            
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles2, respones2);
            plot( allAngles, allResponses,'o', 'color', [0 0 1], 'markersize',10,'linewidth',2,'markerfacecolor',[0.7 0.7 1])
            plot(a,p, 'color', [0 0 1],'linewidth',2);
            line([SVV, SVV], [0 100], 'color',[0 0 1],'linewidth',2);
            
            %xlabel('Angle (deg)', 'fontsize',16);
            ylabel({'Percent answered' 'tilted right'}, 'fontsize',16);
            text(30, 60, sprintf('SVV: %0.2f°',SVV), 'fontsize',16,'HorizontalAlignment','right');
            
            set(gca,'xlim',[-30 30],'ylim',[-10 110])
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca,'xticklabel',[])
            
        end
        
        function plotResults = Plot_SigmoidUpDown(this)
            analysisResults = 0;
            
            ds = this.Session.trialDataTable;
            ds(ds.TrialResult>0,:) = [];
            
            figure('position',[400 100 1000 600],'color','w','name',this.Session.name)
            
            subds = ds(strcmp(ds.Position,'Up'),:);
            subds((subds.Response==0 & subds.Angle<-50) | (subds.Response==1 & subds.Angle>50),:) = [];
            
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
            
            set(gca,'nextplot','add', 'fontsize',12);
            
            plot( allAngles, allResponses,'^', 'color', [0.7 0.7 0.7], 'markersize',10,'linewidth',2)
            plot(a,p, 'color', 'k','linewidth',2);
            line([SVV,SVV], [0 100], 'color','k','linewidth',2);
            plot(SVV, 0,'^', 'markersize',10, 'markerfacecolor','k', 'color','k','linewidth',2);
            
            
            text(30, 80, sprintf('SVV UP: %0.2f°',SVV), 'fontsize',16,'HorizontalAlignment','right');
                      
            
            subds = ds(strcmp(ds.Position,'Down'),:);
            subds((subds.Response==0 & subds.Angle<-50) | (subds.Response==1 & subds.Angle>50),:) = [];
            
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( subds.Angle, subds.Response);
            
            plot( allAngles, allResponses,'v', 'color', [0.7 0.7 0.7], 'markersize',10,'linewidth',2)
            plot(a,p, 'color', 'k','linewidth',2);
            line([SVV, SVV], [0 100], 'color','k','linewidth',2);
            plot(SVV, 100,'v', 'markersize',10, 'markerfacecolor','k', 'color','k','linewidth',2);
            
            text(30, 60, sprintf('SVV DOWN: %0.2f°',SVV), 'fontsize',16,'HorizontalAlignment','right');
            
            
            xlabel('Angle (deg)', 'fontsize',16);
            ylabel({'Percent answered' 'tilted right'}, 'fontsize',16);
            
            set(gca,'xlim',[-30 30],'ylim',[-10 110])
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
        end 
    end
    
    % ---------------------------------------------------------------------
    % Utility methods
    % ---------------------------------------------------------------------
    methods ( Static = true )
        function [SVV, a, p, allAngles, allResponses, trialCounts, SVVth] = FitAngleResponses( angles, responses)
            
            % add values in the extremes to "support" the logistic fit
            
            if ( iscell(responses) )
                % fix for new tables. Usually responses will come as a cell
                responses = cell2mat(responses);
            end
            
            ds = dataset;
            if ( max(responses)>10)
                n = length(angles);
                angles(end+1) = -40;
                angles(end+1) = 40;
                angles(end+1) = -40;
                angles(end+1) = 40;
                
                responses(end+1) = 'L';
                responses(end+1) = 'R';
                responses(end+1) = 'L';
                responses(end+1) = 'R';
                ds.Response = responses=='R';
            else
                angles(end+1) = -40;
                angles(end+1) = 40;
                angles(end+1) = -40;
                angles(end+1) = 40;

                responses(end+1) = 0;
                responses(end+1) = 1;
                responses(end+1) = 0;
                responses(end+1) = 1;
                ds.Response = responses;
            end
            ds.Angle = angles;
            
            outliers = find((ds.Response==1 & ds.Angle<-50) | (ds.Response==0 & ds.Angle>50));

            ds(outliers,:) = [];
            
            %             if ( length(ds.Responses) > 20 )
            modelspec = 'Response ~ Angle';
            
            orig_state = warning;
            warning('off','stats:glmfit:PerfectSeparation')
            warning('off','stats:glmfit:IterationLimit')
            mdl = fitglm(ds(:,{'Response', 'Angle'}), modelspec, 'Distribution', 'binomial');
            warning(orig_state);
            %             ds(mdl.Diagnostics.CooksDistance > 400/length(mdl.Diagnostics.CooksDistance),:) = [];
            %             end
            
            if ( sum(ds.Response==0) == 0 || sum(ds.Response==1) == 0)
                if ( sum(ds.Response==0) == 0 )
                    ds.Response(end+1) = 0;
                    ds.Angle(end) = max(ds.Angle(1:end-1))+1;
                end
                
                if ( sum(ds.Response==1) == 0 )
                    ds.Response(end+1) = 1;
                    ds.Angle(end) = min(ds.Angle(1:end-1))-1;
                end
                
                
                modelspec = 'Response ~ Angle';
                mdl = fitglm(ds(:,{'Response', 'Angle'}), modelspec, 'Distribution', 'binomial');
            end
            
            angles = ds.Angle;
            responses = ds.Response;
            
            a = -90:0.1:90;
            p = predict(mdl,a')*100;
            
            [svvr svvidx] = min(abs( p-50));
            
            SVV = a(svvidx);
            
            [svvr2 svvidx2] = min(abs( p-75));
            SVVth = a(svvidx2)-SVV;
            
            allAngles = -90:2:90;
            angles = 2*round(angles/2);
            allResponses = nan(size(allAngles));
            trialCounts = nan(size(allAngles));
            for ia=1:length(allAngles)
                allResponses(ia) = mean(responses(angles==allAngles(ia))*100);
                trialCounts(ia) = sum(angles==allAngles(ia));
            end
            
        end
        
        function drawFrame( graph, angle, color)
            
            lineLength = 350;
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
            
%             fromH = +cos(angle/180*pi)*lineLength+centerLeft - lineLength*sin(angle/180*pi);
%             fromV = sin(angle/180*pi)*lineLength+my + lineLength*cos(angle/180*pi);
%             toH = +cos(angle/180*pi)*lineLength+centerLeft+ lineLength*sin(angle/180*pi);
%             toV = sin(angle/180*pi)*lineLength+my - lineLength*cos(angle/180*pi);
%             Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, width);
%             
%             fromH = -cos(angle/180*pi)*lineLength+centerLeft - lineLength*sin(angle/180*pi);
%             fromV = -sin(angle/180*pi)*lineLength+my + lineLength*cos(angle/180*pi);
%             toH = -cos(angle/180*pi)*lineLength+centerLeft+ lineLength*sin(angle/180*pi);
%             toV = -sin(angle/180*pi)*lineLength+my - lineLength*cos(angle/180*pi);
%             Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, width);
%             
%             
%             fromH = +cos(angle/180*pi)*lineLength+centerLeft - lineLength*sin(angle/180*pi);
%             fromV = sin(angle/180*pi)*lineLength+my + lineLength*cos(angle/180*pi);
%             toH = -cos(angle/180*pi)*lineLength+centerLeft - lineLength*sin(angle/180*pi);
%             toV = -sin(angle/180*pi)*lineLength+my + lineLength*cos(angle/180*pi);
%             Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, width);
%             
%             fromH = +cos(angle/180*pi)*lineLength+centerLeft+ lineLength*sin(angle/180*pi);
%             fromV = sin(angle/180*pi)*lineLength+my - lineLength*cos(angle/180*pi);
%             toH = -cos(angle/180*pi)*lineLength+centerLeft+ lineLength*sin(angle/180*pi);
%             toV = -sin(angle/180*pi)*lineLength+my - lineLength*cos(angle/180*pi);
%             Screen('DrawLine', graph.window, color, fromH, fromV, toH, toV, width);
            
            
        end
    end
end

