classdef Arume < handle
    %ARUME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant=true)
        defaultDataFolder = '/Users/amirh19/Documents/amir/research/Arume/ArumeData';
        tempFolder = '/Users/amirh19/Documents/amir/research/Arume/Temp';
        
        AnalysisMethodPrefix = 'Analysis_';
        PlotsMethodPrefix = 'Plot_';
        PlotsAggregateMethodPrefix = 'PlotAggregate_';
    end
    
    properties(SetAccess=private)
        currentProject      % Current working project 
        selectedSessions    % Current selected sessions (if multiple selected enabled)
    end
        
    properties(Dependent=true)
        currentSession      % Current selected session
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
                        % do nothing, just let the constructor finish so 
                        % the object is created
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
           
        %
        % Managing projects
        %
        
        function newProject( this, path, name, defaultExperiment )
            % Creates a new project
            
            this.currentProject = ArumeCore.Project.NewProject( path, name, defaultExperiment);
            this.selectedSessions = [];
        end
        
        function loadProject( this, file )
            % Loads a project from a project file
            
            this.currentProject = ArumeCore.Project.LoadProject( file );
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
        
        function session = newSession( this, experiment, subject_Code, session_Code, experimentOptions )
            % Crates a new session to start the experiment and collect data
            
            session = ArumeCore.Session.NewSession( this.currentProject, experiment, subject_Code, session_Code, experimentOptions );
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
        
        function deleteCurrentSession( this )
            % Deletes the current session
            this.currentProject.deleteSession(this.currentSession);
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
                        for session = this.selectedSessions
                            session.experiment.([this.PlotsMethodPrefix plots{selection(i)}])();
                        end
                    elseif ( ismethod( this.currentSession.experiment, [this.PlotsAggregateMethodPrefix plots{selection(i)}] ) )
                        this.currentSession.experiment.([this.PlotsAggregateMethodPrefix plots{selection(i)}])( this.selectedSessions );
                    end
                end
            end
        end
        
    end
    
    methods ( Static = true )
    end
    
end

