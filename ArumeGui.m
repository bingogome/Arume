classdef ArumeGui < handle
    %ARUMEGUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        % main controller
        arume
        
        % figure handle
        figureHandle
        
        % control handles
        projectTextLabel
        experimentTextLabel
        pathTextLabel
        sessionListBox
        analysisListBox
        plotsListBox
        
        infoBox
        commentsTextBox
        
        % panel handles
        topPanel
        leftPanel
        rightPanel
        bottomPanel
        
        % Menu items
        menuFile
        menuFileNewProject
        menuFileLoadProject
        menuFileCloseProject
        menuFileExportProject
        menuFileNewSession
        menuFileImportSession
        
        menuRun
        menuRunStartSession
        menuRunResumeSession
        menuRunRestartSession
        
        menuAnalyze
        menuAnalyzePrepare
        menuAnalyzeRunAnalyses
        menuAnalyzeExportAnalysisData
        
        menuPlot
        menuPlotGeneratePlots
        
        % Session Contextual menu
        sessionContextMenu
        sessionContextMenuRename
        sessionContextMenuDelete
    end
    
    %% Constructor
    methods
        function this = ArumeGui( parent )
              
            % Ensure singleton behavior
            h = findall(0,'tag','Arume');
            if ( ~isempty( h ) )
                figure(h);
                return
            end
            defaultBackground = get(0,'defaultUicontrolBackgroundColor');
            
            w = 1000;
            h = 600;
            
            this.arume = parent;
            
            %  Construct the figure
            this.figureHandle = figure( ...
                'Tag'           , 'Arume', ...
                'Visible'       , 'off', ...
                'Color'         , defaultBackground,...
                'Name'          , 'Arume',...
                'NumberTitle'   , 'off',... % Do not show figure number
                'Position'      , [360,500,w,h], ...
                'CloseRequestFcn', @this.figureCloseRequest, ...
                'ResizeFcn'     , @this.figureResizeFcn);
            
            %  Construct panels
            
            this.topPanel = uipanel ( ...
                'Parent'    , this.figureHandle,...
                'Title'     , '', ...
                'Units'     , 'Pixels' );
            
            this.leftPanel = uipanel ( ...
                'Parent'    , this.figureHandle,...
                'Title'     , 'Sessions',...
                'Units'     , 'Pixels' );
            
            this.rightPanel = uipanel ( ...
                'Parent'    , this.figureHandle,...
                'Title'     , '',...
                'Units'     , 'Pixels' );
            
            this.bottomPanel = uipanel ( ...
                'Parent'    , this.figureHandle,... 
                'Title'     , '',...
                'Units'     , 'Pixels' );
                            
            
            %  Construct the components
            this.projectTextLabel = uicontrol( ...
                'Parent'    , this.topPanel,...
                'Style'     , 'text',...
                'String'    , 'Project: ',...
                'HorizontalAlignment', 'left',...
                'Position'  , [10,36,500,15]);
            
            this.experimentTextLabel = uicontrol( ...
                'Parent'    , this.topPanel,...
                'Style'     , 'text',...
                'String'    , 'Experiment: ',...
                'HorizontalAlignment', 'left',...
                'Position'  , [10,21,500,15]);
            
            this.pathTextLabel = uicontrol( ...
                'Parent'    , this.topPanel,...
                'Style'     , 'text',...
                'String'    , 'Project: ',...
                'HorizontalAlignment', 'left',...
                'Position'  , [10,3,500,15]);
            
            this.sessionListBox = uicontrol( ...
                'Parent'    , this.leftPanel,...
                'Style'     , 'listbox',...
                'FontName'	, 'consolas',...
                'String'    , '',...
                'Units'     ,'normalized',...
                'Position'  , [0.02 0.02 0.96 0.96], ...
                'BackgroundColor'     , 'w', ...
                'Max'       , 20, ...
                'Callback'  , @this.sessionListBoxCallBack);
            
            this.infoBox = uicontrol( ...
                'Parent'    , this.rightPanel,...
                'Style'     , 'edit',...
                'Max'       , 10, ...
                'Enable'    , 'inactive', ...
                'HorizontalAlignment'   , 'Left',...
                'FontName'	, 'consolas',...
                'String'    , 'INFO:',...
                'Units'     ,'normalized',...
                'Position'  , [0.02 0.62 0.47 0.36], ...
                'BackgroundColor'     , 'w', ...
                'Callback'  , @this.sessionListBoxCallBack);
            
            this.commentsTextBox = uicontrol( ...
                'Parent'    , this.rightPanel,...
                'Style'     , 'edit',...
                'Max'       , 10, ...
                'HorizontalAlignment'   , 'Left',...
                'FontName'	, 'consolas',...
                'String'    , '',...
                'Units'     ,'normalized',...
                'Position'  , [0.5 0.62 0.47 0.36], ...
                'BackgroundColor'     , 'w', ...
                'Callback'  , @this.commentsTextBoxCallBack);
            
            this.analysisListBox = uicontrol( ...
                'Parent'    , this.rightPanel,...
                'Style'     , 'listbox',...
                'FontName'	, 'consolas',...
                'Max'       , 20, ...
                'String'    , '',...
                'Units'     ,'normalized',...
                'Position'  , [0.02 0.02 0.47 0.58], ...
                'BackgroundColor'     , 'w', ...
                'Callback'  , @this.analysisListBoxCallBack);
            
            this.plotsListBox = uicontrol( ...
                'Parent'    , this.rightPanel,...
                'Style'     , 'listbox',...
                'FontName'	, 'consolas',...
                'Max'       , 20, ...
                'String'    , '',...
                'Units'     ,'normalized',...
                'Position'  , [0.51 0.02 0.47 0.58], ...
                'BackgroundColor'     , 'w', ...
                'Callback'  , @this.plotsListBoxCallBack);
            
            % menu
            set(this.figureHandle,'MenuBar','none'); 
            
            this.menuFile = uimenu(this.figureHandle, ...
                'Label'     , 'File');
            
            this.menuFileNewProject = uimenu(this.menuFile, ...
                'Label'     , 'New project ...', ...
                'Callback'  , @this.newProject);
            this.menuFileLoadProject = uimenu(this.menuFile, ...
                'Label'     , 'Load project ...', ...
                'Callback'  , @this.loadProject);
            this.menuFileCloseProject = uimenu(this.menuFile, ...
                'Label'     , 'Close project', ...
                'Callback'  , @this.closeProject);
            this.menuFileExportProject = uimenu(this.menuFile, ...
                'Label'     , 'Export project ...', ...
                'Callback'  , @(varargin)msgbox('Not implemented'));
            
            this.menuFileNewSession = uimenu(this.menuFile, ...
                'Label'     , 'New session', ...
                'Separator' , 'on', ...
                'Callback'  , @this.newSession);
            this.menuFileImportSession = uimenu(this.menuFile, ...
                'Label'     , 'Import session', ...
                'Callback'  , @this.importSession);
            
            
            this.menuRun = uimenu(this.figureHandle, ...
                'Label'     , 'Run');
            
            this.menuRunStartSession = uimenu(this.menuRun, ...
                'Label'     , 'Start session...', ...
                'Callback'  , @this.startSession);
            this.menuRunResumeSession = uimenu(this.menuRun, ...
                'Label'     , 'Resume session', ...
                'Callback'  , @this.resumeSession);
            this.menuRunRestartSession = uimenu(this.menuRun, ...
                'Label'     , 'Restart session', ...
                'Callback'  , @this.restartSession);
            
        
            this.menuAnalyze = uimenu(this.figureHandle, ...
                'Label'     , 'Analyze');
            
            this.menuAnalyzePrepare = uimenu(this.menuAnalyze, ...
                'Label'     , 'Prepare ...', ...
                'Callback'  , @this.PrepareAnalysis);
            
            this.menuAnalyzeRunAnalyses = uimenu(this.menuAnalyze, ...
                'Label'     , 'Run analyses ...', ...
                'Callback'  , @this.RunAnalyses);
            
            this.menuAnalyzeExportAnalysisData = uimenu(this.menuAnalyze, ...
                'Label'     , 'Export analyses data to workspace ...', ...
                'Callback'  , @this.ExportAnalysesData);
            
            
            this.menuPlot = uimenu(this.figureHandle, ...
                'Label'     , 'Plot');
            
            this.menuPlotGeneratePlots = uimenu(this.menuPlot, ...
                'Label'     , 'Generate plots ...', ...
                'Callback'  , @this.GeneratePlots);
            
            % session contextual menu
            % Define a context menu; it is not attached to anything
            this.sessionContextMenu = uicontextmenu;
            this.sessionContextMenuDelete = uimenu(this.sessionContextMenu, ...
                'Label'     , 'Delete sessions ...', ...
                'Callback'  , @this.DeleteSessions);
            this.sessionContextMenuRename = uimenu(this.sessionContextMenu, ...
                'Label'     , 'Rename session ...', ...
                'Callback'  , @this.RenameSession);
            set(this.sessionListBox, 'uicontextmenu', this.sessionContextMenu)
            
            % Move the GUI to the center of the screen.
            movegui(this.figureHandle,'center')
            
            % This is to avoid a close all closing the GUI
            set(this.figureHandle, 'handlevisibility', 'off');
            
            % Make the GUI visible.
            set(this.figureHandle,'Visible','on');
            
            this.updateGui();
        end
    end
    
    %%  Callbacks 
    methods 
        
        function figureCloseRequest( this, source, eventdata )
            if ( this.closeProjectQuestdlg( ) )
                if ( ~isempty( this.arume.currentProject) )
                    this.arume.currentProject.save();
                end
                delete(this.figureHandle)
                Arume('clear');
            end
        end
        
        function figureResizeFcn( this, source, eventdata )
            figurePosition = get(this.figureHandle,'position');
            w = figurePosition(3);  % figure width
            h = figurePosition(4);  % figure height
            
            m = 5;      % margin between panels
            th = 60;    % top panel height
            bh = 60;    % bottom panel height
            lw = 300;   % left panel width            
            
            set(this.topPanel, ...
                'Position'  , [m (h-th-m) (w-m*2) th]);
            set(this.leftPanel, ...
                'Position'  , [m (bh+m*2) lw (h-m*4-th-bh)]);
            set(this.rightPanel, ...
                'Position'  , [(m*2+lw) (bh+m*2) (w- lw-m*3) (h-m*4-th-bh)]);
            set(this.bottomPanel, ...
                'Position'  , [m m (w-m*2) bh]);
        end
        
        function newProject(this, source, eventdata )
            if ( this.closeProjectQuestdlg() )
                sDlg.Path = { {['uigetdir(''' this.arume.defaultDataFolder ''')']} };
                sDlg.Name = 'ProjectName';
                sDlg.Default_Experiment = {ArumeCore.ExperimentDesign.GetExperimentList};
                P = StructDlg(sDlg);
                if ( isempty( P ) )
                    return
                end
                if ( ~isempty( this.arume.currentProject ) )
                    this.arume.currentProject.save();
                end
                
                this.arume.newProject( P.Path, P.Name, P.Default_Experiment);
                this.updateGui();
            end
        end
        
        function loadProject(this, source, eventdata )
            if ( this.closeProjectQuestdlg() )
                [filename, pathname] = uigetfile([this.arume.defaultDataFolder '/*.aruprj'], 'Pick a project file');
                if ( ~filename  )
                    return
                end
                if ( ~isempty( this.arume.currentProject ) )
                    this.arume.currentProject.save();
                end
                
                this.arume.loadProject(fullfile(pathname, filename));
                this.updateGui();
            end
        end
                
        function closeProject(this, source, eventdata )
            if ( this.closeProjectQuestdlg )
                this.arume.closeProject();
                this.updateGui();
            end
        end
        
        function newSession( this, source, eventdata ) 
            
            sessionDlg.Experiment = {ArumeCore.ExperimentDesign.GetExperimentList};
            % Set the default experiment
            defaultExperimentIndex = strcmp(sessionDlg.Experiment{1},this.arume.currentProject.defaultExperiment);
            sessionDlg.Experiment{1}{defaultExperimentIndex} = ['{'  sessionDlg.Experiment{1}{defaultExperimentIndex} '}'];
            sessionDlg.Subject_Code = '000';
            sessionDlg.Session_Code = 'Z';
            
            session = StructDlg(sessionDlg);
            if ( isempty( session ) )
                return
            end
            
            % Show the dialog for experiment options if necessary
            optionsDlg = ArumeCore.ExperimentDesign.GetExperimentDesignOptions( session.Experiment );
            if ( ~isempty( optionsDlg) )
                options = StructDlg(optionsDlg);
                if ( isempty( options ) )
                    options = StructDlg(optionsDlg,'',[],[],'off');
                end
            else
                options = [];
            end
            
            this.arume.newSession( session.Experiment, session.Subject_Code, session.Session_Code, options );
            
            this.updateGui();
        end
        
        function importSession( this, source, eventdata )     
               
            sDlg.Experiment = {ArumeCore.ExperimentDesign.GetExperimentList};
            % Set the default experiment
            for i=1:length(sDlg.Experiment{1})
                if ( strcmp(sDlg.Experiment{1}{i}, this.arume.currentProject.defaultExperiment) )
                    sDlg.Experiment{1}{i} = ['{'  sDlg.Experiment{1}{i} '}'];
                end
            end
            
            sDlg.Subject_Code = '000';
            sDlg.Session_Code = 'Z';
            P = StructDlg(sDlg);
            if ( isempty( P ) )
                return
            end
            this.arume.importSession( P.Experiment, P.Subject_Code, P.Session_Code );
            
            this.updateGui();
        end 
        
        function DeleteSessions( this, source, eventdata )
            choice = questdlg('Are you sure you want to delete the sessions?', ...
                'Closing', ...
                'Yes','No','No');
            switch choice
                case 'Yes'
                this.arume.deleteSelectedSessions();
                this.updateGui();
            end
        end
        function RenameSession( this, source, eventdata )
            
            sDlg.Subject_Code = this.arume.currentSession.subjectCode;
            sDlg.Session_Code = this.arume.currentSession.sessionCode;
            P = StructDlg(sDlg);
            if ( isempty( P ) )
                return
            end
            
            if ( ~isempty( intersect({this.arume.currentProject.sessions.name}, {'NI'})) )
                msgbox('Name already in use');
                return
            end
            
            this.arume.renameCurrentSession(P.Subject_Code, P.Session_Code);
            this.updateGui();
            
        end
        
        function startSession( this, source, eventdata ) 
            this.arume.runSession();
            this.updateGui();
        end
        
        function resumeSession( this, source, eventdata ) 
            this.arume.resumeSession();
            this.updateGui();
        end
        
        function restartSession( this, source, eventdata ) 
            this.arume.restartSession();
            this.updateGui();
        end
        
        function PrepareAnalysis( this, source, eventdata ) 
            this.arume.prepareAnalysis();
            this.updateGui();
        end
        
        function RunAnalyses( this, source, eventdata ) 
            this.arume.runAnalyses();
            this.updateGui();
        end
        
        function ExportAnalysesData( this, source, eventdata ) 
            this.arume.exportAnalysesData();
            this.updateGui();
        end
        
        function GeneratePlots( this, source, eventdata ) 
            
            plots = get(this.plotsListBox,'string');
            selection = get(this.plotsListBox,'value');
            
            this.arume.generatePlots(plots, selection);
            this.updateGui();
        end
        
        function sessionListBoxCallBack( this, source, eventdata )
            
            sessionListBoxCurrentValue = get(this.sessionListBox,'value');
            
            if ( sessionListBoxCurrentValue > 0 )
                this.arume.setCurrentSession( sessionListBoxCurrentValue );
                this.updateGui();
            end
        end
        
        function commentsTextBoxCallBack( this, source, eventdata )
            this.arume.currentSession.updateComment(get(this.commentsTextBox, 'string'));
        end
        
        
        function analysisListBoxCallBack( this, source, eventdata )
            
        end
        
        function plotsListBoxCallBack( this, source, eventdata )
            
        end
    end
    
    methods(Access=public)
        function updateGui( this )
            % update top box info
            if ( ~isempty( this.arume.currentProject ) )
                set(this.projectTextLabel, 'String', ['Project: ' this.arume.currentProject.name] );
                set(this.pathTextLabel, 'String', ['Path: ' this.arume.currentProject.path] );
            else
                set(this.projectTextLabel, 'String', ['Project: ' '-'] );
                set(this.pathTextLabel, 'String', ['Path: ' '-'] );
            end
            
            % update session listbox
            if ( ~isempty( this.arume.currentProject ) )
                % populate sessionlist
                sessionNames = cell(length(this.arume.currentProject.sessions),1);
                for i=1:length( this.arume.currentProject.sessions )
                    sessionNames{i} = [this.arume.currentProject.sessions(i).experiment.Name ' - ' this.arume.currentProject.sessions(i).name];
                end
                set(this.sessionListBox, 'String', sessionNames);
                if ( ~isempty( this.arume.currentSession ) )
                    s = [];
                    for i=1:length(this.arume.selectedSessions)
                        s = [s; find(this.arume.currentProject.sessions == this.arume.selectedSessions(i))];
                    end
                    set(this.sessionListBox, 'Value', s );
                else
                    set(this.sessionListBox, 'Value', min(1,length(this.arume.currentProject.sessions)) )
                end
            else
                set(this.sessionListBox, 'String', {});
                set(this.sessionListBox, 'Value', 0 )
            end
            
            % update info box
            if ( ~isempty( this.arume.currentSession ) )
                s = '';
                s = [s sprintf('%25s: %s\n', 'Experiment', this.arume.currentSession.experiment.Name)];
                %                 s = [s sprintf('%25s: %s\n', 'DataRawPath', this.arume.currentSession.dataRawPath)];
                %                 s = [s sprintf('%25s: %s\n', 'DataAnalysisPath', this.arume.currentSession.dataAnalysisPath)];
                if ( ~isempty( this.arume.currentSession.experiment.ExperimentOptions ) )
                    options = fieldnames(this.arume.currentSession.experiment.ExperimentOptions);
                    for i=1:length(options)
                        optionClass = class(this.arume.currentSession.experiment.ExperimentOptions.(options{i}));
                        switch(optionClass)
                            case 'double'
                                optionValue = num2str(this.arume.currentSession.experiment.ExperimentOptions.(options{i}));
                            case 'char'
                                optionValue = this.arume.currentSession.experiment.ExperimentOptions.(options{i});
                            otherwise
                                optionValue = '-';
                        end
                        s = [s sprintf('%25s: %s\n', options{i}, optionValue) ];
                    end
                end
                
                NoYes = {'No' 'Yes'};
                s = [s sprintf('%25s: %s\n', 'Started', NoYes{this.arume.currentSession.isStarted+1})];
                s = [s sprintf('%25s: %s\n', 'Finished', NoYes{this.arume.currentSession.isFinished+1})];
                if ( ~isempty(this.arume.currentSession.CurrentRun) )
                    stats = this.arume.currentSession.CurrentRun.GetStats();
                    s = [s sprintf('%25s: %s\n', 'Trials Good/Aborts/Left', sprintf('%d/%d/%d', stats.trialsCorrect, stats.trialsAbort, stats.totalTrials-stats.trialsCorrect))];
                end
                
                set(this.infoBox,'string', s);
            end
            
            % update comments text box
            if ( ~isempty( this.arume.currentSession ) )
                set(this.commentsTextBox,'string',this.arume.currentSession.comment);
            else
                set(this.commentsTextBox,'string','');
            end
            
            % update analysis listbox
            if ( ~isempty( this.arume.currentSession ) && this.arume.currentSession.isReadyForAnalysis)
                anlysisList =  this.arume.GetAnalysisList();
                set(this.analysisListBox, 'String', anlysisList);
                set(this.analysisListBox, 'Value', min(1,length(anlysisList)) )
            else
                set(this.analysisListBox, 'String', {});
                set(this.analysisListBox, 'Value', 0 )
                set(this.analysisListBox, 'Enable', 'on');
            end
            
            % update plots listbox
            if ( ~isempty( this.arume.currentSession ) && this.arume.currentSession.isReadyForAnalysis)
                plotsList = {};
                for session = this.arume.selectedSessions
                    if ( isempty (plotsList) )
                        plotsList = this.arume.GetPlotList();
                    else
                        plotsList =  intersect(plotsList, this.arume.GetPlotList());
                    end
                end
                set(this.plotsListBox, 'String', plotsList);
                set(this.plotsListBox, 'Value', min(1,length(plotsList)) )
            else
                set(this.plotsListBox, 'String', {});
                set(this.plotsListBox, 'Value', 0 )
                set(this.plotsListBox, 'Enable', 'on');
            end
                
            % update menu 
            
            % top level menus
            if ( ~isempty( this.arume.currentSession ) )
                set(this.menuRun, 'Enable', 'on');
                set(this.menuAnalyze, 'Enable', 'on');
                set(this.menuPlot, 'Enable', 'on');
            else
                set(this.menuRun, 'Enable', 'off');
                set(this.menuAnalyze, 'Enable', 'off');
                set(this.menuPlot, 'Enable', 'off');
            end
            if ( isscalar( this.arume.selectedSessions ) )
                set(this.menuRun, 'Enable', 'on');
            else
                set(this.menuRun, 'Enable', 'off');
            end
            
            
            % sub menus
            
            if ( ~isempty( this.arume.currentProject ) )
                set(this.menuFileCloseProject, 'Enable', 'on');
                set(this.menuFileExportProject, 'Enable', 'on');
                
                set(this.menuFileNewSession, 'Enable', 'on');
                
            else
                set(this.menuFileCloseProject, 'Enable', 'off');
                set(this.menuFileExportProject, 'Enable', 'off');
                
                set(this.menuFileNewSession, 'Enable', 'off');
            end
            
            if ( ~isempty( this.arume.currentSession ) )
                
                set(this.experimentTextLabel, 'String', ['Experiment: ' this.arume.currentSession.experiment.Name] );
                
                if ( ~this.arume.currentSession.isStarted )
                    set(this.menuRunStartSession, 'Enable', 'on');
                else
                    set(this.menuRunStartSession, 'Enable', 'off');
                end
                if ( this.arume.currentSession.isStarted && ~this.arume.currentSession.isFinished )
                    set(this.menuRunResumeSession, 'Enable', 'on');
                    set(this.menuRunRestartSession, 'Enable', 'on');
                else
                    set(this.menuRunResumeSession, 'Enable', 'off');
                    set(this.menuRunRestartSession, 'Enable', 'off');
                end
                if ( this.arume.currentSession.isStarted && ~this.arume.currentSession.isFinished  )
                    set(this.menuRunRestartSession, 'Enable', 'on');
                else
                    set(this.menuRunRestartSession, 'Enable', 'off');
                end
                
                set(this.sessionContextMenuDelete, 'Enable', 'on');
                set(this.sessionContextMenuRename, 'Enable', 'on');
            else
                set(this.experimentTextLabel, 'String', ['Experiment: ' '-'] );
                
                set(this.menuRunStartSession, 'Enable', 'off');
                set(this.menuRunResumeSession, 'Enable', 'off');
                set(this.menuRunRestartSession, 'Enable', 'off');
                
                set(this.sessionContextMenuDelete, 'Enable', 'off');
                set(this.sessionContextMenuRename, 'Enable', 'off');
            end
            
            
        end
    end
    
    
    %%  Utility functions 
    methods
        function result = closeProjectQuestdlg( this )
            if ( isempty( this.arume.currentProject) )
                result = 1;
                return
            end
            choice = questdlg('Do you want to close the current project?', ...
                'Closing', ...
                'Yes','No','No');
            
            switch choice
                case 'Yes'
                    result = 1;
                case 'No'
                    result = 0;
            end
        end
    end
    
end

