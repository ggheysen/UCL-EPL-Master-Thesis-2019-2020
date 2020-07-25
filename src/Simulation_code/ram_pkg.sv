
    package ram_pkg;
		import dma_pkg::*;
		// Bitwidth
		parameter PX_W = 16;
		parameter WG_W = 16;
		
		// RAM FMI param
		parameter FMI_N_ELEM = Tix * Tiy * Tif;
		parameter FMI_N_CHAN = Tix * Tiy;
		
		// RAM FMO param
		parameter FMO_N_ELEM = Tox * Toy * Tof;
		
		// RAM KEX param
		parameter KEX_N_ELEM = Nnp * Tif; // Normally, Nnp * maximum possible Ngr * Npar, but as max Ngr = (max Nif)/Npar => Nnp * Nif
		
		// RAM KPW param
		parameter KPW_N_ELEM = Nnp * Tof;
		
		// RAM FDW param
		parameter KDW_N_ELEM = Nkx * Nky * Npar;
		
		// RAM FMINT param
		parameter FMINT_N_ELEM = Tix * Tiy * Npar;
		
	endpackage
