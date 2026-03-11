`timescale 1ns/1ps
// cdc_pulse_sync.v - Pulse synchronizer using toggle handshake
module cdc_pulse_sync(
    input wire clk_src, input wire rst_src_n,
    input wire pulse_in, // single cycle pulse
    input wire clk_dst, input wire rst_dst_n,
    output wire pulse_out // single cycle pulse in dst domain
);
    reg toggle; wire sync_toggle; reg sync_r;
    always @(posedge clk_src or negedge rst_src_n) begin if(!rst_src_n) toggle<=0; else if(pulse_in) toggle<=~toggle; end
    cdc_sync_2ff u_sync(.clk_dst(clk_dst),.rst_dst_n(rst_dst_n),.data_in(toggle),.data_out(sync_toggle));
    always @(posedge clk_dst or negedge rst_dst_n) begin if(!rst_dst_n) sync_r<=0; else sync_r<=sync_toggle; end
    assign pulse_out=sync_toggle^sync_r;
endmodule
