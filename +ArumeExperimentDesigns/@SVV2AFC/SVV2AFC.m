classdef SVV2AFC < ArumeCore.ExperimentDesign
    %SVV2AFC Parent experiment design for designs of SVV experiments
    % using 2AFC two alternative forced choice task
    
    properties
    end
    
    % ---------------------------------------------------------------------
    % Options to set at runtime
    % ---------------------------------------------------------------------
    methods ( Static = true )
        function dlg = GetOptionsStructDlg( this )
        end
    end
    
    % ---------------------------------------------------------------------
    % Experiment design methods
    % ---------------------------------------------------------------------
    methods ( Access = protected )
        
    end
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        % Function that gets the angles of each trial with 0 meaning 
        % upright, positive tilted CW and negative CCW.
        function angles = GetAngles( this )
            angles = this.Session.trialDataSet.Angle;
        end
        
        % Function that gets the left and right responses with 1 meaning 
        % right and 0 meaning left.
        function responses = GetLeftRightResponses( this )
            responses = this.Session.trialDataSet.Response;
        end
        
        function plotResults = Plot_Sigmoid(this)
            
            angles = this.GetAngles();
            angles(this.Session.trialDataSet.TrialResult>0) = [];
            
            respones = this.GetLeftRightResponses();
            respones(this.Session.trialDataSet.TrialResult>0) = [];
            
            [SVV, a, p, allAngles, allResponses,trialCounts] = ArumeExperimentDesigns.SVV2AFC.FitAngleResponses( angles, respones);
            
            
            figure('position',[400 400 1000 400],'color','w','name',this.Session.name)
            ax1=subplot(3,1,[1:2],'nextplot','add', 'fontsize',12);
            
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
            
            
            ax2=subplot(3,1,[3],'nextplot','add', 'fontsize',12);
            bar(allAngles, trialCounts, 'edgecolor','none','facecolor',[0.5 0.5 0.5])
            
            set(gca,'xlim',[-30 30],'ylim',[0 15])
            xlabel('Angle (deg)', 'fontsize',16);
            ylabel('Number of trials', 'fontsize',16);
            set(gca,'xgrid','on')
            set(gca,'xcolor',[0.3 0.3 0.3],'ycolor',[0.3 0.3 0.3]);
            set(gca, 'YAxisLocation','right')
            
            linkaxes([ax1 ax2],'x');
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
            
            ds(mdl.Diagnostics.CooksDistance>0.1,:) = [];
            modelspec = 'Response ~ Angle';
            mdl = fitglm(ds(:,{'Response', 'Angle'}), modelspec, 'Distribution', 'binomial');
            
            angles = ds.Angle;
            responses = ds.Response;
            
            a = min(angles):0.1:max(angles);
            p = predict(mdl,a')*100;
            
            [svvr svvidx] = min(abs( p-50));
            
            SVV = a(svvidx);
            
            allAngles = -90:2:90;
            angles = 2*round(angles/2);
            allResponses = nan(size(allAngles));
            trialCounts = nan(size(allAngles));
            for ia=1:length(allAngles)
                allResponses(ia) = mean(responses(angles==allAngles(ia))*100);
                trialCounts(ia) = sum(angles==allAngles(ia));
            end
            
        end
    end
end

