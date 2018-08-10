classdef EyeTracking  < ArumeCore.ExperimentDesign
    
    properties
        eyeTracker
    end
    
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods (Access=protected)
        function dlg = GetOptionsDialog( this )
            dlg.UseEyeTracker = { {'0' '{1}'} };
        end
        
%         function initBeforeRunning( this )            
%             if ( this.ExperimentOptions.UseEyeTracker )
%                 this.eyeTracker = ArumeHardware.VOG();
%                 this.eyeTracker.Connect();
%                 this.eyeTracker.SetSessionName(this.Session.name);
%                 this.eyeTracker.StartRecording();
%             end
%         end
%         
%         function cleanAfterRunning(this)
%             
%             if ( this.ExperimentOptions.UseEyeTracker )
%                 this.eyeTracker.StopRecording();
%         
%                 disp('Downloading files...');
%                 files = this.eyeTracker.DownloadFile();
%                 
%                 disp(files{1});
%                 disp(files{2});
%                 disp(files{3});
%                 disp('Finished downloading');
%                 
%                 this.Session.addFile('vogDataFile', files{1});
%                 this.Session.addFile('vogCalibrationFile', files{2});
%                 this.Session.addFile('vogEventsFile', files{3});
%             end
%         end
    end
            
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function plotResults = Plot_Traces(this)
            
            data = this.Session.samplesDataSet;
        
            
            MEDIUM_BLUE =  [0.1000 0.5000 0.8000];
            MEDIUM_RED = [0.9000 0.2000 0.2000];
            
            figure
            time = (1:length(data.RightT))/500;
            
            subplot(3,1,1,'nextplot','add')
            plot(time, data.LeftX, 'color', [ MEDIUM_BLUE ])
            plot(time, data.RightX, 'color', [ MEDIUM_RED])
            set(gca,'ylim',[-50 50])
            ylabel('Horizontal (deg)','fontsize', 16);
            
            subplot(3,1,2,'nextplot','add')
            plot(time, data.LeftY, 'color', [ MEDIUM_BLUE ])
            plot(time, data.RightY, 'color', [ MEDIUM_RED])
            set(gca,'ylim',[-50 50])
            ylabel('Vertical (deg)','fontsize', 16);
            
            subplot(3,1,3,'nextplot','add')
            plot(time, data.LeftT, 'color', [ MEDIUM_BLUE ])
            plot(time, data.RightT, 'color', [ MEDIUM_RED])
            set(gca,'ylim',[-50 50])
            ylabel('Torsion (deg)','fontsize', 16);
            xlabel('Time (s)');
            
        end
        
        function plotResults = Plot_Saccades(this)
            data = this.Session.samplesDataSet;
            VOG.PlotQuickPhaseDebug(data)
        end
        
        function plotResults = Plot_SPV(this)
               
            data = this.Session.samplesDataSet;
            trialData = this.Session.trialDataSet;
           
            
            g1 = grpstats(trialData,{'CenterLocation', 'Side'},{'mean'},'DataVars',{'SPVBaseline', 'SPVBegRebound'});
            g2 = grpstats(trialData,{'Side'},{'mean'},'DataVars',{'SPVBegEcc', 'SPVEndEcc'});
            
            figure
            plot(-g1.CenterLocation(g1.Side=='Left'),g1.mean_SPVBegRebound(g1.Side=='Left'),'-o')
            hold
            plot(g1.CenterLocation(g1.Side=='Right'),g1.mean_SPVBegRebound(g1.Side=='Right'),'-o')
            
            plot(-40,g2.mean_SPVBegEcc(g2.Side=='Left'),'-o')
            plot(40,g2.mean_SPVBegEcc(g2.Side=='Right'),'-o')
            plot(-40,g2.mean_SPVEndEcc(g2.Side=='Left'),'-o')
            plot(40,g2.mean_SPVEndEcc(g2.Side=='Right'),'-o')
            a=1;
        end
        
        function plotResults = PlotAggregate_SPVAvg(this, sessions)
            
            reboundSessions = [];
            calibrationSessions = [];
            for i=1:length(sessions)
                if ( strcmp(sessions(i).experiment.Name, 'ReboundCalibration'))
                    if ( isempty(calibrationSessions) )
                        calibrationSessions = sessions(i);
                    else
                        calibrationSessions(end+1) = sessions(i);
                    end
                end
                if ( strcmp(sessions(i).experiment.Name, 'ReboundVariCenter'))
                    if ( isempty(reboundSessions) )
                        reboundSessions = sessions(i);
                    else
                        reboundSessions(end+1) = sessions(i);
                    end
                end
            end
             
             figure
             hold
             g1 = table();
             g2 = table();
             for i=1:length(reboundSessions)
                 trialData = reboundSessions(i).trialDataSet;
                 
                 g11 = grpstats(trialData,{'CenterLocation', 'Side'},{'mean'},'DataVars',{'SPVBaseline', 'SPVBegRebound'});
                 g11.Properties.RowNames = {};
                 g1 = [g1;[g11 table(repmat(i,height(g11),1))]];
                 
                 g22 = grpstats(trialData,{'Side'},{'mean'},'DataVars',{'SPVBegEcc', 'SPVEndEcc'});
                 g22.Properties.RowNames = {};
                 g2 = [g2;[g22 table(repmat(i,height(g22),1))]];
                 
                 plot(-g11.CenterLocation(g11.Side=='Left'),g11.mean_SPVBegRebound(g11.Side=='Left'),'r-o')
                 plot(g11.CenterLocation(g11.Side=='Right'),g11.mean_SPVBegRebound(g11.Side=='Right'),'b-o')
             end
             
             d = grpstats(g1,{'CenterLocation', 'Side'},{'mean' 'sem'},'DataVars',{'mean_SPVBaseline', 'mean_SPVBegRebound'});
             d2 = grpstats(g2,{'Side'},{'mean' 'sem'},'DataVars',{'mean_SPVBegEcc', 'mean_SPVEndEcc'});
             
             
             g1 = table();
             g2 = table();
             for i=1:length(calibrationSessions)
                 
                 data = calibrationSessions(i).samplesDataSet;
                 trialData = calibrationSessions(i).trialDataSet;
                 
                 g11 = grpstats(trialData,{'Position'},{'mean'},'DataVars',{'SPVBegEcc'});
                 g11.Properties.RowNames = {};
                 g1 = [g1;[g11 table(repmat(i,height(g11),1))]];
                 
                 
                 plot(g11.Position,g11.mean_SPVBegEcc,'k-o')
             end
             
             dcali = grpstats(g1,{'Position'},{'mean' 'sem'},'DataVars',{'mean_SPVBegEcc'});
             
             
             
             
             figure
             h1=errorbar(-d.CenterLocation(d.Side=='Left'),d.mean_mean_SPVBegRebound(d.Side=='Left'),d.sem_mean_SPVBegRebound(d.Side=='Left'),'-o','linewidth',2)
             hold
             h2=errorbar(d.CenterLocation(d.Side=='Right'),d.mean_mean_SPVBegRebound(d.Side=='Right'),d.sem_mean_SPVBegRebound(d.Side=='Right'),'-o','linewidth',2)
             
             
             h3=errorbar([-40 40],d2.mean_mean_SPVBegEcc,d2.sem_mean_SPVBegEcc,'ko','linewidth',2)
             h4= errorbar(dcali.Position,dcali.mean_mean_SPVBegEcc,dcali.sem_mean_SPVBegEcc,'k-o')
