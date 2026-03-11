`timescale 1ns/1ps
// cdc_sync_2ff.v - 2-flop synchronizer for single-bit CDC
module cdc_sync_2ff #(parameter RESET_VAL=1'b0)(
    input wire clk_dst, input wire rst_dst_n,
    input wire data_in, output wire data_out
);
    (* ASYNC_REG = "TRUE" *) reg stage1, stage2;
    always @(posedge clk_dst or negedge rst_dst_n) begin
        if(!rst_dst_n) begin stage1<=RESET_VAL; stage2<=RESET_VAL; end
        else begin stage1<=data_in; stage2<=stage1; end
    end
    assign data_out=stage2;
endmodule
