`ifndef TBPACKAGE_DONE
    `define TBPACKAGE_DONE
    

    package tb_pkg;
		parameter hlf_clk  = 5;
		parameter full_clk = 2*hlf_clk;
		parameter lng_wait = 10*hlf_clk;
		parameter ini_wait = 10;
		parameter offset_inf_conv = 0;
		parameter offset_fmi = 2*(2**20);
		parameter offset_fmo = 24*(2**20);
		parameter offset_kex = 46*(2**20);
		parameter offset_kpw = 66*(2**20);
		parameter offset_kdw = 84*(2**20);
		parameter stp_offset = 103*(2**20);
	endpackage

    // import package in the design
    import tb_pkg::*;

`endif
