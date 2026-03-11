`timescale 1ns/1ps
module i2c_slave #(parameter ADDR=7'h50)(
    input wire clk, input wire rst_n,
    inout wire sda, input wire scl,
    output reg [7:0] rd_data, output reg rd_valid,
    input wire [7:0] wr_data_resp
);
    reg sda_prev, scl_prev; reg sda_oe; reg sda_out;
    assign sda=sda_oe?sda_out:1'bz;
    always @(posedge clk) begin sda_prev<=sda; scl_prev<=scl; end
    // Start/Stop detection (simplified)
    always @(posedge clk) begin rd_valid<=0; if(scl&&sda_prev&&!sda) rd_valid<=1; end // start condition
endmodule
