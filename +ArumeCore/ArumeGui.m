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
        menuFileSaveProjectBackup
        menuFileLoadProjectBackup
        menuFileLoadRecentProject
        menuFileCloseProject
        menuFileNewSession
        menuFileImportSession
        menuFileSortSessions
        
        menuRun
        menuRunStartSession
        menuRunResumeSession
        menuRunRestartSession
        menuResumeSessionFrom
        
        menuAnalyze
        menuAnalyzePrepare
        
        menuPlot
        menuPlotGeneratePlots
        menuPlotGeneratePlotsCombined
        menuPlotGeneratePlotsAggregated
        
        % Session Contextual menu
        sessionContextMenu
        sessionContextMenuEditSettings
        sessionContextMenuRename
        sessionContextMenuRenameSubjects
        sessionContextMenuDelete
        sessionContextMenuCopy
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
            
            w = 900;
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
                'SizeChangedFcn' , @this.figureResizeFcn); %Jing, change 'ResizeFcn' to 'SizeChangedFcn', becuase it might be removed in future
            
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
                'BorderType', 'none',...
                'Units'     , 'Pixels' );
            
            this.rightPanel = uipanel ( ...
                'Parent'    , this.figureHandle,...
                'Title'     , 'Session info',...
                'FontName'	, 'consolas',...
                'FontSize'	, 9,...
                'BorderType', 'none',...
                'Units'     , 'Pixels' );
            
            this.bottomPanel = uipanel ( ...
                'Parent'    , this.figureHandle,... 
                'Title'     , 'Session notes',...
                'FontName'	, 'consolas',...
                'FontSize'	, 9,...
                'BorderType', 'none',...
                'Units'     , 'Pixels' );
                            
            
            %  Construct the components
            this.projectTextLabel = uicontrol( ...
                'Parent'    , this.topPanel,...
                'Style'     , 'text',...
                'String'    , 'Project: ',...
                'FontName'	, 'consolas',...
                'FontSize'	, 11,...
                'HorizontalAlignment', 'left',...
                'Position'  , [5,18,500,15]);
            
            this.pathTextLabel = uicontrol( ...
                'Parent'    , this.topPanel,...
                'Style'     , 'text',...
                'FontName'	, 'consolas',...
                'FontSize'	, 9,...
                'String'    , 'Project: ',...
                'HorizontalAlignment', 'left',...
                'Position'  , [5,0,500,15]);
            
            this.sessionListBox = uicontrol( ...
                'Parent'    , this.leftPanel,...
                'Style'     , 'listbox',...
                'FontName'	, 'consolas',...
                'FontSize'	, 9,...
                'String'    , '',...
                'Units'     ,'normalized',...
                'Position'  , [0 0 1 1], ...
                'BackgroundColor'     , 'w', ...
                'Max'       , 20, ...
                'Callback'  , @this.sessionListBoxCallBack);
            
            this.infoBox = uicontrol( ...
                'Parent'    , this.rightPanel,...
                'Style'     , 'edit',...
                'FontName'	, 'consolas',...
                'FontSize'	, 8,...
                'Max'       , 10, ...
                'Enable'    , 'inactive', ...
                'HorizontalAlignment'   , 'Left',...
                'FontName'	, 'consolas',...
                'String'    , '',...
                'Units'     ,'normalized',...
                'Position'  , [0 0 1 1], ...
                'BackgroundColor'     , 'w');
            
            this.commentsTextBox = uicontrol( ...
                'Parent'    , this.bottomPanel,...
                'Style'     , 'edit',...
                'FontName'	, 'consolas',...
                'FontSize'	, 9,...
                'Max'       , 10, ...
                'HorizontalAlignment'   , 'Left',...
                'String'    , '',...
                'Units'     ,'normalized',...
                'Position'  , [0 0 1 1], ...
                'BackgroundColor'     , [1 1 0.8], ...
                'Callback'  , @this.commentsTextBoxCallBack);
            
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
            
            this.menuFileSaveProjectBackup = uimenu(this.menuFile, ...
                'Label'     , 'Backup project ...', ...
                'Separator' , 'on', ...
                'Callback'  , @this.saveProjectBackup);
            this.menuFileLoadProjectBackup = uimenu(this.menuFile, ...
                'Label'     , 'Restore project backup ...', ...
                'Callback'  , @this.loadProjectBackup);
            
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
            this.menuResumeSessionFrom = uimenu(this.menuRun, ...
                'Label'     , 'Resume session from ...', ...
                'Separator' , 'on' );
            
        
            this.menuAnalyze = uimenu(this.figureHandle, ...
                'Label'     , 'Analyze');
            
            this.menuAnalyzePrepare = uimenu(this.menuAnalyze, ...
                'Label'     , 'Prepare ...', ...
                 'Callback'  , @this.PrepareAnalysis);
            
            
            this.menuPlot = uimenu(this.figureHandle, ...
                'Label'     , 'Plot', ...
                 'Callback'  , @this.Plot);
            
            this.menuPlotGeneratePlots = uimenu(this.menuPlot, ...
                'Label'     , 'Generate plots');
            
            this.menuPlotGeneratePlotsCombined = uimenu(this.menuPlot, ...
                'Label'     , 'Generate plots combined');
            
            this.menuPlotGeneratePlotsAggregated = uimenu(this.menuPlot, ...
                'Label'     , 'Generate plots aggregated');
            
            
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
            
            m = 8;      % margin between panels
            th = 40;    % top panel height
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
            
            % Clean up and refill the recent projects menu
            
            delete(get(this.menuFileLoadRecentProject,'children'));
            
            for i=1:length(this.arumeController.recentProjects)
                uimenu(this.menuFileLoadRecentProject, ...
                'Label'     , this.arumeController.recentProjects{i}, ...
                'Callback'  , @this.loadProject);
            end
        end
            
        function newProject(this, source, eventdata )
            if ( this.closeProjectQuestdlg() )
               
                P.Path = this.arumeController.defaultDataFolder;
                P.Name = 'ProjectName';
                
                while(1)
                    
                    sDlg.Path = { {['uigetdir(''' P.Path ''')']} };
                    sDlg.Name = P.Name;
                    sDlg.Default_Experiment = {this.arumeController.possibleExperiments};
                    
                    P = StructDlg(sDlg, 'New project');
                    if ( isempty( P ) )
                        return
                    end
                    
                    if ( ~exist( P.Path, 'dir' ) )
                        uiwait(msgbox('The folder selected does not exist', 'Error', 'Modal'));
                        continue;
                    end
                    
                    if ( ~ArumeCore.Project.IsValidProjectName(P.Name) )
                        uiwait(msgbox('The project name is not valid (no spaces or special signs)', 'Error', 'Modal'));
                        continue;
                    end
                    
                    if ( exist( fullfile(P.Path, P.Name), 'dir') )
                        uiwait(msgbox('There is already a project with that name in that folder.', 'Error', 'Modal'));
                        continue;
                    end
                    
                    break;
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
                    pathname = uigetdir(this.arumeController.defaultDataFolder, 'Pick a project folder');
                    if ( isempty(pathname) || (isscalar(pathname) && (~pathname)) || ~exist(pathname,'dir')  )
                        return
                    end
                                        
                    if ( ~isempty(this.arumeController.currentProject) )
                        this.arumeController.currentProject.save();
                    end
                else % load a recent project
                    pathname = get(source,'Label');
                    if ( ~exist(pathname,'dir') )
                        msgbox('File does not exist');
                        return;
                    end
                end
                
                h=waitbar(0,'Please wait..');
                waitbar(1/2)
                this.arumeController.loadProject(pathname);
                waitbar(2/2)
                this.updateGui();
                close(h)
            end
            
        end
        
        function loadProjectBackup(this, source, eventdata )
            
            if ( this.closeProjectQuestdlg() )
                
                [filename, pathname] = uigetfile({'*.zip;*.aruprj', 'Arume backup files (*.zip, *.aruprj'}, 'Pick a project backup');
                if ( isempty(filename) )
                    return
                end
                
                backupFile = fullfile(pathname, filename);
                newParentPath = uigetdir(this.arumeController.defaultDataFolder, 'Pick the parent folder for the restored project');
                if ( ~newParentPath  )
                    return
                end
                
                if ( ~isempty(this.arumeController.currentProject) )
                    this.arumeController.currentProject.save();
                end
                
                h=waitbar(0,'Please wait..');
                waitbar(1/2)
                this.arumeController.loadProjectBackup(backupFile, newParentPath);
                waitbar(2/2)
                this.updateGui();
                close(h)
            end
            
        end
        
        function saveProjectBackup(this, source, eventdata )
            
            [filename, pathname] = uiputfile([this.arumeController.defaultDataFolder '/*.zip'], 'Pick a project backup');
            if ( isempty(filename) )
                return
            end
            
            backupFile = fullfile(pathname, filename);
            
            h=waitbar(0,'Please wait..');
            waitbar(1/2)
            this.arumeController.saveProjectBackup(backupFile);
            waitbar(2/2)
            this.updateGui();
            close(h)
            
        end
                
        function closeProject(this, source, eventdata )
            if ( this.closeProjectQuestdlg )
                this.arumeController.closeProject();
                this.updateGui();
            end
        end
        
        function newSession( this, source, eventdata ) 
            
            experiments = this.arumeController.possibleExperiments;
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
                
                if ( ~ArumeCore.Session.IsValidSubjectCode(session.Subject_Code) )
                    uiwait(msgbox('The subject code is not valid', 'Error', 'Modal'));
                    continue;
                end
                if ( ~ArumeCore.Session.IsValidSessionCode(session.Session_Code) )
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
            experiment = ArumeCore.ExperimentDesign.Create(session.Experiment);
            optionsDlg = experiment.GetExperimentOptionsDialog( );
            if ( ~isempty( optionsDlg) )
                options = StructDlg(optionsDlg, 'Edit experiment options');
                if ( isempty( options ) )
                    options = StructDlg(optionsDlg,'',[],[],'off');
                end
            else
                options = [];
            end
            
            this.arumeController.newSession( session.Experiment, session.Subject_Code, session.Session_Code, options );
            
            this.updateGui();
        end
        
        function importSession( this, source, eventdata )     
            
            experiments = this.arumeController.possibleExperiments;
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
                
                if ( ~ArumeCore.Session.IsValidSubjectCode(session.Subject_Code) )
                    uiwait(msgbox('The subject code is not valid', 'Error', 'Modal'));
                    continue;
                end
                if ( ~ArumeCore.Session.IsValidSessionCode(session.Session_Code) )
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
            experiment = ArumeCore.ExperimentDesign.Create(session.Experiment);
            optionsDlg = experiment.GetExperimentOptionsDialog( 1 );
            if ( ~isempty( optionsDlg) )
                options = StructDlg(optionsDlg, 'Edit experiment options');
                if ( isempty( options ) )
                    return;
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
                        if ( ~ArumeCore.Session.IsValidSubjectCode(newSubjectCodes{i}) || ~ArumeCore.Session.IsValidSessionCode(newSessionCodes{i}) )
                            allgood = 0;
                            break;
                        end
                        if ( strcmp(session.subjectCode, newSubjectCodes{i}) &&  strcmp(session.sessionCode, newSessionCodes{i}) )
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
                        if ( ~ArumeCore.Session.IsValidSubjectCode(newSubjectCodes{i}) || ~ArumeCore.Session.IsValidSessionCode(newSessionCodes{i}) )
                            allgood = 0;
                            break;
                        end
                        if ( streq(upper(session.subjectCode), upper(newSubjectCodes{i})) && streq(upper(session.sessionCode), upper(newSessionCodes{i})) )
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
                        if ( ~ArumeCore.Session.IsValidSubjectCode(newSubjectCodes{i}) || ~ArumeCore.Session.IsValidSessionCode(newSessionCodes{i}) )
                            allgood = 0;
                            break;
                        end
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
            experiment = ArumeCore.ExperimentDesign.Create(session.experiment.Name);
            optionsDlg = experiment.GetExperimentOptionsDialog( );
            if ( ~isempty( optionsDlg) )
                options = StructDlg(optionsDlg,'Edit experiment options',session.experiment.ExperimentOptions);
                if ( isempty( options ) )
                    return;
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
        
        function resumeSessionFrom( this, source, eventdata ) 
            
            choice = questdlg('Are you sure you want to resume from a past point?', ...
                'Closing', ...
                'Yes','No','No');
            switch choice
                case 'Yes'
                    pastRunNumber = regexp(source.Text, '\[(?<runNumber>\d+)\]', 'names');
                    pastRunNumber = str2double(pastRunNumber.runNumber);
                    
                    this.arumeController.resumeSessionFrom(pastRunNumber);
                    this.updateGui();
            end
        end
        
        function restartSession( this, source, eventdata ) 
            
            choice = questdlg('Are you sure you want to restart the sessions?', ...
                'Closing', ...
                'Yes','No','No');
            switch choice
                case 'Yes'
                    this.arumeController.restartSession();
                    this.updateGui();
            end
        end
        
        function PrepareAnalysis( this, source, eventdata ) 
            this.arumeController.prepareAnalysis();
            this.updateGui();
        end
        
        function Plot( this, source, eventdata )
            
            delete(get(this.menuPlotGeneratePlots,'children'));
            delete(get(this.menuPlotGeneratePlotsCombined,'children'));
            delete(get(this.menuPlotGeneratePlotsAggregated,'children'));
            
            
%             if ( ~isempty( this.arumeController.currentSession ) && this.arumeController.currentSession.isReadyForAnalysis)
            if ( ~isempty( this.arumeController.currentSession ) )
            
                plotsList = {};
                plotsListAgg = {};
                for session = this.arumeController.selectedSessions
                    if ( isempty (plotsList) )
                        plotsList = this.arumeController.GetPlotList();
                    else
                        plotsList =  intersect(plotsList, this.arumeController.GetPlotList());
                    end
                    if ( isempty (plotsListAgg) )
                        plotsListAgg = this.arumeController.GetAggregatePlotList();
                    else
                        plotsListAgg =  intersect(plotsListAgg, this.arumeController.GetAggregatePlotList());
                    end
                end
            else
                plotsList = {};
                plotsListAgg = {};
            end
            
            for i=1:length(plotsList)
                uimenu(this.menuPlotGeneratePlots, ...
                    'Label'     , plotsList{i}, ...
                    'Callback'  , @this.GeneratePlots);
                uimenu(this.menuPlotGeneratePlotsCombined, ...
                    'Label'     , plotsList{i}, ...
                    'Callback'  , @this.GeneratePlotsCombined);
            end
            
            for i=1:length(plotsListAgg)
                uimenu(this.menuPlotGeneratePlotsAggregated, ...
                    'Label'     , plotsListAgg{i}, ...
                    'Callback'  , @this.GeneratePlots);
            end
            
            
            % update plots listbox
        end
        
        function GeneratePlots( this, source, eventdata )
                        
            this.arumeController.generatePlots({source.Label}, 1);
            this.updateGui();
        end
        
        function GeneratePlotsCombined( this, source, eventdata ) 
            this.arumeController.generatePlots({source.Label}, 1);
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
        
        function SendToWorkspace( this, source, eventdata)
            
        end
    end
    
    methods(Access=public)
        function updateGui( this )
            if ( isempty( this.arumeController ))
                return;
            end
            
            % update top box info
            if ( ~isempty( this.arumeController.currentProject ) )
                set(this.projectTextLabel,              'String', ['Project: ' this.arumeController.currentProject.name] );
                set(this.pathTextLabel,                 'String', ['Path: ' this.arumeController.currentProject.path] );
                set(this.defaultExperimentTextLabel,    'String', ['Default experiment: ' this.arumeController.currentProject.defaultExperiment] );
            else
                set(this.projectTextLabel,              'String', 'Project: -' );
                set(this.pathTextLabel,                 'String', 'Path: -' );
                set(this.defaultExperimentTextLabel,    'String', 'Default experiment: -' );
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
                        row = '';
                        switch(optionClass)
                            case 'double'
                                if ( isscalar(dataTable{1,i}))
                                   row = sprintf('%-25s: %s\n', dataTable.Properties.VariableNames{i}, num2str(dataTable{1,i}));
                                end
                            case 'char'
                                fieldText = dataTable{1,i};
                                if ( length(fieldText) > 50 )
                                    fieldText = [fieldText(1:20) ' [...] ' fieldText(end-30:end)];
                                end
                                row = sprintf('%-25s: %s\n', dataTable.Properties.VariableNames{i}, fieldText);
                            case 'string'
                                fieldText = dataTable{1,i};
                                if ( length(fieldText) > 50 )
                                    fieldText = [fieldText(1:20) ' [...] ' fieldText(end-30:end)];
                                end
                                row = sprintf('%-25s: %s\n', dataTable.Properties.VariableNames{i}, fieldText);
                            case 'categorical'
                                row = sprintf('%-25s: %s\n', dataTable.Properties.VariableNames{i}, string(dataTable{1,i}));
                            case 'cell'
                                if ( length(size(dataTable{1,i}))<=2 && min(size(dataTable{1,i}))==1 && ischar(dataTable{1,i}{1}) && ~isempty(dataTable{1,i}) )
                                    for j=1:length(dataTable{1,i})
                                        fieldText = dataTable{1,i}{j};
                                        if ( length(fieldText) > 50 )
                                            fieldText = [fieldText(1:20) ' [...] ' fieldText(end-30:end)];
                                        end
                                        row = [row sprintf('%-25s: %s\n', [dataTable.Properties.VariableNames{i} num2str(j)], fieldText)];
                                    end
                                else
                                    row = sprintf('%-25s: %s\n', dataTable.Properties.VariableNames{i}, 'CELL');
                                end
                            otherwise
                                row = sprintf('%-25s: %s\n', dataTable.Properties.VariableNames{i}, '-');
                        end   
                         s = [s row];
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
                set(this.menuFileNewSession, 'Enable', 'on');
                
            else
                set(this.menuFileCloseProject, 'Enable', 'off');
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
            end
            
            % Update past runs
            
            delete(get(this.menuResumeSessionFrom,'children'));
            set(this.menuResumeSessionFrom, 'Enable', 'off');
            
            session = this.arumeController.currentSession;
            if (~isempty(session) )
                for i=length(session.pastRuns):-1:1
                    if ( ~isempty( session.pastRuns(i).pastTrialTable ) && ...
                            any(strcmp(session.pastRuns(i).pastTrialTable.Properties.VariableNames, 'TrialNumber')) && ...
                            any(strcmp(session.pastRuns(i).pastTrialTable.Properties.VariableNames, 'DateTimeTrialStart') ))
                        label = [];
                        try
                            label = sprintf('[%d] Trial %d interrupted on %s', i, session.pastRuns(i).pastTrialTable{end,'TrialNumber'},session.pastRuns(i).pastTrialTable{end,'DateTimeTrialStart'}{1});
                        end
                        if ( ~isempty(label) )
                            uimenu(this.menuResumeSessionFrom, ...
                                'Label'     , label, ...
                                'Callback'  , @this.resumeSessionFrom);
                            set(this.menuResumeSessionFrom, 'Enable', 'on');
                        end
                    end
                end
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

