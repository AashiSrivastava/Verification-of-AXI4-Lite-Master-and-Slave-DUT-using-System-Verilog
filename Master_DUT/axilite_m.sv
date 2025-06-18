`timescale 1ns/1ps

module axilite_m (
    input  wire         m_axi_aclk,
    input  wire         m_axi_aresetn,

    // Write address channel
    output reg          m_axi_awvalid,
    input  wire         m_axi_awready,
    output reg  [31:0]  m_axi_awaddr,

    // Write data channel
    output reg          m_axi_wvalid,
    input  wire         m_axi_wready,
    output reg  [31:0]  m_axi_wdata,
    output reg  [3:0]   m_axi_wstrb,  // write strobe

    // Write response channel
    input  wire         m_axi_bvalid,
    output reg          m_axi_bready,
    input  wire [1:0]   m_axi_bresp,

    // Read address channel
    output reg          m_axi_arvalid,
    input  wire         m_axi_arready,
    output reg  [31:0]  m_axi_araddr,

    // Read data channel
    input  wire         m_axi_rvalid,
    output reg          m_axi_rready,
    input  wire [31:0]  m_axi_rdata,
    input  wire [1:0]   m_axi_rresp,

    // Control inputs
    input wire          start_write,
    input wire          start_read,
    input wire [31:0]   write_addr,
    input wire [31:0]   write_data,
    input wire [3:0]    write_strb,  
    input wire [31:0]   read_addr,
    output reg [31:0]   read_data,
    output reg          done
);

localparam IDLE        = 0,
           SEND_AW     = 1,
           SEND_W      = 2,
           WAIT_B      = 3,
           SEND_AR     = 4,
           WAIT_R      = 5;

reg [2:0] state = IDLE;

always @(posedge m_axi_aclk or negedge m_axi_aresetn) begin
    if (!m_axi_aresetn) begin
        state         <= IDLE;
        m_axi_awvalid <= 0;
        m_axi_awaddr  <= 0;
        m_axi_wvalid  <= 0;
        m_axi_wdata   <= 0;
        m_axi_wstrb   <= 0;  // Reset strobe
        m_axi_bready  <= 0;
        m_axi_arvalid <= 0;
        m_axi_araddr  <= 0;
        m_axi_rready  <= 0;
        read_data     <= 0;
        done          <= 0;
    end else begin
        case (state)
            IDLE: begin
                done <= 0;
                if (start_write) begin
                    m_axi_awvalid <= 1;
                    m_axi_awaddr  <= write_addr;
                    state         <= SEND_AW;
                end else if (start_read) begin
                    m_axi_arvalid <= 1;
                    m_axi_araddr  <= read_addr;
                    state         <= SEND_AR;
                end
            end

            // WRITE TRANSACTION
            SEND_AW: begin
                if (m_axi_awready) begin
                    m_axi_awvalid <= 0;
                    m_axi_wvalid  <= 1;
                    m_axi_wdata   <= write_data;
                    m_axi_wstrb   <= write_strb;  // Assign strobe
                    state         <= SEND_W;
                end
            end

            SEND_W: begin
                if (m_axi_wready) begin
                    m_axi_wvalid <= 0;
                    m_axi_bready <= 1;
                    state        <= WAIT_B;
                end
            end

            WAIT_B: begin
                if (m_axi_bvalid) begin
                    m_axi_bready <= 0;
                    done         <= 1;
                    state        <= IDLE;
                end
            end

            // READ TRANSACTION
            SEND_AR: begin
                if (m_axi_arready) begin
                    m_axi_arvalid <= 0;
                    m_axi_rready  <= 1;
                    state         <= WAIT_R;
                end
            end

            WAIT_R: begin
                if (m_axi_rvalid) begin
                    m_axi_rready <= 0;
                    read_data    <= m_axi_rdata;
                    done         <= 1;
                    state        <= IDLE;
                end
            end

            default: state <= IDLE;
        endcase
    end
end

endmodule
interface axi_if;
  logic clk, resetn;

  // Write address channel
  logic awvalid, awready;
  logic [31:0] awaddr;

  // Write data channel
  logic wvalid, wready;
  logic [31:0] wdata;
  logic [3:0]  wstrb; 

  // Write response channel
  logic bready, bvalid;
  logic [1:0] wresp;

  // Read address channel
  logic arvalid, arready;
  logic [31:0] araddr;

  // Read data channel
  logic rvalid, rready;
  logic [31:0] rdata;
  logic [1:0]  rresp;

   logic         start_write;
   logic          start_read;
   logic [31:0]   write_addr;
   logic [31:0]   write_data;
   logic [3:0]    write_strb;  
   logic [31:0]   read_addr;
   logic [31:0]   read_data;
   logic          done;

endinterface

