classdef MVSAlexander < ArumeExperimentDesigns.MVS
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        %        function [samplesDataTable, rawDataTable] = PrepareSamplesDataTable(this)
        %             samplesDataTable= [];
        %             rawDataTable = [];
        %         end
        %         function trialDataTable = PrepareTrialDataTable( this, trialDataTable)
        %         end
        %         function [analysisResults, samplesDataTable, trialDataTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable)
        %         end
        %         function sessionDataTable = PrepareSessionDataTable(this, sessionDataTable)
        %         end
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        % ---------------------------------------------------------------------
        % Plot methods
        % ---------------------------------------------------------------------
        
        function Plot_MVSAlex_PlotSPV(this)
            
            %%
            t = this.Session.analysisResults.SPV.Time;
            pos = (this.Session.analysisResults.SPV.LeftXPos+this.Session.analysisResults.SPV.RightXPos)/2;
            pos = pos-nanmedian(pos);
            v = (this.Session.analysisResults.SPV.LeftX+this.Session.analysisResults.SPV.RightX)/2;
%             v = (this.Session.analysisResults.SPV.LeftX);
            
            leftIdx = find(pos<-10);
            rightIdx = find(pos>10);
            centerIdx =  find(pos>-5 & pos<5);
            
%             figure
%             subplot(2,1,1,'nextplot','add')
%             plot(t(leftIdx),pos(leftIdx),'.','markersize',6)
%             plot(t(rightIdx),pos(rightIdx),'.','markersize',6)
%             plot(t(centerIdx),pos(centerIdx),'.','markersize',6)
%             subplot(2,1,2,'nextplot','add')
%             plot(t(leftIdx),v(leftIdx),'.','markersize',6)
%             plot(t(rightIdx),v(rightIdx),'.','markersize',6)
%             plot(t(centerIdx),v(centerIdx),'.','markersize',6)
            
            VbinLeft = [];
            VbinRight = [];
            VbinCenter = [];
            VbinLeftPos = [];
            VbinRightPos = [];
            VbinCenterPos = [];
            
            D  = 11;
            for i=1:D*6
                idx = (1:20) + (i-1)*20;
                Pchunk = pos(idx);
                Vchunk = v(idx); 
                VbinRight(i) = nanmedian(Vchunk(Pchunk>10));
                VbinLeft(i) = nanmedian(Vchunk(Pchunk<-10));
                VbinCenter(i) = nanmedian(Vchunk(Pchunk>-5 & Pchunk<5));
                VbinRightPos(i) = nanmedian(Pchunk(Pchunk>10));
                VbinLeftPos(i) = nanmedian(Pchunk(Pchunk<-10));
                VbinCenterPos(i) = nanmedian(Pchunk(Pchunk>-5 & Pchunk<5));
            end
            %%
            figure
            subplot(3,1,1,'nextplot','add')
            plot((1:D*6)/6,VbinLeftPos,'o','markerSize',10);
            plot((1:D*6)/6,VbinRightPos,'o','markerSize',10);
            plot((1:D*6)/6,VbinCenterPos,'o','markerSize',10);
            xlabel('Time (min)');
            ylabel('Eye position (deg)');
            legend({'Left gaze', 'Right gaze', 'Center gaze'});
            grid
            
            subplot(3,1,2,'nextplot','add')
            plot((1:D*6)/6,VbinLeft,'o','markerSize',10);
            plot((1:D*6)/6,VbinRight,'o','markerSize',10);
            plot((1:D*6)/6,VbinCenter,'o','markerSize',10);
            xlabel('Time (min)');
            ylabel('Slow phase velocity (deg/s)');
            legend({'Left gaze', 'Right gaze', 'Center gaze'});
            grid
                        
            subplot(3,1,3,'nextplot','add')
            plot((1:D*6)/6,VbinLeft-VbinCenter,'o','markerSize',10);
            plot((1:D*6)/6,VbinRight-VbinCenter,'o','markerSize',10);
            plot((1:D*6)/6,VbinCenter-VbinCenter,'o','markerSize',10);
            xlabel('Time (min)');
            ylabel('Slow phase velocity - Left-Right (deg/s)');
            grid
            
            %%
            figure
            subplot(2,1,1,'nextplot','add')
            plot(VbinLeftPos, VbinLeft-VbinCenter,'.')
            plot(VbinRightPos, VbinRight-VbinCenter,'.')
            ylabel('SPV difference eccentric-center (deg/s)')
            xlabel('Eye position (deg)');
            subplot(2,1,2,'nextplot','add')
            plot(abs(VbinCenter), abs(VbinLeft-VbinRight),'.')
            xlabel('Abs Eye velocity at center (deg/s)');
            ylabel('Abs SPV difference left-right (deg/s)')
            
            
            
        end
    end
end

