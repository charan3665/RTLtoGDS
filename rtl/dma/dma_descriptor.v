`timescale 1ns/1ps
// dma_descriptor.v - Scatter-Gather DMA Descriptor Table
module dma_descriptor #(parameter N_DESC=32, AW=64)(
    input wire clk, input wire rst_n,
    // Descriptor write (from CPU)
    input wire wr_en, input wire [$clog2(N_DESC)-1:0] wr_idx,
    input wire [AW-1:0] wr_src, wr_dst, input wire [31:0] wr_len, input wire [31:0] wr_ctrl,
    input wire wr_valid_bit, input wire wr_link_valid,
    input wire [$clog2(N_DESC)-1:0] wr_next_idx,
    // Descriptor read (from DMA engine)
    input wire rd_en, input wire [$clog2(N_DESC)-1:0] rd_idx,
    output reg [AW-1:0] rd_src, rd_dst, output reg [31:0] rd_len, rd_ctrl,
    output reg rd_valid, output reg rd_link, output reg [$clog2(N_DESC)-1:0] rd_next
);
    reg [AW-1:0] src[0:N_DESC-1], dst[0:N_DESC-1];
    reg [31:0] len[0:N_DESC-1], ctrl[0:N_DESC-1];
    reg valid[0:N_DESC-1], link[0:N_DESC-1];
    reg [$clog2(N_DESC)-1:0] nxt[0:N_DESC-1];
    always @(posedge clk) begin
        if(wr_en) begin src[wr_idx]<=wr_src; dst[wr_idx]<=wr_dst; len[wr_idx]<=wr_len; ctrl[wr_idx]<=wr_ctrl; valid[wr_idx]<=wr_valid_bit; link[wr_idx]<=wr_link_valid; nxt[wr_idx]<=wr_next_idx; end
        if(rd_en) begin rd_src<=src[rd_idx]; rd_dst<=dst[rd_idx]; rd_len<=len[rd_idx]; rd_ctrl<=ctrl[rd_idx]; rd_valid<=valid[rd_idx]; rd_link<=link[rd_idx]; rd_next<=nxt[rd_idx]; end
    end
endmodule
