{smcl}
{* *! version 1.2.1  07mar2013}{...}
{findalias asfradohelp}{...}
{vieweralsosee "" "--"}{...}
{vieweralsosee "[R] help" "help help"}{...}
{viewerjumpto "Syntax" "examplehelpfile##syntax"}{...}
{viewerjumpto "Description" "examplehelpfile##description"}{...}
{viewerjumpto "Options" "examplehelpfile##options"}{...}
{viewerjumpto "Remarks" "examplehelpfile##remarks"}{...}
{viewerjumpto "Examples" "examplehelpfile##examples"}{...}
{title:Title}

{phang}
{bf:permtest} {hline 2} Permutation inference for treatment effects


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:permtest}
[{outcomes}]
{if}
{cmd:,} treat(varlist) np(#) [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{synopt:{opt t:reat(varlist)}}scalar treatment indicator{p_end}
{syntab:Inference}
{synopt:{opt np}}number of permutations{p_end}
{synopt:{opt b:lockvars(varlist)}}block permutation variables (strata){p_end}
{synopt:{opt naive}}perform naive permutation (overrides {opt blockvars}) {p_end}
{synopt:{opt lc:vars(varlist)}}linear conditioning variables{p_end}
{synopt:{opt ipwcovars1(varlist)}}IPW reweighting variables{p_end}
{synopt:{opt ipwcovars2-5}}additional IPW reweighting variables{p_end}
{syntab:Other}
{synopt:{opt rev:erse}}reverse sign of outcomes for treatment effects   {p_end}
{synopt:{opt effsize}}report effect sizes {p_end}
{synopt:{opt ver:bose}}print additional information about progress to console{p_end}
{syntab:Saving}
{synopt:{opt savemat(path)}}save output in matrix form as csv {p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:permtest} performs permutation-based inference of treatment effects. 
It includes adjustments for stratified randomisation design, 
multiple hypotheses, treatment imbalance and non-random attrition.


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt treat} specifies the variable containing the treatment indicator. It must be
binary coded with values of 0 and 1.

{dlgtab:Inference}

{phang}
{opt np} specifies the desired number of permutations of the outcome vector

{phang}
{opt blockvars(varlist)} can be used to supply one or more strata used in the
randomisation protocol. Permutations will then be performed within
blocks defined by the values (or combination of values, if more than one
stratum is supplied) in {opt blockvars}. The strata variables should be
categorical, and shouldn't partition the sample in sets that are too small.

{phang}
{opt naive} overrides {opt blockvars}, by instructing the permutation
to disregard strata and just permute outcomes across the whole sample.

{phang}
{opt lcvars(varlist)} can be used to supply a list of variables to linearly 
condition on during inference. The conditioning is performed using the 
methodology from Freedman and Lane (1983).
Typical usage includes the case of baseline covariate imbalance.

{phang}
{opt ipwcovars1(varlist)} can be used to supply a list of variables to perform 
an inverse probability weighting adjustment on the treatment effect estimates.
Typical usage includes corrections for non-random attrition through the 
study period.

    
    Denote by W_j an indicator for outcome Y_j being observed. The {opt ipwcovars1} option computes
    a set of weights from a logit regression of W_j on {it:varlist}, and uses them to adjust the
    final treatment effect estimates.

    Note that:

        The logit weights are computed _for each permutation_: as such this option significantly
        increases the time intensity of the command.

        Supplying only {opt ipwcovars1} uses the same set of adjustment variables foreach outcome
        in _depvars_. If you want to specify different sets of adjustmentvariables for each
        outcome, use {opt ipwcovars2}-{opt ipwcovars5} (currently limited to 5 different sets of
        covariates).

{dlgtab:Other}

{phang}
{opt reverse} prompts all the treatment effect estimates to be reversed in sign.
This is because {cmd:permtest} conducts inference only in the form of one-sided
pvalues, and as such the sign of the outcome variables in {it:outcomes} matters.

        If the hypotheses to be tested for the variables in {it:outcomes} have different signs, the
        variables need to be reversed manually before supplying them to {cmd:permtest}.

{phang}
{opt effsize} reports treatment effects on the console as effect sizes, i.e.
standardised using the SD of the control group. This does not affect the results
stored in {cmd:r()}, which will include both normal treatment effects and effect
sizes.

{phang}
{opt verbose} instructs to print more information to the console throughout
the execution of the command.


{marker remarks}{...}
{title:Remarks}

TO COMPLETE

{marker results}{...}
{title:Stored results}

{pstd}
{cmd:permtest} stores the following in {cmd:r()}:

{synoptset 22 tabbed}{...}
{syntab:Matrices}
{synopt:{cmd:r(res)}}matrix of results{p_end}
{synopt:{cmd:r(tstat_p)}}matrix of permuted t-stats{p_end}
{synopt:{cmd:r(tstat_s)}}matrix of sample t-stats{p_end}
{synopt:{cmd:r(tstat_p_ipw)}}matrix of permuted t-stats with IPW reweighting{p_end}
{synopt:{cmd:r(tstat_s_ipw)}}matrix of sample t-stats with IPW reweighting{p_end}
{synopt:{cmd:r(pval_reg1s)}}matrix of sample p-values{p_end}
{synopt:{cmd:r(pval_reg1s_ipw)}}matrix of sample p-values with IPW reweighting{p_end}
{synopt:{cmd:r(pval_p)}}matrix of permutation p-values{p_end}
{synopt:{cmd:r(pval_p_ipw)}}matrix of permutation p-values with IPW reweighting{p_end}
{synopt:{cmd:r(pval_permsd)}}matrix of stepdown p-values{p_end}
{synopt:{cmd:r(ipWeights)}}matrix of inverse probability weights{p_end}


{marker examples}{...}
{title:Examples}

TO COMPLETE
{phang}{cmd:. whatever mpg weight}{p_end}

{phang}{cmd:. whatever mpg weight, meanonly}{p_end}

{marker author}{...}
{title:Author}

Giacomo Mason
Competition and Markets Authority - London, UK
mason.gcm@gmail.com

{marker references}{...}
{title:References}

David Freedman and David Lane. A Nonstochastic Interpretation of Reported Significance Levels. Journal of Business & Economic Statistics, 1(4):292, October 1983. ISSN 07350015. doi: 10.2307/1391660.



