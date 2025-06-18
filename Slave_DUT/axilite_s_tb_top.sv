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
    for(int i=0; i < count; i++)  begin
     // if(i%128 == 0) begin
     //   if(wr_flg == 1) begin
     //     rd_flg = 1;
     //     wr_flg = 0;
     //   end
     //   else if(rd_flg == 1) begin
     //     rd_flg = 0;
     //     wr_flg = 1;
     //   end
     // end
      assert(tr.randomize() with {

                                 //   if(wr_flg==1) tr.op==1;
                                 //   else tr.op == 0;

                                 //   if(tr.op==0) {
                                 //     araddr == i % 129;
                                 //     awaddr == 0;
                                 //     wdata == 0;
                                 //     wstrb == 0;
                                 //   }
                                 //   if(tr.op==1) {
                                 //     awaddr == i % 129;
                                 //     araddr == 0;
                                 //   }
                                 }) else $error("Randomization Failed");
      $display("[GEN] : OP : %0b awaddr : %0d wdata : %0d wstrb : %0d araddr : %0d iter %0d : count %0d",tr.op, tr.awaddr, tr.wdata, tr.wstrb, tr.araddr,i,count);
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
     vif.awvalid <= 1'b0;
     vif.awaddr  <= 0; 
     vif.wvalid <= 0;
     vif.wdata <= 0;
     vif.bready <= 0;  
     vif.arvalid <= 1'b0;
     vif.araddr <= 0;
    repeat(5) @(posedge vif.clk);
     vif.resetn <= 1'b1;
    
    $display("-----------------[DRV] : RESET DONE-----------------------------"); 
  endtask
  
  
   task write_data(input transaction tr);
      $display("[DRV] : OP : %0b awaddr : %0d wdata : %0d wstrb : %0d",tr.op, tr.awaddr, tr.wdata, tr.wstrb);
      mbxdm.put(tr);
      vif.resetn  <= 1'b1;
      vif.awvalid <= 1'b1;
      vif.arvalid <= 1'b0;  ////disable read
      vif.araddr  <= 0;
      vif.awaddr  <= tr.awaddr;
      @(negedge vif.awready);
      vif.awvalid <= 1'b0;
      vif.awaddr  <= 0;
      vif.wvalid  <= 1'b1;
      vif.wdata   <= tr.wdata;
      vif.wstrb   <= tr.wstrb;
      @(negedge vif.wready);
      vif.wvalid  <= 1'b0;
      vif.wdata   <= 0;
      vif.bready  <= 1'b1;
      vif.rready  <= 1'b0;
      @(negedge vif.bvalid);
      vif.bready  <= 1'b0;
   endtask
     
     
   task read_data(input transaction tr);
     $display("[DRV] : OP : %0b araddr : %0d ",tr.op, tr.araddr);
      mbxdm.put(tr);
      vif.resetn  <= 1'b1;
      vif.awvalid <= 1'b0;
      vif.awaddr  <= 0;
      vif.wvalid  <= 1'b0;
      vif.wdata   <= 0;
      vif.bready  <= 1'b0;
      vif.arvalid <= 1'b1;  
      vif.araddr  <= tr.araddr;
      @(negedge vif.arready);
      vif.araddr  <= 0;
      vif.arvalid <= 1'b0;
      vif.rready  <= 1'b1;
      @(negedge vif.rvalid);
      vif.rready  <= 1'b0;
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
            @(posedge vif.bvalid);
            tr.wresp  = vif.wresp;
            @(negedge vif.bvalid);
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
     data[i]=0;
 endtask
 
  
  function new( mailbox #(transaction) mbxms , mailbox #(transaction) mbxgs);
    this.mbxms = mbxms;
    this.mbxgs = mbxgs;
  endfunction
  
  
  task run();
    
    forever 
      begin  
        
      mbxms.get(tr);
      mbxgs.get(txn);
      
        if(tr.op == 1)
              begin
                strb = tr.wstrb;
                $display("[GEN->SCO] : OP : %0b awaddr : %0h wdata : %0b wstrb : %0b  wresp : %0d",txn.op, txn.awaddr, txn.wdata, txn.wstrb, txn.wresp);
                $display("[MON->SCO] : OP : %0b awaddr : %0h wdata : %0b wstrb : %0b  wresp : %0d",tr.op, tr.awaddr, tr.wdata, tr.wstrb, tr.wresp);
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
                $display("[SCO] : DATA STORED ADDR :%0d and DATA :%0d", tr.awaddr, tr.wdata);
                $display("[SCO] : DATA : %0p",data);
                end
              end
            else
              begin
                $display("[SCO] : OP : %0b araddr : %0d rdata : %0d rresp : %0d",tr.op, tr.araddr, tr.rdata, tr.rresp);
                $display("[SCO] : DATA : %0p",data);
                temp = data[tr.araddr];
                $display("[SCO] temp",temp);
                if(tr.rresp == 3)
                  $display("[SCO] : DEC ERROR");
                else if (tr.rresp == 0 && tr.rdata == temp)
                  $display("[SCO] : DATA MATCHED");
                else
                  $display("[SCO] : DATA MISMATCHED");
              end
        $display("----------------------------------------------------");
        ->sconext;
    end
  endtask
  
  
endclass
 
 
///////////////////////////////////////////////////
`include"axilite_cov.sv"
 
 module axilite_s_tb_top;
   
  monitor mon; 
  generator gen;
  driver drv;
  scoreboard sco;
   
   
  event nextgd;
  event nextgm;
  
 
  
   mailbox #(transaction) mbxgd, mbxms, mbxdm , mbxgs;
  
  axi_if vif();
  axilite_cov axilitecov;
   
  axilite_s dut (vif.clk, vif.resetn, vif.awvalid, vif.awready, vif.awaddr,  vif.wvalid, vif.wready,  vif.wdata, vif.wstrb, vif.bvalid, vif.bready, vif.wresp , vif.arvalid,  vif.arready, vif.araddr, vif.rvalid, vif.rready, vif.rdata, vif.rresp);
 
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
    
    gen.count = (128 * 100 + 2);
    drv.vif = vif;
    mon.vif = vif;
    axilitecov=new(vif);
 
    
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

