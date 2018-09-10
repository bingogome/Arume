classdef Project < handle
    %PROJECT Class handingling Arume projects
    %
    
    properties( SetAccess = private)
        name            % Name of the project
        path            % Working path of the project
        
        sessions        % Sessions that belong to this project
        sessionsTable    % table with information about the sessions
    end
    
    methods(Access=private)
        %
        % Initialization methods
        %
        % Always use the static methods Load and Create to create new
        % project objects.
        function initNew( this, parentPath, projectName )
            % Initializes a new project
            this.name               = projectName;
            this.path               = fullfile(parentPath, projectName);
            this.sessions           = [];
            
            % prepare folder structure
            mkdir( parentPath, projectName );
            
            % save the project
            this.save();
        end
        
        function initExisting( this, path )
            % Initializes a project loading from a folder
            
            [~, projectName] = fileparts(path);
            
            % initialize the project
            this.name               = projectName;
            this.path               = path;
            this.sessions           = [];
            
            % find the session folders
            d = struct2table(dir(path));
            d = d(d.isdir & ~strcmp(d.name,'.') & ~strcmp(d.name,'..'),:);
            d = sortrows(d,'date');
            
            % load sessions
            for i=1:length(d.name)
                sessionName = d.name{i};
                sessionPath = fullfile(path, sessionName);
                session = ArumeCore.Session.LoadSession( sessionPath );
                if ( ~isempty(session) )
                    this.addSession(session);
                else
                    disp(['WARNING: session ' sessionName ' could not be loaded. May be an old result of corruption.']);
                end
            end
            
            this.sessionsTable = this.GetDataTable();
        end
    end
    
    methods(Access=public)
        %
        % Save project
        %
        function save( this )
            
            for session = this.sessions
                session.save();
            end
            
            this.sessionsTable = this.GetDataTable();
            
            disp('======= ARUME PROJECT SAVED TO DISK REMEMBER TO BACKUP ==============================')
        end
        
        function backup(this, file)
            if (~isempty(file) )
                % create a backup of the last project file before
                % overriding it
                if ( exist(file,'file') )
                    copyfile(file, [file '.aruback']);
                end
                
                % compress project file and keep temp folder
                zip(file , this.path);
            end
        end
        
        %
        % Other methods
        %
        function addSession( this, session)
            if ( ~isempty(this.findSession(session.subjectCode, session.sessionCode) ) )
                error( 'Arume: session already exists use a diferent name' );
            end
            
            if ( isempty( this.sessions ) )
                this.sessions = session;
            else
                this.sessions(end+1) = session;
            end
        end
        
        function deleteSession( this, session )
            session.deleteFolders();
            this.sessions( this.sessions == session ) = [];
        end
        
        function [session, i] = findSessionByIDNumber( this, sessionIDNumber)
            
            for i=1:length(this.sessions)
                if ( this.sessions(i).sessionIDNumber ==sessionIDNumber )
                    session = this.sessions(i);
                    return;
                end
            end
            
            % if not found
            session = [];
            i = 0;
        end
        
        function [session, i] = findSession( this, subjectCode, sessionCode)
            
            for i=1:length(this.sessions)
                if ( exist('sessionCode','var') )
                    if ( strcmpi(this.sessions(i).subjectCode, subjectCode) &&  ...
                            strcmpi(this.sessions(i).sessionCode, sessionCode))
                        session = this.sessions(i);
                        return;
                    end
                else
                    if ( strcmpi(this.sessions(i).experimentDesign.Name, experimentName) &&  ...
                            strcmpi([upper(this.sessions(i).subjectCode) upper(this.sessions(i).sessionCode),], subjectCode))
                        session = this.sessions(i);
                        return;
                    end
                end
            end
            
            % if not found
            session = [];
            i = 0;
        end
        
        function sortSessions(this)
            
            sessionNames = cell(length(this.sessions),1);
            for i=1:length(this.sessions)
                sessionNames{i} = [this.sessions(i).subjectCode this.sessions(i).sessionCode];
            end
            [~, i] = sort(sessionNames);
            this.sessions = this.sessions(i);
        end
        
        %
        % Analysis methods
        %
        function dataTable = GetDataTable(this)
         
            dataTable = table();
            
            for isess=1:length(this.sessions)
                session = this.sessions(isess);
                
                if ( ~isempty( session.sessionDataTable ) )
                    sessionRow = session.sessionDataTable;
                else
                    sessionRow = session.GetBasicSessionDataTable();
                end
                
                dataTable = VertCatTablesMissing(dataTable, sessionRow);
            end
            
            %disp(dataTable);
            assignin('base','ProjectTable',dataTable);
        end
    end
    
    
    methods ( Static = true )
        
        %
        % Factory methods
        %
        function project = NewProject( parentPath, projectName )
            
            % check if parentFolder exists
            if ( ~exist( parentPath, 'dir' ) )
                error('Arume: parent folder does not exist');
            end
            
            if ( exist( fullfile(parentPath, projectname), 'dir' ) )
                error('Arume: project folder already not exist');
            end
            
            % check if name is a valid name
            if ( ~ArumeCore.Project.IsValidProjectName( projectName ) )
                error('Arume: project name is not valid');
            end
            
            % create project object
            project = ArumeCore.Project();
            project.initNew( parentPath, projectName );
        end
        
        function project = LoadProject( projectPath )
            
            % check if parentFolder exists
            if ( ~exist( projectPath, 'dir' ) )
                error('Arume: parent folder does not exist');
            end
            
            project = ArumeCore.Project();
            ArumeCore.Project.UpdateFileStructure(projectPath);
            project.initExisting( projectPath );
        end
        
        function project = LoadProjectBackup(file, parentPath)
            
            % check if parentFolder exists
            if ( ~exist( file, 'file' ) )
                error('Arume: file does not exist');
            end
            
            % check if parentFolder exists
            if ( ~exist( parentPath, 'dir' ) )
                error('Arume: parent folder does not exist');
            end
            
            [~, projectName, ext] = fileparts(file);
            
            projectPath = fullfile(parentPath, projectName);
            
            mkdir(projectPath);
            
            % uncompress project file into temp folder
            if ( strcmp(ext, '.aruprj' ) )
                untar(file, parentPath);
            else
                unzip(file, parentPath);
            end
            
            ArumeCore.Project.UpdateFileStructure(projectPath);
            
            project = ArumeCore.Project.LoadProject(projectPath);
        end
        
        function UpdateFileStructure(path)
            [~, projectName] = fileparts(path);
            
            if ( exist(fullfile(path, 'project.mat'),'file') )
                disp('Updated file structure to new version of Arume ...');
                movefile(fullfile(path, 'project.mat'), fullfile(path, [projectName '_ArumeProject.mat']),'f');
                movefile(fullfile(fullfile(path,'dataAnalysis'),'*'), path,'f');
                movefile(fullfile(fullfile(path,'dataRaw'),'*'), path,'f');
                
                if ( exist( fullfile(path, 'analysis'),'dir') )
                    rmdir(fullfile(path, 'analysis'),'s');
                end
                if ( exist( fullfile(path, 'dataAnalysis'),'dir') )
                    rmdir(fullfile(path, 'dataAnalysis'),'s');
                end
                if ( exist( fullfile(path, 'dataRaw'),'dir') )
                    rmdir(fullfile(path, 'dataRaw'),'s');
                end
                if ( exist( fullfile(path, 'figures'),'dir') )
                    rmdir(fullfile(path, 'figures'),'s');
                end
                if ( exist( fullfile(path, 'stimuli'),'dir') )
                    rmdir(fullfile(path, 'stimuli'),'s');
                end
                
                
                projectMatFile = fullfile(path, [projectName '_ArumeProject.mat']);
                
                % load project data
                data = load( projectMatFile, 'data' );
                data = data.data;
                
                for sessionData = data.sessions
                    
                    % TEMPORARY
                    oldSessionName = [sessionData.experimentName '_' sessionData.subjectCode sessionData.sessionCode];
                    if ( strcmp(sessionData.experimentName, 'MVSTorsion') )
                        sessionData.experimentName = 'EyeTracking';
                    end
                    newSessionName = [sessionData.experimentName '__' sessionData.subjectCode '__' sessionData.sessionCode];
                    if ( ~strcmp(oldSessionName, newSessionName) )
                        movefile(fullfile(path,oldSessionName) ,fullfile(path,newSessionName))
                    end
                    
                    
                    sessionName = [sessionData.experimentName '__' sessionData.subjectCode '__' sessionData.sessionCode];
                    
                    disp(sprintf('... updating %s ...',sessionName));
                    sessionData.currentRun = ArumeCore.Project.UpdateRun(sessionData.currentRun, sessionData.experimentName );
                    
                    newPastRuns = [];
                    for i=1:length(sessionData.pastRuns)
                        if (isempty( newPastRuns ) )
                            newPastRuns = ArumeCore.Project.UpdateRun(sessionData.pastRuns(i), sessionData.experimentName );
                        else
                            newPastRuns = cat(1,newPastRuns,  ArumeCore.Project.UpdateRun(sessionData.pastRuns(i), sessionData.experimentName ));
                        end
                    end
                    sessionData.pastRuns = newPastRuns;
                    
                    
                    
                    filename = fullfile( fullfile(path, sessionName), 'ArumeSession.mat');
                    save( filename, 'sessionData' );
                end
                data = rmfield(data,'sessions');
                % TODO: maybe save the updated data without sessions.
                
                disp('... Done updating file structure.');
            end
        end
        
        function newRun = UpdateRun(runData,experimentName)
            
            experimentDesign = ArumeCore.ExperimentDesign.Create( experimentName );
            experimentDesign.init();
            
            if ( isempty( runData) )
                newRun = ArumeCore.ExperimentRun.SetUpNewRun( experimentDesign );
            else
                
                newRun = runData;
                
                futureConditions = runData.futureConditions;
                f2 = table();
                f2.Condition = futureConditions(:,1);
                f2.BlockNumber = futureConditions(:,2);
                f2.BlockSequenceNumber = futureConditions(:,3);
                f2.Session = ones(size(f2.Condition));
                
                t2 = table();
                for i=1:height(f2)
                    vars = experimentDesign.getVariablesCurrentCondition( f2.Condition(i) );
                    t2 = cat(1,t2,struct2table(vars,'AsArray',true));
                end
                
                newRun.futureTrialTable = [f2 t2];
                
                
                futureConditions = runData.originalFutureConditions;
                f2 = table();
                f2.Condition = futureConditions(:,1);
                f2.BlockNumber = futureConditions(:,2);
                f2.BlockSequenceNumber = futureConditions(:,3);
                f2.Session = ones(size(f2.Condition));
                
                
                t2 = table();
                for i=1:height(f2)
                    vars = experimentDesign.getVariablesCurrentCondition( f2.Condition(i) );
                    t2 = cat(1,t2,struct2table(vars,'AsArray',true));
                end
                
                newRun.originalFutureTrialTable = [f2 t2];
                
                
                pastConditions = runData.pastConditions;
                
                f2 = table();
                f2.TrialNumber = (1:length(pastConditions(:,1)))';
                f2.Session = pastConditions(:,5);
                f2.Condition = pastConditions(:,1);
                f2.BlockNumber = pastConditions(:,3);
                f2.BlockSequenceNumber = pastConditions(:,4);
                f2.Session = ones(size(f2.TrialNumber));
                
                t2 = table();
                for i=1:height(f2)
                    vars = experimentDesign.getVariablesCurrentCondition( f2.Condition(i) );
                    t2 = cat(1,t2,struct2table(vars,'AsArray',true));
                end
                f2 = [f2 t2];
                
                i=1;
                Enum = ArumeCore.ExperimentDesign.getEnum();
                Enum.Events.EYELINK_START_RECORDING     = i;i=i+1;
                Enum.Events.EYELINK_STOP_RECORDING      = i;i=i+1;
                Enum.Events.PRE_TRIAL_START             = i;i=i+1;
                Enum.Events.PRE_TRIAL_STOP              = i;i=i+1;
                Enum.Events.TRIAL_START                 = i;i=i+1;
                Enum.Events.TRIAL_STOP                  = i;i=i+1;
                Enum.Events.POST_TRIAL_START            = i;i=i+1;
                Enum.Events.POST_TRIAL_STOP             = i;i=i+1;
                Enum.Events.TRIAL_EVENT                 = i;i=i+1;
                ev = runData.Events;
                ev(ev(:,4)>height(f2),:) = []; % remove events for trials that are not in pastConditions
                
                f2.TimePreTrialStart = nan(size(f2.TrialNumber));
                f2.TimePreTrialStop = nan(size(f2.TrialNumber));
                f2.TimeTrialStart = nan(size(f2.TrialNumber));
                f2.TimeTrialStop = nan(size(f2.TrialNumber));
                f2.TimePostTrialStart = nan(size(f2.TrialNumber));
                f2.TimePostTrialStop = nan(size(f2.TrialNumber));
                
                f2.TimePreTrialStart(ev(ev(:,3)==Enum.Events.PRE_TRIAL_START ,4)) = ev(ev(:,3)==Enum.Events.PRE_TRIAL_START ,1);
                f2.TimePreTrialStop(ev(ev(:,3)==Enum.Events.PRE_TRIAL_STOP ,4)) = ev(ev(:,3)==Enum.Events.PRE_TRIAL_STOP ,1);
                f2.TimeTrialStart(ev(ev(:,3)==Enum.Events.TRIAL_START ,4)) = ev(ev(:,3)==Enum.Events.TRIAL_START ,1);
                f2.DateTimeTrialStart(ev(ev(:,3)==Enum.Events.TRIAL_START ,4),:) = datestr(ev(ev(:,3)==Enum.Events.TRIAL_START ,2));
                f2.TrialResult = Enum.trialResult.PossibleResults(pastConditions(:,2)+1);
                % from here on only if trialresult is correct or abort
                
                f2.TimeTrialStop(ev(ev(:,3)==Enum.Events.TRIAL_STOP ,4)) = ev(ev(:,3)==Enum.Events.TRIAL_STOP ,1);
                f2.TimePostTrialStart( ev(ev(:,3)==Enum.Events.POST_TRIAL_START ,4)) = ev(ev(:,3)==Enum.Events.POST_TRIAL_START ,1);
                f2.TimePostTrialStop(ev(ev(:,3)==Enum.Events.POST_TRIAL_STOP ,4)) = ev(ev(:,3)==Enum.Events.POST_TRIAL_STOP ,1);
                
                tout = table();
                for i=1:height(f2)
                    if ( isfield(runData.Data{i}, 'trialOutput' ) && ~isempty(runData.Data{i}.trialOutput) )
                        trialOutput = runData.Data{i}.trialOutput;
                        if ( isfield(trialOutput,'Response') && (trialOutput.Response == 'L' || trialOutput.Response == 'R') )
                            trialOutput.Response = categorical(cellstr(trialOutput.Response));
                        elseif ( isfield(trialOutput,'Response') )
                            trialOutput = rmfield(trialOutput,'Response');
                        end
                        if ( isfield(trialOutput,'ReactionTime') && (trialOutput.ReactionTime == -1 || isempty(trialOutput.ReactionTime)) )
                            trialOutput = rmfield(trialOutput,'ReactionTime');
                        end
                    else
                        trialOutput = struct();
                    end
                    
                    if ( ~isempty( tout ) )
                        trialOutputTable = struct2table(trialOutput,'AsArray',true);
                        tout = VertCatTablesMissing(tout,trialOutputTable);
                    else
                        tout = struct2table(trialOutput,'AsArray',true);
                    end
                    
                end
                
                if ( ~isempty(tout) )
                    f2 = [f2 tout];
                end
                
                newRun.pastTrialTable = f2;
                
                newRun;
            end
        end
        
        %
        % Other methods
        %
        function result = IsValidProjectName( name )
            result = ~isempty(regexp(name,'^[_a-zA-Z0-9]+$','ONCE') );
        end
    end
end

