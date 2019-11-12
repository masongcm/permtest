
********************************************************************************
// BPERM_MATA -  mata routine to permute by block
********************************************************************************
// Arguments:
// vartoperm 					-  (string name of) Variable to permute
// block						-  (string name of) Block variables
// np							-  (string name of) Number of permutations
// naive						-  Whether permutation must be naive (overrides blocks)
********************************************************************************

cap mata: mata drop bperm_mata()
mata
mata clear  

void bperm_mata( ///
				string scalar vartoperm, ///
				string scalar block, ///
				numeric scalar np, ///
				numeric scalar naive, ///
				string scalar perm) 
{

/* initialise objects */
real matrix V, B, P

st_view(V, ., vartoperm) 		// variable to permute
ni 		= rows(V)				// observations to permute

/* naive permutation */
if (naive==1) { 												
	perm_n=J(ni, np,.) 		 							/* allocate */
	r=1
	for (r=1; r<=np; r++) {
		perm_n[,r] = jumble(V)
	}
	
	P = perm_n
}

/* block permutation */
else if (naive==0) { 		
	st_view(B, ., block) 			// import block variable
	nb = rows(uniqrows(B)) 			// number of blocks
	blockn = (1::ni),B				// add row index to blocks

	perm_b=J(ni, np,.)  								/* allocate */
	b=1

	for (b=1; b<=nb; b++) {
		bplace = select(blockn, blockn[,2]:==b)  		/* get indices of rows for each block */
		r=1
		for (r=1; r<=np; r++) {
		perm_b[bplace[,1],r] = jumble(V[bplace[,1],]) 	/* permute np times within each block */
		}
	}
	P = perm_b
}

st_matrix(perm, P)

}

end


********************************************************************************
// BPERM -  stata wrapper routine to permute treatment status by block
********************************************************************************
// Arguments:
// varlist 								-  Variable to permute
// Options:
// np()									-  Number of permutations
// block()								-  Variable containing blocks
********************************************************************************

cap program drop bperm

program bperm, rclass

syntax varlist (min=1 max=1) [if], np(integer) [block(string)]

// EXTRACT INPUTS
local toperm : word 1 of `varlist'			// variable to permute
										
// DECIDE BLOCKS
if ("`block'"=="") local naive = 1
else local naive = 0

// PERFORM PERMUTATION IN MATA
tempname Yperm
mata: Yperm = bperm_mata("`toperm'", "`block'", `np', `naive', "Yperm")

// RETURN
return scalar naive = `naive'
return matrix Yperm = Yperm

end

