`timescale 1ns/1ps
// cdc_gray_fifo.v - Asynchronous FIFO using Gray code pointers
module cdc_gray_fifo #(parameter DW=32, DEPTH=16)(
    input wire wr_clk, input wire wr_rst_n,
    input wire wr_en, input wire [DW-1:0] wr_data, output wire wr_full,
    input wire rd_clk, input wire rd_rst_n,
    input wire rd_en, output reg [DW-1:0] rd_data, output wire rd_empty
);
    localparam PTR_W=$clog2(DEPTH)+1;
    reg [DW-1:0] mem[0:DEPTH-1];
    reg [PTR_W-1:0] wr_ptr, rd_ptr;
    wire [PTR_W-1:0] wr_gray=wr_ptr^(wr_ptr>>1);
    wire [PTR_W-1:0] rd_gray=rd_ptr^(rd_ptr>>1);
    wire [PTR_W-1:0] wr_gray_sync, rd_gray_sync;
    // Sync pointers across domains
    cdc_sync_2ff #(.RESET_VAL(1'b0)) sync_wr[PTR_W-1:0](.clk_dst(rd_clk),.rst_dst_n(rd_rst_n),.data_in(wr_gray),.data_out(wr_gray_sync));
    cdc_sync_2ff #(.RESET_VAL(1'b0)) sync_rd[PTR_W-1:0](.clk_dst(wr_clk),.rst_dst_n(wr_rst_n),.data_in(rd_gray),.data_out(rd_gray_sync));
    assign wr_full =(wr_gray=={~rd_gray_sync[PTR_W-1:PTR_W-2],rd_gray_sync[PTR_W-3:0]});
    assign rd_empty=(rd_gray==wr_gray_sync);
    always @(posedge wr_clk or negedge wr_rst_n) begin if(!wr_rst_n) wr_ptr<=0; else if(wr_en&&!wr_full) begin mem[wr_ptr[PTR_W-2:0]]<=wr_data; wr_ptr<=wr_ptr+1; end end
    always @(posedge rd_clk or negedge rd_rst_n) begin if(!rd_rst_n) rd_ptr<=0; else if(rd_en&&!rd_empty) begin rd_data<=mem[rd_ptr[PTR_W-2:0]]; rd_ptr<=rd_ptr+1; end end
endmodule
