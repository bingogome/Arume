function hp = plotErrorPatch(x,y,e, varargin)

errplus = y + e;
errminus = y - e;
notnans = ~isnan(errplus) & ~isnan(errplus);

x = x(notnans);
errplus = errplus(notnans);
errminus = errminus(notnans);

xvalues_double = [x   x(end:-1:1)];
err =	[errplus;errminus(end:-1:1)];


hp = patch( xvalues_double, err, varargin{:});
end