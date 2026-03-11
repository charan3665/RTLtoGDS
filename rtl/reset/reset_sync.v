`timescale 1ns/1ps
module reset_sync(
    input wire clk, input wire rst_async_n,
    output wire rst_sync_n
);
    cdc_reset_sync #(.STAGES(3)) u(.clk(clk),.rst_async_n(rst_async_n),.rst_sync_n(rst_sync_n));
endmodule
