classdef Arume < handle
    % ARUME Is a GUI to control experiments and analyze their results.
    %
    %   Usage   : Arume, opens Arume GUI.
    %           : Arume( 'open', 'C:\path\to\project.aprj' ), opens a given project
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
    
    properties( SetAccess=private )
        currentProject      % Current working project 
        selectedSessions    % Current selected sessions (if multiple selected enabled)
        defaultDataFolder   % Default data folder for new projects
        tempFolder          % Temporary folder where data from the current project is unpacked
    end
        
    properties(Dependent=true)
        currentSession      % Current selected session (empty if none)
    end
    
    methods
        function session = get.currentSession( this )
            if ( length(this.selectedSessions) >= 1 )
                session = this.selectedSessions(1);
            else
                session = [];
            end
        end
    end
    
    methods
        
        %
        % Main constructor
        %
        
        function arume = Arume(command, param)
            % Starts arume and loads the GUI
            %   Usage   : Arume
            %           : Arume( 'clear' ) clears the persistent variable
            %           : Arume( 'open', 'C:\path\to\project.aprj' ) opens
            %               a given project
            
            % persistent variable to keep the singleton
            persistent arumeSingleton;
            
            % option to clear the singleton
            if ( exist('command','var') )
                switch (command )
                    case 'clear'
                        % clear the persistent variable
                        clear arumeSingleton;
                        return;
                        
                    case 'createSingleton'
                        % Initialization, object is created automatically
                        % (this is the constructor) and then initialized
                        
                        arume.init();
                        
                        return;
                        
                    case 'open'
                        if ( exist('param','var') )
                            projectPath = param;
                        end
                end
            end
            
            % When called with no parameters work like an static factory
            % to create the singleton object or load it
            if isempty(arumeSingleton)
                arumeSingleton = Arume( 'createSingleton' );
            end
            
            % Load the GUI
            gui = ArumeGui( arumeSingleton );
            
            if ( exist('projectPath','var') )
                arumeSingleton.loadProject( projectPath )
                gui.updateGui();
            end
        end
        
        function init( this)
            % find the folder of arume
            [folder, name, ext] = fileparts(which('Arume'));
            
            this.defaultDataFolder = fullfile(folder, 'ArumeData');
            if ( ~exist( this.defaultDataFolder, 'dir') )
                mkdir(folder, 'ArumeData');
            end
            
            this.tempFolder = fullfile(folder, 'Temp');
            if ( ~exist( this.tempFolder, 'dir') )
                mkdir(folder, 'Temp');
            end
        end
        
        %
        % Managing projects
        %
        
        function newProject( this, projectFilePath, projectName, defaultExperiment )
            % Creates a new project
            
            this.currentProject = ArumeCore.Project.NewProject( projectFilePath, projectName, this.tempFolder, defaultExperiment);
            this.selectedSessions = [];
        end
        
        function loadProject( this, file )
            % Loads a project from a project file
            
            this.currentProject = ArumeCore.Project.LoadProject( file, this.tempFolder );
            this.selectedSessions = [];
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
                this.selectedSessions = this.currentProject.sessions(currentSelection);
            else
                this.selectedSessions = [];
            end
        end
        
        function session = newSession( this, experiment, subjectCode, sessionCode, experimentOptions )
            % Crates a new session to start the experiment and collect data
            
            % check if session already exists with that subjectCode and
            % sessionCode
            for session = this.currentProject.sessions
                if ( isequal(subjectCode, session.subjectCode) && isequal( sessionCode, session.sessionCode) )
                    error( 'Arume: session already exists use a diferent name' );
                end
            end
            
            session = ArumeCore.Session.NewSession( this.currentProject, experiment, subjectCode, sessionCode, experimentOptions );
            this.selectedSessions = session;
            this.currentProject.save();
        end
        
        function session = importSession( this, experiment, subject_Code, session_Code )
            % Imports a session from external files containing the data. It
            % will not be possible to run this session
            
            session = ArumeCore.Session.NewSession( this.currentProject, experiment, subject_Code, session_Code );
            
            [dsTrials, dsSamples] = session.experiment.ImportSession();
            session.importData(dsTrials, dsSamples);
            this.currentSession = session;
            this.selectedSessions = session;
            this.currentProject.save();
        end
        
        function renameCurrentSession( this, subjectCode, sessionCode)
            % Renames the current session
            
            this.currentSession.rename(subjectCode, sessionCode);
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
        
        function restartSession( this )
            % Restarts a session from the begining. Past data will be saved.
            
            this.currentSession.restart();
            this.currentProject.save();
        end
         
        %
        % Analyzing and plotting
        %
        
        function prepareAnalysis( this )
            % Prepares the session for analysis. Mainly this creates the
            % trial dataset and the samples dataset
            
            h = waitbar(0,'Please wait...');
            n = length(this.selectedSessions);
            for i =1:n
                session = this.selectedSessions(i);
                session.prepareForAnalysis();
                waitbar(i/n,h)
            end
            close(h);
            
            this.currentProject.save();
        end
        
        function runAnalyses( this ) 
            % Runs the selected analysis
            
            for session = this.selectedSessions
                session.RunAnalyses();
            end
        end
        
        function analysisList = GetAnalysisList( this )
            analysisList = {};
            methodList = meta.class.fromName(class(this.currentSession.experiment)).MethodList;
            for i=1:length(methodList)
                if ( strfind( methodList(i).Name, this.AnalysisMethodPrefix) )
                    analysisList{end+1} = strrep( methodList(i).Name, this.AnalysisMethodPrefix ,'');
                end
            end
        end
        
        function RunAnalyses( this, analysisList )
            for i=1:length(analysisList)
                this.experiment.([this.AnalysisMethodPrefix analysisList{i}])();
            end
        end
        
        function plotList = GetPlotList( this )
            plotList = {};
            methodList = meta.class.fromName(class(this.currentSession.experiment)).MethodList;
            for i=1:length(methodList)
                if ( strfind( methodList(i).Name, this.PlotsMethodPrefix) )
                    plotList{end+1} = strrep(methodList(i).Name, this.PlotsMethodPrefix ,'');
                end
                if ( strfind( methodList(i).Name, this.PlotsAggregateMethodPrefix) )
                    plotList{end+1} = strrep(methodList(i).Name, this.PlotsAggregateMethodPrefix ,'');
                end
            end
        end
        
        function generatePlots( this, plots, selection )
            if ( ~isempty( selection ) )
                for i=1:length(selection)
                    if ( ismethod( this.currentSession.experiment, [this.PlotsMethodPrefix plots{selection(i)}] ) )
                        % Single sessions plot
                        for session = this.selectedSessions
                            session.experiment.([this.PlotsMethodPrefix plots{selection(i)}])();
                        end
                    elseif ( ismethod( this.currentSession.experiment, [this.PlotsAggregateMethodPrefix plots{selection(i)}] ) )
                        % Aggregate session plots
                        this.currentSession.experiment.([this.PlotsAggregateMethodPrefix plots{selection(i)}])( this.selectedSessions );
                    end
                end
            end
        end
        
    end
    
    methods ( Static = true )
    end
    
end

