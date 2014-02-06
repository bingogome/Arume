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
        menuAnalyzeRunAnalysis
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
            
            
            w = 800;
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
                'String'    , '',...
                'Units'     ,'normalized',...
                'Position'  , [0.02 0.02 0.96 0.96], ...
                'BackgroundColor'     , 'w', ...
                'Callback'  , @this.sessionListBoxCallBack);
            
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
                'Callback'  , @(varargin)msgbox('Not implemented'));
            
            
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
                'Label'     , 'Prepare...', ...
                'Callback'  , @this.PrepareAnalysis);
            
            this.menuAnalyzeRunAnalysis = uimenu(this.menuAnalyze, ...
                'Label'     , 'Resume session', ...
                'Callback'  , @this.RunAnalysis);
            
            % Move the GUI to the center of the screen.
            movegui(this.figureHandle,'center')
            
            % Make the GUI visible.
            set(this.figureHandle,'Visible','on');
            
            this.updateGui();
        end
    end
    
    %%  Callbacks 
    methods 
        
        function figureCloseRequest( this, source, eventdata )
            if ( this.closeProjectQuestdlg( ) )
                delete(this.figureHandle)
            end
        end
        
        function figureResizeFcn( this, source, eventdata )
            figurePosition = get(this.figureHandle,'position');
            w = figurePosition(3);  % figure width
            h = figurePosition(4);  % figure height
            
            m = 5;      % margin between panels
            th = 60;    % top panel height
            bh = 60;    % bottom panel height
            lw = 200;   % left panel width            
            
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
                P = StructDlg(sDlg);
                if ( isempty( P ) )
                    return
                end
                this.arume.newProject( P.Path, P.Name);
                this.updateGui();
            end
        end
        
        function loadProject(this, source, eventdata )
            if ( this.closeProjectQuestdlg() )
                [filename, pathname] = uigetfile([this.arume.defaultDataFolder '\*.mat'], 'Pick a project file');
                if ( ~filename  )
                    return
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
            sDlg.Experiment = { {'{torsion}' 'test'} };
            sDlg.Subject_Code = '000';
            sDlg.Session_Code = 'Z';
            P = StructDlg(sDlg);
            if ( isempty( P ) )
                return
            end
            this.arume.newSession( P.Experiment, P.Subject_Code, P.Session_Code );
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
        
        function RunAnalysis( this, source, eventdata ) 
            this.arume.runAnalysis();
            this.updateGui();
        end
        
        
        function sessionListBoxCallBack( this, source, eventdata )
            
            sessionListBoxCurrentValue = get(this.sessionListBox,'value');
            
            if ( sessionListBoxCurrentValue > 0 )
                this.arume.setCurrentSession( sessionListBoxCurrentValue );
                this.updateGui();
            end
            
        end
    end
    
    methods
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
                sessionListBoxCurrentValue = get(this.sessionListBox,'value');
                
                sessionNames = cell(length(this.arume.currentProject.sessions),1);
                for i=1:length( this.arume.currentProject.sessions )
                    sessionNames{i} = this.arume.currentProject.sessions(i).name;
                end
                set(this.sessionListBox, 'String', sessionNames);
                if ( sessionListBoxCurrentValue > 0 )
                    set(this.sessionListBox, 'Value', sessionListBoxCurrentValue )
                else
                    set(this.sessionListBox, 'Value', 1 )
                end
            else
                set(this.sessionListBox, 'String', {});
                set(this.sessionListBox, 'Value', 0 )
            end
                
            % update menu 
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
                set(this.experimentTextLabel, 'String', ['Experiment: ' this.arume.currentSession.experiment] );
                
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
                if ( this.arume.currentSession.isStarted  )
                    set(this.menuRunRestartSession, 'Enable', 'on');
                else
                    set(this.menuRunRestartSession, 'Enable', 'off');
                end
            else
                set(this.experimentTextLabel, 'String', ['Experiment: ' '-'] );
                
                set(this.menuRunStartSession, 'Enable', 'off');
                set(this.menuRunResumeSession, 'Enable', 'off');
                set(this.menuRunRestartSession, 'Enable', 'off');
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

