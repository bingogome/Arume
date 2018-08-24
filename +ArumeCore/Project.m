classdef Project < handle
    %PROJECT Class handingling Arume projects
    %
    
    properties( SetAccess = private)
        name        % Name of the project
        path        % Working path of the uncompressed project (typically the temp folder)
        
        defaultExperiment % default experiment for this project
        
        sessions    % Sessions that belong to this project
    end
    
    methods(Access=private)
        %
        % Initialization methods
        %
        % Always use the static methods Load and Create to create new
        % project objects.
        function initNew( this, parentPath, projectName, defaultExperiment )
            % Initializes a new project
            
            if ( ~exist( parentPath, 'dir' ) )
                error( 'Arume: folder does not exist.' );
            end
            
            if ( exist( fullfile(parentPath, projectName), 'dir' ) )
                error( 'Arume: project file already exists.' );
            end
            
            % initialize the project
            this.name               = projectName;
            this.path               = fullfile(parentPath, projectName);
            this.defaultExperiment  = defaultExperiment;
            this.sessions           = [];
            
            % prepare folder structure
            mkdir( parentPath, projectName );
            
            % save the project
            this.save();
        end
        
        function initExisting( this, path )
            % Initializes a project loading from a folder
            
            if ( ~exist( path, 'dir' ) )
                error( 'Arume: project folder does not exist.' );
            end
            
            [~, projectName] = fileparts(path);
            projectMatFile = fullfile(path, [projectName '_ArumeProject.mat']);
            
            % load project data
            data = load( projectMatFile, 'data' );
            data = data.data;
            
            % initialize the project
            this.name               = projectName;
            this.path               = path;
            this.defaultExperiment  = data.defaultExperiment;
            this.sessions           = [];
            
            % find the session folders
            d = struct2table(dir(path));
            d = d(d.isdir & ~strcmp(d.name,'.') & ~strcmp(d.name,'..'),:);
            
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
        end
    end
    
    methods
        %
        % Save project
        %
        function save( this )
            % for safer storage do not save the actual matlab Project
            % object. Instead create a struct and save that. It will be
            % more robust to version changes.
            data = [];
            data.defaultExperiment = this.defaultExperiment;
            
            for session = this.sessions
                session.save();
            end
            
            % Save the data structure
            filename = fullfile( this.path, [this.name '_ArumeProject.mat']);
            save( filename, 'data' );
            
            disp('======= ARUME PROJECT SAVED TO DISK REMEMBER TO BACKUP ==============================')
            try
                tbl = this.GetDataTable;
                if (~isempty(tbl) )
                    writetable(tbl,fullfile(this.path, [this.name '_ArumeSessionTable.xlsx']));
                end
                
                disp('======= ARUME EXCEL DATA SAVED TO DISK ==============================')
            catch err
                disp('ERROR saving excel data');
                disp(err.getReport);
            end
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
        
        function [session, i] = findSession( this, experimentName, subjectCode, sessionCode)
            
            for i=1:length(this.sessions)
                if ( exist('sessionCode','var') )
                    if ( strcmpi(this.sessions(i).experiment.Name, upper(experimentName)) &&  ...
                            strcmpi(this.sessions(i).subjectCode, upper(subjectCode)) &&  ...
                            strcmpi(this.sessions(i).sessionCode, upper(sessionCode)))
                        session = this.sessions(i);
                        return;
                    end
                else
                    if ( strcmpi(this.sessions(i).experiment.Name, upper(experimentName)) &&  ...
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
        function dataTable = GetDataTable(this, subjectSelection, sessionSelection)
            allSubjects = {};
            allSessionCodes = {};
            for session=this.sessions
                allSubjects{end+1} = session.subjectCode;
                allSessionCodes{end+1} = session.sessionCode;
            end
            if ( ~exist( 'subjectSelection', 'var' ) && ~exist( 'sessionSelection', 'var' ))
                subjectSelection = unique(allSubjects);
                sessionSelection = unique(allSessionCodes);
            end
            
            dataTable = table();
            for isess=1:length(this.sessions)
                session=this.sessions(isess);
                % if this is one of the sessions we want
                if ( any(categorical(subjectSelection) == session.subjectCode) && any(categorical(sessionSelection)==session.sessionCode))
                    sessionRow = session.sessionDataTable;
                    if ( isempty( sessionRow ) )
                        sessionRow = table();
                        sessionRow.Subject = categorical(cellstr(session.subjectCode));
                        sessionRow.SessionCode = categorical(cellstr(session.sessionCode));
                        sessionRow.Experiment = categorical(cellstr(session.experiment.Name));
                    end
                    if ( isempty(dataTable))
                        dataTable = sessionRow;
                    else
                        dataTable = VertCatTablesMissing(dataTable, sessionRow);
                    end
                end
            end 
            
            disp(dataTable)
            assignin('base','ProjectTable',dataTable);
        end
    end
    
    
    methods ( Static = true )
        
        %
        % Factory methods
        %
        function project = NewProject( parentPath, projectName, defaultExperiment)
            
            % check if parentFolder exists
            if ( ~exist( parentPath, 'dir' ) )
                error('Arume: parent folder does not exist');
            end
            
            % check if name is a valid name
            if ( ~ArumeCore.Project.IsValidProjectName( projectName ) )
                error('Arume: project name is not valid');
            end
            
            % create project object
            project = ArumeCore.Project();
            project.initNew( parentPath, projectName, defaultExperiment );
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
                    if ( strcmp(sessionData.experimentName, 'MVSTorsion') )
                        oldSessionName = [sessionData.experimentName '_' sessionData.subjectCode sessionData.sessionCode];
                        sessionData.experimentName = 'EyeTracking';
                        newSessionName = [sessionData.experimentName '_' sessionData.subjectCode sessionData.sessionCode];
                        movefile(fullfile(path,oldSessionName) ,fullfile(path,newSessionName))
                    end
                    
                    
                    sessionName = [sessionData.experimentName '_' sessionData.subjectCode sessionData.sessionCode];
                    
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
                    
                    
                    
                    filename = fullfile( fullfile(path, sessionName), [sessionName '_ArumeSession.mat']);
                    save( filename, 'sessionData' );
                end
                data = rmfield(data,'sessions');
                % TODO: maybe save the updated data without sessions.
                
                disp('... Done updating file structure.');
            end
        end
        
        function newRun = UpdateRun(runData,experimentName)
            
            experimentDesign = ArumeCore.ExperimentDesign.Create( [], experimentName );
            experimentDesign.init();
            
            if ( isempty( runData) )
                newRun = ArumeCore.ExperimentRun.SetUpNewRun( experimentDesign );
                vars = newRun.futureTrialTable;
                vars.TrialResult = 0;
                newRun.AddPastTrialData(vars);
                newRun.futureTrialTable(:,:) = [];
            else
                
                newRun = runData;
                
                futureConditions = runData.futureConditions;
                f2 = table();
                f2.TrialNumber = (1:length(futureConditions(:,1)))';
                f2.Condition = futureConditions(:,1);
                f2.BlockNumber = futureConditions(:,2);
                f2.BlockSequenceNumber = futureConditions(:,3);
                
                t2 = table();
                for i=1:height(f2)
                    vars = experimentDesign.getVariablesCurrentCondition( f2.Condition(i) );
                    t2 = cat(1,t2,struct2table(vars,'AsArray',true));
                end
                
                newRun.futureTrialTable = [f2 t2];
                
                
                futureConditions = runData.originalFutureConditions;
                f2 = table();
                f2.TrialNumber = (1:length(futureConditions(:,1)))';
                f2.Condition = futureConditions(:,1);
                f2.BlockNumber = futureConditions(:,2);
                f2.BlockSequenceNumber = futureConditions(:,3);
                
                
                t2 = table();
                for i=1:height(f2)
                    vars = experimentDesign.getVariablesCurrentCondition( f2.Condition(i) );
                    t2 = cat(1,t2,struct2table(vars,'AsArray',true));
                end
                
                newRun.originalFutureTrialTable = [f2 t2];
                
                
                pastConditions = runData.pastConditions;
                
                f2 = table();
                f2.TrialAttempt = (1:length(pastConditions(:,1)))';
                f2.Session = pastConditions(:,5);
                f2.TrialNumber = nan(size(f2.TrialAttempt));
                f2.Condition = pastConditions(:,1);
                f2.BlockNumber = pastConditions(:,3);
                f2.BlockSequenceNumber = pastConditions(:,4);
                
                t2 = table();
                for i=1:height(f2)
                    vars = experimentDesign.getVariablesCurrentCondition( f2.Condition(i) );
                    t2 = cat(1,t2,struct2table(vars,'AsArray',true));
                end
                f2 = [f2 t2];
                
                i=1;
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
                
                f2.TimePreTrialStart = ev(ev(:,3)==Enum.Events.PRE_TRIAL_START ,1);
                if ( length(f2.TimePreTrialStart) == length(ev(ev(:,3)==Enum.Events.PRE_TRIAL_STOP ,1)))
                    f2.TimePreTrialStop = ev(ev(:,3)==Enum.Events.PRE_TRIAL_STOP ,1);
                    f2.TimeTrialStart = ev(ev(:,3)==Enum.Events.TRIAL_START ,1);
                    f2.DateTimeTrialStart = datestr(ev(ev(:,3)==Enum.Events.TRIAL_START ,2));
                else
                    % crashed during pre trial
                    f2.TimePreTrialStop(pastConditions(:,2)<2) = ev(ev(:,3)==Enum.Events.PRE_TRIAL_STOP ,1);
                    f2.TimeTrialStart(pastConditions(:,2)<2) = ev(ev(:,3)==Enum.Events.TRIAL_START ,1);
                    f2.DateTimeTrialStart(find(pastConditions(:,2)<2),:) = datestr(ev(ev(:,3)==Enum.Events.TRIAL_START ,2));
                end
                f2.TrialResult = pastConditions(:,2);
                % from here on only if trialresult is correct or abort
                f2.TimeTrialStop(f2.TrialResult<2) = ev(ev(:,3)==Enum.Events.TRIAL_STOP ,1);
                f2.TimePostTrialStart(f2.TrialResult<2) = ev(ev(:,3)==Enum.Events.POST_TRIAL_START ,1);
                f2.TimePostTrialStop(f2.TrialResult<2) = ev(ev(:,3)==Enum.Events.POST_TRIAL_STOP ,1);
                f2.TrialNumber(f2.TrialResult<2) = 1:sum(f2.TrialResult<2);
                
                tout = table();
                for i=1:height(f2)
                    if ( isfield(runData.Data{i}, 'trialOutput' ) && ~isempty(runData.Data{i}.trialOutput) )
                        trialOutput = runData.Data{i}.trialOutput;
                    else
                        trialOutput = struct();
                    end
                    
                    if ( ~isempty( tout ) )
                        t1 = tout;
                        t2 = struct2table(trialOutput,'AsArray',true);
                        t1colmissing = setdiff(t2.Properties.VariableNames, t1.Properties.VariableNames);
                        t2colmissing = setdiff(t1.Properties.VariableNames, t2.Properties.VariableNames);
                        t1 = [t1 array2table(nan(height(t1), numel(t1colmissing)), 'VariableNames', t1colmissing)];
                        t2 = [t2 array2table(nan(height(t2), numel(t2colmissing)), 'VariableNames', t2colmissing)];
                        for colname = t1colmissing
                            if iscell(t2.(colname{1}))
                                t1.(colname{1}) = cell(height(t1), 1);
                            end
                        end
                        for colname = t2colmissing
                            if iscell(t1.(colname{1}))
                                t2.(colname{1}) = cell(height(t2), 1);
                            end
                        end
                        tout = [t1; t2];
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

