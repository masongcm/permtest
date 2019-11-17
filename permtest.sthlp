{smcl}
{it:v. 1.0.0} 


{title:Title}

{p 4 4 2}
{bf:permtest} -- Permutation inference for linear models.



{title:Syntax}

{p 8 8 2} {bf:permtest} {it:depvars} [{it:if}] [, {it:options}]


{p 4 4 2}
{it:options}

{space 4}{hline}

{p 4 4 2}
	{bf:treat}: Treatment indicator (required, must be 0/1)    {break}

{p 4 4 2}
Inference    {break}
	{bf:np}: Number of permutations (required)    {break}
	{bf:blockvars} ({it:varlist}): variables to be used for block permutation (if not specified, defaults to naive)    {break}
	{bf:naive}: whether to perform naive permutation, disregarding blocks (overrides {bf:blockvars_})    {break}
	{bf:lcvars} ({it:varlist}): variables to be used for linear conditioning    {break}
	{bf:ipwcovars1} ({it:varlist}): variables for IPW step (applies to all outcomes in {it:depvars} if specified alone)    {break}
	{bf:ipwcovars2-ipwcovars5} : variables for IPW step (applies to each separate outcome in {it:depvars})    {break}
	
{p 4 4 2}
Other    {break}
	{bf:reverse}: reverse sign of outcomes for treatment effects    {break}
	{bf:effsize}: display treatment effects in terms of effect size (standardised by control group SD)    {break}
	{bf:verbose}: print more information about progress to console    {break}

{p 4 4 2}
Saving    {break}
	{bf:savemat}  ({it:string}): path where to save output in matrix form    {break}
	
{space 4}{hline}

{p 4 4 2}
{bf:by} is allowed; see {bf: {browse "help by":[D] by}}    {break}
{bf:fweight} is allowed;  {browse "help weight":weight}    {break}



{title:Description}

{p 4 4 2}
{bf:permtest} performs permutation-based inference of treatment effects 
in randomised treatments. 
It includes adjustments for stratified randomisation design, 
multiple hypotheses, treatment imbalance and non-random attrition.


{title:Options}

{p 4 4 2}
{bf:treat} specifies the variable containing the treatment indicator. It must be
binary coded with values of 0 and 1.

{p 4 4 2}
{bf:np} specifies the desired number of permutations of the outcome vector.

{p 4 4 2}
{bf:blockvars} ({it:varlist}) can be used to supply one or more strata used in the
randomisation protocol. Permutations will then be performed {it:within} 
blocks defined by the values (or combination of values, if more than one
stratum is supplied) in {bf:blockvars}. The strata variables should be
categorical, and shouldn{c 39}t partition the sample in sets that are too small.

{p 4 4 2}
{bf:naive} overrides the {bf:blockvars} option, by instructing the permutation
to disregard strata and just permute outcomes across the whole sample.

{p 4 4 2}
{bf:lcvars} ({it:varlist}) can be used to supply a list of variables to linearly 
condition on during inference. The conditioning is performed using the 
methodology from  {browse "https://www.jstor.org/stable/1391660":Freedman and Lane (1983)}.
Typical usage includes the case of baseline covariate imbalance.

{p 4 4 2}
{bf:ipwcovars1} ({it:varlist}) can be used to supply a list of variables to perform 
an inverse probability weighting adjustment on the treatment effect estimates.
Typical usage includes corrections for non-random attrition through the 
study period.
Denote by W_j an indicator for outcome Y_j being observed. The {bf:ipwcovars1}
option computes a set of weights from a logit regression of W_j on {it:varlist}, 
and uses them to adjust the final treatment effect estimates. Note that:

{p 8 8 2} The logit weights are computed {it:for each permutation}: as such this option 
significantly increases the time intensity of the command.

{p 8 8 2} Supplying only {bf:ipwcovars1} uses the same set of adjustment variables for
each outcome in {it:depvars}. If you want to specify different sets of adjustment
variables for each outcome, use {bf:ipwcovars1__-__ipwcovars5}.



{title:Remarks}

{p 4 4 2}
The remarks are the detailed description of the command and its 
nuances. Official documented Stata commands don{c 39}t have much for 
remarks, because the remarks go in the documentation.


{title:Example(s)}

    explain what it does
        . example command

    second explanation
        . example command


{title:Stored results}

{p 4 4 2}
{bf:commandname} stores the following in {bf:r()} or {bf:e()}:

{p 4 4 2}
Scalars

{p 8 8 2} {bf:r(N)}: number of observations 

{p 4 4 2}
Macros

{p 4 4 2}
Matrices

{p 4 4 2}
Functions


{title:Acknowledgements}

{p 4 4 2}
If you have thanks specific to this command, put them here.


{title:Author}

{p 4 4 2}
Author information here; nothing for official Stata commands
leave 2 white spaces in the end of each line for line break. For example:

{p 4 4 2}
Your Name     {break}
Your affiliation      {break}
Your email address, etc.      {break}


{title:References}

{p 4 4 2}
Author Name (year),  {browse "http://www.haghish.com/markdoc/":title & external link}

{space 4}{hline}

{p 4 4 2}
This help file was dynamically produced by 
{browse "http://www.haghish.com/markdoc/":MarkDoc Literate Programming package} 


{p 4 4 2}
/*
{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}
// PERMTEST -  main function
{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}
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
{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}
{break}    */

