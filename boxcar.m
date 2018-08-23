function y = boxcar(x, n,n1)
% Fast function to apply a boxcar filter
% Takes into account edge effects
% Jorge Otero-Millan - Feb'2008

y = zeros(size(x));
if ( size(x,2) > 1 )
    for icol = 1:size(x,2)
        y(:,icol) = boxcar(x(:,icol),n);
    end
else
    % first we interpolate in the case there are NaNs in the data so they don't
    % propagate with the size of the window.

    if ( sum(isnan(x)) > 0 )
        x(isnan(x)) = interp1( find( ~isnan(x)), x(~isnan(x)), find( isnan(x) ), 'linear' );
    end

    % we add zeros at the end so we can get all the data in the outpu
    x = [x;zeros(n,1)];

    % filter with boxcar of size n
    b = ones(1,n)/n;
    a = 1;
    y = filter( b, a, x );

    % correct the samples at the begining and the end
    for i=floor(n/2):n
        y(i)       = y(i) * n / i;
        if( i > 1 )
            y(end-i+1) = y(end-i+1) * n / (i-1);
        end
    end

    % crop the data at the begining and the end
    y = y( ceil(n/2) : end-floor(n/2)-1 );
end