%              errorbar([-40 40],d2.mean_mean_SPVEndEcc,d2.mean_mean_SPVEndEcc,'o','color',[0.5 .5 .5],'linewidth',2)
             set(gca,'xlim',[-42 42])
%              legend({'Rebound after left','Rebound after right','Initial gaze evoked','Final gaze evoked'});
             xlabel('Position (deg)');
             ylabel('Slow phase velocity (deg/s)');
             line([-40 40],[0 0],'linestyle','--');
             line([0 0],[-2 2],'linestyle','--');
%              errorbar(40,d2.mean_mean_SPVBegEcc(d2.Side=='Right'),d2.sem_mean_SPVBegEcc(d2.Side=='Right'),'-o')
%              errorbar(-40,d2.mean_mean_SPVEndEcc(d2.Side=='Left'),d2.sem_mean_SPVEndEcc(d2.Side=='Left'),'-o')
%              errorbar(40,d2.mean_mean_SPVEndEcc(d2.Side=='Right'),d2.sem_mean_SPVEndEcc(d2.Side=='Right'),'-o')
             
%              arrow([40 d2.mean_mean_SPVBegEcc(d2.Side=='Left')], [40 d2.mean_mean_SPVEndEcc(d2.Side=='Left')])

             legend([h1 h2 h3 h4],{'Rebound after left','Rebound after right','Gaze evoked (rebound exp)', 'Gae evoked (calib.)'});
         end
        
        
    end
    
end