{p 4 4 2}
#delimit ;

{p 4 4 2}
cap program drop permtest;

{p 4 4 2}
program permtest, rclass;

{p 4 4 2}
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

{p 4 4 2}
/* Unabbreviate */
unab varlist 	: {c 96}varlist{c 39};
unab treat 		: {c 96}treat{c 39};
if ("{c 96}blockvars{c 39}"!="") 	unab blockvars 	: {c 96}blockvars{c 39};
if ("{c 96}lcvars{c 39}"!="") 	unab lcvars 	: {c 96}lcvars{c 39};

{p 4 4 2}
/* EXTRACT INPUTS */
clear matrix;
local nh: word count {c 96}varlist{c 39};				/* count number of outcomes */
local nd: word count {c 96}treat{c 39};				/* count number of treatments supplied (for errors)	*/						
local D : word 1 of {c 96}treat{c 39};				/* treatment group identifier */

{p 4 4 2}
local nip = 0;								/* count sets of IPW covariates */
if ("{c 96}ipwcovars1{c 39}"!="") local nip = 1;
forvalues i = 2(1)5 {;
	if ("{c 96}ipwcovars{c 96}i{c 39}{c 39}"!="") local nip = {c 96}i{c 39};
	};

{p 4 4 2}
/* DEFAULTS ------------------------------------------------------------------*/									
if "{c 96}link{c 39}"=="" local link "logit";			/* default link to logit */
if "{c 96}sdmethod{c 39}"=="" local sdmethod "rw16";	/* default sdmethod to Romano Wolf 16 */


{p 4 4 2}
/* ERRORS --------------------------------------------------------------------*/
if "{c 96}link{c 39}"!="probit" & "{c 96}link{c 39}"!="logit" {;
	di as error "Link must be either {c 39}probit{c 39} or {c 39}logit{c 39}";
	exit 111;
};

{p 4 4 2}
if "{c 96}link{c 39}"=="probit" {;
	di as error " {c 39}probit{c 39} link not supported yet";
	exit 111;
};

{p 4 4 2}
if (nd{c 39} !=1 ) {;
	di as error "Only 1 treatment indicator can be supplied";
	exit 111;
};

{p 4 4 2}
qui su {c 96}D{c 39};
if (r(max)!=1 | r(min)!=0 ) {;
	di as error "Treatment indicator must be 0 (control) 1 (treated)";
	exit 111;
};

{p 4 4 2}
cap assert missing(D{c 39}), fast;
if !_rc {;
	di as error "Treatment indicator cannot contain missings";
	exit 111;
};

{p 4 4 2}
if ("{c 96}sdmethod{c 39}" != "rw16" & "{c 96}sdmethod{c 39}" != "rp") {;
	di as error "Stepdown method must be either Romano-Wolf ({c 39}rw16{c 39}) or Rodrigo{c 39}s ({c 39}rp{c 39})";
	exit 111;
	};

{p 4 4 2}
if (missing(np{c 39})) "Must supply number of permutations [np()]";

{p 4 4 2}
if ("{c 96}ipwcovars1{c 39}"=="" & ("{c 96}ipwcovars2{c 39}"!="" | "{c 96}ipwcovars3{c 39}"!="" | "{c 96}ipwcovars4{c 39}"!="" | "{c 96}ipwcovars5{c 39}"!="")) {;
	di as error	"WARNING: You should specify first set of ipwcovars, and then 2-5!";
	};

{p 4 4 2}
if (nip{c 39}>1 & {c 96}nip{c 39}!={c 96}nh{c 39}) {;
	di as error	"If you want to specify more than 1 set of IPW covariates,";
	di as error	"the number of IPW sets must match the number of variables in varlist";
	exit 111;
	};
	

{p 4 4 2}
/* IF CONDITION --------------------------------------------------------------*/
if "{c 96}if{c 39}" != "" {;
preserve;
qui keep {c 96}if{c 39};
};

{p 4 4 2}
/* count observations */
qui count;
local ni = r(N);


{p 4 4 2}
/* PREALLOCATION -------------------------------------------------------------*/

{p 4 4 2}
/* matrix for control/treatment means and sds */
/* columns: C N, C mean, C sd, T N, T mean, T sd, diff */
mat msd 			= J(nh{c 39},7,.);
mat rownames msd 	= {c 96}varlist{c 39};
mat colnames msd 	= "C N" "C mean" "C SD" "T N" "T mean" "T SD" "T-C Diff";

{p 4 4 2}
/* preallocate matrix for permuted t statistics */
/* dimensions: np rows, as many columns as there are hypotheses */
/* NOTE: gets overwritten if using Rodrigo{c 39}s tstats */
mat tstat_p 		= J(np{c 39},{c 96}nh{c 39},.);
mat tstat_p_ipw 	= J(np{c 39},{c 96}nh{c 39},.);

{p 4 4 2}
/* preallocate vector for sample t statistics */
mat uteff_s 		= J(1,{c 96}nh{c 39},.);		/* UNconditional TEs */
mat utese_s 		= J(1,{c 96}nh{c 39},.);		/* UNconditional TEs Standard Errors */
mat uteff_s_es 		= J(1,{c 96}nh{c 39},.);		/* UNconditional TEs (effect size) */
mat utese_s_es 		= J(1,{c 96}nh{c 39},.);		/* UNconditional TEs Standard Errors (effect size) */

