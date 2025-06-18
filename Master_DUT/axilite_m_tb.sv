module axilite_m_tb;
 
    reg tb_m_axi_aclk=0;
    reg tb_m_axi_aresetn=0;
  
    wire tb_m_axi_awvalid;
    reg tb_m_axi_awready=0;
    wire [31:0] tb_m_axi_awaddr;

    wire tb_m_axi_wvalid;
    reg tb_m_axi_wready=0;
    wire [31:0] tb_m_axi_wdata;
    wire [3:0] tb_m_axi_wstrb;

    reg tb_m_axi_bvalid=0;
    wire tb_m_axi_bready;
    reg [1:0] tb_m_axi_bresp=0;

    wire tb_m_axi_arvalid;
    reg tb_m_axi_arready=0;
    wire [31:0] tb_m_axi_araddr;

    reg tb_m_axi_rvalid=0;
    wire tb_m_axi_rready;
    reg [31:0] tb_m_axi_rdata=0;
    reg [1:0] tb_m_axi_rresp=0;

    reg tb_start_write=0;
    reg tb_start_read=0; 
    reg [31:0] tb_write_addr=0;
    reg [31:0] tb_write_data=0;
    reg [3:0]tb_write_strb=0;
    reg [31:0]tb_read_addr=0;
    wire [31:0] tb_read_data;
    wire tb_done;

  //DUT Instantiantion
  axilite_m uut( 
            .m_axi_aclk(tb_m_axi_aclk),
            .m_axi_aresetn(tb_m_axi_aresetn),
            .m_axi_awvalid(tb_m_axi_awvalid),
            .m_axi_awready(tb_m_axi_awready),
            .m_axi_awaddr(tb_m_axi_awaddr),
            .m_axi_wvalid(tb_m_axi_wvalid),
            .m_axi_wready(tb_m_axi_wready),
            .m_axi_wdata(tb_m_axi_wdata),
            .m_axi_wstrb(tb_m_axi_wstrb),
            .m_axi_bvalid(tb_m_axi_bvalid),
            .m_axi_bready(tb_m_axi_bready),
            .m_axi_bresp(tb_m_axi_bresp),
            .m_axi_arvalid(tb_m_axi_arvalid),
            .m_axi_arready(tb_m_axi_arready),
            .m_axi_araddr(tb_m_axi_araddr),
            .m_axi_rvalid(tb_m_axi_rvalid),
            .m_axi_rready(tb_m_axi_rready),
            .m_axi_rdata(tb_m_axi_rdata),
            .m_axi_rresp(tb_m_axi_rresp),
            .start_write(tb_start_write),
            .start_read(tb_start_read),  
            .write_addr(tb_write_addr),
            .write_data(tb_write_data),
            .write_strb(tb_write_strb),
            .read_addr(tb_read_addr),
            .read_data(tb_read_data),
            .done(tb_done)
  );

  reg [31:0] awaddr, araddr, wdata, rdata;
  reg [3:0] wstrb;
  reg [1:0] bresp, rresp;


  reg [31:0] mem [128];


