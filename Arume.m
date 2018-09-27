classdef Arume < handle
    % ARUME Is a GUI to control experiments and analyze their results.
    %
    %   Usage   : Arume, opens Arume GUI.
    %           : Arume( 'open', 'C:\path\to\project' ), opens a given project
    %
    % A project in Arume consists on multiple experimental SESSIONS and the
    % results ana analyses associted with them.
    %
    % A session is asociated with a given experimental paradigm selected
    % when the session is created.
    %
    % A session can be restarted, paused and resumed. Every time a new
    % experiment run is created containing the data related to each run.
    % That is, if you run the experiment, almost finish and the restart
    % over. All the data will be saved. For the first partial run and for
    % the second complete run.
    %
    % A project can have sessions of different paradigms but a session will
    % have runs of one individual paradigm.
    %
    % The projects can be managed with the GUI but also with command line.
    
    properties( Constant=true )
        AnalysisMethodPrefix = 'Analysis_';
        PlotsMethodPrefix = 'Plot_';
        PlotsAggregateMethodPrefix = 'PlotAggregate_';
    end
    
    properties( Access=private )
        configuration       % Configuration options saved into a mat file in the Arume folder
    end
    
    properties
        gui                 % Current gui associated with the controller
        possibleExperiments % List of possible experiments
    end
    
    properties( SetAccess=private )
        currentProject      % Current working project
        selectedSessions    % Current selected sessions (if multiple selected enabled)
    end
    
    properties(Dependent=true)
        currentSession      % Current selected session (empty if none)
        
        defaultDataFolder   % Default data folder for new projects
        recentProjects      % List of recent projects
    end
    
    methods
        function session = get.currentSession( this )
            if ( length(this.selectedSessions) >= 1 )
                session = this.selectedSessions(end);
            else
                session = [];
            end
        end
        
        function defaultDataFolder = get.defaultDataFolder( this )
            if (~isempty(this.configuration) && isfield( this.configuration, 'defaultDataFolder' ) )
                defaultDataFolder = this.configuration.defaultDataFolder;
            else
                defaultDataFolder = '';
            end
        end
        
        function recentProjects = get.recentProjects( this )
            if (~isempty(this.configuration) && isfield( this.configuration, 'recentProjects' ) )
                recentProjects = this.configuration.recentProjects(~contains(this.configuration.recentProjects','.aruprj'));
                
            else
                recentProjects = '';
            end
        end
    end
    
    methods( Access=public )
        
        %
        % Main constructor
        %
        
        function arumeController = Arume(command, param)
            
            % Persistent variable to keep the singleton to make sure there is only one
            % arume controller loaded at any point in time. That way we can open the UI
            % and then also call arume in the command line to get a reference to the
            % controller and write scripts working with the current project.
            persistent arumeSingleton;
            
            if ( isempty( arumeSingleton ) )
                % The persistent variable gets deleted with clear all. However,
                % variables within the UI do not until UI is closed. So, we can search
                % for the handle of the UI window and get the controller from there.
                % This way we avoid problems if clear all is called with the UI open
                % and then Arume is called again.
                h = findall(0,'tag','Arume');
                if ( ~isempty(h) )
                    arumeSingleton = h.UserData.arumeController;
                end
            end
            
            
            useGui = 1;
            
            % option to clear the singleton
            if ( exist('command','var') )
                switch (command )
                    case 'open'
                        if ( exist('param','var') )
                            projectPath = param;
                        end
                        
                    case 'nogui'
                        if ( exist('param','var') )
                            projectPath = param;
                        end
                        useGui = 0;
                end
            end
            
            if isempty(arumeSingleton)
                % Initialization, object is created automatically
                % (this is the constructor) and then initialized
                
                arumeSingleton = arumeController;
                arumeSingleton.init();
            end
            
            if ( exist('projectPath','var') )
                arumeSingleton.loadProject( projectPath );
            end
            
            if ( useGui )
                if ( isempty(arumeSingleton.gui) || ~arumeSingleton.gui.isvalid)
                    % Load the GUI
                    arumeSingleton.gui = ArumeCore.ArumeGui( arumeSingleton );
                end
                % make sure the Arume gui is on the front and update
                figure(arumeSingleton.gui.figureHandle)
                arumeSingleton.gui.updateGui();
            end
            
            arumeController = arumeSingleton;
            
        end
        
        function init( this)
            % find the folder of arume
            [folder, name, ext] = fileparts(which('Arume'));
            
            % find the configuration file
            if ( ~exist(fullfile(folder,'arumeconf.mat'),'file'))
                conf = [];
                this.configuration = conf;
                save(fullfile(folder,'arumeconf.mat'), 'conf');
            end
            confdata = load(fullfile(folder,'arumeconf.mat'));
            conf = confdata.conf;
            
            % double check configuration fields
            if ( ~isfield( conf, 'defaultDataFolder') )
                conf.defaultDataFolder = fullfile(folder, 'ArumeData');
            end
            
            if ( ~isfield( conf, 'tempFolder') )
                conf.tempFolder = fullfile(folder, 'Temp');
            end
            
            % save the updated configuration
            this.configuration = conf;
            save(fullfile(folder,'arumeconf.mat'), 'conf');
            
            % create folders if they don't exist
            if ( ~exist( this.configuration.defaultDataFolder, 'dir') )
                mkdir(folder, 'ArumeData');
            end
            
            if ( ~exist( this.configuration.tempFolder, 'dir') )
                mkdir(folder, 'Temp');
            end
            
            % Get the list of possible experiments
            this.possibleExperiments = sort(ArumeCore.ExperimentDesign.GetExperimentList());
        end
        
        %
        % Managing projects
        %
        
        function newProject( this, parentPath, projectName )
            % Creates a new project
            
            this.currentProject = ArumeCore.Project.NewProject( parentPath, projectName);
            this.selectedSessions = [];
            
            this.updateRecentProjects(this.currentProject.path);
        end
        
        function loadProject( this, folder )
            % Loads a project from a project folder
            
            if ( ~exist( folder, 'dir') )
                msgbox( 'The project folder does not exist.');
            end
            
            if ( ~isempty(this.currentProject) && strcmp(this.currentProject.path, folder))
                disp('Loading the same project folder that is currently loaded');
                return;
            end
            
            this.currentProject = ArumeCore.Project.LoadProject( folder );
            this.selectedSessions = [];
            
            this.updateRecentProjects(this.currentProject.path)
        end
        
        function loadProjectBackup( this, file, parentPath )
            % Loads a project from a project file
            if ( ~exist( file, 'file') )
                msgbox( 'The project file does not exist.');
            end
            
            [~,projectName] = fileparts(file);
            
            if ( ~isempty(this.currentProject) && strcmp(this.currentProject.name, projectName))
                disp('Loading the same project file that is currently loaded');
                return;
            end
            
            this.currentProject = ArumeCore.Project.LoadProjectBackup( file, parentPath );
            if ~isempty(this.currentProject.sessions)
                this.selectedSessions = this.currentProject.sessions(1);
            else
                this.selectedSessions = [];
            end
            
            this.updateRecentProjects(this.currentProject.path)
        end
        
        function saveProjectBackup(this, file)
            if ( exist( file, 'file') )
                msgbox( 'The file already exists.');
            end
            
            this.currentProject.backup(file);
        end
        
        function updateRecentProjects(this, currentProjectFile)
            
            if ( ~isfield(this.configuration, 'recentProjects' ) )
                this.configuration.recentProjects = {};
            end
            
            % remove the current file
            this.configuration.recentProjects = unique(this.configuration.recentProjects,'stable');
            if (~isempty( this.configuration.recentProjects ) )
                this.configuration.recentProjects =  this.configuration.recentProjects(1:min(30,length(this.configuration.recentProjects)));
            end
            this.configuration.recentProjects(find(strcmp(this.configuration.recentProjects, currentProjectFile))) = [];
            % add it again at the top
            this.configuration.recentProjects = [currentProjectFile this.configuration.recentProjects];
            conf = this.configuration;
            [folder, name, ext] = fileparts(which('Arume'));
            save(fullfile(folder,'arumeconf.mat'), 'conf');
        end
        
        function closeProject( this )
            % Closes the current project (always saves)
            
            this.currentProject.save();
            this.currentProject = [];
            this.selectedSessions = [];
        end
        
        %
        % Managing sessions
        %
        
        function setCurrentSession( this, currentSelection )
            
            % Updates the current session selection
            if  ~isempty( currentSelection )
                this.selectedSessions = this.currentProject.sessions(sort(currentSelection));
            else
                this.selectedSessions = [];
            end
            
        end
        
        function session = newSession( this, experiment, subjectCode, sessionCode, experimentOptions )
            % Crates a new session to start the experiment and collect data
            
            % check if session already exists with that subjectCode and
            % sessionCode
            if ( ~isempty(this.currentProject.findSession(subjectCode, sessionCode) ) )
                error( 'Arume: session already exists, use a diferent name' );
            end
            
            session = ArumeCore.Session.NewSession( this.currentProject.path, experiment, subjectCode, sessionCode, experimentOptions );
            this.currentProject.addSession(session);
            this.selectedSessions = session;
            this.currentProject.save();
        end
        
        function session = importSession( this, experiment, subjectCode, sessionCode, options )
            % Imports a session from external files containing the data. It
            % will not be possible to run this session
            
            % check if session already exists with that subjectCode and
            % sessionCode
            if ( ~isempty(this.currentProject.findSession(subjectCode, sessionCode) ) )
                error( 'Arume: session already exists, use a diferent name' );
            end
            
            session = ArumeCore.Session.NewSession( this.currentProject.path, experiment, subjectCode, sessionCode, options );
            this.currentProject.addSession(session);
            this.selectedSessions = session;
            
            session.importSession();
            
            this.currentProject.save();
        end
        
        function renameSession( this, session, subjectCode, sessionCode)
            % Renames the current session
            
            for session1 = this.currentProject.sessions
                if ( isequal(subjectCode, session1.subjectCode) && isequal( sessionCode, session1.sessionCode) )
                    error( 'Arume: session already exists use a diferent name' );
                end
            end
            disp(['Renaming session' session.subjectCode ' - ' session.sessionCode ' to '  subjectCode ' - ' sessionCode]);
            
            [~, i] = this.currentProject.findSession(session.subjectCode, session.sessionCode);
            this.currentProject.sessions(i).rename(subjectCode, sessionCode);
            this.currentProject.save();
        end
        
        function copySelectedSessions( this, newSubjectCodes, newSessionCodes)
            
            newSessions = [];
            for i =1:length(this.selectedSessions)
                newSession = this.selectedSessions(i).copy(newSubjectCodes{i}, newSessionCodes{i});
                this.currentProject.addSession(newSession);
                newSessions = cat(1,newSessions, newSession);
            end
            
            this.selectedSessions = newSessions;
            
            this.currentProject.save();
        end
        
        function deleteSelectedSessions( this )
            % Deletes the current session
            sessions = this.selectedSessions;
            
            for i =1:length(sessions)
                this.currentProject.deleteSession(sessions(i));
            end
            
            this.selectedSessions = [];
            
            this.currentProject.save();
        end
        
        %
        % Running sessions
        %
        
        function runSession( this )
            % Start running the experimental session
            
            this.currentSession.start();
            this.currentProject.save();
        end
        
        function resumeSession( this )
            % Resumes running the experimental session
            
            this.currentSession.resume();
            this.currentProject.save();
        end
        
        function resumeSessionFrom( this, runNumber )
            % Resumes running the experimental session
            
            this.currentSession.resumeFrom(runNumber);
            this.currentProject.save();
        end
        
        function restartSession( this )
            % Restarts a session from the begining. Past data will be saved.
            
            this.currentSession.restart();
            this.currentProject.save();
        end
        
        %
        % Analyzing and plotting
        %
        function prepareAnalysis( this, sessions )
            % Prepares the session for analysis. Mainly this creates the
            % trial dataset and the samples dataset
            
            useWaitBar = 0;
            
            if ( ~exist('sessions','var') )
                sessions = this.selectedSessions;
                useWaitBar = 1;
            end
            
            n = length(sessions);
            
            if (useWaitBar)
                h = waitbar(0,'Please wait...');
            end
            
            for i =1:n
                try
                    cprintf('blue', '++ ARUME::preparing analyses for session %s\n', sessions(i).name);
                    session = sessions(i);
                    session.prepareForAnalysis();
                    if ( useWaitBar )
                        waitbar(i/n,h)
                    end
                catch ex
                    
                    beep
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!! ARUME ERROR PREPARING ANALYSES: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    disp(ex.getReport);
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!! END ARUME ERROR: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                end
            end
            
            this.currentProject.save();
            
            try
                if (~isempty(this.currentProject.sessionsTable) )
                    writetable(...
                        this.currentProject.sessionsTable, ...
                        fullfile(this.currentProject.path, ...
                        [this.currentProject.name '_ArumeSessionTable.csv']));
                end
                
                disp('======= ARUME EXCEL DATA SAVED TO DISK ==============================')
            catch err
                disp('ERROR saving excel data');
                disp(err.getReport);
            end
            
            if (useWaitBar)
                close(h);
            end
        end
        
        function dlg = getAnalysisOptions(this, sessions)
            
            if ( ~exist('sessions','var') )
                sessions = this.selectedSessions;
            end
            
            dlg = struct();
            for session = sessions
                dlg1 = session.experimentDesign.GetAnalysisOptionsDialog();
                f1 = fields(dlg);
                f2 = fields(dlg1);
                for i=1:length(f2)
                    if ( ~any(contains(f1,f2{i})) )
                        dlg.(f2{i}) = dlg1.(f2{i});
                    end
                end
            end
        end
        
        function options = getDefaultAnalysisOptions(this, sessions)
            options = StructDlg(this.getAnalysisOptions(sessions),'',[],[],'off');
        end
        
        function runDataAnalyses(this, options, sessions)
            useWaitBar = 0;
            
            if ( ~exist('sessions','var') )
                sessions = this.selectedSessions;
                useWaitBar = 1;
            end
            
            n = length(sessions);
            
            if (useWaitBar)
                h = waitbar(0,'Please wait...');
            end
            
            for i =1:n
                try
                    cprintf('blue', '++ ARUME::running analyses for session %s\n', sessions(i).name);
                    session = sessions(i);
                    session.runAnalysis(options);
                    if ( useWaitBar )
                        waitbar(i/n,h)
                    end
                catch ex
                    
                    beep
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!! ARUME ERROR RUNNING ANALYSES: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    disp(ex.getReport);
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!! END ARUME ERROR: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                    cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                end
            end
            
            this.currentProject.save();
            
            try
                if (~isempty(this.currentProject.sessionsTable) )
                    writetable(...
                        this.currentProject.sessionsTable, ...
                        fullfile(this.currentProject.path, ...
                        [this.currentProject.name '_ArumeSessionTable.csv']));
                end
                
                disp('======= ARUME EXCEL DATA SAVED TO DISK ==============================')
            catch err
                disp('ERROR saving excel data');
                disp(err.getReport);
            end
            
            if (useWaitBar)
                close(h);
            end
        end
        
        
        function plotList = GetPlotList( this )
            plotList = {};
            methodList = meta.class.fromName(class(this.currentSession.experimentDesign)).MethodList;
            for i=1:length(methodList)
                if ( strfind( methodList(i).Name, this.PlotsMethodPrefix) )
                    plotList{end+1} = strrep(methodList(i).Name, this.PlotsMethodPrefix ,'');
                end
            end
        end
        
        function plotList = GetAggregatePlotList( this )
            plotList = {};
            methodList = meta.class.fromName(class(this.currentSession.experimentDesign)).MethodList;
            for i=1:length(methodList)
                if ( strfind( methodList(i).Name, this.PlotsAggregateMethodPrefix) )
                    plotList{end+1} = strrep(methodList(i).Name, this.PlotsAggregateMethodPrefix ,'');
                end
            end
        end
        
        function generatePlots( this, plots, selection, COMBINE_SESSIONS)
            if ( ~exist('COMBINE_SESSIONS','var' ) )
                COMBINE_SESSIONS = 0;
            end
            
            if ( ~isempty( selection ) )
                for i=1:length(selection)
                    if ( ismethod( this.currentSession.experimentDesign, [this.PlotsMethodPrefix plots{selection(i)}] ) )
                        try
                            if ( ~COMBINE_SESSIONS)
                                % Single sessions plot
                                for session = this.selectedSessions
                                    session.experimentDesign.([this.PlotsMethodPrefix plots{selection(i)}])();
                                end
                            else
                                
                                nplot1 = [1 1 1 2 2 2 2 2 3 2 3 3 3 3 4 4 4 4 4 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5 5];
                                nplot2 = [1 2 3 2 3 3 4 4 3 5 4 4 5 5 4 5 5 5 5 5 5 5 5 5 6 6 6 6 6 6 7 7 7 7 7 7];
                                combinedFigures = [];
                                nSessions = length(this.selectedSessions);
                                p1 = nplot1(nSessions);
                                p2 = nplot2(nSessions);
                                iSession = 0;
                                
                                % Single sessions plot
                                for session = this.selectedSessions
                                    iSession = iSession+1;
                                    handles = get(0,'children');
                                    session.experimentDesign.([this.PlotsMethodPrefix plots{selection(i)}])();
                                    
                                    newhandles = get(0,'children');
                                    for iplot =1:(length(newhandles)-length(handles))
                                        
                                        if ( length(combinedFigures) < i )
                                            combinedFigures(iplot) = figure;
                                        end
                                        
                                        idx = length(handles)+1;
                                        axorig = get(newhandles(1),'children');
                                        theTitle = strrep(get(newhandles(1),'name'),'_',' ');
                                        if ( iSession > 1 )
                                            axcopy = copyobj(axorig(end), combinedFigures(iplot));
                                        else
                                            % copy all including legend
                                            axcopy = copyobj(axorig(:), combinedFigures(iplot));
                                        end
                                        ax = subplot(p1,p2,iSession,axcopy(end));
                                        title(ax,theTitle);
                                    end
                                    
                                    close(setdiff( newhandles,handles))
                                end
                            end
                        catch err
                            beep
                            cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                            cprintf('red', '!!!!!!!!!!!!! ARUME PLOT ERROR: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                            cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                            cprintf('red', '\n')
                            cprintf('red', 'Error ploting, try preparing the session first!\n')
                            cprintf('red', '\n')
                            disp(err.getReport);
                            cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                            cprintf('red', '!!!!!!!!!!!!! END PLOT ARUME ERROR: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                            cprintf('red', '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n')
                        end
                        
                    elseif ( ismethod( this.currentSession.experimentDesign, [this.PlotsAggregateMethodPrefix plots{selection(i)}] ) )
                        % Aggregate session plots
                        this.currentSession.experimentDesign.([this.PlotsAggregateMethodPrefix plots{selection(i)}])( this.selectedSessions );
                    end
                end
            end
        end
        
    end
    
end

