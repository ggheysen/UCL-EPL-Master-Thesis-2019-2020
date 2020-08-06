package irb_pkg;
		/* CNN parameters */
		// Kernel
		parameter Nkx 	= 3; // Width of a DW kernel
		parameter Nky  = 3; // Height of a DW kernel
		
		// FM
		parameter Tox_I = 7; // Tox parameter
		parameter Tix_T 	= Tox_I + Nkx - 1; // Corresponding Tix
		parameter Tox_T 	= Tox_I; // To have Tix and Tox have the same value
		parameter Toy_I = 7; // Tox parameter
		parameter Tiy_T = Toy_I + Nky - 1; // Corresponding Tix
		parameter Toy_T = Toy_I; // To have Tix and Tox have the same value
		parameter Tif 	= 1280; // Maximum number of input channel
		parameter Tof 	= Tif; // Maximum number of output channel
		
		/* Pruning parameters */
		parameter Npar = 32;
		parameter Nnp 	= 2;
		
		/* Layer information paramters */
		parameter Size_Par = Npar * Nnp;
		parameter Size_inf_layer = 8;
		
		/* Pruning parameters */
		parameter PX_W = 16;
		parameter WG_W = 16; 
		
		/* RAM parameters */
		// RAM FMI
		parameter FMI_N_ELEM = 7*7*1280; // Number of element in RAM
		parameter Size_FMI_T = Tix_T * Tiy_T; 		  // Size of one FMI Tile
		
		// RAM FMO 
		parameter FMO_N_ELEM = 7*7*1280; // Number of element in RAM
		parameter Size_FMO_T = Tox_T * Toy_T;		  // Size of one FMO Tile (in address)
		
		// RAM KEX
		parameter KEX_N_ELEM = Nnp * Tif; // Normally, Nnp * maximum possible Ngr * Npar, but as max Ngr = (max Nif)/Npar => Nnp * Nif
		
		// RAM KPW
		parameter KPW_N_ELEM = Nnp * Tof;
		
		// RAM FDW
		parameter KDW_N_ELEM = Nkx * Nky * Npar;
		parameter SIZE_DW_T = Nkx * Nky;				// Number of element in one DW kernel
		parameter SIZE_PAR_DW = Nkx * Nky * Npar;
		
		// RAM FMINT
		parameter FMINT_N_ELEM = Tix_T * Tiy_T * Npar;
		parameter Size_FMINT_T = Tix_T * Tiy_T;
endpackage
