`timescale 1ns/1ps
module dma_channel #(parameter AW=64, DW=128, CH_ID=0)(
    input wire clk, input wire rst_n,
    input  wire [AW-1:0] src, dst, input wire [31:0] len, input wire [31:0] ctrl, input wire en,
    output reg done, output reg err,
    output reg m_arvalid, output reg [AW-1:0] m_araddr, input wire m_arready,
    input  wire m_rvalid, input wire [DW-1:0] m_rdata, output wire m_rready,
    output reg m_awvalid, output reg [AW-1:0] m_awaddr, input wire m_awready,
    output reg m_wvalid, output reg [DW-1:0] m_wdata, input wire m_wready, output wire m_bready,
    input wire m_bvalid
);
    localparam ST_IDLE=2'd0, ST_RD=2'd1, ST_WR=2'd2, ST_DONE=2'd3;
    reg [1:0] state; reg [DW-1:0] dbuf; reg [AW-1:0] src_r, dst_r; reg [31:0] rem;
    assign m_rready=(state==ST_RD); assign m_bready=(state==ST_DONE);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin state<=ST_IDLE; done<=0; err<=0; m_arvalid<=0; m_awvalid<=0; m_wvalid<=0; end
        else begin
            case(state)
                ST_IDLE: if(en) begin src_r<=src; dst_r<=dst; rem<=len; done<=0; err<=0; m_arvalid<=1; m_araddr<=src; state<=ST_RD; end
                ST_RD: begin
                    if(m_arready) m_arvalid<=0;
                    if(m_rvalid) begin dbuf<=m_rdata; state<=ST_WR; m_awvalid<=1; m_awaddr<=dst_r; end
                end
                ST_WR: begin
                    if(m_awready) m_awvalid<=0;
                    m_wvalid<=1; m_wdata<=dbuf;
                    if(m_wready) begin m_wvalid<=0; state<=ST_DONE; end
                end
                ST_DONE: begin
                    if(m_bvalid) begin
                        src_r<=src_r+16; dst_r<=dst_r+16;
                        rem<=(rem>16)?(rem-16):0;
                        if(rem<=16) begin done<=1; state<=ST_IDLE; end
                        else begin m_arvalid<=1; m_araddr<=src_r+16; state<=ST_RD; end
                    end
                end
            endcase
        end
    end
endmodule
