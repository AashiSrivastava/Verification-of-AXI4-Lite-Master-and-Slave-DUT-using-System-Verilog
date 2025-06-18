class axilite_cov;
  virtual axi_if vif;

  function new(virtual axi_if vif);
    this.vif=vif;
    this.cg_axilite = new();
  endfunction

  covergroup cg_axilite @(!vif.clk);
    option.per_instance = 1;

    WRITE_ADDRESS                 : coverpoint axilite_m_tb_top.mem_vif.awaddr {
                                     bins ADDR_1_TO_10[] = {[1:10]};
                                     bins ADDR_11_TO_20[] = {[2:20]};
                                     bins ADDR_21_TO_50[4] = {[21:50]};
                                     bins ADDR_51_TO_100[4] = {[51:100]};
                                     bins ADDR_101_TO_128 = {[101:128]};

                                   }

    READ_ADDRESS                 : coverpoint axilite_m_tb_top.mem_vif.araddr {
                                     bins ADDR_1_TO_10[] = {[1:10]};
                                     bins ADDR_11_TO_20[] = {[2:20]};
                                     bins ADDR_21_TO_50[4] = {[21:50]};
                                     bins ADDR_51_TO_100[4] = {[51:100]};
                                     bins ADDR_101_TO_128 = {[101:128]};

                                   }


   WRITE_STROBE                 : coverpoint axilite_m_tb_top.mem_vif.wstrb {
                                     bins WSTRB_1 = {1};
                                     bins WSTRB_2 = {2};
                                     bins WSTRB_3 = {3};
                                     bins WSTRB_4 = {4};
                                     bins WSTRB_5 = {5};
                                     bins WSTRB_6 = {6};
                                     bins WSTRB_7 = {7};
                                     bins WSTRB_8 = {8};
                                     bins WSTRB_9 = {9};
                                     bins WSTRB_10 = {10};
                                     bins WSTRB_11 = {11};
                                     bins WSTRB_12 = {12};
                                     bins WSTRB_13 = {13};
                                     bins WSTRB_14 = {14};
                                     bins WSTRB_15 = {15};

                                   }



    WRITE_DATA	                   : coverpoint axilite_m_tb_top.mem_vif.wdata {
                                    ignore_bins DATA_0_2D              = {0};
                                    bins DATA_1_10_2D[] 		           = {[1:10]};
                                    bins DATA_11_2POW10_MIN1_2D        = {[11:(2**10)-1]};
				                            bins DATA_2POW10_2P0W11_MIN1_2D	   = {[(2**10):(2**11)-1]};
				                            bins DATA_2POW11_2P0W13_MIN1_2D    = {[(2**11):(2**13)-1]};
                                    bins DATA_2POW13_2P0W15_MIN1_2D    = {[(2**13):(2**15)-1]};
                                    bins DATA_2POW15_2P0W16_MIN1_2D    = {[(2**15):(2**16)-1]};
                                    bins DATA_2POW16_2P0W31_MIN1_2D    = {[(2**16):(2**31)-1]};
                                   }


    READ_DATA	                   : coverpoint axilite_m_tb_top.mem_axi_rdata {
                                    ignore_bins DATA_0_2D              = {0};
                                    bins DATA_1_10_2D[] 		           = {[1:10]};
                                    bins DATA_11_2POW10_MIN1_2D        = {[11:(2**10)-1]};
				                            bins DATA_2POW10_2P0W11_MIN1_2D	   = {[(2**10):(2**11)-1]};
				                            bins DATA_2POW11_2P0W13_MIN1_2D    = {[(2**11):(2**13)-1]};
                                    bins DATA_2POW13_2P0W15_MIN1_2D    = {[(2**13):(2**15)-1]};
                                    bins DATA_2POW15_2P0W16_MIN1_2D    = {[(2**15):(2**16)-1]};
                                    bins DATA_2POW16_2P0W31_MIN1_2D    = {[(2**16):(2**31)-1]};
                                   }
                               
   WRITE_DEC_ERROR                :coverpoint axilite_m_tb_top.mem_axi_bresp{
                                    bins NO_ERROR = {0};
                                    bins DEC_ERROR = {3};

                                   }

   READ_DEC_ERROR                :coverpoint axilite_m_tb_top.mem_axi_rresp{
                                    bins NO_ERROR = {0};
                                    bins DEC_ERROR = {3};

                                   } 

  endgroup

endclass
