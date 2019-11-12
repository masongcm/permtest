/*
********************************************************************************
// PERMTEST -  main function
********************************************************************************
// Arguments:
// varlist		 						-  Outcomes
//								if they end in "_r", they will be reversed
//
// Options for Permutation:
// treat()		 						-  Treatment Indicator
// np()									-  Number of permutations
// blockvars()							-  (optional) List of variables to be used for block permutation (if not specified, naive)
// lcvars()								-  (optional) List of variables to be used for linear conditioning
// sdmethod()							-  (optional) Which stepdown method to use (rw16 or rp)
// naive								-  (optional) Whether to perform naive permutation (overrides blockvars)
// reverse								-  (optional) Whether to reverse ALL outcomes for pvalues and TEs
//
// Options for IPW:
// link()								-  (optional) Probit or Logit link
// ipwcovars1()							-  (optional) Control variables for IPW (applies to all variables if specified alone)
// ipwcovars2()-ipwcovars5()			-  (optional) Additional Control variables for IPW (if different for each outcome)
//											NOTE: write NA to have gaps
//
// Generic options
// verbose								-  (optional) Print full progress of routine
// effsize								-  (optional) Display effects in terms of effect size
// savemat								-  (optional) File to save results matrix (csv)
********************************************************************************


#delimit ;

cap program drop permtest;

program permtest, rclass;

syntax varlist (min=1) [if], 		Treat(varlist)
									np(integer)
									[
									Blockvars(varlist) 
									LCvars(varlist)
									link(string) 
									sdmethod(string) 
									naive
									REVerse
									VERbose
									effsize
									savemat(string)
									ipwcovars1(string) 
									ipwcovars2(string) 
									ipwcovars3(string) 
									ipwcovars4(string) 
									ipwcovars5(string)
									];
*/
									
/***
_v. 1.0.0_ 

Title
====== 

__permtest__ -- Permutation inference for linear models.


Syntax
------ 

> __permtest__ _depvars_ [_if_] [, _options_]


_options_

- - -

	__treat__: Treatment indicator (required, must be 0/1)  

Permutation inference  
	__np__: Number of permutations (required)  
	__blockvars__ (_varlist_): variables to be used for block permutation (if not specified, defaults to naive)  
	__lcvars__ (_varlist_): variables to be used for linear conditioning  
	__naive__: whether to perform naive permutation, disregarding blocks (overrides __blockvars__)  
	
Inverse probability weighting  
	__ipwcovars1__ (_varlist_): variables for IPW step (applies to all outcomes in _depvars_ if specified alone)  
	__ipwcovars2-ipwcovars5__ : variables for IPW step (applies to each separate outcome in _depvars_)  
	
Saving  
	__savemat__  (_string_): path where to save output in matrix form  
	
Other  
	__reverse__: reverse sign of outcomes for treatment effects  
	__effsize__: display treatment effects in terms of effect size (standardised by control group SD)  
	__verbose__: print more information about progress to console  

- - -

__by__ is allowed; see __[[D] by](help by)__  
__fweight__ is allowed; [weight](help weight)  


Description
-----------

__permtest__ performs permutation-based inference with multiple outcomes

Options
-------

__whatever__ does yak yak

> Use __>__ for additional paragraphs within and option 
description to indent the paragraph.

__2nd option__ etc.

Remarks
-------

The remarks are the detailed description of the command and its 
nuances. Official documented Stata commands don't have much for 
remarks, because the remarks go in the documentation.

Example(s)
----------

    explain what it does
        . example command

    second explanation
        . example command

Stored results
--------------

__commandname__ stores the following in __r()__ or __e()__:

Scalars

> __r(N)__: number of observations 

Macros

Matrices

Functions

Acknowledgements
----------------

If you have thanks specific to this command, put them here.

Author
------

Author information here; nothing for official Stata commands
leave 2 white spaces in the end of each line for line break. For example:

Your Name   
Your affiliation    
Your email address, etc.    

References
----------

Author Name (year), [title & external link](http://www.haghish.com/markdoc/)

- - -

This help file was dynamically produced by 
[MarkDoc Literate Programming package](http://www.haghish.com/markdoc/) 
***/


//OFF

/*
********************************************************************************
// PCOMPUTE -  MATA routine to compute stepdown pvalues after permutation
********************************************************************************
// nh = number of hypotheses tested jointly
// nr = number of permutations
// Arguments:
// ts 								-  original statistic for each H (1 x nh)
// ts 								-  matrix of permuted statistics (nr x nh)
// sides 							-  one or two sided test
********************************************************************************
*/

cap mata: mata drop pcompute_perm()
cap mata: mata drop pcompute_permsd()

mata

/* FUNCTION FOR PERMUTATION PVALUES *******************************************/

