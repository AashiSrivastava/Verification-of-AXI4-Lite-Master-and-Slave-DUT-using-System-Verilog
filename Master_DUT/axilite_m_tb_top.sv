class transaction;
  
  rand bit        op;
  rand bit [31:0] awaddr;
  rand bit [31:0] wdata;
  rand bit [3:0]  wstrb;
  rand bit [31:0] araddr;
       bit [31:0] rdata;
       bit [1:0]  wresp;
       bit [1:0]  rresp;
  

   constraint valid_strb_range {soft wstrb dist { 15 :/ 50, [1:14] :/ 60}; }
   constraint dist_addr {soft awaddr dist {[1:128]:=90, [128:500]:=10};
                         soft araddr dist {[1:128]:=90, [128:500]:=10};  
                        }
   constraint valid_wdata {soft wdata dist {[0:2**5] :/ 20, [2**6 : 2**8] :/ 20, [2**9 : 2**12] :/ 20, [2**13 : 2**14] :/ 20, [2**15 : 2**16] :/ 20, [2**17:2**30] :/ 10, 2**31 :/ 10};}
   constraint dist_oper {soft op dist { 1:=50, 0:=50};
                       }  
  
endclass
 
 
 
//////////////////////////////////
class generator;
  
  transaction tr,txn;
  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxgs;
  
  event done; ///gen completed sending requested no. of transaction
  event sconext; ///scoreboard complete its work
 
   int count = 0;
   int wr_flg=0, rd_flg=1;
  
  function new( mailbox #(transaction) mbxgd,mailbox #(transaction)mbxgs  );
    this.mbxgd = mbxgd;   
    this.mbxgs = mbxgs;   
    tr =new();
    txn =new();
  endfunction
  
    task run();
    for(int i=0; i < count; i++) 
    begin
     if(i%128 == 0) begin
        if(wr_flg == 1) begin
          rd_flg = 1;
          wr_flg = 0;
          $display("Rd iter %0d",((i/128)/2));
        end
        else if(rd_flg == 1) begin
          rd_flg = 0;
          wr_flg = 1;
          $display("Wr iter %0d",((i/128)/2));
        end
      end

      assert(tr.randomize() with {

                                    if(wr_flg==1) tr.op==1;
                                    else tr.op == 0;

                                    if(tr.op==0) {
                                      araddr == i % 129;
                                      awaddr == 0;
                                      wdata == 0;
                                      wstrb == 0;
                                    }
                                    if(tr.op==1) {
                                      awaddr == i % 129;
                                      araddr == 0;
                                    }
                                 }) else $error("Randomization Failed");
      $display("[GEN] : OP : %0b awaddr : %0d wdata : %0d wstrb : %0d araddr : %0d",tr.op, tr.awaddr, tr.wdata, tr.wstrb, tr.araddr);
      txn=tr;
      mbxgd.put(tr);
      mbxgs.put(txn);
      @(sconext);
    end
    ->done;
  endtask
  
   
endclass
 
 
/////////////////////////////////////
 
 
class driver;
  
  virtual axi_if vif;
  
  transaction tr;
  
  
  mailbox #(transaction) mbxgd;
  mailbox #(transaction) mbxdm;
 
  
  function new( mailbox #(transaction) mbxgd,  mailbox #(transaction) mbxdm);
    this.mbxgd = mbxgd; 
    this.mbxdm = mbxdm;
  endfunction
  
  //////////////////Resetting System
  task reset();
    
     vif.resetn  <= 1'b0; 
     vif.awready <= 1'b0;
     vif.awaddr  <= 0; 
     vif.wready <= 0;
     vif.wdata <= 0;
     vif.bvalid <= 0;  
     vif.arready <= 1'b0;
     vif.araddr <= 0;
    repeat(5) @(posedge vif.clk);
     vif.resetn <= 1'b1;
    
    $display("-----------------[DRV] : RESET DONE-----------------------------"); 
  endtask
  
  
   task write_data(input transaction tr);
      $display("[DRV] : OP : %0b awaddr : %0d wdata : %0d wstrb : %0d",tr.op, tr.awaddr, tr.wdata, tr.wstrb);
      mbxdm.put(tr);
      vif.resetn  <= 1'b1;
      vif.write_addr<=tr.awaddr;
      vif.start_write<=1'b1;
      vif.awready <= 1'b1;
      vif.arready <= 1'b0;  ////disable read
      //vif.araddr  <= 0;
      vif.write_data<=tr.wdata;
      vif.write_strb<=tr.wstrb;
      @(negedge vif.awvalid);
      vif.awready <= 1'b0;
      vif.start_write  <= 0;
      vif.wready  <= 1'b1;
      @(negedge vif.wvalid);
      vif.wready  <= 1'b0;
      vif.write_data  <= 0;
      vif.bvalid  <= 1'b1;
      vif.rvalid  <= 1'b0;
      @(negedge vif.bready);
      vif.bvalid  <= 1'b0;
   endtask
     
     
   task read_data(input transaction tr);
     $display("[DRV] : OP : %0b araddr : %0d ",tr.op, tr.araddr);
      mbxdm.put(tr);
      vif.resetn  <= 1'b1;
      vif.read_addr <= tr.araddr;
      vif.start_read<=1'b1;
      vif.awready <= 1'b0;
      vif.write_addr  <= 0;
      vif.wready  <= 1'b0;
      vif.write_data   <= 0;
      vif.bready  <= 1'b0;
      vif.arready <= 1'b1;  
      vif.rvalid  <= 1'b0;
      @(negedge vif.arvalid);
      vif.arready <= 1'b0;
      vif.start_read<=0;
      vif.rvalid  <= 1'b1;
     
      @(negedge vif.rready);
      vif.rvalid  <= 1'b0;
   endtask
 
  
 
  
  task run();
    
    forever 
    begin        
      mbxgd.get(tr);
      @(posedge vif.clk);     
     /////////////////////////write mode check and sig gen 
      if(tr.op == 1'b1) 
        write_data(tr);    
      else
        read_data(tr);    
    end
 
  endtask
  
    
  
endclass
///////////////////////////////////////////////////////
 
 
class monitor;
    
  virtual axi_if vif; 
  transaction tr,trd;
  mailbox #(transaction) mbxms;
  mailbox #(transaction) mbxdm;
 
 
  function new( mailbox #(transaction) mbxms , mailbox #(transaction) mbxdm);
    this.mbxms = mbxms;
    this.mbxdm = mbxdm;
  endfunction
  
  
  task run();
    
    tr = new();
    
    forever 
      begin 
        
      @(posedge vif.clk);
        mbxdm.get(trd);
        
        if(trd.op == 1)
          begin
            
            tr.op     = trd.op;
            tr.awaddr = trd.awaddr;
            tr.wdata  = trd.wdata;
            tr.wstrb  = trd.wstrb;
            @(posedge vif.awvalid);
            //tr.wresp=vif.wresp;
            @(negedge vif.bready);
            tr.wresp=vif.wresp;
            $display("[MON] : OP : %0b awaddr : %0d wdata : %0d wstrb : %0d wresp:%0d",tr.op, tr.awaddr, tr.wdata, tr.wstrb, tr.wresp);
            mbxms.put(tr); 
          end
        else 
          begin
            tr.op = trd.op;
            tr.araddr = trd.araddr;
            @(posedge vif.rvalid);
            tr.rdata = vif.rdata;
            tr.rresp = vif.rresp;
            @(negedge vif.rvalid);
            $display("[MON] : OP : %0b araddr : %0d rdata : %0d rresp:%0d",tr.op, tr.araddr, tr.rdata, tr.rresp);
            mbxms.put(tr); 
          end
    
      end 
  endtask
 
  
  
endclass
 
///////////////////////////////////////
 
 
class scoreboard;
  
  transaction tr,txn;
  event sconext;
 
  
  mailbox #(transaction) mbxms;
  mailbox #(transaction) mbxgs;
 
 
  
  bit [31:0] temp;
  bit [31:0] data[128] ;
  bit [3:0]  strb;
 
 task sco_mem_init();
   for(int i=0; i<128; i++)
     data[i]=2*i;
 endtask
 
  
  function new( mailbox #(transaction) mbxms , mailbox #(transaction) mbxgs);
    this.mbxms = mbxms;
    this.mbxgs = mbxgs;
  endfunction
  
  
  task run();
    
    forever 
      begin
        @(posedge axilite_m_tb_top.mem_axi_aclk);
        
      mbxms.get(tr);
      mbxgs.get(txn);
      
        if(tr.op == 1)
              begin
                strb = tr.wstrb;
                $display("[GEN->SCO] : OP : %0b awaddr : %0d wdata : %0b wstrb : %0b  wresp : %0d",txn.op, txn.awaddr, txn.wdata, txn.wstrb, txn.wresp);
                $display("[MON->SCO] : OP : %0b awaddr : %0d wdata : %0b wstrb : %0b  wresp : %0d",tr.op, tr.awaddr, tr.wdata, tr.wstrb, tr.wresp);
                if(tr.wresp == 3)
                $display("[SCO] : DEC ERROR");  
                else begin
                     case(strb)

							                            4'b0001:begin   
							                                        data[tr.awaddr][7:0] = txn.wdata[7:0];
							                                    end
							                                    
							                            4'b0010:begin   
							                                        data[tr.awaddr][15:8] =  txn.wdata[15:8];
							                                    end
							                                    
							                            4'b0100:begin   
							                                        data[tr.awaddr][23:16] =  txn.wdata[23:16];
							                                    end
							                                    
							                            4'b1000:begin
							                                        data[tr.awaddr][31:24] =  txn.wdata[31:24];
							                                    end
							                                    
							                            4'b0011:begin   
							                                        data[tr.awaddr][7:0] =  txn.wdata[7:0];
							                                        data[tr.awaddr][15:8] =  txn.wdata[15:8];
							                                    end
							                                    
							                            4'b0101:begin   
							                                        data[tr.awaddr][7:0] =  txn.wdata[7:0];                                            
							                                        data[tr.awaddr][23:16] =  txn.wdata[23:16];
							                                    end
							                                    
							                            4'b1001:begin   
							                                        data[tr.awaddr][7:0] =  txn.wdata[7:0];                                            
							                                        data[tr.awaddr][31:24] =  txn.wdata[31:24];
							                                    end
							                                    
							                            4'b0110:begin
							                                        data[tr.awaddr][15:8] =  txn.wdata[15:8];                                               
							                                        data[tr.awaddr][23:16] =  txn.wdata[23:16];
							                                    end
							                                    
							                            4'b1010:begin
							                                        data[tr.awaddr][15:8] =  txn.wdata[15:8];                                       
							                                        data[tr.awaddr][31:24] =  txn.wdata[31:24];
							                                    end
							                                    
							                            4'b1100:begin   
							                                        data[tr.awaddr][23:16] =  txn.wdata[23:16];
							                                        data[tr.awaddr][31:24] =  txn.wdata[31:24];
							                                    end
							                                    
							                            4'b0111:begin                                       
							                                        data[tr.awaddr][7:0] =  txn.wdata[7:0];
							                                        data[tr.awaddr][15:8] =  txn.wdata[15:8];                                         
							                                        data[tr.awaddr][23:16] =  txn.wdata[23:16];
							                                    end
							                                    
							                            4'b1110:begin   
							                                        data[tr.awaddr][15:8] =  txn.wdata[15:8];
							                                        data[tr.awaddr][23:16] =  txn.wdata[23:16];                                        
							                                        data[tr.awaddr][31:24] =  txn.wdata[31:24];
							                                    end
							                                    
							                            4'b1011:begin   
							                                        data[tr.awaddr][7:0]   =  txn.wdata[7:0];
							                                        data[tr.awaddr][15:8]  =  txn.wdata[15:8];                                         
							                                        data[tr.awaddr][31:24] =  txn.wdata[31:24];
							                                    end
							                                    
							                            4'b1101:begin   
							                                        data[tr.awaddr][7:0]   =  txn.wdata[7:0];                                        
							                                        data[tr.awaddr][23:16] =  txn.wdata[23:16];                                            
							                                        data[tr.awaddr][31:24] =  txn.wdata[31:24];
							                                    end
							                                    
							                            4'b1111:begin   
							                                        data[tr.awaddr][7:0]   =  txn.wdata[7:0];                                        
							                                        data[tr.awaddr][15:8]  =  txn.wdata[15:8];                                     
							                                        data[tr.awaddr][23:16] =  txn.wdata [23:16];                                       
							                                        data[tr.awaddr][31:24] =  txn.wdata [31:24];
							                                    end
							                            default: begin
							                                       // data[tr.awaddr] =  8'b1;                                        
							                                       // data[tr.awaddr+1] =  8'b1;                                        
							                                       // data[tr.awaddr+2] =  8'b1;                                        
							                                       // data[tr.awaddr+3] =  8'b1;                                        
							                                     end 

                               						 endcase
                      
                $display("[SCO] : DATA STORED ADDR :%0d and DATA :%0b with WSTRB %0b", tr.awaddr, tr.wdata, tr.wstrb);
                $display("[SCO] : DATA : %0p",data);
                end
              end
            else
              begin
                $display("time %0t : [SCO] : OP : %0b araddr : %0d rdata : %0d rresp : %0d",$time,tr.op, tr.araddr, tr.rdata, tr.rresp);
                $display("[SCO] : DATA : %0p",data);
               // $display("[SCO] : SLAVE MEM : %0p",axilite_m_tb_top.mem);
                temp = data[tr.araddr];
                $display("[SCO] temp  : %0d",temp);
                $display("[SCO] mem_axi_rdata : %0d",axilite_m_tb_top.mem_axi_rdata);
                if(tr.rresp == 3 )
                  $display("[SCO] : DEC ERROR");
                else if(axilite_m_tb_top.mem_axi_rresp == 0 && axilite_m_tb_top.mem_axi_rdata == temp)
                  $display("[SCO] : DATA MATCHED");
                  else
                  $display("[SCO] : DATA MISMATCHED ACT %0b : EXP %0b",axilite_m_tb_top.mem_axi_rdata,temp);
                end
        $display("----------------------------------------------------");
        ->sconext;
    end
  endtask
  
  
endclass
 
 
///////////////////////////////////////////////////
 `include"slave_mem_model.sv" 
 `include"axilite_cov.sv" 
 module axilite_m_tb_top;
   
  monitor mon; 
  generator gen;
  driver drv;
  scoreboard sco;
   
   
  event nextgd;
  event nextgm;
  
    logic         mem_axi_aclk;
    logic         mem_axi_aresetn;
    logic         mem_axi_awvalid;
    logic         mem_axi_awready;
    logic [31: 0] mem_axi_awaddr;
 
    logic         mem_axi_wvalid;
    logic         mem_axi_wready;
    logic [31: 0] mem_axi_wdata;
    logic [3:0]   mem_axi_wstrb;
 
    logic         mem_axi_bvalid;
    logic         mem_axi_bready;
    logic [1: 0]  mem_axi_bresp;
 
    logic         mem_axi_arvalid;
    logic         mem_axi_arready;
    logic[31: 0]  mem_axi_araddr;
 
    logic         mem_axi_rvalid;
    logic         mem_axi_rready;
    logic[31: 0]  mem_axi_rdata;
    logic [1: 0]  mem_axi_rresp; 
  
   mailbox #(transaction) mbxgd, mbxms, mbxdm , mbxgs;
  
  axi_if vif();
  axi_mem_if mem_vif();
  axilite_cov axilitecov;
   
  axilite_m dut (vif.clk, vif.resetn, vif.awvalid, vif.awready, vif.awaddr,  vif.wvalid, vif.wready,  vif.wdata, vif.wstrb, vif.bvalid, vif.bready, vif.wresp , vif.arvalid,  vif.arready, vif.araddr, vif.rvalid, vif.rready, vif.rdata, vif.rresp, vif.start_write,vif.start_read, vif.write_addr, vif.write_data, vif.write_strb, vif.read_addr, vif.read_data, vif.done);
  
  assign mem_vif.clk=vif.clk;
  assign mem_vif.resetn=vif.resetn;
  assign mem_vif.awvalid=vif.awvalid;
  assign mem_vif.arvalid=vif.arvalid;
  assign mem_vif.wvalid=vif.wvalid;
  assign mem_vif.bready=vif.bready;
  assign mem_vif.rready=vif.rready;
  assign mem_vif.awaddr=vif.awaddr;
  assign mem_vif.araddr=vif.araddr;
  assign mem_vif.wdata=vif.wdata;
  assign mem_vif.wstrb=vif.wstrb;

  assign vif.rdata = mem_axi_rdata;
  assign vif.rresp = mem_axi_rresp;
  assign vif.arready = mem_axi_arready;
  assign vif.wresp = mem_axi_bresp;
  assign vif.bvalid = mem_axi_bvalid;
  assign vif.wready = mem_axi_wready;
  assign vif.awready = mem_axi_awready;
   
  assign mem_axi_aclk = mem_vif.clk;
  assign mem_axi_aresetn= mem_vif.resetn;
  assign mem_axi_awvalid= mem_vif.awvalid;
  assign mem_axi_awaddr=mem_vif.awaddr;
                  
  assign mem_axi_wvalid=mem_vif.wvalid;
  assign mem_axi_wdata=vif.wdata;
  assign mem_axi_wstrb=vif.wstrb;
                  
  assign mem_axi_bready=mem_vif.bready;
                  
  assign mem_axi_arvalid=mem_vif.arvalid;
  assign mem_axi_araddr=mem_vif.araddr;
                  
  assign mem_axi_rready=mem_vif.rready;
 //slave_mem_model ( input  wire         .mem_axi_aclk(mem_axi_aclk),
 //                  input  wire         .mem_axi_aresetn(mem_axi_aresetn),
 //                  input  wire         .mem_axi_awvalid(mem_axi_awvalid),
 //                  output reg          .mem_axi_awready(mem_axi_awready),
 //                  input  wire [31:0]  .mem_axi_awaddr(mem_axi_awaddr),
 //                  input  wire         .mem_axi_wvalid(mem_axi_wvalid),
 //                  output reg          .mem_axi_wready(mem_axi_wready),
 //                  input  wire [31:0]  .mem_axi_wdata(mem_axi_wdata),
 //                  input  wire [3:0]   .mem_axi_wstrb(mem_axi_wstrb),
 //                  output reg          .mem_axi_bvalid(mem_axi_bvalid),
 //                  input  wire         .mem_axi_bready(mem_axi_bready),
 //                  output reg [1:0]    .mem_axi_bresp(mem_axi_bresp),
 //                  input  wire         .mem_axi_arvalid(mem_axi_arvalid),
 //                  output reg          .mem_axi_arready(mem_axi_arready),
 //                  input  wire [31:0]  .mem_axi_araddr(mem_axi_araddr),
 //                  output reg          .mem_axi_rvalid(mem_axi_rvalid),
 //                  input  wire         .mem_axi_rready(mem_axi_rready),
 //                  output reg [31:0]   .mem_axi_rdata(mem_axi_rdata),
 //                  output reg [1:0]    .mem_axi_rresp(mem_axi_rresp)
 //                ); 
 // 
  slave_mem_model mem_init (mem_vif.clk, mem_vif.resetn, mem_axi_awvalid, mem_axi_awready, mem_axi_awaddr,  mem_axi_wvalid, mem_axi_wready,  mem_axi_wdata, mem_axi_wstrb, mem_axi_bvalid, mem_axi_bready, mem_axi_bresp , mem_axi_arvalid, mem_axi_arready, mem_axi_araddr, mem_axi_rvalid, mem_axi_rready, mem_axi_rdata,mem_axi_rresp);
  


 // assign mem_vif.awready=mem_axi_awready;
 // assign mem_vif.wready=mem_axi_wready;
 // assign mem_vif.bvalid=mem_axi_bvalid;
 // assign mem_vif.bresp= mem_axi_bresp;
 // assign mem_vif.arready=mem_axi_arready;
 // assign mem_vif.rvalid=mem_axi_rvalid;
 // assign mem_vif.rdata=mem_axi_rdata;
 // assign mem_vif.rresp=mem_axi_rresp ;


  initial begin
    vif.clk <= 0;
  end
  
  always #5 vif.clk <= ~vif.clk;
  
  initial begin
 
    mbxgd = new();
    mbxms = new();
    mbxdm = new();
    mbxgs = new();
    gen = new(mbxgd, mbxgs);
    drv = new(mbxgd,mbxdm);
    
    mon = new(mbxms,mbxdm);
    sco = new(mbxms, mbxgs);
    
    gen.count = ((128*100)+2);
    drv.vif = vif;
    mon.vif = vif;
    axilitecov = new(vif);
 
    
    gen.sconext = nextgm;
    sco.sconext = nextgm;
    
  end
  
  initial begin
    drv.reset();
    sco.sco_mem_init();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join_any  
    wait(gen.done.triggered);
    $finish;
  end
   
  //initial begin
  //  $dumpfile("dump.vcd");
  //  $dumpvars;   
  //end
 
   
endmodule
interface axi_mem_if;
  logic clk,resetn;
  logic awvalid, awready;
  logic arvalid, arready;
  logic wvalid, wready;
  logic bready, bvalid;
  logic rvalid, rready;
  logic [31:0] awaddr, araddr, wdata, rdata;
  logic [3:0] wstrb;
  logic [1:0] bresp,rresp;
  
endinterface

