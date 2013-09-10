classdef ArumeGui < handle
    %ARUMEGUI Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        projectTextLabel
        experimentTextLabel
        pathTextLabel
        
        sessionListBox
        
        logTextBox
        
        figureHandle
        
        topPanel
        leftPanel
        rightPanel
        bottomPanel
        
        menuProject
        menuProjectNewProject
        menuProjectLoadProject
        menuProjectSaveProject
        menuProjectCloseProject
        menuProjectExportProject
        
        menuSession
        menuSessionNewSession
        menuSessionRun
        menuSessionResume
        menuSessionRestart
        
        
        menuEdit
        menuTools
        menuhelp
        
        arume
        
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
                'Tag'       , 'Arume', ...
                'Visible'   , 'off', ...
                'Color'     ,defaultBackground,...
                'Name'      , 'Arume',...
                'NumberTitle', 'off',... % Do not show figure number
                'Position'  , [360,500,w,h], ...
                'CloseRequestFcn', @this.figureCloseRequest );
            
            %  Construct panels
            
            this.topPanel = uipanel ( ...
                'Parent'    , this.figureHandle,...
                'Title'     , '',...
                'Position'  , [.02 .76 .96 .2]);
            
            this.leftPanel = uipanel ( ...
                'Parent'    , this.figureHandle,...
                'Title'     , 'Sessions',...
                'Position'  , [.02 .24 .3 .5]);
            
            this.rightPanel = uipanel ( ...
                'Parent'    , this.figureHandle,...
                'Title'     , '',...
                'Position'  , [.34 .24 .64 .5]);
            
            this.bottomPanel = uipanel ( ...
                'Parent'    , this.figureHandle,... 
                'Title'     , '',...
                'Position'  , [.02 .02 .96 .2]);
                
            
            %  Construct the components
            this.projectTextLabel = uicontrol( ...
                'Parent'    , this.topPanel,...
                'Style'     , 'text',...
                'String'    , 'Project: ',...
                'HorizontalAlignment', 'left',...
                'Position'  , [10,75,500,15]);
            
            this.experimentTextLabel = uicontrol( ...
                'Parent'    , this.topPanel,...
                'Style'     , 'text',...
                'String'    , 'Experiment: ',...
                'HorizontalAlignment', 'left',...
                'Position'  , [10,55,500,15]);
            
            this.pathTextLabel = uicontrol( ...
                'Parent'    , this.topPanel,...
                'Style'     , 'text',...
                'String'    , 'Project: ',...
                'HorizontalAlignment', 'left',...
                'Position'  , [10,35,500,15]);
            
            this.sessionListBox = uicontrol( ...
                'Parent'    , this.leftPanel,...
                'Style'     , 'listbox',...
                'String'    , '',...
                'Units'     ,'normalized',...
                'Position'  , [0.02 0.02 0.96 0.96], ...
                'BackgroundColor'     , 'w', ...
                'Callback'  , @this.sessionListBoxCallBack);
            
            set(this.figureHandle,'MenuBar','none'); 
            
            this.menuProject = uimenu(this.figureHandle, ...
                'Label'     , 'File');
            
            this.menuProjectNewProject = uimenu(this.menuProject, ...
                'Label'     , 'New project ...', ...
                'Callback'  , @this.newProject);
            this.menuProjectLoadProject = uimenu(this.menuProject, ...
                'Label'     , 'Load project ...', ...
                'Callback'  , @this.loadProject);
            this.menuProjectSaveProject = uimenu(this.menuProject, ...
                'Label'     , 'Save project', ...
                'Callback'  , @this.saveProject);
            this.menuProjectCloseProject = uimenu(this.menuProject, ...
                'Label'     , 'Close project', ...
                'Callback'  , @this.closeProject);
            this.menuProjectExportProject = uimenu(this.menuProject, ...
                'Label'     , 'Export project ...', ...
                'Callback'  , @(varargin)msgbox('Not implemented'));
            
            this.menuSession = uimenu(this.figureHandle, ...
                'Label'     , 'Session');
            
            this.menuSessionNewSession = uimenu(this.menuSession, ...
                'Label'     , 'New session', ...
                'Callback'  , @this.sessionNewSession);
            this.menuSessionRun = uimenu(this.menuSession, ...
                'Label'     , 'Run ...', ...
                'Callback'  , @this.sessionRun);
            this.menuSessionResume = uimenu(this.menuSession, ...
                'Label'     , 'Resume', ...
                'Callback'  , @this.sessionResume);
            this.menuSessionRestart = uimenu(this.menuSession, ...
                'Label'     , 'Restart', ...
                'Callback'  , @this.sessionRestart);
            
            
            % Initialize the GUI.
            % Change units to normalized so components resize
            % automatically.
            set([ ...
                this.figureHandle, ...
                ],...
                'Units'     ,'normalized');

            
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
            if ( ~isempty ( this.arume.currentProject) )
                % Construct a questdlg with three options
                choice = questdlg('Are you sure?', ...
                    'Closing', ...
                    'Save project before closing','Close without saving project','Cancel','Cancel');
                
                % Handle response
                switch choice
                    case 'Save project before closing'
                        this.arume.saveProject();
                        delete(this.figureHandle)
                    case 'Close without saving project'
                        if ( ~this.closeProjectQuestdlg() )
                            return
                        end
                    case 'Cancel'
                        return
                end
                
            end
            delete(this.figureHandle)
        end
        
        function newProject(this, source, eventdata )
            if ( this.closeProjectQuestdlg() )
                sDlg.Experiment = { {'{torsion}' 'test'} };
                sDlg.Path = { {['uigetdir(''' this.arume.defaultDataFolder ''')']} };
                sDlg.Name = 'ProjectName';
                P = StructDlg(sDlg);
                if ( isempty( P ) )
                    return
                end
                this.arume.newProject( P.Experiment, P.Path, P.Name);
                this.updateGui();
            end
        end
        function loadProject(this, source, eventdata )
            if ( this.closeProjectQuestdlg() )
                [filename, pathname, filterindex] = uigetfile([this.arume.defaultDataFolder '\*.mat'], 'Pick a project file');
                if ( ~filename  )
                    return
                end
                this.arume.loadProject(pathname);
                this.updateGui();
            end
        end
        function saveProject(this, source, eventdata )
            this.arume.saveProject();
            this.updateGui();
        end
        function closeProject(this, source, eventdata )
            if ( this.closeProjectQuestdlg )
                this.arume.closeProject();
                this.updateGui();
            end
        end
        
        function sessionNewSession( this, source, eventdata ) 
            sDlg.Subject_Code = '000';
            sDlg.Session_Code = 'Z';
            P = StructDlg(sDlg);
            if ( isempty( P ) )
                return
            end
            this.arume.newSession( P.Subject_Code, P.Session_Code );
            this.updateGui();
        end
        function sessionRun( this, source, eventdata ) 
            this.arume.runSession();
            this.updateGui();
        end
        function sessionResume( this, source, eventdata ) 
            this.arume.resumeSession();
            this.updateGui();
        end
        function sessionRestart( this, source, eventdata ) 
            this.arume.restartSession();
            this.updateGui();
        end
        
        function sessionListBoxCallBack( this, source, eventdata )
            
            sessionListBoxCurrentValue = get(this.sessionListBox,'value');
            
            if ( sessionListBoxCurrentValue > 0 )
                this.arume.setCurrentSession( sessionListBoxCurrentValue );
                this.updateGui();
            end
            
        end

        
        function updateGui( this )
            % update top box info
            if ( ~isempty( this.arume.currentProject ) )
                set(this.projectTextLabel, 'String', ['Project: ' this.arume.currentProject.name] );
                set(this.experimentTextLabel, 'String', ['Experiment: ' this.arume.currentProject.experiment] );
                set(this.pathTextLabel, 'String', ['Path: ' this.arume.currentProject.path] );
            else
                set(this.projectTextLabel, 'String', ['Project: ' '-'] );
                set(this.experimentTextLabel, 'String', ['Experiment: ' '-'] );
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
                set(this.menuProjectSaveProject, 'Enable', 'on');
                set(this.menuProjectCloseProject, 'Enable', 'on');
                set(this.menuProjectExportProject, 'Enable', 'on');
                
                set(this.menuSessionNewSession, 'Enable', 'on');
                
            else
                set(this.menuProjectSaveProject, 'Enable', 'off');
                set(this.menuProjectCloseProject, 'Enable', 'off');
                set(this.menuProjectExportProject, 'Enable', 'off');
                
                set(this.menuSessionNewSession, 'Enable', 'off');
            end
            
            if ( ~isempty( this.arume.currentSession ) )
                if ( ~this.arume.currentSession.isStarted )
                    set(this.menuSessionRun, 'Enable', 'on');
                else
                    set(this.menuSessionRun, 'Enable', 'off');
                end
                if ( this.arume.currentSession.isStarted && ~this.arume.currentSession.isFinished )
                    set(this.menuSessionResume, 'Enable', 'on');
                    set(this.menuSessionRestart, 'Enable', 'on');
                else
                    set(this.menuSessionResume, 'Enable', 'off');
                    set(this.menuSessionRestart, 'Enable', 'off');
                end
                if ( this.arume.currentSession.isStarted  )
                    set(this.menuSessionRestart, 'Enable', 'on');
                else
                    set(this.menuSessionRestart, 'Enable', 'off');
                end
            else
                set(this.menuSessionRun, 'Enable', 'off');
                set(this.menuSessionResume, 'Enable', 'off');
                set(this.menuSessionRestart, 'Enable', 'off');
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
            choice = questdlg('Do you want to close the current project? all data will be lost', ...
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

