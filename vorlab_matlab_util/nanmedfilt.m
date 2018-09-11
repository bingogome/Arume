%%
function y = nanmedfilt(x,w)

y = nan(size(x));

for i=1:length(x)
    idx = i+(-w/2:w/2);
    idx(idx<1) = [];
    idx(idx>length(x)) = [];
    
    if( sum(~isnan(x(idx))) > 5 )
        y(i) = nanmedian(x(idx));
    end
end


