clear all
set more off
set matsize 10000
set seed 43
set maxvar 11000

/* this dofile generates a synthetic sample of a randomly assigned treatment,
and uses it to illustrate and test the permtest command */

// GENERATE SYNTHETIC DATA -----------------------------------------------------
/* 	covariates: sex and SES
	variable determining attrition: age
*/
set obs 200
gen id=string(10000+_n)

// generate covariate blocks (e.g. sex and SES)
gen ses = floor((3-1+1)*runiform() + 1)			// SES
tab ses, gen(sesd)
gen rand = runiform()							// sex
gen sex = (rand>0.7) + 1
drop rand
egen block=group(sex ses)

// generate age (covariate driving attrition)
gen age = floor((60-40+1)*runiform() + 40)					// between 40 and 60

// generate random assignment by block (Block Randomisation)
levelsof block, local(blockval)
gen D=.
//foreach v of local blockval {
	replace D = (runiform()>.3) if block==1
	replace D = (runiform()>.4) if block==2
	replace D = (runiform()>.4) if block==3
	replace D = (runiform()>.7) if block==4
	replace D = (runiform()>.5) if block==5
	replace D = (runiform()>.6) if block==6
//}

// generate outcomes with treatment effects
gen outcome =.
gen outcome2 =.
gen outcome3 =.
replace outcome = 10 + 0.2*D - 0.05*age + 0.2*sex + 0.05*sesd2 + 0.1*sesd3 + rnormal(0,1)
replace outcome2 = 10 + 0.5*D + 0.1*age - 0.3*sex + 0.02*sesd2 + 0.06*sesd3 + rnormal(0,1)
replace outcome3 = 10 + 0.3*D + 0.2*age - 0.2*sex + 0.03*sesd2 + 0.08*sesd3 + rnormal(0,1)


// generate LOGIT attrition for age
gen attrprob = 1/(1+exp(-( -6 + 0.1*age - 0.3*D)))
gen runif = runiform()
gen attr=(runif<attrprob)
su attr

replace outcome=. if attr==1
replace outcome2=. if attr==1
replace outcome3=. if attr==1

drop attrprob runif

/*
********************************************************************************
// PERMTEST -  main function
********************************************************************************
// Arguments:
// varlist		 						-  Outcomes
//								if they end in "_r", they will be reversed
//
// Options:
// treat()		 						-  Treatment Indicator
// np()									-  Number of permutations
// blockvars()							-  (optional) List of variables to be used for block permutation (if not specified, naive)
// lcvars()								-  (optional) List of variables to be used for linear conditioning
// sdmethod()							-  (optional) Which stepdown method to use (rw16 or rp)
// naive								-  (optional) Whether to perform naive permutation (overrides blockvars)
// reverse								-  (optional) Whether to reverse ALL outcomes for pvalues and TEs
// robust								-  (optional) Whether to use robust standard errors
//
// Options for IPW:
// link()								-  (optional) Probit or Logit link
// ipwcovars1()							-  (optional) Control variables for IPW (applies to all variables if specified alone)
// ipwcovars2()-ipwcovars5()			-  (optional) Additional Control variables for IPW (if different for each outcome)
//
// Generic options
// verbose								-  (optional) Print full progress of routine
// effsize								-  (optional) Display effects in terms of effect size
// savemat								-  (optional) File to save results matrix (csv)

// Returned objects
// r(ipWeights)							- Matrix of inverse probability weights
// r(Yperm)								- Matrix of permuted outcome vectors
// r(pval_asym2s)						- two-sided asymptotic pvalues
// r(pval_asym1s)						- one-sided asymptotic pvalues
// r(pval_perm)							- one-sided permutation pvalues
// r(pval_permipw)						- one-sided permutation+IPW pvalues
// r(pval_permipw)						- one-sided permutation+IPW pvalues
// r(pval_permsd)						- one-sided permutation+IPW+stepdown pvalues
// r(tstat_p)							- Matrix of permuted t-stats
// r(tstat_p_ipw)						- Matrix of permuted t-stats with IPW
// r(tstat_s)							- Matrix of original t-stats
// r(tstat_s_ipw)						- Matrix of original t-stats with IPW
// r(res)								- Matrix with table of results

********************************************************************************
*/

// EXAMPLE: NAIVE PERMUTATION
//permtest outcome outcome2 outcome3, treat(D) np(1000)


// EXAMPLE: NAIVE PERMUTATION + IPW with same covariate for all outcomes
// permtest outcome outcome2 outcome3, treat(D) np(10) ipwcovars1(age)

// EXAMPLE: BLOCK PERMUTATION
permtest outcome outcome2 outcome3, blockvars(sex ses) treat(D) np(1000)




