
    package dma_pkg;
		parameter Tox_I = 7;
		parameter Tix 	= 2*Tox_I;
		parameter Tox 	= Tix;
		
		parameter Toy_I = 7;
		parameter Tiy 	= 2*Toy_I;
		parameter Toy 	= Tiy;
		
		parameter Nkx 	= 3;
		parameter Nky  = 3;
		
		parameter Tif 	= 8;
		parameter Tof 	= Tif;
		
		parameter Npar = 8;
		
		parameter Nnp 	= 2;
		
		parameter Size_Par = Npar * Nnp;
		parameter KDWSize = Nkx * Nky; // 16 bits each weight
		parameter init_words = 8;
	endpackage
