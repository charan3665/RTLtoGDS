`timescale 1ns/1ps
// cdc_handshake.v - 4-phase handshake CDC for multi-bit data
module cdc_handshake #(parameter DW=32)(
    input wire clk_src, input wire rst_src_n,
    input wire req, input wire [DW-1:0] data_in, output wire ack_src,
    input wire clk_dst, input wire rst_dst_n,
    output reg valid_dst, output reg [DW-1:0] data_dst, output wire ready_dst
);
    reg req_toggle; reg [DW-1:0] data_latch;
    wire req_sync, ack_toggle;
    reg ack_toggle_r;
    always @(posedge clk_src or negedge rst_src_n) begin if(!rst_src_n) req_toggle<=0; else if(req) begin req_toggle<=~req_toggle; data_latch<=data_in; end end
    cdc_sync_2ff u_req_sync(.clk_dst(clk_dst),.rst_dst_n(rst_dst_n),.data_in(req_toggle),.data_out(req_sync));
    cdc_sync_2ff u_ack_sync(.clk_dst(clk_src),.rst_dst_n(rst_src_n),.data_in(ack_toggle),.data_out(ack_src));
    reg req_sync_r; assign ready_dst=1'b1;
    always @(posedge clk_dst or negedge rst_dst_n) begin
        if(!rst_dst_n) begin req_sync_r<=0; valid_dst<=0; ack_toggle_r<=0; end
        else begin req_sync_r<=req_sync; valid_dst<=(req_sync^req_sync_r); if(req_sync^req_sync_r) data_dst<=data_latch; ack_toggle_r<=req_sync; end
    end
    assign ack_toggle=ack_toggle_r;
endmodule
