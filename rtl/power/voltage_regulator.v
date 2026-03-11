`timescale 1ns/1ps
// voltage_regulator.v - On-chip LDO/DCDC behavioral model
module voltage_regulator #(
    parameter VOUT_MV_DEFAULT = 850
)(
    input  wire         clk, input wire rst_n,
    input  wire [9:0]   vout_set,  // target voltage in mV (0-1023)
    output wire [9:0]   vout_mon,  // measured voltage in mV
    input  wire         en,
    output wire         pg         // power good
);
    reg [9:0] vout_reg; integer ramp_cnt;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin vout_reg<=0; ramp_cnt<=0; end
        else if(en) begin if(vout_reg<vout_set) vout_reg<=vout_reg+1; end
        else vout_reg<=0;
    end
    assign vout_mon = vout_reg;
    assign pg = (vout_reg >= vout_set - 10) && en;
endmodule