{p 4 4 2}
mat teff_s 			= J(1,{c 96}nh{c 39},.);		/* conditional TEs */
mat tese_s 			= J(1,{c 96}nh{c 39},.);		/* conditional TEs Standard Errors */
mat tstat_s 		= J(1,{c 96}nh{c 39},.);		/* t-stats */
mat teff_s_es 		= J(1,{c 96}nh{c 39},.);		/* conditional TEs (effect size) */
mat tese_s_es 		= J(1,{c 96}nh{c 39},.);		/* conditional TEs Standard Errors (effect size) */

{p 4 4 2}
mat teff_s_ipw 		= J(1,{c 96}nh{c 39},.);		/* conditional TEs with IPW */
mat tese_s_ipw 		= J(1,{c 96}nh{c 39},.);		/* conditional TEs Standard Errors with IPW */
mat tstat_s_ipw 	= J(1,{c 96}nh{c 39},.);		/* t-stats with IPW */
mat teff_s_ipw_es 	= J(1,{c 96}nh{c 39},.);		/* conditional TEs with IPW (effect size) */
mat tese_s_ipw_es 	= J(1,{c 96}nh{c 39},.);		/* conditional TEs Standard Errors with IPW (effect size) */

{p 4 4 2}
mat pval_reg 		= J(1,{c 96}nh{c 39},.);		/* regular pvalues */
mat pval_reg1s 		= J(1,{c 96}nh{c 39},.);		/* regular pvalues (1 sided) */
mat pval_reg1s_ipw 	= J(1,{c 96}nh{c 39},.);		/* regular pvalues (1 sided, IPW) */

