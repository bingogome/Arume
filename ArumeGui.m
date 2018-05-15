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
        menuFileSortSessions
        
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
        menuPlotGeneratePlotsCombined
        
        % Session Contextual menu
        sessionContextMenu
        sessionContextMenuEditSettings
        sessionContextMenuRename
        sessionContextMenuRenameSubjects
        sessionContextMenuDelete
        sessionContextMenuCopy
        sessionContextMenuCopyTo
        
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
                'Title'     ,  sprintf('%-19.19s %-10.10s %-12.12s', 'Experiment', 'Subject', 'Session code'),...
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
            
            this.menuFileSortSessions = uimenu(this.menuFile, ...
                'Label'     , 'Sort sessions', ...
                'Callback'  , @this.SortSessions);
            
            
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
            
            this.menuPlotGeneratePlotsCombined = uimenu(this.menuPlot, ...
                'Label'     , 'Generate plots combined ...', ...
                'Callback'  , @this.GeneratePlotsCombined);
            
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
                'Label'     , 'Rename sessions ...', ...
                'Callback'  , @this.RenameSessions);
            this.sessionContextMenuRenameSubjects = uimenu(this.sessionContextMenu, ...
                'Label'     , 'Rename subjects ...', ...
                'Callback'  , @this.RenameSubjects);
            this.sessionContextMenuEditSettings = uimenu(this.sessionContextMenu, ...
                'Label'     , 'Edit settings ...', ...
                'Callback'  , @this.EditSessionSettings);
            this.sessionContextMenuCopyTo = uimenu(this.sessionContextMenu, ...
                'Label'     , 'Copy session to different project ...', ...
                'Callback'  , @this.CopySessionsTo);
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
            lw = 400;   % left panel width            
            
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
                
                P = StructDlg(sDlg, 'New project');
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
            
            h=waitbar(0,'Please wait..');
            
            if ( this.closeProjectQuestdlg() )
                if ( this.menuFileLoadProject == source ) 
                    [filename, pathname] = uigetfile([this.arumeController.defaultDataFolder '/*.aruprj'], 'Pick a project file');
                    if ( ~filename  )
                        close(h)
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
                        close(h)
                        msgbox('File does not exist');
                        return;
                    end
                end
                
                waitbar(1/2)
                this.arumeController.loadProject(fullfile(pathname, filename));
                waitbar(2/2)
                this.updateGui();
            end
            
            close(h)
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
                
                session = StructDlg(sessionDlg, 'New Session');
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
                options = StructDlg(optionsDlg, 'Edit experiment options');
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
                
                session = StructDlg(sessionDlg, 'New Session');
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
                options = StructDlg(optionsDlg, 'Edit experiment options');
                if ( isempty( options ) )
                    options = StructDlg(optionsDlg,'',[],[],'off');
                end
            else
                options = [];
            end
                        
            this.arumeController.importSession( session.Experiment, session.Subject_Code, session.Session_Code, options  );
            
            this.updateGui();
        end 
        
        function SortSessions( this, source, eventdata )
            this.arumeController.currentProject.sortSessions();
            this.updateGui();
        end
        
        
        function CopySessions( this, source, eventdata )
            
            sessions = this.arumeController.selectedSessions;
            
            
            newSubjectCodes = {};
            newSessionCodes = {};
            for session=sessions
                newSubjectCodes{end+1} = session.subjectCode;
                newSessionCodes{end+1} = session.sessionCode;
            end
            
            
            while(1)
                newNamesDlg = [];
                for i=1:length(sessions)
                    session = sessions(i);
                    newNamesDlg.([session.name '_New_Subject_Code' ]) = newSubjectCodes{i};
                    newNamesDlg.([session.name '_New_Session_Code' ]) = newSessionCodes{i};
                end

                P = StructDlg(newNamesDlg);
                if ( isempty( P ) )
                    return
                end
                
                newSubjectCodes = {};
                newSessionCodes = {};
                for session=sessions
                    newSubjectCodes{end+1} = P.([session.name '_New_Subject_Code' ]);
                    newSessionCodes{end+1} = P.([session.name '_New_Session_Code' ]);
                end
                
                allgood = 1;
                for i=1:length(sessions)
                    for session = this.arumeController.currentProject.sessions
                        if ( streq(session.subjectCode, newSubjectCodes{i}) &&  streq(session.sessionCode, newSessionCodes{i}) )
                            uiwait(msgbox(['One of the names is repeated ' newSubjectCodes{i} '-' newSessionCodes{i} '.'], 'Error', 'Modal'));
                            allgood = 0;
                            break;
                        end
                    end
                    if ( allgood == 0)
                        break;
                    end
                end
                
                if ( allgood)
                    break;
                end
            end
            
            %Check that the names don't exist already
            
            
             this.arumeController.copySelectedSessions(newSubjectCodes, newSessionCodes);
             this.updateGui();
        end
        
        function CopySessionsTo( this, source, eventdata )
            
            sessions = this.arumeController.selectedSessions;
            
            
            h=waitbar(0,'Please wait..');
            
            [filename, pathname] = uigetfile([this.arumeController.defaultDataFolder '/*.aruprj'], 'Pick a project file');
            if ( ~filename  )
                close(h)
                return
            end
            
            waitbar(1/2)
            this.arumeController.copySelectedSessionsToDifferentProject(fullfile(pathname, filename));
            waitbar(2/2)
            this.updateGui();
            
            close(h)
            
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
        
        function RenameSessions( this, source, eventdata )
            
            sessions = this.arumeController.selectedSessions;
            
            
            newSubjectCodes = {};
            newSessionCodes = {};
            for session=sessions
                newSubjectCodes{end+1} = session.subjectCode;
                newSessionCodes{end+1} = session.sessionCode;
            end
            
            
            while(1)
                newNamesDlg = [];
                for i=1:length(sessions)
                    session = sessions(i);
                    newNamesDlg.([session.name '_New_Session_Code' ]) = newSessionCodes{i};
                end

                P = StructDlg(newNamesDlg);
                if ( isempty( P ) )
                    return
                end
                
                newSessionCodes = {};
                for session=sessions
                    newSessionCodes{end+1} = P.([session.name '_New_Session_Code' ]);
                end
                
                allgood = 1;
                for i=1:length(sessions)
                    for session = this.arumeController.currentProject.sessions
                        if ( streq(session.subjectCode, newSubjectCodes{i}) &&  streq(session.sessionCode, newSessionCodes{i}) )
                            uiwait(msgbox(['One of the names is repeated ' newSubjectCodes{i} '-' newSessionCodes{i} '.'], 'Error', 'Modal'));
                            allgood = 0;
                            break;
                        end
                    end
                    if ( allgood == 0)
                        break;
                    end
                end
                
                if ( allgood)
                    break;
                end
            end
            
            %Check that the names don't exist already
            
            
            for i=1:length(sessions) 
                this.arumeController.renameSession(sessions(i), newSubjectCodes{i}, newSessionCodes{i});
            end
            this.updateGui();
        end
        
        
        function RenameSubjects( this, source, eventdata )
            
            sessions = this.arumeController.selectedSessions;
            
            
            newSubjectCodes = {};
            newSessionCodes = {};
            for session=sessions
                newSubjectCodes{end+1} = session.subjectCode;
                newSessionCodes{end+1} = session.sessionCode;
            end
            
            
            while(1)
                newNamesDlg = [];
                for i=1:length(sessions)
                    session = sessions(i);
                    newNamesDlg.([session.name '_New_Subject_Code' ]) = newSubjectCodes{i};
                end

                P = StructDlg(newNamesDlg);
                if ( isempty( P ) )
                    return
                end
                
                newSubjectCodes = {};
                for session=sessions
                    newSubjectCodes{end+1} = P.([session.name '_New_Subject_Code' ]);
                end
                
                allgood = 1;
                for i=1:length(sessions)
                    for session = this.arumeController.currentProject.sessions
                        if ( streq(session.subjectCode, newSubjectCodes{i}) &&  streq(session.sessionCode, newSessionCodes{i}) )
                            uiwait(msgbox(['One of the names is repeated ' newSubjectCodes{i} '-' newSessionCodes{i} '.'], 'Error', 'Modal'));
                            allgood = 0;
                            break;
                        end
                    end
                    if ( allgood == 0)
                        break;
                    end
                end
                
                if ( allgood)
                    break;
                end
            end
            
            %Check that the names don't exist already
            
            
            for i=1:length(sessions) 
                this.arumeController.renameSession(sessions(i), newSubjectCodes{i}, newSessionCodes{i});
            end
            this.updateGui();
        end
        
        function EditSessionSettings(this, source, eventdata )
            
            
            session = this.arumeController.currentSession;
            
            if ( session.isStarted )
                msgbox('This is session is already started, cannot change settings.');
                return;
            end
            
            % Show the dialog for experiment options if necessary
            experiment = ArumeCore.ExperimentDesign.Create([], session.experiment.Name);
            optionsDlg = experiment.GetExperimentOptionsDialog( );
            if ( ~isempty( optionsDlg) )
                options = StructDlg(optionsDlg,'Edit experiment options',session.experiment.ExperimentOptions);
                if ( isempty( options ) )
                    options = StructDlg(optionsDlg,'',session.experiment,[],'off');
                end
            else
                options = [];
            end
            
            session.updateExperimentOptions( options );
            
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
            
            analyses = get(this.analysisListBox,'string');
            selection = get(this.analysisListBox,'value');
            
            this.arumeController.runAnalyses(analyses, selection);
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
        
        function GeneratePlotsCombined( this, source, eventdata ) 
            
            plots = get(this.plotsListBox,'string');
            selection = get(this.plotsListBox,'value');
            
            this.arumeController.generatePlots(plots, selection,1);
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
                    sessionNames{i} = sprintf('%-20.20s %-10.10s %-20.20s', ...
                        this.arumeController.currentProject.sessions(i).experiment.Name, ...
                        char(this.arumeController.currentProject.sessions(i).subjectCode-0), ...
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
                if ( ~isempty(this.arumeController.currentSession.sessionDataTable) )
                    dataTable = this.arumeController.currentSession.sessionDataTable;
                else
                    dataTable = this.arumeController.currentSession.GetBasicSessionDataTable();
                end
                    for i=1:length(dataTable.Properties.VariableNames)
                        optionClass = class(dataTable{1,i});
                        switch(optionClass)
                            case 'double'
                                if ( isscalar(dataTable{1,i}))
                                    s = [s sprintf('%-25s: %s\n', dataTable.Properties.VariableNames{i}, num2str(dataTable{1,i}))];
                                end
                            case 'char'
                                s = [s sprintf('%-25s: %s\n', dataTable.Properties.VariableNames{i}, dataTable{1,i})];
                            case 'categorical'
                                s = [s sprintf('%-25s: %s\n', dataTable.Properties.VariableNames{i}, string(dataTable{1,i}))];
                            otherwise
                                s = [s sprintf('%-25s: %s\n', dataTable.Properties.VariableNames{i}, '-')];
                        end         
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
                plots = get(this.plotsListBox,'string');
                selection = get(this.plotsListBox,'value');
            
                plotsList = {};
                for session = this.arumeController.selectedSessions
                    if ( isempty (plotsList) )
                        plotsList = this.arumeController.GetPlotList();
                    else
                        plotsList =  intersect(plotsList, this.arumeController.GetPlotList());
                    end
                end
                
                if ( ~isempty(selection) && selection(1) > 0 )
                    [a newselection] = intersect(plotsList,plots(selection));
                else
                    newselection = min(1,length(plotsList));
                end
                
                set(this.plotsListBox, 'String', plotsList);
                set(this.plotsListBox, 'Value', newselection );
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

