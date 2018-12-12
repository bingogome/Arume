
#ifndef MLF_V2
#define MLF_V2 1
#endif

#ifndef V4_COMPAT
#define V4_COMPAT 1
#endif

#include "mex.h" 

#include "mclmcr.h"

void bins(double *vec, int lngth, double item,double *z) {

        int low=0,high=lngth-1;
        int mid;

    if (item<=vec[0]) {
	
	*z=1.0;
	return;
	
    }
    while ((high-low) > 1) {
        
        mid=(high+low)/2;
        
        if (item>vec[mid]) {

        low=mid;
 
        } else {

        high=mid;
                       
        }
    }

	*z=high+1.0;

}



void mexFunction(int nlhs, mxArray *plhs[], int nrhs, mxArray *prhs[]) {

	double *vec=mxGetPr(prhs[0]);
	double lngth=mxGetN(prhs[0]);
	double *item=mxGetPr(prhs[1]);
	int howmany=mxGetN(prhs[1]);
	int i;
	double *z;

	if (nrhs!=2 || nlhs>1) {

   	mexErrMsgTxt("Wrong number of inputs or outputs.");
	}

	plhs[0]=mxCreateDoubleMatrix(1,howmany,mxREAL);	

	z=mxGetPr(plhs[0]);

	for (i=0;i<howmany;i++) {

	bins(vec,lngth,item[i],(z+i));

	}
}


