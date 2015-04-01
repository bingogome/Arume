classdef ArumeController < handle
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
    
    properties( Access=private )
        configuration       % Configuration options saved into a mat file in the Arume folder
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
                recentProjects = this.configuration.recentProjects;
            else
                recentProjects = '';
            end
        end
    end
    
    methods( Access=public )
        
        %
        % Main constructor
        %
        
        function arumeController = ArumeController()
            
        end
        
        function init( this)
            % find the folder of arume
            [folder, name, ext] = fileparts(which('Arume'));
            
            % find the configuration file
            if ( ~ exist(fullfile(folder,'arumeconf.mat')))
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
        end
        %
        % Managing projects
        %
        
        function newProject( this, projectFilePath, projectName, defaultExperiment )
            % Creates a new project
            
            this.currentProject = ArumeCore.Project.NewProject( projectFilePath, projectName, this.configuration.tempFolder, defaultExperiment);
            this.selectedSessions = [];
            
            if ( ~isfield(this.configuration, 'recentProjects' ) )
                this.configuration.recentProjects = {};
            end
            
            this.configuration.recentProjects(find(strcmp(this.configuration.recentProjects, this.currentProject.projectFile))) = [];
            
            this.configuration.recentProjects = [this.currentProject.projectFile this.configuration.recentProjects];
            conf = this.configuration;
            [folder, name, ext] = fileparts(which('Arume'));
            save(fullfile(folder,'arumeconf.mat'), 'conf'); 
        end
        
        function loadProject( this, file )
            % Loads a project from a project file
            
            if ( ~exist( file, 'file') )
                msgbox( 'The project file does not exist.');
            end
            
            this.currentProject = ArumeCore.Project.LoadProject( file, this.configuration.tempFolder );
            this.selectedSessions = [];
            
            if ( ~isfield(this.configuration, 'recentProjects' ) )
                this.configuration.recentProjects = {};
            end
            
            this.configuration.recentProjects(find(strcmp(this.configuration.recentProjects, this.currentProject.projectFile))) = [];
            
            this.configuration.recentProjects = [file this.configuration.recentProjects];
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
            this.currentProject.addSession(session);
            this.selectedSessions = session;
            this.currentProject.save();
        end
        
        function session = importSession( this, experiment, subject_Code, session_Code )
            % Imports a session from external files containing the data. It
            % will not be possible to run this session
            
            session = ArumeCore.Session.NewSession( this.currentProject, experiment, subject_Code, session_Code );
            
            [dsTrials, dsSamples] = session.experiment.ImportSession();
            this.currentProject.addSession(session);
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
        
        function copySelectedSessions( this, newSubjectCodes, newSessionCodes);
            
            sessions = this.selectedSessions;
            
            for i =1:length(sessions)
                newSession = ArumeCore.Session.CopySession( sessions(i), newSubjectCodes{i}, newSessionCodes{i});
                this.currentProject.addSession(newSession);
            end
                        
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
        
        function exportAnalysesData(this)
            a=1;
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
    
end

