classdef Arume < handle
    %ARUME Summary of this class goes here
    %   Detailed explanation goes here
    
    
    properties(Constant=true)
        defaultDataFolder = 'C:\secure\Code\arume\ArumeData';
        
        AnalysisMethodPrefix = 'Analysis_';
        PlotsMethodPrefix = 'Plot_';
        PlotsAggregateMethodPrefix = 'PlotAggregate_';
    end
    
    properties
        % Current working project 
        currentProject
       
        % Current selected sessions (if multiple selected enabled)
        selectedSessions
    end
        
    properties(Dependent=true)
        % Current selected session
        currentSession
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
        
        function arume = Arume(command)
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
                end
            end
            
            % When called with no parameters work like an static factory
            % to create the singleton object or load it
            if isempty(arumeSingleton)
                arumeSingleton = Arume( 'createSingleton' );
            end
            
            % Load the GUI
            ArumeGui( arumeSingleton );
        end
           
        %
        % Managing projects
        %
        
        function project = newProject( this, path, name, defaultExperiment )
            project = ArumeCore.Project.New( path, name, defaultExperiment);
            this.currentProject = project;
            this.selectedSessions = [];
        end
        
        function project = loadProject( this, path )
            project = ArumeCore.Project.Load( path );
            this.currentProject = project;
            this.selectedSessions = [];
        end
        
        function closeProject( this )
            this.currentProject.save();
            this.currentProject = [];
            this.selectedSessions = [];
        end
                
        %
        % Managing sessions
        %
        
        function setCurrentSession( this, currentSelection )
            if  ~isempty( currentSelection )
                this.selectedSessions = this.currentProject.sessions(currentSelection);
            else
                this.selectedSessions = [];
            end
        end
        
        function session = newSession( this, experiment, subject_Code, session_Code, experimentOptions )
            session = ArumeCore.Session.NewSession( this.currentProject, experiment, subject_Code, session_Code, experimentOptions );
            this.selectedSessions = session;
            this.currentProject.save();
        end
        
        function session = importSession( this, experiment, subject_Code, session_Code )
            session = ArumeCore.Session.NewSession( this.currentProject, experiment, subject_Code, session_Code );
            
            [dsTrials, dsSamples] = session.experiment.ImportSession();
            session.importData(dsTrials, dsSamples);
            this.currentSession = session;
            this.selectedSessions = session;
            this.currentProject.save();
        end
        
        function renameCurrentSession( this, subjectCode, sessionCode)
            this.currentSession.rename(subjectCode, sessionCode);
            this.currentProject.save();
        end
        
        function deleteCurrentSession( this )
            sessidx = find( this.currentProject.sessions == this.currentSession );
            this.currentSession.deleteFolders();
            this.currentProject.sessions(sessidx) = [];
            this.selectedSessions = [];
            this.currentProject.save();
        end
        
        %
        % Running sessions
        %
        
        function runSession( this )
            this.currentSession.start();
            this.currentProject.save();
        end
        
        function resumeSession( this )
            this.currentSession.resume();
            this.currentProject.save(); 
        end
        
        function restartSession( this )
            this.currentSession.restart();
            this.currentProject.save();
        end
         
        %
        % Analyzing and plotting
        %
        
        function prepareAnalysis( this )
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