function pcompute_perm(ts,tp) 
{

/* PRELIMS -------------------------------------------------------------------*/
/* rows and columns */
nh = cols(tp)
nr = rows(tp)

/* allocate p for each hypothesis */
preg = J(1,nh,.)

/* one-sided test */
	tsa = ts
	tpa = tp

	h=1
	for (h=1; h<=nh; h++) {
		tvec = J(nr,1,tsa[1,h])
		fails = sum((tpa[.,h]-tvec):>0)
		preg[1,h] = fails/nr
	}

return(preg)
}

/* FUNCTION FOR STEPDOWN PVALUES **********************************************/
function pcompute_permsd(ts,tp,string scalar method) 
{
	
/* PRELIMS -------------------------------------------------------------------*/
/* rows and columns */
nh = cols(tp)
nr = rows(tp)

/* one-sided test */
tsa = ts
tpa = tp

/* STEPDOWN PVALUES ----------------------------------------------------------*/

/* give column numbers to hypotheses */
tsa2 = (1::nh)'\tsa

/* sort by highest t */
tsa_sorted = sort(tsa2', -2)'

/* map btw sorted and unsorted hypotheses */
/* row: original ordering */
sortmap = tsa_sorted[1,.]

/* remove top row from the sorted statistics */
tsa_sorted = tsa_sorted[2,.]

/* sort matrix of statistics in same way */
tpa_sorted = J(nr,nh,.)
for (i=1; i<=nh; i++) {
	j = select((1..nh), (sortmap :== i))
	tpa_sorted[.,j] = tpa[.,i]
}

/* allocate p for each hypothesis */
pvec_sorted = J(1,nh,.)

/* LIKE ROMANO AND WOLF 2016 ------------------------------------------------ */

if (method=="rw16") {
/* pvalue for first hypothesis */
max1vec = rowmax(tpa_sorted)
tvec1 = J(nr,1,tsa_sorted[1,1])
fails1 = sum((max1vec-tvec1):>0)
pvec_sorted[1,1] = fails1/nr

/* pvalue for remaining hypotheses */
h=2
for (h=2; h<=nh; h++) {
		maxvec = rowmax(tpa_sorted[.,h..nh])
		tvec = J(nr,1,tsa_sorted[1,h])
		fails = sum((maxvec-tvec):>0)
		pvec_sorted[1,h] = max((fails/nr, pvec_sorted[1,h-1]))
}
}

/* LIKE RODRIGO ------------------------------------------------------------- */

if (method=="rp") {
nhm = nh-1
h=1
for (h=1; h<=nhm; h++) {
		maxvec = rowmax(tpa_sorted[.,h..nh])
		tvec = J(nr,1,tsa_sorted[1,h])
		fails = sum((maxvec-tvec):>0)
		pvec_sorted[1,h] = fails/nr
}

		tvec = J(nr,1,tsa_sorted[1,nh])
		fails = sum((tpa_sorted[.,nh]-tvec):>0)
		pvec_sorted[1,nh] = fails/nr

}

/* -------------------------------------------------------------------------- */


/* reorder p's according to original ordering */
pvec_orig = J(1,nh,.)
i=1
for (i=1; i<=nh; i++) {
	pvec_orig[1,sortmap[1,i]] = pvec_sorted[1,i]
}

return(pvec_orig)

}

end



********************************************************************************
// RESIDUALISE -  stata function to residualise outcome
********************************************************************************
// Arguments:
// varlist 								-  	first variable: outcome to residualise
//											other variables: linear conditioning variables
// resname()							-  (optional) name for generated residual variable
// predname()							-  (optional) name for generated predicted values variable

********************************************************************************

cap program drop residualise

program residualise, rclass

syntax varlist (min=1) [if] [in], [resname(string) predname(string)]
	local Y : word 1 of `varlist'
	local X `:list varlist - Y'
	marksample touse
	qui reg `Y' `X'
	
	/* assign residuals name if specified */
	if "`resname'" == "" {
		predict `Y'_res, residuals
		recast double `Y'_res
	}
	else {
		predict `resname', residuals
		recast double `resname'
	}
	
	/* assign predicted values name if specified */
	if "`predname'" == "" {
		predict `Y'_pred, xb
		recast double `Y'_pred
	}
	else {
		predict `predname', xb
		recast double `predname'
	}
end

/******************************************************************************/


/*
********************************************************************************
// PERMTEST -  main function
********************************************************************************
// Arguments:
// varlist		 						-  Outcomes
//								if they end in "_r", they will be reversed
//
// Options for Permutation:
// treat()		 						-  Treatment Indicator
// np()									-  Number of permutations
// blockvars()							-  (optional) List of variables to be used for block permutation (if not specified, naive)
// lcvars()								-  (optional) List of variables to be used for linear conditioning
// sdmethod()							-  (optional) Which stepdown method to use (rw16 or rp)
// naive								-  (optional) Whether to perform naive permutation (overrides blockvars)
// reverse								-  (optional) Whether to reverse ALL outcomes for pvalues and TEs
//
// Options for IPW:
// link()								-  (optional) Probit or Logit link
// ipwcovars1()							-  (optional) Control variables for IPW (applies to all variables if specified alone)
// ipwcovars2()-ipwcovars5()			-  (optional) Additional Control variables for IPW (if different for each outcome)
//											NOTE: write NA to have gaps
//
// Generic options
// verbose								-  (optional) Print full progress of routine
// effsize								-  (optional) Display effects in terms of effect size
// savemat								-  (optional) File to save results matrix (csv)
********************************************************************************
*/

#delimit ;

cap program drop permtest;

program permtest, rclass;

syntax varlist (min=1) [if], 		Treat(varlist)
									np(integer)
									[
									Blockvars(varlist) 
									LCvars(varlist)
									link(string) 
									sdmethod(string) 
									naive
									REVerse
									VERbose
									effsize
									savemat(string)
									ipwcovars1(string) 
									ipwcovars2(string) 
									ipwcovars3(string) 
									ipwcovars4(string) 
									ipwcovars5(string)
									];

/* Unabbreviate */
unab varlist 	: `varlist';
unab treat 		: `treat';
if ("`blockvars'"!="") 	unab blockvars 	: `blockvars';
if ("`lcvars'"!="") 	unab lcvars 	: `lcvars';

/* EXTRACT INPUTS */
clear matrix;
local nh: word count `varlist';				/* count number of outcomes */
local nd: word count `treat';				/* count number of treatments supplied (for errors)	*/						
local D : word 1 of `treat';				/* treatment group identifier */

local nip = 0;								/* count sets of IPW covariates */
if ("`ipwcovars1'"!="") local nip = 1;
forvalues i = 2(1)5 {;
	if ("`ipwcovars`i''"!="") local nip = `i';
	};

/* DEFAULTS ------------------------------------------------------------------*/									
if "`link'"=="" local link "logit";			/* default link to logit */
if "`sdmethod'"=="" local sdmethod "rw16";	/* default sdmethod to Romano Wolf 16 */


/* ERRORS --------------------------------------------------------------------*/
if "`link'"!="probit" & "`link'"!="logit" {;
	di as error "Link must be either 'probit' or 'logit'";
	exit 111;
};

if "`link'"=="probit" {;
	di as error " 'probit' link not supported yet";
	exit 111;
};

if (`nd' !=1 ) {;
	di as error "Only 1 treatment indicator can be supplied";
	exit 111;
};

qui su `D';
if (r(max)!=1 | r(min)!=0 ) {;
	di as error "Treatment indicator must be 0 (control) 1 (treated)";
	exit 111;
};

cap assert missing(`D'), fast;
if !_rc {;
	di as error "Treatment indicator cannot contain missings";
	exit 111;
};

if ("`sdmethod'" != "rw16" & "`sdmethod'" != "rp") {;
	di as error "Stepdown method must be either Romano-Wolf ('rw16') or Rodrigo's ('rp')";
	exit 111;
	};

if (missing(`np')) "Must supply number of permutations [np()]";

if ("`ipwcovars1'"=="" & ("`ipwcovars2'"!="" | "`ipwcovars3'"!="" | "`ipwcovars4'"!="" | "`ipwcovars5'"!="")) {;
	di as error	"WARNING: You should specify first set of ipwcovars, and then 2-5!";
	};

if (`nip'>1 & `nip'!=`nh') {;
	di as error	"If you want to specify more than 1 set of IPW covariates,";
	di as error	"the number of IPW sets must match the number of variables in varlist";
	exit 111;
	};
	

/* IF CONDITION --------------------------------------------------------------*/
if "`if'" != "" {;
preserve;
qui keep `if';
};

/* count observations */
qui count;
local ni = r(N);


/* PREALLOCATION -------------------------------------------------------------*/

/* matrix for control/treatment means and sds */
/* columns: C N, C mean, C sd, T N, T mean, T sd, diff */
mat msd 			= J(`nh',7,.);
mat rownames msd 	= `varlist';
mat colnames msd 	= "C N" "C mean" "C SD" "T N" "T mean" "T SD" "T-C Diff";

/* preallocate matrix for permuted t statistics */
/* dimensions: np rows, as many columns as there are hypotheses */
/* NOTE: gets overwritten if using Rodrigo's tstats */
mat tstat_p 		= J(`np',`nh',.);
mat tstat_p_ipw 	= J(`np',`nh',.);

/* preallocate vector for sample t statistics */
mat uteff_s 		= J(1,`nh',.);		/* UNconditional TEs */
mat utese_s 		= J(1,`nh',.);		/* UNconditional TEs Standard Errors */
mat uteff_s_es 		= J(1,`nh',.);		/* UNconditional TEs (effect size) */
mat utese_s_es 		= J(1,`nh',.);		/* UNconditional TEs Standard Errors (effect size) */

mat teff_s 			= J(1,`nh',.);		/* conditional TEs */
mat tese_s 			= J(1,`nh',.);		/* conditional TEs Standard Errors */
mat tstat_s 		= J(1,`nh',.);		/* t-stats */
mat teff_s_es 		= J(1,`nh',.);		/* conditional TEs (effect size) */
mat tese_s_es 		= J(1,`nh',.);		/* conditional TEs Standard Errors (effect size) */

mat teff_s_ipw 		= J(1,`nh',.);		/* conditional TEs with IPW */
mat tese_s_ipw 		= J(1,`nh',.);		/* conditional TEs Standard Errors with IPW */
mat tstat_s_ipw 	= J(1,`nh',.);		/* t-stats with IPW */
mat teff_s_ipw_es 	= J(1,`nh',.);		/* conditional TEs with IPW (effect size) */
mat tese_s_ipw_es 	= J(1,`nh',.);		/* conditional TEs Standard Errors with IPW (effect size) */

mat pval_reg 		= J(1,`nh',.);		/* regular pvalues */
mat pval_reg1s 		= J(1,`nh',.);		/* regular pvalues (1 sided) */
mat pval_reg1s_ipw 	= J(1,`nh',.);		/* regular pvalues (1 sided, IPW) */

/*******************************************************************************/
/*** COMPUTATION STARTS HERE ***************************************************/
/*******************************************************************************/

local h=1;				/* start outcome (hypothesis) counting */

foreach outc of varlist `varlist' {;

	/* OUTCOME REVERSING -----------------------------------------------------*/
	
	/* convert to double precision */
	recast double `outc';
	
	/* generate variable with correct sign based on reverse */
	tempvar `outc'_use;
	if "`reverse'" == "" {;
		qui gen double ``outc'_use' = `outc';
		};
		else {;
		qui gen double ``outc'_use' = -`outc';
	};

	quietly {;
	
	/* progress */
	if "`verbose'"!="" {;
	nois di "";
	if "`reverse'" == "no" nois di as text "Calculating Permuted TEs for `outc':";
	if "`reverse'" == "yes"	nois di as text "Calculating Permuted TEs for `outc' (reversed):";
	};
	
	/* COMPUTATION OF TREATMENT/CONTROL MEANS ------------------------------------*/
	
	/* check if dummy (to not report SD) */
	su `outc';
	scalar dummy_`outc'=0;
	if (r(min)==0 & r(max)==1) scalar dummy_`outc'=1;
	
	/* control mean/sd */
	su `outc' if `D'==0;
	scalar nc_`outc' = r(N);
	scalar mc_`outc' = r(mean);
	scalar sdc_`outc' = r(sd);
	
	/* treatment mean/sd */
	su `outc' if `D'==1;
	scalar nt_`outc' = r(N);
	scalar mt_`outc' = r(mean);
	scalar sdt_`outc' = r(sd);
	
	/* mean difference */
	scalar diff_`outc'=mt_`outc'-mc_`outc';
	
	/* fill in matrix */
	mat msd[`h', 1]=nc_`outc';
	mat msd[`h', 2]=mc_`outc';
	mat msd[`h', 4]=nt_`outc';
	mat msd[`h', 5]=mt_`outc';
	mat msd[`h', 7]=diff_`outc';
	if dummy_`outc'==0 {;
		mat msd[`h', 3]=sdc_`outc';
		mat msd[`h', 6]=sdt_`outc';
	};
	
	
	/* COMPUTATION OF SAMPLE TSTAT AND TREATMENT EFFECT ----------------------*/
	/* compute sample t-stats and treatment effects */
	
	/* get matrix of outcome */
	mkmat ``outc'_use', matrix(outcome);

	/* get IPW weight matrix for sample */
	if (`nip'==1) {; 		/* single set of IPW covariates */
		if ("`ipwcovars1'"!="" & strtrim("`ipwcovars1'")!="NA") {;
			ipweights , permoutc(outcome) treat(`D') covars(`ipwcovars1') link(`link');
			mat ipw_s = r(weights);
		};
		else {;								/* in case of empty input */
			mat ipw_s = J(`ni',1,1);
		};
	};
	else if (`nip'>1) {;	/* multiple sets of IPW covariates */
		if ("`ipwcovars`h''"!="" & strtrim("`ipwcovars`h''")!="NA") {;			
			ipweights , permoutc(outcome) treat(`D') covars(`ipwcovars`h'') link(`link');
			mat ipw_s = r(weights);
		};
		else {;								/* in case of empty input */
			mat ipw_s = J(`ni',1,1);
		};
	};		
	else if (`nip'==0) {;
		mat ipw_s = J(`ni',1,1);
	};

	/* make temporary outcome variable for treatment effects */
	/* depending on reverse and effsize */
	tempvar `outc'_use_es;
	qui su ``outc'_use' if `D'==0;
	gen ``outc'_use_es' = ``outc'_use'/r(sd);
	
	/* obtain UNCONDITIONAL treatment effects */
	reg ``outc'_use' `D';
	mat uteff_s[1,`h'] 		= _b[`D'];
	mat utese_s[1,`h'] 		= _se[`D'];

	/* with effect size */
	reg ``outc'_use_es' `D';
	mat uteff_s_es[1,`h'] 		= _b[`D'];
	mat utese_s_es[1,`h'] 		= _se[`D'];

	
	/* obtain CONDITIONAL treatment effects */
	reg ``outc'_use' `D' `blockvars' `lcvars';
	mat teff_s[1,`h'] 		= _b[`D'];
	mat tese_s[1,`h'] 		= _se[`D'];
	mat tstat_s[1,`h'] 		= _b[`D']/_se[`D'];
	mat pval_reg[1,`h'] 	= 2*ttail(r(df_r),abs(tstat_s[1,`h']));
	test _b[`D']=0;
	local sign_D = sign(_b[`D']);
	mat pval_reg1s[1,`h'] 	= ttail(r(df_r),`sign_D'*sqrt(r(F)));
	
	/* with effect size */
	reg ``outc'_use_es' `D' `blockvars' `lcvars';
	mat teff_s_es[1,`h'] 		= _b[`D'];
	mat tese_s_es[1,`h'] 		= _se[`D'];

	
	/* obtain CONDITIONAL treatment effects WITH IPW */
	if (`nip'>0) {;
		svmat ipw_s, names(varipw);
		reg ``outc'_use' `D' `blockvars' `lcvars' [pweight=varipw1];
		mat teff_s_ipw[1,`h'] 		= _b[`D'];
		mat tese_s_ipw[1,`h'] 		= _se[`D'];
		mat tstat_s_ipw[1,`h'] 		= _b[`D']/_se[`D'];
		test _b[`D']=0;
		local sign_D = sign(_b[`D']);
		mat pval_reg1s_ipw[1,`h'] 	= ttail(r(df_r),`sign_D'*sqrt(r(F)));
		
		/* with effect size */
		reg ``outc'_use_es' `D' `blockvars' `lcvars' [pweight=varipw1];
		mat teff_s_ipw_es[1,`h'] 		= _b[`D'];
		mat tese_s_ipw_es[1,`h'] 		= _se[`D'];

		drop varipw*;
	};
	
	/* RESIDUALISATION -------------------------------------------------------*/
	/* residualise outcomes for linear conditioning */
	
	tempvar `outc'_res;
	tempvar `outc'_pred;
	
	if "`lcvars'"!="" {;
		residualise ``outc'_use' `lcvars', resname(``outc'_res') predname(``outc'_pred');
		if ("`verbose'"!="") nois di as text "Residualising `outc' in `lcvars':";
	};
	else {;
		gen double ``outc'_res' = ``outc'_use';
	};
		
	
	/* PERMUTATION -----------------------------------------------------------*/
	/* permute the outcome vector */
	
	if "`naive'"!="" {;
		if ("`verbose'"!="") nois di as text "Naive Permutations for `outc' (chosen by user)";
		bperm ``outc'_res', np(`np');
	};
	else {;
	/* default to naive permutation if no block variables supplied */
		if "`blockvars'"=="" {; /* Naive Permutations (no blocks supplied) */
			if ("`verbose'"!="") nois di as text "Naive Permutations for `outc' (no blocks supplied)";
			bperm ``outc'_res', np(`np');
		};
		else {; /* Blocks: combinations of `blockvars'" */
			if ("`verbose'"!="") nois di as text "Block Permutations for `outc' (blocks: `blockvars')";
			tempvar block;
			egen `block'=group(`blockvars');				/* variable identifying blocks */
			bperm ``outc'_res', np(`np') block(`block');
		};
};
	
	mat Yperm = r(Yperm);
	
	/* add back predicted values if linear conditioning */
	if "`lcvars'"!="" {;
		mkmat ``outc'_pred', matrix(pred);
		mata: predmat = st_matrix("pred");		/* vector (ni x 1) of predicted values */
		mata: permmat = st_matrix("Yperm");		/* matrix (ni x np) of permuted outcomes */
		mata: newpermmat = permmat + J(1,`np',predmat);		/* replicate pred np times in columns and sum to each permuted outcome */
		mata: st_matrix("newpermmat", newpermmat);
		mat Yperm = newpermmat;
	};
	
	
	/* GENERATE IPW WEIGHTS MATRIX --------------------------------------------------------*/
	cap nois {;				/* to continue even in cases of no convergence */
	if (`nip'==1) {; 		/* single set of IPW covariates */
		if ("`ipwcovars1'"!="" & strtrim("`ipwcovars1'")!="NA") {;
			if ("`verbose'"!="") nois di as text "Generating IP weights for `outc' (covars: `ipwcovars1')";
			ipweights , permoutc(Yperm) treat(`D') covars(`ipwcovars1') link(`link');
			mat ipWeights = r(weights);
			scalar nfails_`h' = r(nfails);
			scalar nsucc_`h' = r(nsucc);
			// check
			if (`np'!=nsucc_`h'+nfails_`h') {;
			di as error "Incorrect number of fails + successes in IPW";
			exit 111;
			};
		};
		else {;					/* in case of empty input */
			mat ipWeights = J(`ni', `np', 1);
		};
	};
	else if (`nip'>1) {;	/* multiple sets of IPW covariates */
		if ("`ipwcovars`h''"!="" & strtrim("`ipwcovars`h''")!="NA") {;
			if ("`verbose'"!="") nois di as text "Generating IP weights for `outc' (covars: `ipwcovars`h'')";
			ipweights , permoutc(Yperm) treat(`D') covars(`ipwcovars`h'') link(`link');
			mat ipWeights = r(weights);
			scalar nfails_`h' = r(nfails);
			scalar nsucc_`h' = r(nsucc);
			// check
			if (`np'!=nsucc_`h'+nfails_`h') {;
			di as error "Incorrect number of fails + successes in IPW";
			exit 111;
			};
		};
		else {;					/* in case of empty input */
			mat ipWeights = J(`ni', `np', 1);
		};
	};
	else if (`nip'==0) {;	/* otherwise just matrix of unit weights */
		mat ipWeights = J(`ni', `np', 1);
		};
	};
	
	
	/******************************************************************************/
	/* COMPUTE DISTRIBUTION OF TSTATS ----------------------------- */
	
	/* initialise empty column matrix to store tstats */
	mat tstats = J(`np',1,.);	
	mat tstats_ipw = J(`np',1,.);
	
	forvalues r = 1(1)`np' {;
		mat current_perm = Yperm[1..`ni',`r'];				/* extract permuted Y */
		svmat current_perm, names(Yp);						/* convert to variable */
		mat current_wt = ipWeights[1..`ni',`r'];			/* extract permuted IP weight */
		svmat current_wt, names(IPwt);						/* convert to variable */
		
		/* if IPW is selected, get both weighted and unweighted tstats */
		if (`nip'>0) {;
			qui reg Yp1 `D' `lcvars';							/* get t statistic (unweighted) */
			mat tstats[`r',1] = _b[`D']/_se[`D'];
			/* compute IPW weighted tstat iff it worked */
			capture assert mi(IPwt1);
			if _rc {;
				qui reg Yp1 `D' `lcvars' `blockvars' [pweight=IPwt1];			/* get t statistic (IPW weighted) */
				mat tstats_ipw[`r',1] = _b[`D']/_se[`D'];
			};
		};
		else if (`nip'==0) {;
			qui reg Yp1 `D' `lcvars' `blockvars';							/* get t statistic (unweighted) */
			mat tstats[`r',1] = _b[`D']/_se[`D'];
		};
		drop Yp1 IPwt1;
	};
	
	if (`h'==1) {; 	/* if first hyp, initialise matrix */
						mat tstat_p 	= tstats;
		if (`nip'>0) 	mat tstat_p_ipw = tstats_ipw;
	};
	else {; 	 	/* if later hyp, add as column to existing matrix */
						mat tstat_p 	= tstat_p, tstats;
		if (`nip'>0) 	mat tstat_p_ipw = tstat_p_ipw, tstats_ipw;
	};
	
	
	local h=`h'+1; 				/* go to next hypothesis (outcome) */
	
	}; /* quietly */
	
	};
	
	
/* CALCULATE PVALUES VIA MATA ------------------------------------------------*/

/* import matrices in mata */
mata: ts=st_matrix("tstat_s");
mata: tp=st_matrix("tstat_p");
if (`nip'>0) mata: ts_ipw=st_matrix("tstat_s_ipw");
if (`nip'>0) mata: tp_ipw=st_matrix("tstat_p_ipw");

/* calculate pvalues */
if (`nip'>0) {;
	mata: pval_perm		= pcompute_perm(ts,tp);								/* permutation */
	mata: pval_perm_ipw	= pcompute_perm(ts_ipw,tp_ipw);						/* permutation+IPW */
	mata: pval_permsd	= pcompute_permsd(ts_ipw,tp_ipw, "`sdmethod'");		/* permutation+IPW+stepdown */
};
else if (`nip'==0) {;
	mata: pval_perm		= pcompute_perm(ts,tp);								/* permutation */
	mata: pval_perm_ipw	= J(1,`nh',.);										/* permutation+IPW (empty) */
	mata: pval_permsd	= pcompute_permsd(ts,tp, "`sdmethod'");				/* permutation+stepdown (no IPW)*/
};

/* put back to stata */
local matsfrommata "pval_perm pval_perm_ipw pval_permsd ";
foreach x of local matsfrommata {;
mata: st_matrix("`x'", `x');
};


/* matrix column names */
local matnames "pval_reg pval_reg1s pval_perm pval_perm_ipw pval_permsd tstat_p tstat_s";
foreach x of local matnames {;
mat colnames `x' = `varlist';
};

/* combine matrices */
mat res = 		msd, 
				uteff_s', utese_s', uteff_s_es', utese_s_es', 
				teff_s', tese_s', teff_s_es', tese_s_es',
				teff_s_ipw', tese_s_ipw', teff_s_ipw_es', tese_s_ipw_es',
				pval_reg1s', pval_perm', pval_perm_ipw', pval_permsd';
mat colnames res = 	"N_C" "mean_C" "SD_C" "N_T" "mean_T" "SD_T" "diff_TC" 
					"UCTE" "UCTE_SE" "UCTE_es" "UCTE_SE_es" 
					"CTE" "CTE_SE" "CTE_es" "CTE_SE_es" 
					"CTEI" "CTEI_SE" "CTEI_es" "CTEI_SE_es" 
					"p_samp" "p_perm" "p_pipw" "p_pisd";
mat rownames res = `varlist';



/* DISPLAY HEADER -----------------------------------------------------------*/

di as text "";
di as result		"PERMUTATION-STEPDOWN RESULTS";

// SUBSAMPLE header
if "`if'" != "" {;
		di as text "Subsample: " as result "`if'";
	};

// BLOCKS header
if "`blockvars'"=="" {;
	nois di as text "Naive Permutations (no blocks supplied)";
};
else {;
	if "`blockvars'"=="" {;
		nois di as text "Naive Permutations (no blocks supplied)";
	};
	else {;
		nois di as text "Blocks: combinations of " as result "`blockvars'";
	};
};

// LINEAR CONDITIONING HEADER
if "`lcvars'"!="" {;
	nois di as text "Linear conditioning in " as result  "`lcvars'";
};

// IPW header
if (`nip'==0) {;
		di as text "No IPW Adjustment for Attrition";
	};
	else if (`nip'==1) {;
		if ("`ipwcovars1'"!="") {;
			di as text "IPW Adjustment for Attrition, using " as result "`ipwcovars1'";
			forvalues h=1(1)`nh' {;
				local o: word `h' of `varlist';
				di as text "    success rate for `o': " (`np'-nfails_`h')/`np' *100 "% (" `np'-nfails_`h' "/" `np' ")";
			};
		};
	};
	else if (`nip'>1) {;
		di as text "IPW Adjustment for Attrition, using:";
		forvalues i=1(1)`nip' {;
			local o: word `i' of `varlist';
			di as text "for " as result "`o'" as text ": " "`ipwcovars`i''";
			di as text "			success rate: " (`np'-nfails_`i')/`np' *100 "% (" `np'-nfails_`i' "/" `np' ")";
		};
	};

// SDMETHOD header
if ("`sdmethod'" == "rw16") {;
		di as text "Stepdown method: Romano and Wolf (2016)";
	};
	else {;
		di as text "Stepdown method: Rodrigo";
	};
	
/* DISPLAY RESULTS TABLE -----------------------------------------------------------*/

di as text "{hline 21}{c TT}{hline 19}{c TT}{hline 19}{c TT}{hline 18}{c TT}{hline 30}{c TRC}";
if ("`effsize'"=="") 	di as text "                     {c |}      Controls     {c |}      Treated      {c |}     Cond. TE     {c |}       1-Sided P-Values       {c |}";
else 					di as text "                     {c |}      Controls     {c |}      Treated      {c |} Cond. TE (esize) {c |}       1-Sided P-Values       {c |}";
di as text "         Outcome     {c |}  Obs   Mean (SD)  {c |}  Obs   Mean (SD)  {c |}  No IPW    IPW   {c |}   Samp   Perm    IPW   StpD  {c |}";
di as text "{hline 21}{c +}{hline 19}{c +}{hline 19}{c +}{hline 18}{c +}{hline 30}{c +}";

local h=1;
foreach outc of varlist `varlist' {;

/* generate line of pvalue stars */

if 			inrange(pval_reg1s[1,`h'],0, .01) {;
 		local stars_1 = "***";
};
else if 	inrange(pval_reg1s[1,`h'], 0.01, .05) {;
 		local stars_1 = "** ";
};
else if 	inrange(pval_reg1s[1,`h'], 0.05, .1) {;
 		local stars_1 = "*  ";
};
else {;
		local stars_1 = "   ";
};
/* -------------------- */
if 			inrange(pval_perm[1,`h'],0, .01) {;
 		local stars_2 = "***";
};
else if 	inrange(pval_perm[1,`h'], 0.01, .05) {;
 		local stars_2 = "** ";
};
else if 	inrange(pval_perm[1,`h'], 0.05, .1) {;
 		local stars_2 = "*  ";
};
else {;
		local stars_2 = "   ";
};
/* -------------------- */
if 			inrange(pval_perm_ipw[1,`h'],0, .01) {;
 		local stars_3 = "***";
};
else if 	inrange(pval_perm_ipw[1,`h'], 0.01, .05) {;
 		local stars_3 = "** ";
};
else if 	inrange(pval_perm_ipw[1,`h'], 0.05, .1) {;
 		local stars_3 = "*  ";
};
else {;
		local stars_3 = "   ";
};
/* -------------------- */
if 			inrange(pval_permsd[1,`h'],0, .01) {;
 		local stars_4 = "***";
};
else if 	inrange(pval_permsd[1,`h'], 0.01, .05) {;
 		local stars_4 = "** ";
};
else if 	inrange(pval_permsd[1,`h'], 0.05, .1) {;
 		local stars_4 = "*  ";
};
else {;
		local stars_4 = "   ";
};
/* -------------------- */

local outclab: variable label `outc';
if ("`outclab'" == "") local outclab = "`outc'";

/* dispay normal TE */
if ("`effsize'"=="") {;
di as text 			%-20s abbrev("`outclab'",20)
					" {c |}" %5.0g msd[`h', 1] "   " %8.3f msd[`h', 2] "   {c |}" %5.0g msd[`h', 4] "   " %8.3f msd[`h', 5] "   {c |}" 		/* N and Mean */
					"  " %6.2f teff_s[1, `h']  "  " %6.2f teff_s_ipw[1, `h'] "  {c |}"																						/* TEs */
					"  " %5.3f pval_reg1s[1,`h'] "  " %5.3f pval_perm[1,`h'] "  " %5.3f pval_perm_ipw[1,`h'] "  " %5.3f pval_permsd[1,`h'] "  {c |}"						/* PVALS 1SIDED */
					;
di as text			
					"                     {c |}        (" %7.3f msd[`h', 3]  ")  {c |}        (" %7.3f msd[`h', 6] ")  {c |}"						/* SD */
					" (" %5.2f tese_s[1, `h'] ")  (" %5.2f tese_s_ipw[1, `h'] ") {c |}" 																													
					"  `stars_1'    `stars_2'    `stars_3'    `stars_4'    {c |}"  																				/* PVALS STARS */
					;
};
/* dispay effect size TE */
else {;
di as text 			%-20s abbrev("`outclab'",20)
					" {c |}" %5.0g msd[`h', 1] "   " %8.3f msd[`h', 2] "   {c |}" %5.0g msd[`h', 4] "   " %8.3f msd[`h', 5] "   {c |}" 		/* N and Mean */
					"  " %6.2f teff_s_es[1, `h']  "  " %6.2f teff_s_ipw_es[1, `h'] "  {c |}"																						/* TEs */
					"  " %5.3f pval_reg1s[1,`h'] "  " %5.3f pval_perm[1,`h'] "  " %5.3f pval_perm_ipw[1,`h'] "  " %5.3f pval_permsd[1,`h'] "  {c |}"						/* PVALS 1SIDED */
					;
di as text			
					"                     {c |}        (" %7.3f msd[`h', 3]  ")  {c |}        (" %7.3f msd[`h', 6] ")  {c |}"						/* SD */
					" (" %5.2f tese_s_es[1, `h'] ")  (" %5.2f tese_s_ipw_es[1, `h'] ") {c |}" 																													
					"  `stars_1'    `stars_2'    `stars_3'    `stars_4'    {c |}"  																				/* PVALS STARS */
					;
};



/* special last line */
if (`h' != `nh') 	di as text "{hline 21}{c +}{hline 19}{c +}{hline 19}{c +}{hline 18}{c +}{hline 30}{c +}";
else 				di as text "{hline 21}{c BT}{hline 19}{c BT}{hline 19}{c BT}{hline 18}{c BT}{hline 30}{c BRC}";

local h=`h'+1;
};

if "`if'" != "" {;
restore;
};

/* RETURN OBJECTS ------------------------------------------------------------*/

/* save matrix */
qui {;
if "`savemat'" != "" {;
	preserve;
	clear;
	set obs `=rowsof(res)';	/* to avoid press key */
	gen junk=_n;
	svmat2 res, names(col) rnames(varname);
	drop junk;
	export delimited using "`savemat'", nolab replace;
	restore;
};
};

return matrix ipWeights = ipWeights;
return matrix Yperm = Yperm;
return matrix pval_reg1s = pval_reg1s;
return matrix pval_reg1s_ipw = pval_reg1s_ipw;
return matrix pval_perm = pval_perm;
return matrix pval_perm_ipw = pval_perm_ipw;
return matrix pval_permsd = pval_permsd;
return matrix tstat_p = tstat_p;
return matrix tstat_s = tstat_s;
return matrix tstat_p_ipw = tstat_p_ipw;
return matrix tstat_s_ipw = tstat_s_ipw;
return matrix res = res;





end;

#delimit cr
