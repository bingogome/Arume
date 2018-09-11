% BINS Binary search.
%	
%	BINS searches one vector for the elements of another using 
%	binary search.
%	
%	V=BINS(A,B) returns the indices of first elements in A that are 
%	greater than or equal to the elements of B. If no greater elements 
%	are found, BINS returns length(A).
%	
%	Note that A and B must be nonnegative row vectors (and you 
%	probably want A to be sorted).
%
%	Warning: prone to crashing if used without care.
%
%	Example:
%
%	A=[1 2 3 4 5]; B=[.1 1 1.1 6];
%
%	bins(A,B) returns [1 1 2 5].	
%


