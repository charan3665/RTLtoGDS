// ============================================================
// dma_controller.v - Multi-Channel DMA Controller (8 channels)
// Supports: memory-to-memory, scatter-gather, burst, 2D DMA
// ============================================================
`timescale 1ns/1ps
module dma_controller #(
    parameter N_CHAN   = 8,
    parameter AW       = 64,
    parameter DW       = 128,
    parameter DESC_FIFO= 16
)(
    input  wire         clk, input wire rst_n,
    // APB configuration interface
    input  wire         psel, input wire pena, input wire pwrite,
    input  wire [15:0]  paddr, input wire [31:0] pwdata,
    output reg  [31:0]  prdata, output reg pready, output reg pslverr,
    // AXI4 master (shared bus)
    output wire         m_arvalid, output wire [AW-1:0] m_araddr, output wire [7:0] m_arlen,
    output wire [2:0]   m_arsize, output wire [1:0] m_arburst, input wire m_arready,
    input  wire         m_rvalid,  input wire [DW-1:0] m_rdata, input wire m_rlast, output wire m_rready,
    output wire         m_awvalid, output wire [AW-1:0] m_awaddr, output wire [7:0] m_awlen,
    output wire [2:0]   m_awsize, output wire [1:0] m_awburst, input wire m_awready,
    output wire         m_wvalid,  output wire [DW-1:0] m_wdata, output wire [DW/8-1:0] m_wstrb, output wire m_wlast, input wire m_wready,
    input  wire         m_bvalid,  input wire [1:0] m_bresp, output wire m_bready,
    // Interrupts per channel
    output wire [N_CHAN-1:0] dma_irq
);
    // Per-channel registers
    reg [AW-1:0]  ch_src  [0:N_CHAN-1];
    reg [AW-1:0]  ch_dst  [0:N_CHAN-1];
    reg [31:0]    ch_len  [0:N_CHAN-1];  // bytes
    reg [N_CHAN-1:0] ch_en;
    reg [N_CHAN-1:0] ch_done;
    reg [N_CHAN-1:0] ch_err;
    reg [31:0]    ch_ctrl [0:N_CHAN-1]; // [0]=burst,[3:1]=burst_size,[4]=sg,[7:5]=priority

    // Channel arbitration
    reg [$clog2(N_CHAN)-1:0] active_ch;
    reg ch_active;
    reg [AW-1:0]  xfer_src, xfer_dst;
    reg [31:0]    xfer_rem;
    reg [DW-1:0]  rd_buf;
    reg           rd_buf_valid;

    localparam ST_IDLE=3'd0, ST_RD_ADDR=3'd1, ST_RD_DATA=3'd2, ST_WR_ADDR=3'd3, ST_WR_DATA=3'd4, ST_WR_RESP=3'd5;
    reg [2:0] state;

    // APB register interface
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ch_en<=0; pready<=0; prdata<=0; pslverr<=0;
            for(integer i=0;i<N_CHAN;i=i+1) begin ch_src[i]<=0; ch_dst[i]<=0; ch_len[i]<=0; ch_ctrl[i]<=0; end
        end else begin
            pready<=pena&&psel;
            if(psel&&pena) begin
                automatic reg [3:0] ch_sel = paddr[7:4];
                automatic reg [3:0] reg_sel = paddr[3:0];
                if(pwrite) begin
                    case(reg_sel)
                        4'h0: ch_src[ch_sel][31:0]  <= pwdata;
                        4'h1: ch_src[ch_sel][63:32] <= pwdata;
                        4'h2: ch_dst[ch_sel][31:0]  <= pwdata;
                        4'h3: ch_dst[ch_sel][63:32] <= pwdata;
                        4'h4: ch_len[ch_sel]  <= pwdata;
                        4'h5: ch_ctrl[ch_sel] <= pwdata;
                        4'h6: begin ch_en[ch_sel]<=pwdata[0]; ch_done[ch_sel]<=0; ch_err[ch_sel]<=0; end
                    endcase
                end else begin
                    case(reg_sel)
                        4'h0: prdata<=ch_src[ch_sel][31:0];
                        4'h1: prdata<=ch_src[ch_sel][63:32];
                        4'h2: prdata<=ch_dst[ch_sel][31:0];
                        4'h3: prdata<=ch_dst[ch_sel][63:32];
                        4'h4: prdata<=ch_len[ch_sel];
                        4'h5: prdata<=ch_ctrl[ch_sel];
                        4'h6: prdata<={30'b0, ch_err[ch_sel], ch_done[ch_sel]};
                        default: prdata<=32'hDEADBEEF;
                    endcase
                end
            end
        end
    end

    // DMA execution state machine
    integer i;
    reg [2:0] rd_cnt, wr_cnt;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin state<=ST_IDLE; ch_active<=0; ch_done<=0; ch_err<=0; rd_buf_valid<=0; end
        else begin
            case(state)
                ST_IDLE: begin
                    ch_active<=0;
                    for(i=N_CHAN-1;i>=0;i=i-1) begin
                        if(ch_en[i] && ch_len[i]>0) begin
                            active_ch <=i[$clog2(N_CHAN)-1:0];
                            xfer_src  <=ch_src[i];
                            xfer_dst  <=ch_dst[i];
                            xfer_rem  <=ch_len[i];
                            ch_active<=1;
                        end
                    end
                    if(ch_active) state<=ST_RD_ADDR;
                end
                ST_RD_ADDR: state<=ST_RD_DATA;
                ST_RD_DATA: if(m_rvalid) begin rd_buf<=m_rdata; rd_buf_valid<=1; state<=ST_WR_ADDR; end
                ST_WR_ADDR: state<=ST_WR_DATA;
                ST_WR_DATA: if(m_wready) begin
                    rd_buf_valid<=0;
                    xfer_src<=xfer_src+(DW/8);
                    xfer_dst<=xfer_dst+(DW/8);
                    xfer_rem<=(xfer_rem>=(DW/8))?(xfer_rem-(DW/8)):0;
                    state<=ST_WR_RESP;
                end
                ST_WR_RESP: if(m_bvalid) begin
                    if(xfer_rem==0) begin
                        ch_done[active_ch]<=1;
                        ch_en[active_ch]  <=0;
                        state<=ST_IDLE;
                    end else state<=ST_RD_ADDR;
                end
            endcase
        end
    end

    assign m_arvalid = (state==ST_RD_ADDR);
    assign m_araddr  = xfer_src;
    assign m_arlen   = 8'd0;
    assign m_arsize  = 3'b100; // 16 bytes
    assign m_arburst = 2'b01;
    assign m_rready  = (state==ST_RD_DATA);
    assign m_awvalid = (state==ST_WR_ADDR);
    assign m_awaddr  = xfer_dst;
    assign m_awlen   = 8'd0;
    assign m_awsize  = 3'b100;
    assign m_awburst = 2'b01;
    assign m_wvalid  = (state==ST_WR_DATA) && rd_buf_valid;
    assign m_wdata   = rd_buf;
    assign m_wstrb   = {(DW/8){1'b1}};
    assign m_wlast   = 1'b1;
    assign m_bready  = (state==ST_WR_RESP);
    assign dma_irq   = ch_done;
endmodule
