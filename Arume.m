classdef Arume < handle
    %ARUME Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        arumeGui
        
        defaultDataFolder = 'C:\secure\Code\arume\ArumeData';
        
        currentProject
        currentSession
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
                this.arumeGui = ArumeGui( arumeSingleton );
            end
        end
        
        function project = newProject( this, path, name, defaultExperiment )
            project = ArumeCore.Project.New( path, name, defaultExperiment);
            this.currentProject = project;
            this.currentSession = [];
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
        end
        
        function session = newSession( this, experiment, subject_Code, session_Code )
            session = ArumeCore.Session.NewSession( this.currentProject, experiment, subject_Code, session_Code );
            this.currentSession = session;
            this.currentProject.save();
        end
        
        function deleteSession( this )
            %this.currentSession = session;
            sessidx = find( this.currentProject.sessions == this.currentSession );
            this.currentProject.sessions(sessidx) = [];
            this.currentSession = [];
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
            this.currentSession.prepareForAnalysis();
        end
        
        function runAnalysis( this )
            this.currentSession.Analyze();
        end
        
        function setCurrentSession( this, currentSession )
            if isscalar( currentSession ) && ~isempty( currentSession )
                this.currentSession = this.currentProject.sessions(currentSession);
            else
                this.currentSession = currentSession;
            end
        end
    end
    
    methods ( Static = true )
    end
    
end