// Generate clock signal
  initial begin
    tb_m_axi_aclk = 0;
    forever #5 tb_m_axi_aclk = ~tb_m_axi_aclk; // 100 MHz clock
  end

  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, axilite_m_tb); // Top-level module
  end

  initial begin
    for(int i = 0; i < 128; i++)begin
      mem[i] <= 0;
    end
  end

 
  // Test stimulus
  initial begin
    // Initialize signal
    tb_m_axi_aresetn = 0;
    // Reset the design
    repeat(5) @(posedge tb_m_axi_aclk);
    tb_m_axi_aresetn = 1;
    
    // Write transaction
    @(posedge tb_m_axi_aclk);
    tb_write_addr=32'h30;
    repeat(2) @(posedge tb_m_axi_aclk);
    tb_start_write = 1;
    awaddr= tb_m_axi_awaddr;
    tb_m_axi_awready=1;
    tb_write_data=32'hC0DECAFE;
    tb_write_strb=4'b1100;
    wdata = tb_m_axi_wdata; 
    wstrb = tb_m_axi_wstrb; 

    
    @(negedge tb_m_axi_awvalid);
    awaddr<= tb_m_axi_awaddr;
    wdata <= tb_m_axi_wdata; 
    wstrb <= tb_m_axi_wstrb; 
    tb_m_axi_awready=0;
    tb_start_write = 0;
    tb_m_axi_wready = 1;
    if(tb_m_axi_awaddr<128)
      bresp=2'b00;
    else
      bresp=2'b11;
    


    @(negedge tb_m_axi_wvalid);
    tb_m_axi_wready = 0;
 
    // Write response ready
    tb_m_axi_bvalid = 1;
    if(bresp==2'b00)begin
      case(wstrb)

							                            4'b0001:begin   
							                                        mem[awaddr][7:0] <= wdata[7:0];
							                                    end
							                                    
							                            4'b0010:begin   
							                                        mem[awaddr][15:8] <=  wdata[15:8];
							                                    end
							                                    
							                            4'b0100:begin   
							                                        mem[awaddr][23:16] <=  wdata[23:16];
							                                    end
							                                    
							                            4'b1000:begin
							                                        mem[awaddr][31:24] <=  wdata[31:24];
							                                    end
							                                    
							                            4'b0011:begin   
							                                        mem[awaddr][7:0] <=  wdata[7:0];
							                                        mem[awaddr][15:8] <=  wdata[15:8];
							                                    end
							                                    
							                            4'b0101:begin   
							                                        mem[awaddr][7:0] <=  wdata[7:0];                                            
							                                        mem[awaddr][23:16] <=  wdata[23:16];
							                                    end
							                                    
							                            4'b1001:begin   
							                                        mem[awaddr][7:0] <=  wdata[7:0];                                            
							                                        mem[awaddr][31:24] <=  wdata[31:24];
							                                    end
							                                    
							                            4'b0110:begin
							                                        mem[awaddr][15:8] <=  wdata[15:8];                                               
							                                        mem[awaddr][23:16] <=  wdata[23:16];
							                                    end
							                                    
							                            4'b1010:begin
							                                        mem[awaddr][15:8] <=  wdata[15:8];                                       
							                                        mem[awaddr][31:24] <=  wdata[31:24];
							                                    end
							                                    
							                            4'b1100:begin   
							                                        mem[awaddr][23:16] <=  wdata[23:16];
							                                        mem[awaddr][31:24] <=  wdata[31:24];
							                                    end
							                                    
							                            4'b0111:begin                                       
							                                        mem[awaddr][7:0] <=  wdata[7:0];
							                                        mem[awaddr][15:8] <=  wdata[15:8];                                         
							                                        mem[awaddr][23:16] <=  wdata[23:16];
							                                    end
							                                    
							                            4'b1110:begin   
							                                        mem[awaddr][15:8] <=  wdata[15:8];
							                                        mem[awaddr][23:16] <=  wdata[23:16];                                        
							                                        mem[awaddr][31:24] <=  wdata[31:24];
							                                    end
							                                    
							                            4'b1011:begin   
							                                        mem[awaddr] [7:0] <=  wdata[7:0];
							                                        mem[awaddr] [15:8] <=  wdata[15:8];                                         
							                                        mem[awaddr] [15:8] <=  wdata[31:24];
							                                    end
							                                    
							                            4'b1101:begin   
							                                        mem[awaddr][7:0] <=  wdata[7:0];                                        
							                                        mem[awaddr][23:16] <=  wdata[23:16];                                            
							                                        mem[awaddr][31:24] <=  wdata[31:24];
							                                    end
							                                    
							                            4'b1111:begin   
							                                        mem[awaddr][7:0] <=  wdata[7:0];                                        
							                                        mem[awaddr][15:8] <=  wdata[15:8];                                     
							                                        mem[awaddr][23:16] <=  wdata [23:16];                                       
							                                        mem[awaddr][31:24] <=  wdata [31:24];
							                                    end
							                            default: begin
							                                        end 

                               						 endcase
      end
      tb_m_axi_bresp=bresp;

    @(negedge tb_m_axi_bready);
   // @(posedge tb_s_axi_aclk);
    tb_m_axi_bvalid = 0;

 
   // Read transaction
     @(posedge tb_m_axi_aclk);
    tb_read_addr=32'h30;
    repeat(2)@(posedge tb_m_axi_aclk);
    tb_start_read =1;
    tb_m_axi_arready = 1;

    @(negedge tb_m_axi_arvalid);
    araddr= tb_m_axi_araddr ;
    tb_m_axi_arready = 0;
    tb_start_read =0;

    //  Read data ready
    tb_m_axi_rvalid = 1;
    tb_m_axi_rdata = mem[tb_m_axi_araddr];
    if(tb_m_axi_araddr >128)
      tb_m_axi_rresp=2'b11;
    else
      tb_m_axi_rresp=2'b00;
 
            
    @(negedge tb_m_axi_rready);
    tb_m_axi_rvalid = 0;


    // Read transaction
     @(posedge tb_m_axi_aclk);
    tb_read_addr=32'h31;
    repeat(2)@(posedge tb_m_axi_aclk);
    tb_start_read =1;
    tb_m_axi_arready = 1;

    @(negedge tb_m_axi_arvalid);
    araddr= tb_m_axi_araddr ;
    tb_m_axi_arready = 0;
    tb_start_read =0;

    //  Read data ready
    tb_m_axi_rvalid = 1;
    tb_m_axi_rdata = mem[tb_m_axi_araddr];
    if(tb_m_axi_araddr >128)
      tb_m_axi_rresp=2'b11;
    else
      tb_m_axi_rresp=2'b00;
 
            
    @(negedge tb_m_axi_rready);
    tb_m_axi_rvalid = 0;


     #100;
   $finish();
  end
 
endmodule

