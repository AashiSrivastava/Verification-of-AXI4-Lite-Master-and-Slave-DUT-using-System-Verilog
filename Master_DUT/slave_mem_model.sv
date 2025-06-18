`timescale 1ns / 1ps

module slave_mem_model (
    input  wire         mem_axi_aclk,
    input  wire         mem_axi_aresetn,

    // Write address channel
    input  wire         mem_axi_awvalid,
    output reg          mem_axi_awready,
    input  wire [31:0]  mem_axi_awaddr,

    // Write mem channel
    input  wire         mem_axi_wvalid,
    output reg          mem_axi_wready,
    input  wire [31:0]  mem_axi_wdata,
    input  wire [3:0]   mem_axi_wstrb,

    // Write response channel
    output reg          mem_axi_bvalid,
    input  wire         mem_axi_bready,
    output reg [1:0]    mem_axi_bresp,

    // Read address channel
    input  wire         mem_axi_arvalid,
    output reg          mem_axi_arready,
    input  wire [31:0]  mem_axi_araddr,

    // Read mem channel
    output reg          mem_axi_rvalid,
    input  wire         mem_axi_rready,
    output reg [31:0]   mem_axi_rdata,
    output reg [1:0]    mem_axi_rresp
);

  // Simple internal memory (register array)
  reg [31:0] mem [128];  
  reg [31:0] awaddr_reg, araddr_reg;

  // Write FSM
  typedef enum logic [1:0] {WRITE_IDLE, WRITE_DATA, WRITE_RESP} write_state_t;
  write_state_t write_state;

  // Read FSM
  typedef enum logic [1:0] {READ_IDLE, READ_DATA} read_state_t;
  read_state_t read_state;

  always @(posedge mem_axi_aclk or negedge mem_axi_aresetn) begin
    if (!mem_axi_aresetn) begin
      // Reset all outputs and states
      mem_axi_awready <= 0;
      mem_axi_wready  <= 0;
      mem_axi_bvalid  <= 0;
      mem_axi_bresp   <= 2'b00;
      mem_axi_arready <= 0;
      mem_axi_rvalid  <= 0;
      mem_axi_rdata   <= 0;
      mem_axi_rresp   <= 2'b00;
      write_state   <= WRITE_IDLE;
      read_state    <= READ_IDLE;
      for (int i = 0; i < 128; i++) begin
       mem[i] <= 2*i;
      end
     end
     else begin
      // WRITE FSM
      case (write_state)
        WRITE_IDLE: begin
          mem_axi_awready <= 1;
          mem_axi_wready  <= 1;
          if (mem_axi_wvalid && mem_axi_wready && mem_axi_awaddr<128 ) begin
            awaddr_reg <= mem_axi_awaddr;  // word-aligned, 16-word memory
                case(mem_axi_wstrb)

							                            4'b0001:begin   
							                                        mem[mem_axi_awaddr][7:0] = mem_axi_wdata[7:0];
							                                    end
							                                    
							                            4'b0010:begin   
							                                        mem[mem_axi_awaddr][15:8] =  mem_axi_wdata[15:8];
							                                    end
							                                    
							                            4'b0100:begin   
							                                        mem[mem_axi_awaddr][23:16] =  mem_axi_wdata[23:16];
							                                    end
							                                    
							                            4'b1000:begin
							                                        mem[mem_axi_awaddr][31:24] =  mem_axi_wdata[31:24];
							                                    end
							                                    
							                            4'b0011:begin   
							                                        mem[mem_axi_awaddr][7:0] =  mem_axi_wdata[7:0];
							                                        mem[mem_axi_awaddr][15:8] =  mem_axi_wdata[15:8];
							                                    end
							                                    
							                            4'b0101:begin   
							                                        mem[mem_axi_awaddr][7:0] =  mem_axi_wdata[7:0];                                            
							                                        mem[mem_axi_awaddr][23:16] =  mem_axi_wdata[23:16];
							                                    end
							                                    
							                            4'b1001:begin   
							                                        mem[mem_axi_awaddr][7:0] =  mem_axi_wdata[7:0];                                            
							                                        mem[mem_axi_awaddr][31:24] =  mem_axi_wdata[31:24];
							                                    end
							                                    
							                            4'b0110:begin
							                                        mem[mem_axi_awaddr][15:8] =  mem_axi_wdata[15:8];                                               
							                                        mem[mem_axi_awaddr][23:16] =  mem_axi_wdata[23:16];
							                                    end
							                                    
							                            4'b1010:begin
							                                        mem[mem_axi_awaddr][15:8] =  mem_axi_wdata[15:8];                                       
							                                        mem[mem_axi_awaddr][31:24] =  mem_axi_wdata[31:24];
							                                    end
							                                    
							                            4'b1100:begin   
							                                        mem[mem_axi_awaddr][23:16] =  mem_axi_wdata[23:16];
							                                        mem[mem_axi_awaddr][31:24] =  mem_axi_wdata[31:24];
							                                    end
							                                    
							                            4'b0111:begin                                       
							                                        mem[mem_axi_awaddr][7:0] =  mem_axi_wdata[7:0];
							                                        mem[mem_axi_awaddr][15:8] =  mem_axi_wdata[15:8];                                         
							                                        mem[mem_axi_awaddr][23:16] =  mem_axi_wdata[23:16];
							                                    end
							                                    
							                            4'b1110:begin   
							                                        mem[mem_axi_awaddr][15:8] =  mem_axi_wdata[15:8];
							                                        mem[mem_axi_awaddr][23:16] =  mem_axi_wdata[23:16];                                        
							                                        mem[mem_axi_awaddr][31:24] =  mem_axi_wdata[31:24];
							                                    end
							                                    
							                            4'b1011:begin   
							                                        mem[mem_axi_awaddr][7:0]   =  mem_axi_wdata[7:0];
							                                        mem[mem_axi_awaddr][15:8]  =  mem_axi_wdata[15:8];                                         
							                                        mem[mem_axi_awaddr][31:24] =  mem_axi_wdata[31:24];
							                                    end
							                                    
							                            4'b1101:begin   
							                                        mem[mem_axi_awaddr][7:0]   =  mem_axi_wdata[7:0];                                        
							                                        mem[mem_axi_awaddr][23:16] =  mem_axi_wdata[23:16];                                            
							                                        mem[mem_axi_awaddr][31:24] =  mem_axi_wdata[31:24];
							                                    end
							                                    
							                            4'b1111:begin   
							                                        mem[mem_axi_awaddr][7:0]   =  mem_axi_wdata[7:0];                                        
							                                        mem[mem_axi_awaddr][15:8]  =  mem_axi_wdata[15:8];                                     
							                                        mem[mem_axi_awaddr][23:16] =  mem_axi_wdata[23:16];                                       
							                                        mem[mem_axi_awaddr][31:24] =  mem_axi_wdata[31:24];
							                                    end
							                            default: begin
							                                       // mem[mem_axi_awaddr] =  8'b1;                                        
							                                       // mem[mem_axi_awaddr+1] =  8'b1;                                        
							                                       // mem[mem_axi_awaddr+2] =  8'b1;                                        
							                                       // mem[mem_axi_awaddr+3] =  8'b1;                                        
							                                     end 

                               						 endcase
                           
            
            //mem_axi_awready <= 0;
            //@(posedge mem_axi_aclk);
            //mem_axi_awready <= 1'b0;
            //mem_axi_wready  <= 0;
            //mem_axi_bvalid  <= 1;
              write_state   <= WRITE_RESP;
              
            end
            else begin
              if(mem_axi_awaddr<128)
                mem_axi_bresp   <= 2'b00;  
              else begin
                mem_axi_bresp   <= 2'b11;
              end
              write_state  <= WRITE_IDLE;
            end
        end : WRITE_IDLE

        WRITE_RESP: begin
          if (mem_axi_bready) begin
            mem_axi_bvalid <= 0;
            write_state  <= WRITE_IDLE;
          end
        end

        default: write_state <= WRITE_IDLE;
      endcase

      // READ FSM
      case (read_state)
        READ_IDLE: begin
          mem_axi_arready <= 1;
          if (mem_axi_arvalid) begin
            araddr_reg <= mem_axi_araddr;
            mem_axi_arready <= 0;
            mem_axi_rvalid  <= 1;
            mem_axi_rdata   <= mem[mem_axi_araddr];
            if(mem_axi_araddr<128)
              mem_axi_rresp   <= 2'b00;  
            else
              mem_axi_rresp   <= 2'b11;
            read_state    <= READ_DATA;
          end
        end

        READ_DATA: begin
          if (mem_axi_rready) begin
            mem_axi_rvalid <= 0;
            read_state   <= READ_IDLE;
          end
        end

        default: read_state <= READ_IDLE;
      endcase
    end
  end
endmodule


