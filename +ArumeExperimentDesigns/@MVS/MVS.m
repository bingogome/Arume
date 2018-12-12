classdef MVS < ArumeCore.ExperimentDesign & ArumeExperimentDesigns.EyeTracking
    
    % ---------------------------------------------------------------------
    % Data Analysis methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function optionsDlg = GetAnalysisOptionsDialog(this)
            optionsDlg = GetAnalysisOptionsDialog@ArumeExperimentDesigns.EyeTracking(this);
            optionsDlg.SPV = { {'0' '{1}'} };
            optionsDlg.SPV_Periods = { {'0' '{1}'} };
        end
        
        function [analysisResults, samplesDataTable, trialDataTable, sessionTable]  = RunDataAnalyses(this, analysisResults, samplesDataTable, trialDataTable,sessionTable, options)
            
            [analysisResults, samplesDataTable, trialDataTable, sessionTable] = RunDataAnalyses@ArumeExperimentDesigns.EyeTracking(this, analysisResults, samplesDataTable, trialDataTable,sessionTable, options);
            
            if ( options.SPV )
                analysisResults.SPV = table();
                
                T = samplesDataTable.Properties.UserData.sampleRate;
                analysisResults.SPV.Time = samplesDataTable.Time(1:T:(end-T/2));
                fields = {'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'};
                
                t = samplesDataTable.Time;
                
                %
                % calculate monocular spv
                %
                for j =1:length(fields)
                    
                    [vmed, xmed] = VOGAnalysis.GetSPV_Simple(t, samplesDataTable.(fields{j}));
                    
                    analysisResults.SPV.(fields{j}) = vmed(T/2:T:end);
                    analysisResults.SPV.([fields{j} 'Pos']) = xmed(T/2:T:end);
                end
                
                %
                % calculate binocular spv
                %
                LRdataVars = {'X' 'Y' 'T'};
                for j =1:length(LRdataVars)
                    
                    [vleft, xleft] = VOGAnalysis.GetSPV_Simple(t, samplesDataTable.(['Left' LRdataVars{j}]));
                    [vright, xright] = VOGAnalysis.GetSPV_Simple(t, samplesDataTable.(['Right' LRdataVars{j}]));
                    
                    vmed = nanmedfilt(nanmean([vleft, vright],2),T,1/2);
                    xmed = nanmedfilt(nanmean([xleft, xright],2),T,1/2);
                    
                    analysisResults.SPV.(LRdataVars{j}) = vmed(T/2:T:end);
                    analysisResults.SPV.([LRdataVars{j} 'Pos']) = xmed(T/2:T:end);
                end
                
                %
                % Realign SPV
                %
                % Get the SPV realigned for easier averaging across
                % recordings. Necessary because not all of them have
                % exactly the same time for entering and exiting the
                % magnet.  
                %
                analysisResults.SPVRealigned = ArumeExperimentDesigns.MVS.RealignSPV(...
                    analysisResults.SPV, ...
                    sessionTable.Option_Duration, ...
                    sessionTable.Option_Events.EnterMagnet, ...
                    sessionTable.Option_Events.ExitMagnet);
                
                %
                % Nnormalize data acording to the peak of the control
                %
                
                arume = Arume('nogui');
                controlSession = arume.currentProject.findSession(this.Session.subjectCode, this.Session.experimentDesign.ExperimentOptions.ControlSession);
                
                % process the control just in case (redundant but
                % necessary)
                if ( controlSession ~= this.Session )
                    opt = arume.getDefaultAnalysisOptions(controlSession);
                    opt.SPV = 1;
                    opt.SPV_Periods = 0;
                    controlSession.runAnalysis(opt);
                    controlSession.save();
                    spvControl = controlSession.analysisResults.SPVRealigned;
                else
                    spvControl = analysisResults.SPVRealigned;
                end
                
                analysisResults.SPVNormalized = ArumeExperimentDesigns.MVS.NormalizeSPV( analysisResults.SPVRealigned, spvControl, [1 300] );
            end
            
            if ( options.SPV_Periods )
                
                %
                % Get the SPV at different timepoints
                %
                switch(categorical(sessionTable.Option_Duration))
                    case '5min'
                        timeExitMagnet = 7; % min
                        durationAfterEffect = 3; % min
                    case '20min'
                        timeExitMagnet = 22; % min
                        durationAfterEffect = 7; % min
                    case '60min'
                        timeExitMagnet = 62; % min
                        durationAfterEffect = 7; % min
                end
                
                periods.Baseline        = 2 + [-1.5     -0.2];
                periods.MainEffect      = 2 + [ 0.2   1.5];
                periods.AfterEffect     = timeExitMagnet + [ 0.2    durationAfterEffect];
                periods.BeforeExit      = timeExitMagnet + [-0.1    0.1];

                % add periods for light conditions
                if ( isfield( this.ExperimentOptions.Events, 'LightsOn' ) )
                    switch(categorical(sessionTable.Option_Duration))
                        case '5min'
                            lightsON = 3; % min
                            lightsOFF = 6.7; % min
                        case '20min'
                            lightsON = 3; % min
                            lightsOFF = 21.5; % min
                        case '60min'
                            lightsON = 3; % min
                            lightsOFF = 61.5; % min
                    end
                    
                    periods.AfterLightsON      = lightsON   + [0.3 1.3];
                    periods.BeforeLightsOFF    = lightsOFF  + [-1.3 -0.3];
                    
                end
                
                % add periods for head moving conditions
                if ( isfield( this.ExperimentOptions.Events, 'StartHeadMov' ) )
                    switch(categorical(sessionTable.Option_Duration))
                        case '5min'
                            startHeadMoving = 3; % min
                            stopHeadMoving = 6.7; % min
                        case '20min'
                            startHeadMoving = 3; % min
                            stopHeadMoving = 21.5; % min
                        case '60min'
                            startHeadMoving = 3; % min
                            stopHeadMoving = 61.5; % min
                    end
                    
                    periods.AfterStartHeadMoving	= startHeadMoving   + [0.3 1.3];
                    periods.BeforeStopHeadMoving	= stopHeadMoving  + [-1.3 -0.3];
                    
                end
                
                fields = {'X' 'Y' 'T' 'LeftX', 'LeftY' 'LeftT' 'RightX' 'RightY' 'RightT'};
                periodNames = fieldnames(periods);
                
                for j =1:length(fields)
                    for k = 1:length(periodNames)
                        periodName = periodNames{k};
                        periodMin = periods.(periodName);
                        sessionTable.([periodName 'StartMin']) = periodMin(1);
                        sessionTable.([periodName 'StopMin']) = periodMin(2);
                        
                        sessionTable.(['SPV_' fields{j} '_' periodName]) = nan;
                        sessionTable.(['SPVNorm_' fields{j} '_' periodName]) = nan;
                        sessionTable.(['SPV_' fields{j} '_' periodName '_Peak']) = nan;
                        sessionTable.(['SPV_' fields{j} '_' periodName '_PeakTime']) = nan;
                        sessionTable.(['SPVNorm_' fields{j} '_' periodName '_Peak']) = nan;
                        sessionTable.(['SPVNorm_' fields{j} '_' periodName '_PeakTime']) = nan;
                        
                        x = analysisResults.SPVRealigned.(fields{j});
                        t = analysisResults.SPVRealigned.Time;
                        xNorm = analysisResults.SPVNormalized.(fields{j});
                        
                        if ( ~isnan(sessionTable.([periodName 'StartMin'])))
                            idx = sessionTable.([periodName 'StartMin'])*60:sessionTable.([periodName 'StopMin'])*60;
                            xidx = idx(~isnan(x(idx)));
                            xnormidx = idx(~isnan(xNorm(idx)));
                            % important! measure area under the curve to be
                            % more fair into how samples are weighted in
                            % the case of nans
                            if ( length(xidx)>10 )
                                sessionTable.(['SPV_' fields{j} '_' periodName]) = trapz(t(xidx),x(xidx))/(t(xidx(end))-t(xidx(1)));
                            end
                            if ( length(xnormidx)>10)
                                sessionTable.(['SPVNorm_' fields{j} '_' periodName]) = trapz(t(xnormidx),xNorm(xnormidx))/(t(xnormidx(end))-t(xnormidx(1)));
                            end
                            
                            % find absolute value peak within period
                            [~,maxIdx] = max(abs(x(idx)));
                            sessionTable.(['SPV_' fields{j} '_' periodName '_Peak']) = x(idx(maxIdx));
                            sessionTable.(['SPV_' fields{j} '_' periodName '_PeakTime']) = t(idx(maxIdx));
                            sessionTable.(['SPVNorm_' fields{j} '_' periodName '_Peak']) = xNorm(idx(maxIdx));
                            sessionTable.(['SPVNorm_' fields{j} '_' periodName '_PeakTime']) = t(idx(maxIdx));
                        end
                    end
                end
                
                
            end
        end
        
    end
    
    % ---------------------------------------------------------------------
    % Plot methods
    % ---------------------------------------------------------------------
    methods ( Access = public )
        
        function Plot_MVS_VposExit(this)
            
            t = this.Session.samplesDataTable.Time;
            ly = this.Session.samplesDataTable.LeftY;
            ry = this.Session.samplesDataTable.RightY;
            y = nanmean([ry ly],2);
            
            tExit = this.Session.experimentDesign.ExperimentOptions.Events.ExitMagnet;
            
            figure('name', [this.Session.subjectCode '  ' this.Session.sessionCode]);
            plot(t(1:end-1)/60,sgolayfilt(diff(y),1,5));
            set(gca,'xlim',tExit +[-1 +1],'ylim',[-0.2 0.2]);
        end
        
        function Plot_MVS_SPV_Trace(this)
            if ( ~isfield(this.Session.analysisResults, 'SPV' ) )
                error( 'Need to run analysis SPV before ploting SPV');
            end
            
            t = this.Session.analysisResults.SPV.Time;
            vxl = this.Session.analysisResults.SPV.LeftX;
            vxr = this.Session.analysisResults.SPV.RightX;
            vyl = this.Session.analysisResults.SPV.LeftY;
            vyr = this.Session.analysisResults.SPV.RightY;
            vtl = this.Session.analysisResults.SPV.LeftT;
            vtr = this.Session.analysisResults.SPV.RightT;
            
            %%
            figure('name', [this.Session.subjectCode '  ' this.Session.sessionCode]);
            subplot(3,1,1,'nextplot','add')
            grid
            plot(t,vxl,'o')
            plot(t,vxr,'o')
            ylabel('Horizontal (deg/s)')
            events = struct2array(this.Session.experimentDesign.ExperimentOptions.Events);
            for i=1:length(events)
                line([1 1]*events(i)*60, get(gca,'ylim'),'linestyle','--','color',0.7*[1 1 1]);
            end
            
            
            subplot(3,1,2,'nextplot','add')
            grid
            set(gca,'ylim',[-20 20])
            plot(t,vyl,'o')
            plot(t,vyr,'o')
            ylabel('Vertical (deg/s)')
            
            events = struct2array(this.Session.experimentDesign.ExperimentOptions.Events);
            for i=1:length(events)
                line([1 1]*events(i)*60, get(gca,'ylim'),'linestyle','--','color',0.7*[1 1 1]);
            end
            
            
            subplot(3,1,3,'nextplot','add')
            set(gca,'ylim',[-20 20])
            plot(t,vtl,'o')
            plot(t,vtr,'o')
            ylabel('Torsional (deg/s)')
            grid
            set(gca,'ylim',[-20 20])
            xlabel('Time (s)');
            linkaxes(get(gcf,'children'))
            
        end
        
        
        function Plot_MVS_SPVH_Trace(this)
            CLRS = get(groot,'defaultAxesColorOrder');
            
            if ( ~isfield(this.Session.analysisResults, 'SPV' ) )
                error( ['Need to run analysis SPV before ploting SPV. Session: ' this.Session.name]);
            end
            
            t = this.Session.analysisResults.SPV.Time/60;
            v = this.Session.analysisResults.SPV.X;
            tr = this.Session.analysisResults.SPVRealigned.Time/60;
            vr = this.Session.analysisResults.SPVRealigned.X;
            
            
            %%
            figure('name', [this.Session.subjectCode '  ' this.Session.sessionCode]);
            grid
            plot(t,v,'color',CLRS(2,:))
            hold
            plot(tr,vr,'o','color',CLRS(1,:))
            set(gca,'nextplot','add');
            % make the y axis symmetrical around 0 and a multiple of 10
            set(gca,'ylim',[-1 1]*10*ceil(max(abs(get(gca,'ylim')))/10));
            ylabel('Horizontal (deg/s)')
            xlabel('Time (min)');
            
            if ( isfield(this.Session.experimentDesign.ExperimentOptions, 'Events') ...
                    && isstruct(this.Session.experimentDesign.ExperimentOptions.Events) )
                events = struct2array(this.Session.experimentDesign.ExperimentOptions.Events);
                for i=1:length(events)
                    line([1 1]*events(i), get(gca,'ylim'),'linestyle','--','color',0.7*[1 1 1]);
                end
                
                periods = {'Baseline', 'MainEffect', 'BeforeExit', 'AfterEffect','AfterLightsON' 'BeforeLightsOFF' 'AfterStartHeadMoving' 'BeforeStopHeadMoving'};
                
                for i=1:length(periods)
                    time = this.Session.sessionDataTable.([periods{i} 'StartMin'])*60:this.Session.sessionDataTable.([periods{i} 'StopMin'])*60;
                    value = ones(size(time))*this.Session.sessionDataTable.(['SPV_' 'X' '_' periods{i}]);
                    plot(time/60,value,'o','color','r','linewidth',1);
                    
                   
                    plot(this.Session.sessionDataTable.(['SPV_' 'X' '_' periods{i} '_PeakTime'])/60,this.Session.sessionDataTable.(['SPV_' 'X' '_' periods{i} '_Peak']),'^','color','r','linewidth',2);
                end
            end
            
            
        end
        
        function PlotAggregate_MVS_SPV(this, sessions)
            
            CLRS = get(groot,'defaultAxesColorOrder');
            
            arume = Arume('nogui');
            s = arume.currentProject.GetDataTable(sessions);
            s.SessionObj = sessions';
            s.IsControl = s.Option_ControlSession == s.SessionCode;
            s = sortrows(s,'SessionCode');
            %%
            subjects = unique(s.Subject);
            for i=1:length(subjects)
                subplot(length(subjects),1, i,'nextplot','add');
                ss = s(s.Subject == subjects(i),:);
                for j=1:height(ss)
                    t = ss.SessionObj(j).analysisResults.SPVRealigned.Time/60;
                    vxl = ss.SessionObj(j).analysisResults.SPVRealigned.LeftX;
                    vxr = ss.SessionObj(j).analysisResults.SPVRealigned.RightX;
                    spv = nanmean([vxl vxr],2);
                    if (ss.Option_Experiment=='HeadMoving' )
                        spv(t>180 & t<405) = nan;
                    end
                    if ( ss.IsControl(j))
                        color = CLRS(1,:);
                    else
                        color = CLRS(2,:);
                    end
                    plot(t,spv,'.','markersize',10,'color',color);
                end
                line(get(gca,'xlim'),[0 0],'color',[0.5 0.5 0.5],'linestyle','-.')
                legend(strrep(string(ss.SessionCode),'_',' '));
                title(string(subjects(i)));
                xlabel('Time (s)');
                ylabel('SPV (deg/s)');
            end
        end
        
        function PlotAggregate_MVS_SPV_Normalized(this, sessions)
            
            CLRS = get(groot,'defaultAxesColorOrder');
            
            arume = Arume('nogui');
            s = arume.currentProject.GetDataTable(sessions);
            s.SessionObj = sessions';
            s.IsControl = s.Option_ControlSession == s.SessionCode;
            s = sortrows(s,'SessionCode');
            %%
            subjects = unique(s.Subject);
            for i=1:length(subjects)
                subplot(length(subjects),1, i,'nextplot','add');
                ss = s(s.Subject == subjects(i),:);
                for j=1:height(ss)
                    t = ss.SessionObj(j).analysisResults.SPVNormalized.Time/60;
                    vxl = ss.SessionObj(j).analysisResults.SPVNormalized.LeftX;
                    vxr = ss.SessionObj(j).analysisResults.SPVNormalized.RightX;
                    spv = nanmean([vxl vxr],2);
                    if (ss.Option_Experiment=='HeadMoving' )
                        spv(t>180 & t<405) = nan;
                    end
                    if ( ss.IsControl(j))
                        color = CLRS(1,:);
                    else
                        color = CLRS(2,:);
                    end
                    plot(t,spv,'.','markersize',10,'color',color);
                end
                line(get(gca,'xlim'),[0 0],'color',[0.5 0.5 0.5],'linestyle','-.')
                legend(strrep(string(ss.SessionCode),'_',' '));
                title(string(subjects(i)));
                xlabel('Time (s)');
                ylabel('SPV (deg/s)');
            end
        end
        
        %         function Plot_PlotPositionWithHead(this)
        %             VOG.PlotPositionWithHead(this.Session.samplesDataSet, this.Session.rawDataSet);
        %         end
        %         function Plot_PlotVelocityWithHead(this)
        %             VOG.PlotVelocityWithHead(this.Session.samplesDataSet, this.Session.rawDataSet);
        %         end
        %
        %         function Plot_PlotSPVFeetAndHead(this)
        %
        %             t1 = this.Session.analysisResults.SPV.Time;
        %             vxl = this.Session.analysisResults.SPV.LeftX;
        %             vxl2 = interp1(find(~isnan(vxl)),vxl(~isnan(vxl)),1:1:length(vxl));
        %             vxr = this.Session.analysisResults.SPV.RightX;
        %             vxr2 = interp1(find(~isnan(vxr)),vxr(~isnan(vxr)),1:1:length(vxr));
        %             vx1 = nanmean([vxl2;vxr2]);
        %
        %             %$ TODO fix the finding session
        %             control = this.Project.findSession('MVSNystagmusSuppression',this.ExperimentOptions.AssociatedControl);
        %
        %             t2 = control.analysisResults.SPV.Time;
        %             vxl = control.analysisResults.SPV.LeftX;
        %             vxl2 = interp1(find(~isnan(vxl)),vxl(~isnan(vxl)),1:1:length(vxl));
        %             vxr = control.analysisResults.SPV.RightX;
        %             vxr2 = interp1(find(~isnan(vxr)),vxr(~isnan(vxr)),1:1:length(vxr));
        %             vx2 = nanmean([vxl2;vxr2]);
        %
        %             events =  fields(this.ExperimentOptions.Events);
        %             eventTimes = zeros(size(events));
        %             for i=1:length(events)
        %                 eventTimes(i) = this.ExperimentOptions.Events.(events{i});
        %             end
        %
        %             if ( strfind(this.Session.sessionCode,'Head')>0)
        %                 if ( isfield( this.ExperimentOptions.Events, 'StartMoving' ) )
        %                     tstartMoving = this.ExperimentOptions.Events.StartMoving*60;
        %                     tstopMoving = this.ExperimentOptions.Events.StopMoving*60;
        %                 else
        %                     tstartMoving = this.ExperimentOptions.Events.LightsOn*60;
        %                     tstopMoving = this.ExperimentOptions.Events.LightsOff*60;
        %                 end
        %                 vx1(tstartMoving:tstopMoving) = nan;
        %             end
        %
        %             figure
        %             plot(t1/60, vx1,'.');
        %             hold
        %             plot(t2/60, vx2,'.');
        %             title([this.Session.subjectCode ' ' this.Session.sessionCode])
        %
        %             ylim = [-50 50];
        %             xlim = [0 max(eventTimes)];
        %             set(gca,'ylim',ylim,'xlim',xlim);
        %
        %             for i=1:length(events)
        %                 line(eventTimes(i)*[1 1], ylim,'color',[0.5 0.5 0.5]);
        %                 text( eventTimes(i), ylim(2)-mod(i,2)*5-5, events{i});
        %             end
        %             line(xlim, [0 0],'color',[0.5 0.5 0.5])
        %         end
        
        
    end
    
    methods(Static =true)
        
        function [newSPV] = RealignSPV( spvTable, durationExpeirment, timeEnterMagnet, timeExitMagnet)
            
            switch(categorical(durationExpeirment))
                case '5min'
                    durationInsideMagnet = 5;
                    durationUntilEnd = 11;
                case '20min'
                    durationInsideMagnet = 20;
                    durationUntilEnd = 37;
                case '60min'
                    durationInsideMagnet = 60;
                    durationUntilEnd = 82;
            end
            
            newSPV = table();
            newSPV.Time = (0:1:durationUntilEnd*60)';
            
            fields = setdiff(spvTable.Properties.VariableNames,{'Time'},'stable');
            for i=1:length(fields)
                spvRealigned = nan(size(newSPV.Time));
                spv = spvTable.(fields{i});
                if ( sum(~isnan(spv))> 3 )
                    spv = interp1(find(~isnan(spv)),spv(~isnan(spv)),1:1:length(spv));
                    
                    actualTimeEnter = round(timeEnterMagnet*60);
                    actualTimeExit = round(timeExitMagnet*60);
                    
                    expectedTimeEnter = 2*60;
                    expectedTimeExit = (durationInsideMagnet+2)*60;
                    
                    % From entering the magnet minus 2 min to duration until exist
                    % minus one minute
                    idxOriginPeriod1 = actualTimeEnter + ((-2*60)+1:((durationInsideMagnet-2)*60));
                    idxDestinPreiod1 = expectedTimeEnter + ((-2*60)+1:((durationInsideMagnet-2)*60));
                    remidx = find(idxOriginPeriod1<1 | idxOriginPeriod1>length(spv));
                    idxOriginPeriod1(remidx) = [];
                    idxDestinPreiod1(remidx) = [];
                    spvRealigned(idxDestinPreiod1) = spv(idxOriginPeriod1);
                    
                    idxOriginPeriod2 = actualTimeExit + ((-3*60)+1:((durationUntilEnd-durationInsideMagnet-2)*60));
                    idxDestinPreiod2 = expectedTimeExit + ((-3*60)+1:((durationUntilEnd-durationInsideMagnet-2)*60));
                    remidx = find(idxOriginPeriod2<1 | idxOriginPeriod2>length(spv));
                    idxOriginPeriod2(remidx) = [];
                    idxDestinPreiod2(remidx) = [];
                    spvRealigned(idxDestinPreiod2) = spv(idxOriginPeriod2);
                    
                    if(0)
                        figure
                        subplot(1,2,1)
                        plot(spvTable.Time, spv);
                        subplot(1,2,2)
                        plot(spvRealigned);
                    end
                end
                
                newSPV.(fields{i}) = spvRealigned;
            end
        end
        
        function newSPV = NormalizeSPV( spvTable, spvControlTable, peakInterval )
            
            newSPV = spvTable;
            
            fields = setdiff(spvTable.Properties.VariableNames,{'Time'},'stable');
            for i=1:length(fields)
                spvField = spvControlTable.(fields{i});
                peak = max(abs(spvField(peakInterval(1):peakInterval(2))));
                newSPV.(fields{i}) = spvTable.(fields{i}) / peak;
            end
        end
    end
    
end

