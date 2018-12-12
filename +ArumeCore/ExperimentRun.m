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
        
        function trialData = AddPastTrialData(this, trialData)
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
            newRun.pastTrialTable           = table([],categorical([]),'VariableNames',{'TrialNumber' 'TrialResult'});
            newRun.originalFutureTrialTable = experimentDesign.GetTrialTable();
            newRun.futureTrialTable         = newRun.originalFutureTrialTable;
        end
        
        function run = LoadRunData( data )
            
            % create the new object
            run = ArumeCore.ExperimentRun();
            
            run.pastTrialTable              = data.pastTrialTable;
            run.futureTrialTable            = data.futureTrialTable;
            run.originalFutureTrialTable    = data.originalFutureTrialTable;
            
            if ( isfield( data, 'LinkedFiles' ) )
                run.LinkedFiles = data.LinkedFiles;
            else
                run.LinkedFiles = [];
            end
        end
        
        function runArray = LoadRunDataArray( runs )
            runArray = [];
            for i=1:length(runs)
                runArray  = cat(1,runArray, ArumeCore.ExperimentRun.LoadRunData( runs(i) ));
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
                runArray  = cat(1,runArray, ArumeCore.ExperimentRun.SaveRunData(runs(i)));
            end
        end
    end
    
end

