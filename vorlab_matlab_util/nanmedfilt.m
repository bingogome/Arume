%%
function [y, notnan] = nanmedfilt(x,w,minSamplesFraction)

if ( ~exist('minSamplesFraction','var') )
    minSamples = 0;
else
    minSamples = w*minSamplesFraction;
end

% get the median filtering
y = medfilt1(x,w,'omitnan','truncate');

% count how many non nan samples went into each sample
notnan = boxcar(~isnan(x),w);

% apply the minimum
y(notnan<minSamples/w) = nan;

