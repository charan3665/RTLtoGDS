`timescale 1ns/1ps
module reset_controller(
    input wire clk, input wire por_n, input wire ext_rst_n, input wire wdt_rst_n,
    input wire sw_rst,  // software reset from CSR
    output wire sys_rst_n, output wire [3:0] rst_cause
);
    reg [3:0] rst_cause_r; reg rst_r;
    assign rst_cause=rst_cause_r; assign sys_rst_n=rst_r;
    always @(posedge clk or negedge por_n) begin
        if(!por_n) begin rst_r<=0; rst_cause_r<=4'b0001; end
        else begin
            if(!ext_rst_n) begin rst_r<=0; rst_cause_r<=4'b0010; end
            else if(!wdt_rst_n) begin rst_r<=0; rst_cause_r<=4'b0100; end
            else if(sw_rst) begin rst_r<=0; rst_cause_r<=4'b1000; end
            else rst_r<=1;
        end
    end
endmodule
