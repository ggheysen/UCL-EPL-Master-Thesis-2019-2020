

`ifndef TBPACKAGE_DONE
    `define TBPACKAGE_DONE
    

    package tb_pkg;
		parameter hlf_clk  = 5;
		parameter full_clk = 2*hlf_clk;
	endpackage

    // import package in the design
    import tb_pkg::*;

`endif
