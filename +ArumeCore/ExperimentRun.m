classdef ExperimentRun < matlab.mixin.Copyable
    %EXPERIMENTRUN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % IMPORTANT! all properties must be saved in the method
        % SaveRunData and loaded in LoadRunData
                
        pastTrialTable              = table();
        futureTrialTable            = table();
        originalFutureTrialTable    = table();
        
        LinkedFiles
    end
    
    methods        
        function run = Copy(this)
            run = copy(this); 
        end
        
        function trialData = AddPastTrialData(this, trialData)
            
            % remove empty fields. This will avoid problems when adding an
            % empty or missing element to the first row.
            % It is better to wait until some none empty element is added
            % so the type of the column is stablished. Then, the trials
            % without that column will receive the proper missing value.
            fs = fieldnames(trialData);
            for i=1:length(fs)
                if ( isempty( trialData.(fs{i})) )
                    trialData = rmfield(trialData,fs{i});
                elseif ( iscell(trialData.(fs{i})) && length(trialData.(fs{i}))==1 && isempty(trialData.(fs{i}){1}) )
                    trialData = rmfield(trialData,fs{i});
                elseif ( ismissing(trialData.(fs{i})) )
                    trialData = rmfield(trialData,fs{i});
                end
            end
            
            
            trialData = struct2table(trialData,'AsArray',true);
            
            this.pastTrialTable  = VertCatTablesMissing(this.pastTrialTable,trialData);
            this.pastTrialTable
        end
    end
    
    methods(Static=true)
        
        %% setUpNewRun
        function newRun = SetUpNewRun( experimentDesign )
            
            newRun = ArumeCore.ExperimentRun();
            
            newRun.pastTrialTable   = table(); % conditions already run, including aborts
            newRun.futureTrialTable = table(); % conditions left for running (the whole list is created a priori)
            newRun.LinkedFiles      = [];
            
            newRun.futureTrialTable = experimentDesign.GetTrialTable();
            newRun.originalFutureTrialTable = newRun.futureTrialTable;
            % TODO: check if the table has the needed columns for dealing
            % drops blockid and blockseq
            
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
        
        function runArray = LoadRunDataArray( runsData, experiment )
            runArray = [];
            for i=1:length(runsData)
                if ( isempty(runArray) )
                    runArray  = ArumeCore.ExperimentRun.LoadRunData( runsData(i), experiment );
                else
                    runArray(i)  = ArumeCore.ExperimentRun.LoadRunData( runsData(i), experiment );
                end
            end
        end
        
        function runData = SaveRunData( run )
            
            runData.pastTrialTable = run.pastTrialTable;
            runData.futureTrialTable = run.futureTrialTable;
            runData.originalFutureTrialTable = run.originalFutureTrialTable;
            
            runData.LinkedFiles = run.LinkedFiles;
        end
        
        function runDataArray = SaveRunDataArray( runs )
            runDataArray = [];
            for i=1:length(runs)
                if ( isempty(runDataArray) )
                    runDataArray = ArumeCore.ExperimentRun.SaveRunData(runs(i));
                else
                    runDataArray(i) = ArumeCore.ExperimentRun.SaveRunData(runs(i));
                end
            end
        end
    end
    
end

