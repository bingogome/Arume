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
        function project = newProject( this, experiment, path, name )
            project = ArumeCore.Project.New( experiment, path, name);
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
        
        function session = newSession( this, subject_Code, session_Code )
            session = ArumeCore.Session.NewSession( this.currentProject, subject_Code, session_Code );
            this.currentSession = session;
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
        
        function setCurrentSession( this, currentSession )
            if isscalar( currentSession ) && ~isempty( currentSession )
                this.currentSession = this.currentProject.sessions(currentSession);
            else
                this.currentSession = currentSession;
            end
        end
    end
    
    methods ( Static = true )
        function Run()
            
            arume = Arume( );
            this.arumeGui = ArumeGui( arume );
        end
    end
    
end