{p 4 4 2}
/{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:*/
/{ul:* COMPUTATION STARTS HERE }{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}*/
/{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:*/

{p 4 4 2}
local h=1;				/* start outcome (hypothesis) counting */

{p 4 4 2}
foreach outc of varlist {c 96}varlist{c 39} {;

{p 4 4 2}
	/* OUTCOME REVERSING -----------------------------------------------------*/
	
{p 4 4 2}
	/* convert to double precision */
	recast double {c 96}outc{c 39};
	
{p 4 4 2}
	/* generate variable with correct sign based on reverse */
	tempvar {c 96}outc{c 39}_use;
	if "{c 96}reverse{c 39}" == "" {;
		qui gen double {c 96}{c 96}outc{c 39}_use{c 39} = {c 96}outc{c 39};
		};
		else {;
		qui gen double {c 96}{c 96}outc{c 39}_use{c 39} = -{c 96}outc{c 39};
	};

{p 4 4 2}
	quietly {;
	
{p 4 4 2}
	/* progress */
	if "{c 96}verbose{c 39}"!="" {;
	nois di "";
	if "{c 96}reverse{c 39}" == "no" nois di as text "Calculating Permuted TEs for {c 96}outc{c 39}:";
	if "{c 96}reverse{c 39}" == "yes"	nois di as text "Calculating Permuted TEs for {c 96}outc{c 39} (reversed):";
	};
	
{p 4 4 2}
	/* COMPUTATION OF TREATMENT/CONTROL MEANS ------------------------------------*/
	
{p 4 4 2}
	/* check if dummy (to not report SD) */
	su {c 96}outc{c 39};
	scalar dummy_outc{c 39}=0;
	if (r(min)==0 & r(max)==1) scalar dummy_outc{c 39}=1;
	
{p 4 4 2}
	/* control mean/sd */
	su {c 96}outc{c 39} if {c 96}D{c 39}==0;
	scalar nc_outc{c 39} = r(N);
	scalar mc_outc{c 39} = r(mean);
	scalar sdc_outc{c 39} = r(sd);
	
{p 4 4 2}
	/* treatment mean/sd */
	su {c 96}outc{c 39} if {c 96}D{c 39}==1;
	scalar nt_outc{c 39} = r(N);
	scalar mt_outc{c 39} = r(mean);
	scalar sdt_outc{c 39} = r(sd);
	
{p 4 4 2}
	/* mean difference */
	scalar diff_outc{c 39}=mt_outc{c 39}-mc_outc{c 39};
	
{p 4 4 2}
	/* fill in matrix */
	mat msd[h{c 39}, 1]=nc_outc{c 39};
	mat msd[h{c 39}, 2]=mc_outc{c 39};
	mat msd[h{c 39}, 4]=nt_outc{c 39};
	mat msd[h{c 39}, 5]=mt_outc{c 39};
	mat msd[h{c 39}, 7]=diff_outc{c 39};
	if dummy_outc{c 39}==0 {;
		mat msd[h{c 39}, 3]=sdc_outc{c 39};
		mat msd[h{c 39}, 6]=sdt_outc{c 39};
	};
	
	
{p 4 4 2}
	/* COMPUTATION OF SAMPLE TSTAT AND TREATMENT EFFECT ----------------------*/
	/* compute sample t-stats and treatment effects */
	
{p 4 4 2}
	/* get matrix of outcome */
	mkmat {c 96}{c 96}outc{c 39}_use{c 39}, matrix(outcome);

{p 4 4 2}
	/* get IPW weight matrix for sample */
	if (nip{c 39}==1) {; 		/* single set of IPW covariates */
		if ("{c 96}ipwcovars1{c 39}"!="" & strtrim("{c 96}ipwcovars1{c 39}")!="NA") {;
			ipweights , permoutc(outcome) treat(D{c 39}) covars(ipwcovars1{c 39}) link(link{c 39});
			mat ipw_s = r(weights);
		};
		else {;								/* in case of empty input */
			mat ipw_s = J(ni{c 39},1,1);
		};
	};
	else if (nip{c 39}>1) {;	/* multiple sets of IPW covariates */
		if ("{c 96}ipwcovars{c 96}h{c 39}{c 39}"!="" & strtrim("{c 96}ipwcovars{c 96}h{c 39}{c 39}")!="NA") {;			
			ipweights , permoutc(outcome) treat(D{c 39}) covars(ipwcovars{c 96}h{c 39}{c 39}) link(link{c 39});
			mat ipw_s = r(weights);
		};
		else {;								/* in case of empty input */
			mat ipw_s = J(ni{c 39},1,1);
		};
	};		
	else if (nip{c 39}==0) {;
		mat ipw_s = J(ni{c 39},1,1);
	};

{p 4 4 2}
	/* make temporary outcome variable for treatment effects */
	/* depending on reverse and effsize */
	tempvar {c 96}outc{c 39}_use_es;
	qui su {c 96}{c 96}outc{c 39}_use{c 39} if {c 96}D{c 39}==0;
	gen {c 96}{c 96}outc{c 39}_use_es{c 39} = {c 96}{c 96}outc{c 39}_use{c 39}/r(sd);
	
{p 4 4 2}
	/* obtain UNCONDITIONAL treatment effects */
	reg {c 96}{c 96}outc{c 39}_use{c 39} {c 96}D{c 39};
	mat uteff_s[1,{c 96}h{c 39}] 		= {it:b[D{c 39}];
	mat utese_s[1,{c 96}h{c 39}] 		= {it:se[D{c 39}];

{p 4 4 2}
	/* with effect size */
	reg {c 96}{c 96}outc{c 39}_use_es{c 39} {c 96}D{c 39};
	mat uteff_s_es[1,{c 96}h{c 39}] 		= {it:b[D{c 39}];
	mat utese_s_es[1,{c 96}h{c 39}] 		= {it:se[D{c 39}];

	
{p 4 4 2}
	/* obtain CONDITIONAL treatment effects */
	reg {c 96}{c 96}outc{c 39}_use{c 39} {c 96}D{c 39} {c 96}blockvars{c 39} {c 96}lcvars{c 39};
	mat teff_s[1,{c 96}h{c 39}] 		= {it:b[D{c 39}];
	mat tese_s[1,{c 96}h{c 39}] 		= {it:se[D{c 39}];
	mat tstat_s[1,{c 96}h{c 39}] 		= {it:b[D{c 39}]/_se[D{c 39}];
	mat pval_reg[1,{c 96}h{c 39}] 	= 2*ttail(r(df_r),abs(tstat_s[1,{c 96}h{c 39}]));
	test {it:b[D{c 39}]=0;
	local sign_D = sign({it:b[D{c 39}]);
	mat pval_reg1s[1,{c 96}h{c 39}] 	= ttail(r(df_r),{c 96}sign_D{c 39}*sqrt(r(F)));
	
{p 4 4 2}
	/* with effect size */
	reg {c 96}{c 96}outc{c 39}_use_es{c 39} {c 96}D{c 39} {c 96}blockvars{c 39} {c 96}lcvars{c 39};
	mat teff_s_es[1,{c 96}h{c 39}] 		= {it:b[D{c 39}];
	mat tese_s_es[1,{c 96}h{c 39}] 		= {it:se[D{c 39}];

	
{p 4 4 2}
	/* obtain CONDITIONAL treatment effects WITH IPW */
	if (nip{c 39}>0) {;
		svmat ipw_s, names(varipw);
		reg {c 96}{c 96}outc{c 39}_use{c 39} {c 96}D{c 39} {c 96}blockvars{c 39} {c 96}lcvars{c 39} [pweight=varipw1];
		mat teff_s_ipw[1,{c 96}h{c 39}] 		= {it:b[D{c 39}];
		mat tese_s_ipw[1,{c 96}h{c 39}] 		= {it:se[D{c 39}];
		mat tstat_s_ipw[1,{c 96}h{c 39}] 		= {it:b[D{c 39}]/_se[D{c 39}];
		test {it:b[D{c 39}]=0;
		local sign_D = sign({it:b[D{c 39}]);
		mat pval_reg1s_ipw[1,{c 96}h{c 39}] 	= ttail(r(df_r),{c 96}sign_D{c 39}*sqrt(r(F)));
		
{p 4 4 2}
		/* with effect size */
		reg {c 96}{c 96}outc{c 39}_use_es{c 39} {c 96}D{c 39} {c 96}blockvars{c 39} {c 96}lcvars{c 39} [pweight=varipw1];
		mat teff_s_ipw_es[1,{c 96}h{c 39}] 		= {it:b[D{c 39}];
		mat tese_s_ipw_es[1,{c 96}h{c 39}] 		= {it:se[D{c 39}];

{p 4 4 2}
		drop varipw*;
	};
	
{p 4 4 2}
	/* RESIDUALISATION -------------------------------------------------------*/
	/* residualise outcomes for linear conditioning */
	
{p 4 4 2}
	tempvar {c 96}outc{c 39}_res;
	tempvar {c 96}outc{c 39}_pred;
	
{p 4 4 2}
	if "{c 96}lcvars{c 39}"!="" {;
		residualise {c 96}{c 96}outc{c 39}_use{c 39} {c 96}lcvars{c 39}, resname({c 96}outc{c 39}_res{c 39}) predname({c 96}outc{c 39}_pred{c 39});
		if ("{c 96}verbose{c 39}"!="") nois di as text "Residualising {c 96}outc{c 39} in {c 96}lcvars{c 39}:";
	};
	else {;
		gen double {c 96}{c 96}outc{c 39}_res{c 39} = {c 96}{c 96}outc{c 39}_use{c 39};
	};
		
	
{p 4 4 2}
	/* PERMUTATION -----------------------------------------------------------*/
	/* permute the outcome vector */
	
{p 4 4 2}
	if "{c 96}naive{c 39}"!="" {;
		if ("{c 96}verbose{c 39}"!="") nois di as text "Naive Permutations for {c 96}outc{c 39} (chosen by user)";
		bperm {c 96}{c 96}outc{c 39}_res{c 39}, np(np{c 39});
	};
	else {;
	/* default to naive permutation if no block variables supplied */
		if "{c 96}blockvars{c 39}"=="" {; /* Naive Permutations (no blocks supplied) */
			if ("{c 96}verbose{c 39}"!="") nois di as text "Naive Permutations for {c 96}outc{c 39} (no blocks supplied)";
			bperm {c 96}{c 96}outc{c 39}_res{c 39}, np(np{c 39});
		};
		else {; /* Blocks: combinations of {c 96}blockvars{c 39}" */
			if ("{c 96}verbose{c 39}"!="") nois di as text "Block Permutations for {c 96}outc{c 39} (blocks: {c 96}blockvars{c 39})";
			tempvar block;
			egen {c 96}block{c 39}=group(blockvars{c 39});				/* variable identifying blocks */
			bperm {c 96}{c 96}outc{c 39}_res{c 39}, np(np{c 39}) block(block{c 39});
		};
};
	
{p 4 4 2}
	mat Yperm = r(Yperm);
	
{p 4 4 2}
	/* add back predicted values if linear conditioning */
	if "{c 96}lcvars{c 39}"!="" {;
		mkmat {c 96}{c 96}outc{c 39}_pred{c 39}, matrix(pred);
		mata: predmat = st_matrix("pred");		/* vector (ni x 1) of predicted values */
		mata: permmat = st_matrix("Yperm");		/* matrix (ni x np) of permuted outcomes */
		mata: newpermmat = permmat + J(1,{c 96}np{c 39},predmat);		/* replicate pred np times in columns and sum to each permuted outcome */
		mata: st_matrix("newpermmat", newpermmat);
		mat Yperm = newpermmat;
	};
	
	
{p 4 4 2}
	/* GENERATE IPW WEIGHTS MATRIX --------------------------------------------------------*/
	cap nois {;				/* to continue even in cases of no convergence */
	if (nip{c 39}==1) {; 		/* single set of IPW covariates */
		if ("{c 96}ipwcovars1{c 39}"!="" & strtrim("{c 96}ipwcovars1{c 39}")!="NA") {;
			if ("{c 96}verbose{c 39}"!="") nois di as text "Generating IP weights for {c 96}outc{c 39} (covars: {c 96}ipwcovars1{c 39})";
			ipweights , permoutc(Yperm) treat(D{c 39}) covars(ipwcovars1{c 39}) link(link{c 39});
			mat ipWeights = r(weights);
			scalar nfails_h{c 39} = r(nfails);
			scalar nsucc_h{c 39} = r(nsucc);
			// check
			if (np{c 39}!=nsucc_h{c 39}+nfails_h{c 39}) {;
			di as error "Incorrect number of fails + successes in IPW";
			exit 111;
			};
		};
		else {;					/* in case of empty input */
			mat ipWeights = J(ni{c 39}, {c 96}np{c 39}, 1);
		};
	};
	else if (nip{c 39}>1) {;	/* multiple sets of IPW covariates */
		if ("{c 96}ipwcovars{c 96}h{c 39}{c 39}"!="" & strtrim("{c 96}ipwcovars{c 96}h{c 39}{c 39}")!="NA") {;
			if ("{c 96}verbose{c 39}"!="") nois di as text "Generating IP weights for {c 96}outc{c 39} (covars: {c 96}ipwcovars{c 96}h{c 39}{c 39})";
			ipweights , permoutc(Yperm) treat(D{c 39}) covars(ipwcovars{c 96}h{c 39}{c 39}) link(link{c 39});
			mat ipWeights = r(weights);
			scalar nfails_h{c 39} = r(nfails);
			scalar nsucc_h{c 39} = r(nsucc);
			// check
			if (np{c 39}!=nsucc_h{c 39}+nfails_h{c 39}) {;
			di as error "Incorrect number of fails + successes in IPW";
			exit 111;
			};
		};
		else {;					/* in case of empty input */
			mat ipWeights = J(ni{c 39}, {c 96}np{c 39}, 1);
		};
	};
	else if (nip{c 39}==0) {;	/* otherwise just matrix of unit weights */
		mat ipWeights = J(ni{c 39}, {c 96}np{c 39}, 1);
		};
	};
	
	
{p 4 4 2}
	/{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:}{ul:/
	/* COMPUTE DISTRIBUTION OF TSTATS ----------------------------- */
	
{p 4 4 2}
	/* initialise empty column matrix to store tstats */
	mat tstats = J(np{c 39},1,.);	
	mat tstats_ipw = J(np{c 39},1,.);
	
{p 4 4 2}
	forvalues r = 1(1){c 96}np{c 39} {;
		mat current_perm = Yperm[1..{c 96}ni{c 39},{c 96}r{c 39}];				/* extract permuted Y */
		svmat current_perm, names(Yp);						/* convert to variable */
		mat current_wt = ipWeights[1..{c 96}ni{c 39},{c 96}r{c 39}];			/* extract permuted IP weight */
		svmat current_wt, names(IPwt);						/* convert to variable */
		
{p 4 4 2}
		/* if IPW is selected, get both weighted and unweighted tstats */
		if (nip{c 39}>0) {;
			qui reg Yp1 {c 96}D{c 39} {c 96}lcvars{c 39};							/* get t statistic (unweighted) */
			mat tstats[r{c 39},1] = {it:b[D{c 39}]/_se[D{c 39}];
			/* compute IPW weighted tstat iff it worked */
			capture assert mi(IPwt1);
			if {it:rc {;
				qui reg Yp1 {c 96}D{c 39} {c 96}lcvars{c 39} {c 96}blockvars{c 39} [pweight=IPwt1];			/* get t statistic (IPW weighted) */
				mat tstats_ipw[r{c 39},1] = {it:b[D{c 39}]/_se[D{c 39}];
			};
		};
		else if (nip{c 39}==0) {;
			qui reg Yp1 {c 96}D{c 39} {c 96}lcvars{c 39} {c 96}blockvars{c 39};							/* get t statistic (unweighted) */
			mat tstats[r{c 39},1] = {it:b[D{c 39}]/_se[D{c 39}];
		};
		drop Yp1 IPwt1;
	};
	
{p 4 4 2}
	if (h{c 39}==1) {; 	/* if first hyp, initialise matrix */
						mat tstat_p 	= tstats;
		if (nip{c 39}>0) 	mat tstat_p_ipw = tstats_ipw;
	};
	else {; 	 	/* if later hyp, add as column to existing matrix */
						mat tstat_p 	= tstat_p, tstats;
		if (nip{c 39}>0) 	mat tstat_p_ipw = tstat_p_ipw, tstats_ipw;
	};
	
	
{p 4 4 2}
	local h={c 96}h{c 39}+1; 				/* go to next hypothesis (outcome) */
	
{p 4 4 2}
	}; /* quietly */
	
{p 4 4 2}
	};
	
	
{p 4 4 2}
/* CALCULATE PVALUES VIA MATA ------------------------------------------------*/

{p 4 4 2}
/* import matrices in mata */
mata: ts=st_matrix("tstat_s");
mata: tp=st_matrix("tstat_p");
if (nip{c 39}>0) mata: ts_ipw=st_matrix("tstat_s_ipw");
if (nip{c 39}>0) mata: tp_ipw=st_matrix("tstat_p_ipw");

{p 4 4 2}
/* calculate pvalues */
if (nip{c 39}>0) {;
	mata: pval_perm		= pcompute_perm(ts,tp);								/* permutation */
	mata: pval_perm_ipw	= pcompute_perm(ts_ipw,tp_ipw);						/* permutation+IPW */
	mata: pval_permsd	= pcompute_permsd(ts_ipw,tp_ipw, "{c 96}sdmethod{c 39}");		/* permutation+IPW+stepdown */
};
else if (nip{c 39}==0) {;
	mata: pval_perm		= pcompute_perm(ts,tp);								/* permutation */
	mata: pval_perm_ipw	= J(1,{c 96}nh{c 39},.);										/* permutation+IPW (empty) */
	mata: pval_permsd	= pcompute_permsd(ts,tp, "{c 96}sdmethod{c 39}");				/* permutation+stepdown (no IPW)*/
};

{p 4 4 2}
/* put back to stata */
local matsfrommata "pval_perm pval_perm_ipw pval_permsd ";
foreach x of local matsfrommata {;
mata: st_matrix("{c 96}x{c 39}", {c 96}x{c 39});
};


{p 4 4 2}
/* matrix column names */
local matnames "pval_reg pval_reg1s pval_perm pval_perm_ipw pval_permsd tstat_p tstat_s";
foreach x of local matnames {;
mat colnames {c 96}x{c 39} = {c 96}varlist{c 39};
};

{p 4 4 2}
/* combine matrices */
mat res = 		msd, 
				uteff_s{c 39}, utese_s{c 39}, uteff_s_es{c 39}, utese_s_es{c 39}, 
				teff_s{c 39}, tese_s{c 39}, teff_s_es{c 39}, tese_s_es{c 39},
				teff_s_ipw{c 39}, tese_s_ipw{c 39}, teff_s_ipw_es{c 39}, tese_s_ipw_es{c 39},
				pval_reg1s{c 39}, pval_perm{c 39}, pval_perm_ipw{c 39}, pval_permsd{c 39};
mat colnames res = 	"N_C" "mean_C" "SD_C" "N_T" "mean_T" "SD_T" "diff_TC" 
					"UCTE" "UCTE_SE" "UCTE_es" "UCTE_SE_es" 
					"CTE" "CTE_SE" "CTE_es" "CTE_SE_es" 
					"CTEI" "CTEI_SE" "CTEI_es" "CTEI_SE_es" 
					"p_samp" "p_perm" "p_pipw" "p_pisd";
mat rownames res = {c 96}varlist{c 39};



{p 4 4 2}
/* DISPLAY HEADER -----------------------------------------------------------*/

{p 4 4 2}
di as text "";
di as result		"PERMUTATION-STEPDOWN RESULTS";

{p 4 4 2}
// SUBSAMPLE header
if "{c 96}if{c 39}" != "" {;
		di as text "Subsample: " as result "{c 96}if{c 39}";
	};

{p 4 4 2}
// BLOCKS header
if "{c 96}blockvars{c 39}"=="" {;
	nois di as text "Naive Permutations (no blocks supplied)";
};
else {;
	if "{c 96}blockvars{c 39}"=="" {;
		nois di as text "Naive Permutations (no blocks supplied)";
	};
	else {;
		nois di as text "Blocks: combinations of " as result "{c 96}blockvars{c 39}";
	};
};

{p 4 4 2}
// LINEAR CONDITIONING HEADER
if "{c 96}lcvars{c 39}"!="" {;
	nois di as text "Linear conditioning in " as result  "{c 96}lcvars{c 39}";
};

{p 4 4 2}
// IPW header
if (nip{c 39}==0) {;
		di as text "No IPW Adjustment for Attrition";
	};
	else if (nip{c 39}==1) {;
		if ("{c 96}ipwcovars1{c 39}"!="") {;
			di as text "IPW Adjustment for Attrition, using " as result "{c 96}ipwcovars1{c 39}";
			forvalues h=1(1){c 96}nh{c 39} {;
				local o: word {c 96}h{c 39} of {c 96}varlist{c 39};
				di as text "    success rate for {c 96}o{c 39}: " (np{c 39}-nfails_h{c 39})/{c 96}np{c 39} *100 "% (" {c 96}np{c 39}-nfails_h{c 39} "/" {c 96}np{c 39} ")";
			};
		};
	};
	else if (nip{c 39}>1) {;
		di as text "IPW Adjustment for Attrition, using:";
		forvalues i=1(1){c 96}nip{c 39} {;
			local o: word {c 96}i{c 39} of {c 96}varlist{c 39};
			di as text "for " as result "{c 96}o{c 39}" as text ": " "{c 96}ipwcovars{c 96}i{c 39}{c 39}";
			di as text "			success rate: " (np{c 39}-nfails_i{c 39})/{c 96}np{c 39} *100 "% (" {c 96}np{c 39}-nfails_i{c 39} "/" {c 96}np{c 39} ")";
		};
	};

{p 4 4 2}
// SDMETHOD header
if ("{c 96}sdmethod{c 39}" == "rw16") {;
		di as text "Stepdown method: Romano and Wolf (2016)";
	};
	else {;
		di as text "Stepdown method: Rodrigo";
	};
	
{p 4 4 2}
/* DISPLAY RESULTS TABLE -----------------------------------------------------------*/

{p 4 4 2}
di as text "{hline 21}{c TT}{hline 19}{c TT}{hline 19}{c TT}{hline 18}{c TT}{hline 30}{c TRC}";
if ("{c 96}effsize{c 39}"=="") 	di as text "                     {c |}      Controls     {c |}      Treated      {c |}     Cond. TE     {c |}       1-Sided P-Values       {c |}";
else 					di as text "                     {c |}      Controls     {c |}      Treated      {c |} Cond. TE (esize) {c |}       1-Sided P-Values       {c |}";
di as text "         Outcome     {c |}  Obs   Mean (SD)  {c |}  Obs   Mean (SD)  {c |}  No IPW    IPW   {c |}   Samp   Perm    IPW   StpD  {c |}";
di as text "{hline 21}{c +}{hline 19}{c +}{hline 19}{c +}{hline 18}{c +}{hline 30}{c +}";

{p 4 4 2}
local h=1;
foreach outc of varlist {c 96}varlist{c 39} {;

{p 4 4 2}
/* generate line of pvalue stars */

{p 4 4 2}
if 			inrange(pval_reg1s[1,{c 96}h{c 39}],0, .01) {;
{space 1}		local stars_1 = "{ul:*";
};
else if 	inrange(pval_reg1s[1,{c 96}h{c 39}], 0.01, .05) {;
{space 1}		local stars_1 = "{ul: ";
};
else if 	inrange(pval_reg1s[1,{c 96}h{c 39}], 0.05, .1) {;
{space 1}		local stars_1 = "*  ";
};
else {;
		local stars_1 = "   ";
};
/* -------------------- */
if 			inrange(pval_perm[1,{c 96}h{c 39}],0, .01) {;
{space 1}		local stars_2 = "{ul:*";
};
else if 	inrange(pval_perm[1,{c 96}h{c 39}], 0.01, .05) {;
{space 1}		local stars_2 = "{ul: ";
};
else if 	inrange(pval_perm[1,{c 96}h{c 39}], 0.05, .1) {;
{space 1}		local stars_2 = "*  ";
};
else {;
		local stars_2 = "   ";
};
/* -------------------- */
if 			inrange(pval_perm_ipw[1,{c 96}h{c 39}],0, .01) {;
{space 1}		local stars_3 = "{ul:*";
};
else if 	inrange(pval_perm_ipw[1,{c 96}h{c 39}], 0.01, .05) {;
{space 1}		local stars_3 = "{ul: ";
};
else if 	inrange(pval_perm_ipw[1,{c 96}h{c 39}], 0.05, .1) {;
{space 1}		local stars_3 = "*  ";
};
else {;
		local stars_3 = "   ";
};
/* -------------------- */
if 			inrange(pval_permsd[1,{c 96}h{c 39}],0, .01) {;
{space 1}		local stars_4 = "{ul:*";
};
else if 	inrange(pval_permsd[1,{c 96}h{c 39}], 0.01, .05) {;
{space 1}		local stars_4 = "{ul: ";
};
else if 	inrange(pval_permsd[1,{c 96}h{c 39}], 0.05, .1) {;
{space 1}		local stars_4 = "*  ";
};
else {;
		local stars_4 = "   ";
};
/* -------------------- */

{p 4 4 2}
local outclab: variable label {c 96}outc{c 39};
if ("{c 96}outclab{c 39}" == "") local outclab = "{c 96}outc{c 39}";

{p 4 4 2}
/* dispay normal TE */
if ("{c 96}effsize{c 39}"=="") {;
di as text 			%-20s abbrev("{c 96}outclab{c 39}",20)
					" {c |}" %5.0g msd[h{c 39}, 1] "   " %8.3f msd[h{c 39}, 2] "   {c |}" %5.0g msd[h{c 39}, 4] "   " %8.3f msd[h{c 39}, 5] "   {c |}" 		/* N and Mean */
					"  " %6.2f teff_s[1, {c 96}h{c 39}]  "  " %6.2f teff_s_ipw[1, {c 96}h{c 39}] "  {c |}"																						/* TEs */
					"  " %5.3f pval_reg1s[1,{c 96}h{c 39}] "  " %5.3f pval_perm[1,{c 96}h{c 39}] "  " %5.3f pval_perm_ipw[1,{c 96}h{c 39}] "  " %5.3f pval_permsd[1,{c 96}h{c 39}] "  {c |}"						/* PVALS 1SIDED */
					;
di as text			
					"                     {c |}        (" %7.3f msd[h{c 39}, 3]  ")  {c |}        (" %7.3f msd[h{c 39}, 6] ")  {c |}"						/* SD */
					" (" %5.2f tese_s[1, {c 96}h{c 39}] ")  (" %5.2f tese_s_ipw[1, {c 96}h{c 39}] ") {c |}" 																													
					"  {c 96}stars_1{c 39}    {c 96}stars_2{c 39}    {c 96}stars_3{c 39}    {c 96}stars_4{c 39}    {c |}"  																				/* PVALS STARS */
					;
};
/* dispay effect size TE */
else {;
di as text 			%-20s abbrev("{c 96}outclab{c 39}",20)
					" {c |}" %5.0g msd[h{c 39}, 1] "   " %8.3f msd[h{c 39}, 2] "   {c |}" %5.0g msd[h{c 39}, 4] "   " %8.3f msd[h{c 39}, 5] "   {c |}" 		/* N and Mean */
					"  " %6.2f teff_s_es[1, {c 96}h{c 39}]  "  " %6.2f teff_s_ipw_es[1, {c 96}h{c 39}] "  {c |}"																						/* TEs */
					"  " %5.3f pval_reg1s[1,{c 96}h{c 39}] "  " %5.3f pval_perm[1,{c 96}h{c 39}] "  " %5.3f pval_perm_ipw[1,{c 96}h{c 39}] "  " %5.3f pval_permsd[1,{c 96}h{c 39}] "  {c |}"						/* PVALS 1SIDED */
					;
di as text			
					"                     {c |}        (" %7.3f msd[h{c 39}, 3]  ")  {c |}        (" %7.3f msd[h{c 39}, 6] ")  {c |}"						/* SD */
					" (" %5.2f tese_s_es[1, {c 96}h{c 39}] ")  (" %5.2f tese_s_ipw_es[1, {c 96}h{c 39}] ") {c |}" 																													
					"  {c 96}stars_1{c 39}    {c 96}stars_2{c 39}    {c 96}stars_3{c 39}    {c 96}stars_4{c 39}    {c |}"  																				/* PVALS STARS */
					;
};



{p 4 4 2}
/* special last line */
if (h{c 39} != {c 96}nh{c 39}) 	di as text "{hline 21}{c +}{hline 19}{c +}{hline 19}{c +}{hline 18}{c +}{hline 30}{c +}";
else 				di as text "{hline 21}{c BT}{hline 19}{c BT}{hline 19}{c BT}{hline 18}{c BT}{hline 30}{c BRC}";

{p 4 4 2}
local h={c 96}h{c 39}+1;
};

{p 4 4 2}
if "{c 96}if{c 39}" != "" {;
restore;
};

{p 4 4 2}
/* RETURN OBJECTS ------------------------------------------------------------*/

{p 4 4 2}
/* save matrix */
qui {;
if "{c 96}savemat{c 39}" != "" {;
	preserve;
	clear;
	set obs {c 96}=rowsof(res){c 39};	/* to avoid press key */
	gen junk={it:n;
	svmat2 res, names(col) rnames(varname);
	drop junk;
	export delimited using "{c 96}savemat{c 39}", nolab replace;
	restore;
};
};

{p 4 4 2}
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





{p 4 4 2}
end;

{p 4 4 2}
#delimit cr


