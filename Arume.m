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
    end
    
    methods
        function project = newProject( this, experiment, path, name )
            project = ArumeCore.Project.New( experiment, path, name, []);
            this.currentProject = project;
        end
        
        function project = loadProject( this, path )
            project = ArumeCore.Project.Load( path );
            this.currentProject = project;
        end
        
        function saveProject( this )
            this.currentProject.save();
        end
        
        function closeProject( this )
            this.currentProject = [];
        end
        
        function session = newSession( this, subject_Code, session_Code )
            session = ArumeCore.Session.NewSession( this.currentProject, subject_Code, session_Code );
            this.currentSession = session;
        end
        
        function runSession( this )
            this.currentSession.Run();
        end
        
        function resumeSession( this )
            this.currentSession.Resume();
        end
        function restartSession( this )
            this.currentSession.Restart();
        end
        
        function setCurrentSession( this, currentSession )
            if isscalar( currentSession )
                this.currentSession = this.currentProject.sessions(currentSession);
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

