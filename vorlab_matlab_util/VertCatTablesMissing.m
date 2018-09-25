function dataTable = VertCatTablesMissing(t1,t2)
% Concatenates two tables that may have different variables
% adding missing elements where it corresponds.
%
if ( ~istable(t1) )
    t1 = table();
end
if ( ~istable(t2) )
    t2 = table();
end

t1colmissing = setdiff(t2.Properties.VariableNames, t1.Properties.VariableNames,'stable');
t2colmissing = setdiff(t1.Properties.VariableNames, t2.Properties.VariableNames,'stable');

% cannot add missing to cell columns
t1colmissingCells = {};
for colname = t1colmissing
    if iscell(t2.(colname{1}))
        t1colmissingCells(end+1) = colname;
    end
end
t1colmissing = setdiff(t1colmissing, t1colmissingCells,'stable');
t2colmissingCells = {};
for colname = t2colmissing
    if iscell(t1.(colname{1}))
        t2colmissingCells(end+1) = colname;
    end
end
t2colmissing = setdiff(t2colmissing, t2colmissingCells,'stable');

for colname = t1colmissingCells
    t1.(colname{1}) = cell(height(t1), 1);
end
for colname = t2colmissingCells
    t2.(colname{1}) = cell(height(t2), 1);
end


t1andt2 = intersect(t2.Properties.VariableNames, t1.Properties.VariableNames, 'stable');

% first concatenate the common columns
t = [t1(:,t1andt2);t2(:,t1andt2)];
% then add to the unique columns of t1 missing
% rows for each element of t2
t12 = t1(:,t2colmissing);
if ( height(t2)>0 && ~isempty(t2colmissing))
    t12{height(t1)+(1:height(t2)),:} = missing;
end
% then add to the unique columns of t2 missing
% rows for each element of t1
t21 = t2(:,t1colmissing);
if ( height(t1)>0 && ~isempty(t1colmissing))
    t21{height(t2)+(1:height(t1)),:} = missing;
    % move the values up so the rows match
    t21 = [t21(height(t2)+1:end,:);t21(1:height(t2),:)];
end

% concatenate the 3 tables
if ( ~isempty( t) && ~isempty( t12) && ~isempty( t21) )
    dataTable = [t t12 t21];
elseif ( ~isempty( t) && ~isempty( t12) && isempty( t21) )
    dataTable = [t t12];
elseif ( ~isempty( t) && isempty( t12) && ~isempty( t21) )
    dataTable = [t t21];
elseif ( isempty( t) && ~isempty( t12) && ~isempty( t21) )
    dataTable = [t12 t21];
elseif ( ~isempty( t) && isempty( t12) && isempty( t21) )
    dataTable = t;
elseif ( isempty( t) && ~isempty( t12) && isempty( t21) )
    dataTable = t12;
elseif ( isempty( t) && isempty( t12) && ~isempty( t21) )
    dataTable = t21;
end

end