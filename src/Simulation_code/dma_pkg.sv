`ifndef DMAPACKAGE_DONE
    `define DMAPACKAGE_DONE
    

    package dma_pkg;
		parameter Tix 	= 4;
		parameter Tox 	= Tix;
		parameter Tiy 	= 4;
		parameter Toy 	= Tiy;
		parameter Tif 	= 8;
		parameter Tof 	= Tif;
		parameter Npar = 4;
		parameter Nnp 	= 2;
		parameter Size_Par = Npar * Nnp;
		parameter init_words = 7;
		// Bitwidth
		parameter POS_W = 3; // Log2(Npar)
		// RAM FMI param
		parameter FMI_N_ELEM = Tix * Tiy * Tif;
		parameter FMI_ADDR_W = 8; // Log 2 FMI_N_elem
	endpackage

    // import package in the design
    import dma_pkg::*;

`endif
