********************************************************************************
// IPWCOMP - MATA Routine to Compute inverse probability weights
********************************************************************************
// This performs IPW as in Campbell et al (2014) Science Paper
// Arguments:
// A							-  (string name of) Matrix of (permuted) outcomes (ni x np)
// D							-  (string name of) Matrix of treatment indicator (ni x 1)
// covars						-  (string name of) Matrix of control variables in IPW regression (ni x nk)
// ipWeights					-  (string name of) (returned) Matrix of weights
// ipwfails						-  (string name of) (returned) number of failed iterations
// ipwsucc						-  (string name of) (returned) number of successful iterations
********************************************************************************

cap mata: mata drop ipwcomp()

mata

mata clear  

/* logit */
void logitf(todo,b,data,f,g,H)
{
	real scalar n,k
	real matrix y,x,beta,elta,mu
	n=rows(data)
	k=cols(data)
	y=data[.,1]
	x=data[.,2..k]
	k=cols(x)
	beta=b[1..k]'
	elta=x*beta
	mu=exp(elta):/(1:+exp(elta)) 
	f=y:*ln(mu)+(1:-y):*ln(1:-mu) 
}

/* probit */
void probitf(todo,b,data,f,g,H)
{
	real scalar n,k
	real matrix y,x,beta,elta,mu
	n=rows(data)
	k=cols(data)
	y=data[.,1]
	x=data[.,2..k]
	k=cols(x)
	beta=b[1..k]'
	elta=x*beta
	mu=normal(elta) 
	f=y:*ln(mu)+(1:-y):*ln(1:-mu)
}



void ipwcomp(	///
					string scalar perm, ///
					string scalar treat, ///
					string scalar covars, ///
					string scalar weights, ///
					string scalar ipwfails, ///
					string scalar ipwsucc) 
{

/* initialise objects */
real matrix A, D, X, W
real scalar fail, succ

/*
P = st_matrix(permoutc) // matrix of permuted outcomes
A = P :!=.		// matrix of non-attrited indicators
*/
A = st_matrix(perm) :!=.		// matrix of non-attrited indicators
st_view(D, ., treat) 		// matrix of treatment
st_view(X, ., covars) 		// matrix of covariates
fail = 0
succ = 0

np = cols(A)
ni = rows(X)
nk = cols(X)

/* attach constant to covariates */
X = X, J(ni,1,1)

W = J(ni,np,.)

/* permutation loop */
r=1

while (r<=np) {
	
	/* assemble data */
	AC = A[,r] :* (1:-D)
	ACdata = AC, X
	ACsum = sum(AC)
	AT = A[,r] :* D
	ATdata = AT, X
	ATsum = sum(AT)
	
	/* OLS starting values */
	XpXi = quadcross(X, X)
	XpXi = invsym(XpXi)
	ACbinit  = XpXi*quadcross(X, AC)
	ATbinit  = XpXi*quadcross(X, AT)
	
	/* Controls Optimisation ----------------- */
	SC=optimize_init()
	optimize_init_conv_maxiter(SC,100)
	optimize_init_evaluator(SC,&logitf())
	optimize_init_technique(SC,"nr bhhh")
	optimize_init_evaluatortype(SC,"v0")
	optimize_init_argument(SC,1,ACdata)
	optimize_init_params(SC,ACbinit')
	_optimize(SC)

	errC = optimize_result_errorcode(SC)
	convC = optimize_result_converged(SC)
	
	/* Treated Optimisation ------------------ */
	ST=optimize_init()
	optimize_init_conv_maxiter(ST,100)
	optimize_init_evaluator(ST,&logitf())
	optimize_init_technique(ST,"nr bhhh")
	optimize_init_evaluatortype(ST,"v0")
	optimize_init_argument(ST,1,ATdata)
	optimize_init_params(ST,ATbinit')
	_optimize(ST)

	errT = optimize_result_errorcode(ST)
	convT = optimize_result_converged(ST)
	
	if (errT!=0 | convT!=1 | errC!=0 | convC!=1) { /* if failed */
		fail = fail+1
	}
	else { 	/* if successful */
		/* Assemble Results ---------------------- */
		
		/* Controls: get coefficients */
		ACb=optimize_result_params(SC)'
		/* compute linear index */
		AClinind = X * ACb
		/* compute predicted value (logit) */
		ACip = 1 :/ ((exp(AClinind)):/(1:+exp(AClinind)))
		AC2sum = sum(AC :* ACip)
		ACipw = ACip :/(AC2sum/ACsum)
		
		
		/* Treated: get coefficients */
		ATb=optimize_result_params(ST)'
		/* compute linear index */
		ATlinind = X * ATb
		/* compute predicted value (logit) */
		ATip = 1 :/ ((exp(ATlinind)):/(1:+exp(ATlinind)))
		AT2sum = sum(AT :* ATip)
		ATipw = ATip :/(AT2sum/ATsum)
		
		/* combine treated and untreated weights */
		W[1..ni,r]=D:*ATipw + (1:-D) :*ACipw
		
		succ = succ + 1
		
	}		/* if successful */

		r=r+1
} /* permutation loop */

st_matrix(weights, W)
st_numscalar(ipwfails, fail)
st_numscalar(ipwsucc, succ)

}

end



********************************************************************************
// IPW - Wrapper to Compute inverse probability weights
********************************************************************************
// This performs IPW as in Campbell et al (2014) Science Paper
// Options:
// permoutc()							-  Matrix of permuted outcomes
// permmat()							-  Matrix of treatments
// covars()								-  Control variables in IPW regression
// link()								-  Probit or Logit
********************************************************************************

cap program drop ipweights

program ipweights, rclass

syntax [if], permoutc(string) treat(varlist min=1 max=1) covars(varlist min=1) [link(string)]

// ERRORS ----------------------------------------------------------------------
if "`link'"=="" local link "logit"			// default link to logit

if "`link'"!="probit" & "`link'"!="logit" {
	di as error "Link must be either 'probit' or 'logit'"
	exit 111
}


quietly {
// recast covariates to double
recast double `covars'

// call routine
mata: ipwcomp("`permoutc'", "`treat'", "`covars'", "weights", "nfails", "nsucc")

}

return matrix weights = weights
return scalar nfails = nfails
return scalar nsucc = nsucc

end
