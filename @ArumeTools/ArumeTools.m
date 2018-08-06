classdef ArumeTools
    %ARUMETOOLS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    methods(Static=true)
        function dataTable = GetDataTable(subjects, sessionCodes)
            getAllSubjects = false;
            if (~exist('subjects','var') && ~exist('sessionCodes','var'))
                getAllSubjects = true;
            end
            
            if (~exist('subjects','var') || ~iscell(subjects) )
                error('Needs to specify the list of subjects in cell form. For example {''subj1'' ''subj2''}.');
            end
            
            if (~exist('sessionCodes','var') || ~iscell(sessionCodes) )
                error('Needs to specify the list of session codes in cell form. For example {''sess1'' ''sess2''}.');
            end
            
            dataTable = [];
            a = Arume;
            if ( isempty(a.currentProject) )
                msgbox('A project must be opened first in Arume');
                return;
            end
            if ( ~getAllSubjects )
                dataTable = a.currentProject.GetDataTable(subjects,sessionCodes);
            else
                dataTable = a.currentProject.GetDataTable();
            end
        end
    end
    
end

