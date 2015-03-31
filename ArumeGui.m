classdef ArumeGui < handle
    %ARUMEGUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        % main controller
        arumeController
        
        % figure handle
        figureHandle
        
        % control handles
        projectTextLabel
        defaultExperimentTextLabel
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
        menuFileLoadRecentProject
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
        sessionContextMenuCopy
        
        % Analysis Contextual menu
        analysisContextMenu
        analysisContextMenuSendToWorkspace
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
            
            this.arumeController = parent;
            
            %  Construct the figure
            this.figureHandle = figure( ...
                'Tag'           , 'Arume', ...
                'Visible'       , 'off', ...
                'Color'         , defaultBackground,...
                'Name'          , 'Arume',...
                'NumberTitle'   , 'off',... % Do not show figure number
                'Position'      , [400,800,w,h], ...
                'CloseRequestFcn', @this.figureCloseRequest, ...
                'ResizeFcn'     , @this.figureResizeFcn);
            
            %  Construct panels
            
            this.topPanel = uipanel ( ...
                'Parent'    , this.figureHandle,...
                'Title'     , '', ...
                'Units'     , 'Pixels' );
            
            this.leftPanel = uipanel ( ...
                'Parent'    , this.figureHandle,...
                'Title'     ,  sprintf('%-19.19s %-8.8s %-12.12s', 'Experiment', 'Subject', 'Session code'),...
                'FontName'	, 'consolas',...
                'FontSize'	, 9,...
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
                'FontName'	, 'consolas',...
                'FontSize'	, 9,...
                'HorizontalAlignment', 'left',...
                'Position'  , [10,36,500,15]);
            
            this.defaultExperimentTextLabel = uicontrol( ...
                'Parent'    , this.topPanel,...
                'Style'     , 'text',...
                'String'    , 'Default experiment: ',...
                'FontName'	, 'consolas',...
                'FontSize'	, 9,...
                'HorizontalAlignment', 'left',...
                'Position'  , [10,21,500,15]);
            
            this.pathTextLabel = uicontrol( ...
                'Parent'    , this.topPanel,...
                'Style'     , 'text',...
                'FontName'	, 'consolas',...
                'FontSize'	, 9,...
                'String'    , 'Project: ',...
                'HorizontalAlignment', 'left',...
                'Position'  , [10,3,500,15]);
            
            this.sessionListBox = uicontrol( ...
                'Parent'    , this.leftPanel,...
                'Style'     , 'listbox',...
                'FontName'	, 'consolas',...
                'FontSize'	, 9,...
                'String'    , '',...
                'Units'     ,'normalized',...
                'Position'  , [0.02 0.01 0.96 0.98], ...
                'BackgroundColor'     , 'w', ...
                'Max'       , 20, ...
                'Callback'  , @this.sessionListBoxCallBack);
            
            this.infoBox = uicontrol( ...
                'Parent'    , this.rightPanel,...
                'Style'     , 'edit',...
                'FontName'	, 'consolas',...
                'FontSize'	, 9,...
                'Max'       , 10, ...
                'Enable'    , 'inactive', ...
                'HorizontalAlignment'   , 'Left',...
                'FontName'	, 'consolas',...
                'String'    , 'INFO:',...
                'Units'     ,'normalized',...
                'Position'  , [0.01 0.01 0.48 0.97], ...
                'BackgroundColor'     , 'w', ...
                'Callback'  , @this.sessionListBoxCallBack);
            
            this.commentsTextBox = uicontrol( ...
                'Parent'    , this.rightPanel,...
                'Style'     , 'edit',...
                'FontName'	, 'consolas',...
                'FontSize'	, 9,...
                'Max'       , 10, ...
                'HorizontalAlignment'   , 'Left',...
                'String'    , '',...
                'Units'     ,'normalized',...
                'Position'  , [0.5 0.61 0.48 0.37], ...
                'BackgroundColor'     , [1 1 0.8], ...
                'Callback'  , @this.commentsTextBoxCallBack);
            
            this.analysisListBox = uicontrol( ...
                'Parent'    , this.rightPanel,...
                'Style'     , 'listbox',...
                'FontName'	, 'consolas',...
                'FontSize'	, 9,...
                'Max'       , 20, ...
                'String'    , '',...
                'Units'     ,'normalized',...
                'Position'  , [0.5 0.01 0.48 0.17], ...
                'BackgroundColor'     , 'w', ...
                'Callback'  , @this.analysisListBoxCallBack);
            
            this.plotsListBox = uicontrol( ...
                'Parent'    , this.rightPanel,...
                'Style'     , 'listbox',...
                'FontName'	, 'consolas',...
                'FontSize'	, 9,...
                'Max'       , 20, ...
                'String'    , '',...
                'Units'     ,'normalized',...
                'Position'  , [0.5 0.20 0.48 0.38], ...
                'BackgroundColor'     , 'w', ...
                'Callback'  , @this.plotsListBoxCallBack);
            
            % menu
            set(this.figureHandle,'MenuBar','none'); 
            
            this.menuFile = uimenu(this.figureHandle, ...
                'Label'     , 'File', ...
                'Callback'  , @this.menuFileCallback);
            
            this.menuFileNewProject = uimenu(this.menuFile, ...
                'Label'     , 'New project ...', ...
                'Callback'  , @this.newProject);
            this.menuFileLoadProject = uimenu(this.menuFile, ...
                'Label'     , 'Load project ...', ...
                'Callback'  , @this.loadProject);
            this.menuFileLoadRecentProject = uimenu(this.menuFile, ...
                'Label'     , 'Load recent project');
            
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
            this.sessionContextMenuCopy = uimenu(this.sessionContextMenu, ...
                'Label'     , 'Copy session ...', ...
                'Callback'  , @this.CopySessions);
            this.sessionContextMenuDelete = uimenu(this.sessionContextMenu, ...
                'Label'     , 'Delete sessions ...', ...
                'Callback'  , @this.DeleteSessions);
            this.sessionContextMenuRename = uimenu(this.sessionContextMenu, ...
                'Label'     , 'Rename session ...', ...
                'Callback'  , @this.RenameSession);
            set(this.sessionListBox, 'uicontextmenu', this.sessionContextMenu)
            
            % session contextual menu
            % Define a context menu; it is not attached to anything
            this.analysisContextMenu = uicontextmenu;
            this.analysisContextMenuSendToWorkspace = uimenu(this.analysisContextMenu, ...
                'Label'     , 'Send data to matlab workspace ...', ...
                'Callback'  , @this.SendToWorkspace);
            set(this.analysisListBox, 'uicontextmenu', this.analysisContextMenu)
            
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
                if ( ~isempty( this.arumeController.currentProject) )
                    this.arumeController.currentProject.save();
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
            lw = 350;   % left panel width            
            
            set(this.topPanel, ...
                'Position'  , [m (h-th-m) (w-m*2) th]);
            set(this.leftPanel, ...
                'Position'  , [m (bh+m*2) lw (h-m*4-th-bh)]);
            set(this.rightPanel, ...
                'Position'  , [(m*2+lw) (bh+m*2) (w- lw-m*3) (h-m*4-th-bh)]);
            set(this.bottomPanel, ...
                'Position'  , [m m (w-m*2) bh]);
        end
        
        
        
        function menuFileCallback( this, source, eventdata )
            
            delete(get(this.menuFileLoadRecentProject,'children'));
            
            for i=1:length(this.arumeController.recentProjects) % Add recent projects
                uimenu(this.menuFileLoadRecentProject, ...
                'Label'     , this.arumeController.recentProjects{i}, ...
                'Callback'  , @this.loadProject);
            end
        end
            
        function newProject(this, source, eventdata )
            if ( this.closeProjectQuestdlg() )
                sDlg.Path = { {['uigetdir(''' this.arumeController.defaultDataFolder ''')']} };
                sDlg.Name = 'ProjectName';
                sDlg.Default_Experiment = {ArumeCore.ExperimentDesign.GetExperimentList};
                
%                 for i=1:length(ArumeCore.ExperimentDesign.GetExperimentList)
%                     sessionDlg.(ArumeCore.ExperimentDesign.GetExperimentList{i}) = { {'0','{1}'} };
%                 end
                
                P = StructDlg(sDlg);
                if ( isempty( P ) )
                    return
                end
                if ( ~isempty( this.arumeController.currentProject ) )
                    this.arumeController.currentProject.save();
                end
                
                this.arumeController.newProject( P.Path, P.Name, P.Default_Experiment);
                this.updateGui();
            end
        end
        
        function loadProject(this, source, eventdata )
            if ( this.closeProjectQuestdlg() )
                if ( this.menuFileLoadProject == source ) 
                    [filename, pathname] = uigetfile([this.arumeController.defaultDataFolder '/*.aruprj'], 'Pick a project file');
                    if ( ~filename  )
                        return
                    end
                    if ( ~isempty(this.arumeController.currentProject) )
                        this.arumeController.currentProject.save();
                    end
                else % load a recent project
                    fullname = get(source,'Label');
                    if ( exist(fullname,'file') )
                        [pathname, file, extension] = fileparts(fullname);
                        filename = [file extension];
                    else
                        msgbox('File does not exist');
                        return;
                    end
                end
                
                this.arumeController.loadProject(fullfile(pathname, filename));
                this.updateGui();
            end
        end
        
        function loadRecentProject(this, source, eventdata )
            if ( this.closeProjectQuestdlg() )
               a=1;
            end
        end
                
        function closeProject(this, source, eventdata )
            if ( this.closeProjectQuestdlg )
                this.arumeController.closeProject();
                this.updateGui();
            end
        end
        
        function newSession( this, source, eventdata ) 
            
            experiments = ArumeCore.ExperimentDesign.GetExperimentList;
            defaultExperimentIndex = find(strcmp(experiments,this.arumeController.currentProject.defaultExperiment));
            
            session.Experiment = experiments{defaultExperimentIndex};
            session.Subject_Code = '000';
            session.Session_Code = 'Z';
            
            while(1) 
                sessionDlg.Experiment = {experiments};
                sessionDlg.Experiment{1}{defaultExperimentIndex} = ['{'  experiments{find(strcmp(experiments,session.Experiment))} '}'];
                
                sessionDlg.Subject_Code = session.Subject_Code;
                sessionDlg.Session_Code = session.Session_Code;
                
                session = StructDlg(sessionDlg);
                if ( isempty( session ) )
                    return
                end
                
                if ( isempty(regexp(session.Subject_Code,'^[_a-zA-Z0-9]+$','ONCE') ))
                    uiwait(msgbox('The subject code is not valid', 'Error', 'Modal'));
                    continue;
                end
                
                if ( isempty(regexp(session.Session_Code,'^[_a-zA-Z0-9]+$','ONCE') ))
                    uiwait(msgbox('The session code is not valid', 'Error', 'Modal'));
                    continue;
                end
                
                % Check if session already exists
                if ( isempty(this.arumeController.currentProject.findSession( session.Experiment, session.Subject_Code, session.Session_Code)))
                    break;
                else
                    uiwait(msgbox('There is already a session with this name/code', 'Error', 'Modal'));
                end
            end
            
            
            % Show the dialog for experiment options if necessary
            experiment = ArumeCore.ExperimentDesign.Create([], session.Experiment);
            optionsDlg = experiment.GetExperimentOptionsDialog( );
            if ( ~isempty( optionsDlg) )
                options = StructDlg(optionsDlg);
                if ( isempty( options ) )
                    options = StructDlg(optionsDlg,'',[],[],'off');
                end
            else
                options = [];
            end
            
            session = this.arumeController.newSession( session.Experiment, session.Subject_Code, session.Session_Code, options );
            
            this.updateGui();
        end
        
        function importSession( this, source, eventdata )     
               
            sDlg.Experiment = {ArumeCore.ExperimentDesign.GetExperimentList};
            % Set the default experiment
            for i=1:length(sDlg.Experiment{1})
                if ( strcmp(sDlg.Experiment{1}{i}, this.arumeController.currentProject.defaultExperiment) )
                    sDlg.Experiment{1}{i} = ['{'  sDlg.Experiment{1}{i} '}'];
                end
            end
            
            sDlg.Subject_Code = '000';
            sDlg.Session_Code = 'Z';
            P = StructDlg(sDlg);
            if ( isempty( P ) )
                return
            end
            this.arumeController.importSession( P.Experiment, P.Subject_Code, P.Session_Code );
            
            this.updateGui();
        end 
        
        function CopySessions( this, source, eventdata )
            
            sessions = this.arumeController.selectedSessions;
            
            newNamesDlg = [];
            for session=sessions
                newNamesDlg.([session.name '_New_Subject_Code' ]) = session.subjectCode;
                newNamesDlg.([session.name '_New_Session_Code' ]) = session.sessionCode;
            end
            
            P = StructDlg(newNamesDlg);
            if ( isempty( P ) )
                return
            end
            
            %Check that the names don't exist already
            
            newSubjectCodes = {};
            newSessionCodes = {};
            for session=sessions
                newSubjectCodes{end+1} = P.([session.name '_New_Subject_Code' ]);
                newSessionCodes{end+1} = P.([session.name '_New_Session_Code' ]);
            end
            
             this.arumeController.copySelectedSessions(newSubjectCodes, newSessionCodes);
             this.updateGui();
        end
        
        function DeleteSessions( this, source, eventdata )
            choice = questdlg('Are you sure you want to delete the sessions?', ...
                'Closing', ...
                'Yes','No','No');
            switch choice
                case 'Yes'
                this.arumeController.deleteSelectedSessions();
                this.updateGui();
            end
        end
        
        function RenameSession( this, source, eventdata )
            
            sDlg.Subject_Code = this.arumeController.currentSession.subjectCode;
            sDlg.Session_Code = this.arumeController.currentSession.sessionCode;
            P = StructDlg(sDlg);
            if ( isempty( P ) )
                return
            end
            
            if ( ~isempty( intersect({this.arumeController.currentProject.sessions.name}, {'NI'})) )
                msgbox('Name already in use');
                return
            end
            
            this.arumeController.renameCurrentSession(P.Subject_Code, P.Session_Code);
            this.updateGui();
            
        end
        
        function startSession( this, source, eventdata ) 
            this.arumeController.runSession();
            this.updateGui();
        end
        
        function resumeSession( this, source, eventdata ) 
            this.arumeController.resumeSession();
            this.updateGui();
        end
        
        function restartSession( this, source, eventdata ) 
            this.arumeController.restartSession();
            this.updateGui();
        end
        
        function PrepareAnalysis( this, source, eventdata ) 
            this.arumeController.prepareAnalysis();
            this.updateGui();
        end
        
        function RunAnalyses( this, source, eventdata ) 
            this.arumeController.runAnalyses();
            this.updateGui();
        end
        
        function ExportAnalysesData( this, source, eventdata ) 
            this.arumeController.exportAnalysesData();
            this.updateGui();
        end
        
        function GeneratePlots( this, source, eventdata ) 
            
            plots = get(this.plotsListBox,'string');
            selection = get(this.plotsListBox,'value');
            
            this.arumeController.generatePlots(plots, selection);
            this.updateGui();
        end
        
        function sessionListBoxCallBack( this, source, eventdata )
            
            sessionListBoxCurrentValue = get(this.sessionListBox,'value');
            
            if ( sessionListBoxCurrentValue > 0 )
                this.arumeController.setCurrentSession( sessionListBoxCurrentValue );
                this.updateGui();
            end
        end
        
        function commentsTextBoxCallBack( this, source, eventdata )
            this.arumeController.currentSession.updateComment(get(this.commentsTextBox, 'string'));
        end
        
        
        function analysisListBoxCallBack( this, source, eventdata )
            
        end
        
        function plotsListBoxCallBack( this, source, eventdata )
            
        end
        
        function SendToWorkspace( this, source, eventdata)
            
        end
    end
    
    methods(Access=public)
        function updateGui( this )
            % update top box info
            if ( ~isempty( this.arumeController.currentProject ) )
                set(this.projectTextLabel, 'String', ['Project: ' this.arumeController.currentProject.name] );
                set(this.pathTextLabel, 'String', ['Path: ' this.arumeController.currentProject.projectFile] );
                set(this.defaultExperimentTextLabel, 'String', ['Default experiment: ' this.arumeController.currentProject.defaultExperiment] );
            else
                set(this.projectTextLabel, 'String', ['Project: ' '-'] );
                set(this.pathTextLabel, 'String', ['Path: ' '-'] );
                set(this.defaultExperimentTextLabel, 'String', ['Default experiment: ' '-'] );
            end
            
            % update session listbox
            if ( ~isempty( this.arumeController.currentProject ) )
                % populate sessionlist
                sessionNames = cell(length(this.arumeController.currentProject.sessions),1);
                for i=1:length( this.arumeController.currentProject.sessions )
                    sessionNames{i} = sprintf('%-20.20s %-8.8s %-10.10s', ...
                        this.arumeController.currentProject.sessions(i).experiment.Name, ...
                        this.arumeController.currentProject.sessions(i).subjectCode, ...
                        this.arumeController.currentProject.sessions(i).sessionCode);
                end
                set(this.sessionListBox, 'String', sessionNames);
                if ( ~isempty( this.arumeController.currentSession ) )
                    s = [];
                    for i=1:length(this.arumeController.selectedSessions)
                        s = [s; find(this.arumeController.currentProject.sessions == this.arumeController.selectedSessions(i))];
                    end
                    set(this.sessionListBox, 'Value', s );
                else
                    set(this.sessionListBox, 'Value', min(1,length(this.arumeController.currentProject.sessions)) )
                end
            else
                set(this.sessionListBox, 'String', {});
                set(this.sessionListBox, 'Value', 0 )
            end
            
            % update info box
            if ( ~isempty( this.arumeController.currentSession ) )
                s = '';
                s = [s sprintf('== EXPERIMENT ======= \n\n')];
                s = [s sprintf('%s\n\n', this.arumeController.currentSession.experiment.Name)];
                s = [s sprintf('== EXPERIMENT OPTIONS ======= \n\n')];
                %                 s = [s sprintf('%25s: %s\n', 'DataRawPath', this.arumeController.currentSession.dataRawPath)];
                %                 s = [s sprintf('%25s: %s\n', 'DataAnalysisPath', this.arumeController.currentSession.dataAnalysisPath)];
                if ( ~isempty( this.arumeController.currentSession.experiment.ExperimentOptions ) )
                    options = fieldnames(this.arumeController.currentSession.experiment.ExperimentOptions);
                    for i=1:length(options)
                        optionClass = class(this.arumeController.currentSession.experiment.ExperimentOptions.(options{i}));
                        switch(optionClass)
                            case 'double'
                                optionValue = num2str(this.arumeController.currentSession.experiment.ExperimentOptions.(options{i}));
                            case 'char'
                                optionValue = this.arumeController.currentSession.experiment.ExperimentOptions.(options{i});
                            otherwise
                                optionValue = '-';
                        end
                        s = [s sprintf('%-25s: %s\n', options{i}, optionValue) ];
                    end
                end
                
                s = [s sprintf('\n== SESSION STATUS ======= \n\n')];
                NoYes = {'No' 'Yes'};
                s = [s sprintf('%-25s: %s\n', 'Started', NoYes{this.arumeController.currentSession.isStarted+1})];
                s = [s sprintf('%-25s: %s\n', 'Finished', NoYes{this.arumeController.currentSession.isFinished+1})];
                if ( ~isempty(this.arumeController.currentSession.currentRun) )
                    stats = this.arumeController.currentSession.currentRun.GetStats();
                    s = [s sprintf('%-25s: %s\n', 'Trials Good/Aborts/Left', sprintf('%d/%d/%d', stats.trialsCorrect, stats.trialsAbort, stats.totalTrials-stats.trialsCorrect))];
                end
                
                if ( ~isempty(this.arumeController.currentSession.currentRun) && size(this.arumeController.currentSession.currentRun.Events,2) > 4)
                    s = [s sprintf('%-25s: %s\n','Time first trial ', datestr(this.arumeController.currentSession.currentRun.Events(1,2)))];
                    s = [s sprintf('%-25s: %s\n','Time last trial ',datestr(this.arumeController.currentSession.currentRun.Events(end,2)))];
                end
                        
                set(this.infoBox,'string', s);
            end
            
            % update comments text box
            if ( ~isempty( this.arumeController.currentSession ) )
                set(this.commentsTextBox, 'Enable','on')
                set(this.commentsTextBox,'string',this.arumeController.currentSession.comment);
            else
                set(this.commentsTextBox, 'Enable','off')
                set(this.commentsTextBox,'string','');
            end
            
            % update analysis listbox
            if ( ~isempty( this.arumeController.currentSession ) && this.arumeController.currentSession.isReadyForAnalysis)
                anlysisList =  this.arumeController.GetAnalysisList();
                set(this.analysisListBox, 'String', anlysisList);
                set(this.analysisListBox, 'Value', min(1,length(anlysisList)) )
            else
                set(this.analysisListBox, 'String', {});
                set(this.analysisListBox, 'Value', 0 )
                set(this.analysisListBox, 'Enable', 'on');
            end
            
            % update plots listbox
            if ( ~isempty( this.arumeController.currentSession ) && this.arumeController.currentSession.isReadyForAnalysis)
                plotsList = {};
                for session = this.arumeController.selectedSessions
                    if ( isempty (plotsList) )
                        plotsList = this.arumeController.GetPlotList();
                    else
                        plotsList =  intersect(plotsList, this.arumeController.GetPlotList());
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
            if ( ~isempty( this.arumeController.currentSession ) )
                set(this.menuRun, 'Enable', 'on');
                set(this.menuAnalyze, 'Enable', 'on');
                set(this.menuPlot, 'Enable', 'on');
            else
                set(this.menuRun, 'Enable', 'off');
                set(this.menuAnalyze, 'Enable', 'off');
                set(this.menuPlot, 'Enable', 'off');
            end
            if ( isscalar( this.arumeController.selectedSessions ) )
                set(this.menuRun, 'Enable', 'on');
            else
                set(this.menuRun, 'Enable', 'off');
            end
            
            
            % sub menus
            
            if ( ~isempty( this.arumeController.currentProject ) )
                set(this.menuFileCloseProject, 'Enable', 'on');
                set(this.menuFileExportProject, 'Enable', 'on');
                
                set(this.menuFileNewSession, 'Enable', 'on');
                
            else
                set(this.menuFileCloseProject, 'Enable', 'off');
                set(this.menuFileExportProject, 'Enable', 'off');
                
                set(this.menuFileNewSession, 'Enable', 'off');
            end
            
            if ( ~isempty( this.arumeController.currentSession ) )
                
                if ( ~this.arumeController.currentSession.isStarted )
                    set(this.menuRunStartSession, 'Enable', 'on');
                else
                    set(this.menuRunStartSession, 'Enable', 'off');
                end
                if ( this.arumeController.currentSession.isStarted && ~this.arumeController.currentSession.isFinished )
                    set(this.menuRunResumeSession, 'Enable', 'on');
                    set(this.menuRunRestartSession, 'Enable', 'on');
                else
                    set(this.menuRunResumeSession, 'Enable', 'off');
                    set(this.menuRunRestartSession, 'Enable', 'off');
                end
                if ( this.arumeController.currentSession.isStarted && ~this.arumeController.currentSession.isFinished  )
                    set(this.menuRunRestartSession, 'Enable', 'on');
                else
                    set(this.menuRunRestartSession, 'Enable', 'off');
                end
                
                set(this.sessionContextMenuDelete, 'Enable', 'on');
                set(this.sessionContextMenuRename, 'Enable', 'on');
            else
                
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
            result = 0;
            if ( isempty( this.arumeController.currentProject) )
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

