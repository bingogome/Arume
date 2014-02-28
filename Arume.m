classdef Arume < handle
    %ARUME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        arumeGui
        
        defaultDataFolder = 'C:\secure\Code\arume\ArumeData';
        
        currentProject
        currentSession

        selectedSessions
        
        
        AnalysisMethodPrefix = 'Analysis_';
        PlotsMethodPrefix = 'Plot_';
        PlotsAggregateMethodPrefix = 'PlotAggregate_';
    end
    
    
    methods
        
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
                        % the object is created the object
                        return;
                end
                return
            else
                % When called with no parameters work like an static factory
                % to create the singleton object or load it
                if isempty(arumeSingleton)
                    arumeSingleton = Arume( 'createSingleton' );
                end
                
                % load the gui
                arumeSingleton.arumeGui = ArumeGui( arumeSingleton );
            end
        end
        
        function project = newProject( this, path, name, defaultExperiment )
            project = ArumeCore.Project.New( path, name, defaultExperiment);
            this.currentProject = project;
            this.currentSession = [];
            this.selectedSessions = [];
        end
        
        function project = loadProject( this, path )
            project = ArumeCore.Project.Load( path );
            this.currentProject = project;
            this.currentSession = [];
        end
        
        function closeProject( this )
            this.currentProject.save();
            this.currentProject = [];
            this.currentSession = [];
            this.selectedSessions = [];
        end
        
        function session = newSession( this, experiment, subject_Code, session_Code )
            session = ArumeCore.Session.NewSession( this.currentProject, experiment, subject_Code, session_Code );
            this.currentSession = session;
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
        
        function deleteSession( this )
            sessidx = find( this.currentProject.sessions == this.currentSession );
            this.currentProject.sessions(sessidx) = [];
            this.currentSession = [];
            this.selectedSessions = [];
            this.currentProject.save();
        end
        
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
         
        function prepareAnalysis( this )
            for session = this.selectedSessions
                session.prepareForAnalysis();
            end
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
        
        function generatePlots( this )
            plots = get(this.arumeGui.plotsListBox,'string');
            selection = get(this.arumeGui.plotsListBox,'value');
            if ( ~isempty( selection ) )
                
                for i=1:length(selection)
                    if ( ismethod( this.currentSession.experiment, [this.PlotsMethodPrefix plots{selection(i)}] ) )
                        for session = this.selectedSessions
                            this.currentSession.experiment.([this.PlotsMethodPrefix plots{selection(i)}])();
                        end
                    elseif ( ismethod( this.currentSession.experiment, [this.PlotsAggregateMethodPrefix plots{selection(i)}] ) )
                        this.currentSession.experiment.([this.PlotsAggregateMethodPrefix plots{selection(i)}])( this.selectedSessions );
                    end
                end
            
            end
        end
        
        function setCurrentSession( this, currentSelection )
            if isscalar( currentSelection ) && ~isempty( currentSelection )
                this.currentSession = this.currentProject.sessions(currentSelection);
            else
                this.currentSession = this.currentProject.sessions(currentSelection(1));
            end
            if  ~isempty( currentSelection )
                this.selectedSessions = this.currentProject.sessions(currentSelection);
            else
                this.currentSession = [];
                this.selectedSessions = [];
            end
        end
    end
    
    methods ( Static = true )
    end
    
end

