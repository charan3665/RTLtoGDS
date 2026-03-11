`timescale 1ns/1ps
module pwm_top #(parameter N_CH=8)(
    input wire clk, input wire rst_n,
    input wire psel, input wire pena, input wire pwrite, input wire [7:0] paddr, input wire [31:0] pwdata,
    output reg [31:0] prdata, output wire pready,
    output wire [N_CH-1:0] pwm_out
);
    wire [N_CH-1:0] ch_out;
    genvar g;
    generate for(g=0;g<N_CH;g=g+1) begin : gen_pwm
        pwm_channel u(.clk(clk),.rst_n(rst_n),.period(16'd1000),.duty(16'd500),.en(1'b1),.pwm_out(ch_out[g]));
    end endgenerate
    assign pwm_out=ch_out; assign pready=1;
    always @(posedge clk) if(psel&&pena&&!pwrite) prdata<={24'b0,ch_out};
endmodule
