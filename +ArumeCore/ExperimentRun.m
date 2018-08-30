classdef ExperimentRun < matlab.mixin.Copyable
    %EXPERIMENTRUN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties 
        pastTrialTable              = table(); % trials already run, including aborts
        futureTrialTable            = table(); % trials left for running (the whole list is created a priori)
        originalFutureTrialTable    = table();
        
        LinkedFiles                 = [];
    end
    
    methods        
        function run = Copy(this)
            run = copy(this); 
        end
        
        function trialData = AddPastTrialData(this, variables, trialOutput)
            
            if ( istable(trialOutput) )
                trialData = [variables trialOutput];
            elseif ( isstruct(trialOutput) )
                trialData = [variables struct2table(trialOutput,'AsArray',true)];
            else
                error('trialOutput should be either a table or a struct');
            end
            
            %TODO: at the moment trialOutput cannot have cells or arrays.
            %Need to fix at some point
                                
            % remove empty fields. This will avoid problems when adding an
            % empty or missing element to the first row.
            % It is better to wait until some none empty element is added
            % so the type of the column is stablished. Then, the trials
            % without that column will receive the proper missing value.
            fs = trialData.Properties.VariableNames;
            for i=1:length(fs)
                if ( isempty( trialData.(fs{i})) )
                    trialData(:,fs{i}) = [];
                elseif ( iscell(trialData.(fs{i})) && length(trialData.(fs{i}))==1 && isempty(trialData.(fs{i}){1}) )
                    trialData(:,fs{i}) = [];
                elseif ( ismissing(trialData.(fs{i})) )
                    trialData(:,fs{i}) = [];
                end
            end
            
            this.pastTrialTable = VertCatTablesMissing(this.pastTrialTable,trialData);
        end
    end
    
    methods(Static=true)
        
        %% setUpNewRun
        function newRun = SetUpNewRun( experimentDesign )
            newRun = ArumeCore.ExperimentRun();
            newRun.futureTrialTable         = experimentDesign.GetTrialTable();
            newRun.originalFutureTrialTable = newRun.futureTrialTable;
        end
        
        function run = LoadRunData( data, experiment )
            
            % create the new object
            run = ArumeCore.ExperimentRun();
            
            run.pastTrialTable = data.pastTrialTable;
            run.futureTrialTable = data.futureTrialTable;
            run.originalFutureTrialTable = data.originalFutureTrialTable;
            
            if ( isfield( data, 'LinkedFiles' ) )
                run.LinkedFiles = data.LinkedFiles;
            else
                run.LinkedFiles = [];
            end
        end
        
        function runArray = LoadRunDataArray( runs, experiment )
            runArray = [];
            for i=1:length(runs)
                if ( isempty(runArray) )
                    runArray  = ArumeCore.ExperimentRun.LoadRunData( runs(i), experiment );
                else
                    runArray(i)  = ArumeCore.ExperimentRun.LoadRunData( runs(i), experiment );
                end
            end
        end
        
        function runData = SaveRunData( run )
            
            runData.pastTrialTable = run.pastTrialTable;
            runData.futureTrialTable = run.futureTrialTable;
            runData.originalFutureTrialTable = run.originalFutureTrialTable;
            
            runData.LinkedFiles = run.LinkedFiles;
        end
        
        function runArray = SaveRunDataArray( runs )
            runArray = [];
            for i=1:length(runs)
                if ( isempty(runArray) )
                    runArray = ArumeCore.ExperimentRun.SaveRunData(runs(i));
                else
                    runArray(i) = ArumeCore.ExperimentRun.SaveRunData(runs(i));
                end
            end
        end
    end
    
end

