classdef ArumeGui < matlab.apps.AppBase
    %ARUMEGUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        
        % main controller
        arumeController     ArumeCore.ArumeController
        
        % figure handle
        figureHandle        matlab.ui.Figure
        
        % control handles
        sessionTree
        infoBox
        sessionTable
        trialTable
        commentsTextBox
        
        % panel handles
        leftPanel
        tabSessions
        rightPanel
        tabSessionInfo
        tabSessionTable
        tabTrialTable
        
        % Menu items
        menuProject
        menuProjectNewProject
        menuProjectLoadProject
        menuProjectSaveProjectBackup
        menuProjectLoadProjectBackup
        menuProjectLoadRecentProject
        menuProjectCloseProject
        
        menuSession
        menuSessionNewSession
        menuSessionImportSession
        menuSessionEditSettings
        menuSessionRename
        menuSessionDelete
        menuSessionCopy
        menuSessionSendDataToWorkspace
        
        menuRun
        menuRunStartSession
        menuRunResumeSession
        menuRunRestartSession
        menuResumeSessionFrom
        
        menuAnalyze
        menuAnalyzePrepare
        menuAnalyzeRunAnalyses
        
        menuPlot
        menuPlotGeneratePlots
        menuPlotGeneratePlotsCombined
        menuPlotGeneratePlotsAggregated
        
        menuTools
        menuToolsBiteBarGui
        menuToolsOpenProjectFolderInExplorer
        
    end
    
    %% Constructor
    methods
        function this = ArumeGui( arumeController )
            
            screenSize = get(groot,'ScreenSize');
            screenWidth = screenSize(3);
            screenHeight = screenSize(4);
            w = screenWidth*0.5;
            h = screenHeight*0.5;
            left = screenWidth/2-w/2;
            bottom = screenHeight/2-h/2;
            
            this.arumeController = arumeController;
            
            %  Construct the figure
            this.figureHandle = uifigure();
            this.figureHandle.Name              = 'Arume';
            this.figureHandle.Position          =  [left bottom w h];
            this.figureHandle.Tag               = 'Arume';
            this.figureHandle.CloseRequestFcn   = @this.figureCloseRequest;
            this.figureHandle.AutoResizeChildren = 'off';
            this.figureHandle.SizeChangedFcn    = @this.figureResizeFcn;
            this.figureHandle.UserData          = this;
            
            this.InitMenu();
            
            %  Construct panels
            
            this.leftPanel = uitabgroup(this.figureHandle);
            
            this.rightPanel = uitabgroup(this.figureHandle);
            this.figureResizeFcn();
            
            this.tabSessions = uitab(this.leftPanel);
            this.tabSessions.Title = 'Sessions';
            
            this.tabSessionInfo = uitab(this.rightPanel);
            this.tabSessionInfo.Title = 'Session info';
            
            this.tabSessionTable = uitab(this.rightPanel);
            this.tabSessionTable.Title = 'Session table';
            this.rightPanel.SelectionChangedFcn = @this.tabRightPanelCallBack;
            
            this.tabTrialTable = uitab(this.rightPanel);
            this.tabTrialTable.Title = 'Trial table';
            
            
            %  Construct the components
            this.sessionTree = uitree( this.tabSessions);
            this.sessionTree.Position =  [1 1 this.tabSessions.Position(3)-3 this.tabSessions.Position(4)-35];
            this.sessionTree.FontName = 'consolas';
            this.sessionTree.Multiselect = 'on';
            this.sessionTree.SelectionChangedFcn = @this.sessionListBoxCallBack;
            
            this.infoBox = uitextarea(this.tabSessionInfo);
            this.infoBox.FontName = 'consolas';
            this.infoBox.HorizontalAlignment = 'Left';
            this.infoBox.Editable = 'off';
            this.infoBox.Value = '';
            this.infoBox.Position = [1 this.tabSessionInfo.Position(4)/5+2 this.tabSessionInfo.Position(3)-3 this.tabSessionInfo.Position(4)*4/5-35];
            this.infoBox.BackgroundColor = 'w';
            
            this.sessionTable = uitable(this.tabSessionTable);
            this.sessionTable.Position = [1 1 this.tabSessionInfo.Position(3)-3 this.tabSessionInfo.Position(4)-35];
            
            this.trialTable = uitable(this.tabTrialTable);
            this.trialTable.Position = [1 1 this.tabSessionInfo.Position(3)-3 this.tabSessionInfo.Position(4)-35];
            
            
            this.commentsTextBox = 	uitextarea(this.tabSessionInfo);
            this.commentsTextBox.FontName = 'consolas';
            this.commentsTextBox.HorizontalAlignment = 'Left';
            this.commentsTextBox.Value = 'Session notes:';
            this.commentsTextBox.Editable = 'on';
            this.commentsTextBox.BackgroundColor = [1 1 0.8];
            this.commentsTextBox.ValueChangedFcn = @this.commentsTextBoxCallBack;
            this.commentsTextBox.Position = [1 1 this.tabSessionInfo.Position(3)-3 this.tabSessionInfo.Position(4)*1/5];
            
            % This is to avoid a close all closing the GUI
            set(this.figureHandle, 'handlevisibility', 'off');
            
            this.updateGui();
            
            
            % Register the app with App Designer
            registerApp(this, this.figureHandle)
            
            if nargout == 0
                clear this
            end
        end
        
        function InitMenu(this)
            
            % menu
            set(this.figureHandle,'MenuBar','none');
            
            this.menuProject = uimenu(this.figureHandle);
            this.menuProject.Text = 'Project';
            this.menuProject.Callback = @this.menuProjectCallback;
            
            this.menuProjectNewProject = uimenu(this.menuProject);
            this.menuProjectNewProject.Text = 'New project ...';
            this.menuProjectNewProject.Callback = @this.newProject;
            
            this.menuProjectLoadProject = uimenu(this.menuProject);
            this.menuProjectLoadProject.Text = 'Load project ...';
            this.menuProjectLoadProject.Callback = @this.loadProject;
            
            this.menuProjectLoadRecentProject = uimenu(this.menuProject);
            this.menuProjectLoadRecentProject.Text = 'Load recent project';
            
            this.menuProjectCloseProject = uimenu(this.menuProject);
            this.menuProjectCloseProject.Text = 'Close project';
            this.menuProjectCloseProject.Callback =  @this.closeProject;
            
            this.menuProjectSaveProjectBackup = uimenu(this.menuProject);
            this.menuProjectSaveProjectBackup.Text = 'Backup project ...';
            this.menuProjectSaveProjectBackup.Separator = 'on';
            this.menuProjectSaveProjectBackup.Callback = @this.saveProjectBackup;
            
            this.menuProjectLoadProjectBackup = uimenu(this.menuProject);
            this.menuProjectLoadProjectBackup.Text = 'Restore project backup ...';
            this.menuProjectLoadProjectBackup.Callback = @this.loadProjectBackup;
            
            
            this.menuSession = uimenu(this.figureHandle);
            this.menuSession.Text = 'Session';
            
            this.menuSessionNewSession = uimenu(this.menuSession);
            this.menuSessionNewSession.Text = 'New session';
            this.menuSessionNewSession.Callback = @this.newSession;
            
            this.menuSessionImportSession = uimenu(this.menuSession);
            this.menuSessionImportSession.Text = 'Import session';
            this.menuSessionImportSession.Callback =  @this.importSession;
                        
            this.menuSessionCopy = uimenu(this.menuSession);
            this.menuSessionCopy.Label = 'Copy sessions ...';
            this.menuSessionCopy.Callback = @this.CopySessions;
            this.menuSessionCopy.Separator = 'on';
            
            this.menuSessionDelete = uimenu(this.menuSession);
            this.menuSessionDelete.Label = 'Delete sessions ...';
            this.menuSessionDelete.Callback = @this.DeleteSessions;
            
            this.menuSessionRename = uimenu(this.menuSession);
            this.menuSessionRename.Label = 'Rename sessions ...';
            this.menuSessionRename.Callback = @this.RenameSessions;
            
            this.menuSessionEditSettings = uimenu(this.menuSession);
            this.menuSessionEditSettings.Label = 'Edit settings ...';
            this.menuSessionEditSettings.Callback = @this.EditSessionSettings;
            
            this.menuSessionSendDataToWorkspace = uimenu(this.menuSession);
            this.menuSessionSendDataToWorkspace.Label = 'Send data to workspace ...';
            this.menuSessionSendDataToWorkspace.Callback = @this.SendDataToWorkspace;
            
            
            this.menuRun = uimenu(this.figureHandle);
            this.menuRun.Text = 'Run';
            
            this.menuRunStartSession = uimenu(this.menuRun);
            this.menuRunStartSession.Text = 'Start session...';
            this.menuRunStartSession.Callback = @this.startSession;
            
            this.menuRunResumeSession = uimenu(this.menuRun);
            this.menuRunResumeSession.Text = 'Resume session';
            this.menuRunResumeSession.Callback = @this.resumeSession;
            
            this.menuRunRestartSession = uimenu(this.menuRun);
            this.menuRunRestartSession.Text = 'Restart session';
            this.menuRunRestartSession.Callback = @this.restartSession;
            
            this.menuResumeSessionFrom = uimenu(this.menuRun);
            this.menuResumeSessionFrom.Text = 'Resume session from ...';
            this.menuResumeSessionFrom.Separator = 'on' ;
            
            
            this.menuAnalyze = uimenu(this.figureHandle);
            this.menuAnalyze.Text = 'Analyze';
            
            this.menuAnalyzePrepare = uimenu(this.menuAnalyze);
            this.menuAnalyzePrepare.Text = 'Prepare ...';
            this.menuAnalyzePrepare.Callback = @this.PrepareAnalysis;
            
            this.menuAnalyzeRunAnalyses = uimenu(this.menuAnalyze);
            this.menuAnalyzeRunAnalyses.Text = 'Run data analyses ...';
            this.menuAnalyzeRunAnalyses.Callback = @this.RunDataAnalyses;
            
            
            this.menuPlot = uimenu(this.figureHandle);
            this.menuPlot.Text = 'Plot';
            this.menuPlot.Callback = @this.Plot;
            
            this.menuPlotGeneratePlots = uimenu(this.menuPlot);
            this.menuPlotGeneratePlots.Text = 'Generate plots';
            
            this.menuPlotGeneratePlotsCombined = uimenu(this.menuPlot);
            this.menuPlotGeneratePlotsCombined.Text = 'Generate plots combined';
            
            this.menuPlotGeneratePlotsAggregated = uimenu(this.menuPlot);
            this.menuPlotGeneratePlotsAggregated.Text = 'Generate plots aggregated';
            
            this.menuTools = uimenu(this.figureHandle);
            this.menuTools.Text = 'Tools';
            
            this.menuToolsBiteBarGui = uimenu(this.menuTools);
            this.menuToolsBiteBarGui.Text = 'Bite bar GUI';
            this.menuToolsBiteBarGui.Callback = @BitebarGUI;
            
            this.menuToolsOpenProjectFolderInExplorer = uimenu(this.menuTools);
            this.menuToolsOpenProjectFolderInExplorer.Text = 'Open project folder in explorer...';
            this.menuToolsOpenProjectFolderInExplorer.Callback = @this.OpenProjectFolderInExplorer;
        end
    end
    
    
    %%  Callbacks
    methods
        
        function figureCloseRequest( this, source, eventdata )
            if ( this.closeProjectQuestdlg( ) )
                if ( ~isempty(this.arumeController) && ~isempty( this.arumeController.currentProject) )
                    this.arumeController.currentProject.save();
                end
                delete(this.figureHandle)
                Arume('clear');
            end
        end
        
        function figureResizeFcn( this, source, eventdata )
            figurePosition = this.figureHandle.Position;
            
            %             this.figureHandle.Position = [this.figureHandle.Position(1:3) max(this.figureHandle.Position(4),600)];
            w = figurePosition(3);  % figure width
            h = figurePosition(4);  % figure height
            h = h;
            
            m = 2;      % margin between panels
            lw = 300;   % left panel width
            
            this.leftPanel.Position = [1 1 lw h-2];
            this.rightPanel.Position = [lw+3 1 (w-lw-4) h-2];
        end
        
        function menuProjectCallback( this, source, eventdata )
            
            % Clean up and refill the recent projects menu
            
            delete(get(this.menuProjectLoadRecentProject,'children'));
            
            for i=1:length(this.arumeController.recentProjects)
                uimenu(this.menuProjectLoadRecentProject, ...
                    'Text'     , this.arumeController.recentProjects{i}, ...
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
                
                this.arumeController.newProject( P.Path, P.Name);
                this.updateGui();
            end
        end
        
        function loadProject(this, source, eventdata )
            
            if ( this.closeProjectQuestdlg() )
                
                if ( this.menuProjectLoadProject == source )    
                    pathname = uigetdir(this.arumeController.defaultDataFolder, 'Pick a project folder');
                else % load a recent project
                    pathname = get(source,'Label');
                end
                
                if ( isempty(pathname) || (isscalar(pathname) && (~pathname)) || ~exist(pathname,'dir')  )
                    msgbox('File does not exist');
                    return
                end
                
                h = waitbar(0,'Please wait..');
                
                waitbar(1/3)
                if ( ~isempty(this.arumeController.currentProject) )
                    this.arumeController.currentProject.save();
                    this.arumeController.closeProject();
                end
                
                waitbar(2/3)
                this.arumeController.loadProject(pathname);
                waitbar(3/3)
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
            
            file = fullfile(this.arumeController.defaultDataFolder, [this.arumeController.currentProject.name '-backup-'  datestr(now,'yyyy-mm-dd') '.zip']);
            
            [filename, pathname] = uiputfile(file, 'Pick a project backup');
            if ( isempty(filename) || ( isscalar(filename) && filename == 0) )
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
            if (~isempty(this.arumeController.currentProject.sessions) )
                lastExperiment = this.arumeController.currentProject.sessions(end).experimentDesign.Name;
            else
                lastExperiment = experiments{1};
            end
            
            session.Experiment = lastExperiment;
            session.Subject_Code = '000';
            session.Session_Code = 'Z';
            
            while(1)
                sessionDlg.Experiment = {experiments};
                sessionDlg.Experiment{1}{strcmp(experiments,lastExperiment)} = ['{'  lastExperiment '}'];
                
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
                if ( isempty(this.arumeController.currentProject.findSession( session.Subject_Code, session.Session_Code)))
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
            if (~isempty(this.arumeController.currentProject.sessions) )
                lastExperiment = this.arumeController.currentProject.sessions(end).experimentDesign.Name;
            else
                lastExperiment = experiments{1};
            end
            
            session.Experiment = lastExperiment;
            session.Subject_Code = '000';
            session.Session_Code = 'Z';
            
            while(1)
                sessionDlg.Experiment = {experiments};
                sessionDlg.Experiment{1}{strcmp(experiments,lastExperiment)} = ['{'  lastExperiment '}'];
                
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
                if ( isempty(this.arumeController.currentProject.findSession( session.Subject_Code, session.Session_Code)))
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
                
        function [newSubjectCodes, newSessionCodes] = DlgNewSubjectAndSessionCodes(this)
            
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
                    newSubjectCodes = {};
                    newSessionCodes = {};
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
        end
        
        function CopySessions( this, source, eventdata )
            
            [newSubjectCodes, newSessionCodes] = this.DlgNewSubjectAndSessionCodes();
            
            if ( ~isempty( newSubjectCodes ) )
                this.arumeController.copySelectedSessions(newSubjectCodes, newSessionCodes);
                this.updateGui();
            end
        end
        
        function RenameSessions( this, source, eventdata )
            
            sessions = this.arumeController.selectedSessions;
            
            [newSubjectCodes, newSessionCodes] = this.DlgNewSubjectAndSessionCodes();
            
            if ( ~isempty( newSubjectCodes ) )
                for i=1:length(sessions)
                    this.arumeController.renameSession(sessions(i), newSubjectCodes{i}, newSessionCodes{i});
                end
                this.updateGui();
            end
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
        
        function EditSessionSettings(this, source, eventdata )
            
            session = this.arumeController.currentSession;
            
            if ( session.isStarted )
                msgbox('This is session is already started, cannot change settings.');
                return;
            end
            
            % Show the dialog for experiment options if necessary
            experiment = ArumeCore.ExperimentDesign.Create(session.experimentDesign.Name);
            optionsDlg = experiment.GetExperimentOptionsDialog( );
            if ( ~isempty( optionsDlg) )
                options = StructDlg(optionsDlg,'Edit experiment options',session.experimentDesign.ExperimentOptions);
                if ( isempty( options ) )
                    return;
                end
            else
                options = [];
            end
            
            session.updateExperimentOptions( options );
            
            this.updateGui();
        end
        
        function SendDataToWorkspace( this, source, eventdata )
            if (~isempty(this.arumeController.currentSession))
                TrialDataTable = this.arumeController.currentSession.trialDataTable;
                SamplesDataTable = this.arumeController.currentSession.samplesDataTable;
                ProjectDataTable = this.arumeController.currentProject.GetDataTable();
                analysisResults = this.arumeController.currentSession.analysisResults;
                
                assignin('base','TrialDataTable',TrialDataTable);
                assignin('base','SamplesDataTable',SamplesDataTable);
                assignin('base','AnalysisResults',analysisResults);
                assignin('base','ProjectDataTable',ProjectDataTable);
            end
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
        
        function RunDataAnalyses( this, source, eventdata )
            optionsDlg = this.arumeController.getAnalysisOptions( );
            if ( ~isempty( optionsDlg) )
                options = StructDlg(optionsDlg, 'Edit analysis options');
                if ( isempty( options ) )
                    return;
                end
            else
                options = [];
            end
            
            this.arumeController.runDataAnalyses(options);
            this.updateGui();
        end
        
        function Plot( this, source, eventdata )
            
            delete(get(this.menuPlotGeneratePlots,'children'));
            delete(get(this.menuPlotGeneratePlotsCombined,'children'));
            delete(get(this.menuPlotGeneratePlotsAggregated,'children'));
            
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
            this.arumeController.generatePlots({source.Label}, 1,1);
            this.updateGui();
        end
        
        function OpenProjectFolderInExplorer( this, source, eventdata )
            if ( ~isempty(this.arumeController.currentProject))
                winopen(this.arumeController.currentProject.path)
            end
        end
        
        function sessionListBoxCallBack( this, source, eventdata )
            
            % first if there are subject nodes selected select all the
            % sessions
            shouldSelect = [];
            for i =1:length( eventdata.SelectedNodes)
                node = eventdata.SelectedNodes(i);
                if ( isempty(node.NodeData) )
                    shouldSelect = cat(1,shouldSelect, node.Children);
                end
            end
            this.sessionTree.SelectedNodes = unique(cat(1,this.sessionTree.SelectedNodes,shouldSelect));
            
            
            nodes = this.sessionTree.SelectedNodes;
            sessionListBoxCurrentValue = nan(length(nodes),1);
            for i =1:length( nodes)
                node = nodes(i);
                if ( ~isempty(node.NodeData) )
                    [~,j] = this.arumeController.currentProject.findSessionByIDNumber( node.NodeData );
                    sessionListBoxCurrentValue(i) = j;
                end
            end
            sessionListBoxCurrentValue(isnan(sessionListBoxCurrentValue)) = [];
            
            if ( sessionListBoxCurrentValue > 0 )
                this.arumeController.setCurrentSession( sessionListBoxCurrentValue );
            else
                this.arumeController.setCurrentSession( [] );
            end
            this.updateGui(1);
        end
        
        function commentsTextBoxCallBack( this, source, eventdata )
            this.arumeController.currentSession.updateComment(this.commentsTextBox.Value);
        end
        
        
        function tabRightPanelCallBack(this, source, eventdata )
            switch(eventdata.NewValue.Title)
                case 'Session table'
                    if ( ~isempty( this.arumeController.currentProject ) )
                        this.sessionTable.Data = this.arumeController.currentProject.sessionsTable;
                    end
                case 'Trial table'
                    if ( ~isempty( this.arumeController.currentSession) && ~isempty(this.arumeController.currentSession.currentRun))
                        this.trialTable.Data = this.arumeController.currentSession.currentRun.pastTrialTable;
                    end
            end
        end
        
    end
    
    methods(Access=public)
        
        function updateSessionTree(this)
            % update session listbox
            if ( ~isempty( this.arumeController.currentProject ) && ~isempty(this.arumeController.currentProject.sessions) )
                
                % delete sessions that do not exist anymore and updte text
                % of existing ones
                for iSubj = length(this.sessionTree.Children):-1:1
                    subjNode = this.sessionTree.Children(iSubj);
                    for iSess = length(subjNode.Children):-1:1
                        sessNode = subjNode.Children(iSess);
                        session = this.arumeController.currentProject.findSessionByIDNumber( sessNode.NodeData );
                        if ( isempty( session ) )
                            delete(sessNode);
                        else
                            sessNode.Text = session.sessionCode;
                        end
                    end
                    
                    % if the subject does not have children (sessions) delete it too
                    if ( isempty(subjNode.Children) )
                        delete(subjNode);
                    end
                end
                
                % add nodes for new sessions. Add subject node if necessary
                for i=1:length(this.arumeController.currentProject.sessions)
                    foundSession = 0;
                    foundSubject = 0;
                    session = this.arumeController.currentProject.sessions(i);
                    for iSubj = length(this.sessionTree.Children):-1:1
                        subjNode = this.sessionTree.Children(iSubj);
                        if ( strcmp(subjNode.Text, session.subjectCode ) )
                            foundSubject = iSubj;
                            for iSess = length(subjNode.Children):-1:1
                                sessNode = subjNode.Children(iSess);
                                if (sessNode.NodeData == session.sessionIDNumber)
                                    foundSession = 1;
                                    break;
                                end
                            end
                            break;
                        end
                    end
                    
                    if ( ~foundSession )
                        if ( foundSubject > 0 )
                            newSubjNode = this.sessionTree.Children(foundSubject);
                        else
                            newSubjNode = uitreenode(this.sessionTree);
                            newSubjNode.Text = session.subjectCode;
                            
                            % move to keep alphabetical sorting
                            for iSubj = 1:length(this.sessionTree.Children)
                                subjNode = this.sessionTree.Children(iSubj);
                                [~,j] = sort(upper({subjNode.Text, newSubjNode.Text}));
                                if ( j(1) > 1 )
                                    move(newSubjNode, subjNode, 'before');
                                    break;
                                end
                            end
                        end
                        
                        newSessNode = uitreenode(newSubjNode);
                        newSessNode.Text = session.sessionCode;
                        newSessNode.NodeData = session.sessionIDNumber;
                        
                        % move to keep alphabetical sorting
                        for iSess = 1:length(newSubjNode.Children)
                            sessNode = newSubjNode.Children(iSess);
                            [~,j] = sort(upper({sessNode.Text, newSessNode.Text}) );
                            if ( j(1) > 1 )
                                move(newSessNode, sessNode, 'before');
                                break;
                            end
                        end
                    end
                end
                
                % find the nodes corresponding with the selected sessions
                nodes = [];
                for i=1:length(this.arumeController.selectedSessions)
                    session = this.arumeController.selectedSessions(i);
                    for iSubj = length(this.sessionTree.Children):-1:1
                        subjNode = this.sessionTree.Children(iSubj);
                        if ( strcmp(subjNode.Text, session.subjectCode ) )
                            for iSess = length(subjNode.Children):-1:1
                                sessNode = subjNode.Children(iSess);
                                if (sessNode.NodeData == session.sessionIDNumber)
                                    nodes = cat(1,nodes, sessNode);
                                end
                                expand(subjNode);
                            end
                        end
                    end
                end
                this.sessionTree.SelectedNodes = nodes;
            else
                delete(this.sessionTree.Children);
                this.sessionTree.SelectedNodes = [];
            end
        end
        
        function updateGui( this, fastOption )
            if ( ~exist('fastOption','var') )
                fastOption = 0;
            end
            
            if ( isempty( this.arumeController ))
                return;
            end
            
            % update top box info
            if ( ~isempty( this.arumeController.currentProject ) )
                this.figureHandle.Name = sprintf('Arume - Project: %s', this.arumeController.currentProject.path);
            else
                this.figureHandle.Name = sprintf('Arume');
            end
            
            if ( ~fastOption )
                this.updateSessionTree();
            end
            
            % update info box
            if ( ~isempty( this.arumeController.currentSession ) && length(this.arumeController.selectedSessions)==1 )
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
                            fieldText = char(dataTable{1,i});
                            if ( length(fieldText) > 50 )
                                fieldText = [fieldText(1:20) ' [...] ' fieldText(end-30:end)];
                            end
                            row = sprintf('%-25s: %s\n', dataTable.Properties.VariableNames{i}, fieldText);
                        case 'categorical'
                            row = sprintf('%-25s: %s\n', dataTable.Properties.VariableNames{i}, string(dataTable{1,i}));
                        case 'cell'
                            if ( length(size(dataTable{1,i}))<=2 && min(size(dataTable{1,i}))==1 && ischar(dataTable{1,i}{1}) && ~isempty(dataTable{1,i}) )
                                for j=1:length(dataTable{1,i})
                                    fieldText = char(dataTable{1,i}{j});
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
                
                
                this.infoBox.Value = s;
            elseif ( length(this.arumeController.selectedSessions) > 1 )
                sessions = this.arumeController.selectedSessions;
                sessionNames = cell(length(sessions),1);
                for i=1:length(sessions)
                    sessionNames{i} = [sessions(i).subjectCode ' __ ' sessions(i).sessionCode];
                end
                sessionNames = strcat(sessionNames,'\n');
                sessionNames = horzcat(sessionNames{:});
                this.infoBox.Value = sprintf(['\nSelected sessions: \n\n' sessionNames]);
            else
                this.infoBox.Value = '';
            end
            
            % update comments text box
            if ( ~isempty( this.arumeController.currentSession ) )
                this.commentsTextBox.Enable = 'on';
                this.commentsTextBox.Value = this.arumeController.currentSession.comment;
            else
                this.commentsTextBox.Enable = 'off';
                this.commentsTextBox.Value = '';
            end
            
            % update menu
            
            % top level menus
            if ( ~isempty( this.arumeController.currentSession ) )
                this.menuAnalyze.Enable = 'on';
                this.menuPlot.Enable = 'on';
                if ( isscalar( this.arumeController.selectedSessions ) )
                    this.menuRun.Enable = 'on';
                else
                    this.menuRun.Enable = 'off';
                end
            else
                this.menuRun.Enable = 'off';
                this.menuAnalyze.Enable = 'off';
                this.menuPlot.Enable = 'off';
            end
            
            
            % sub menus
            
            if ( ~isempty( this.arumeController.currentProject ) )
                set(this.menuProjectCloseProject, 'Enable', 'on');
                set(this.menuProjectSaveProjectBackup, 'Enable', 'on');
                set(this.menuSession, 'Enable', 'on');
                set(this.menuSessionNewSession, 'Enable', 'on');
                
            else
                set(this.menuProjectCloseProject, 'Enable', 'off');
                set(this.menuProjectSaveProjectBackup, 'Enable', 'off');
                set(this.menuSession, 'Enable', 'off');
                set(this.menuSessionNewSession, 'Enable', 'off');
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
                
                set(this.menuSessionDelete, 'Enable', 'on');
                set(this.menuSessionRename, 'Enable', 'on');
            else
                
                set(this.menuRunStartSession, 'Enable', 'off');
                set(this.menuRunResumeSession, 'Enable', 'off');
                set(this.menuRunRestartSession, 'Enable', 'off');
                
                set(this.menuSessionDelete, 'Enable', 'off');
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
            
            switch(this.rightPanel.SelectedTab.Title)
                case 'Session table'
                    if ( ~isempty( this.arumeController.currentProject ) )
                        this.sessionTable.Data = this.arumeController.currentProject.sessionsTable;
                    end
                case 'Trial table'
                    if ( ~isempty( this.arumeController.currentSession) && ~isempty(this.arumeController.currentSession.currentRun))
                        this.trialTable.Data = this.arumeController.currentSession.currentRun.pastTrialTable;
                    end
            end
        end
    end
    
    
    %%  Utility functions
    methods
        function result = closeProjectQuestdlg( this )
            result = 0;
            if (isempty(this.arumeController) || isempty( this.arumeController.currentProject) )
                result = 1;
                return
            end
            choice = questdlg('Do you want to close the current project?', ...
                'Closing', ...
                'Yes','No','No');
            
            switch choice
                case 'Yes'
                    choice2 = questdlg('Do you want backup the project?', ...
                        'Closing', ...
                        'Yes','No','No');
                    switch choice2
                        case 'Yes'
                            this.saveProjectBackup();
                        case 'No'
                    end
                    result = 1;
                case 'No'
                    result = 0;
            end
        end
    end
    
end

