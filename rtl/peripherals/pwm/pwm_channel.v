`timescale 1ns/1ps
module pwm_channel(
    input wire clk, input wire rst_n,
    input wire [15:0] period, input wire [15:0] duty, input wire en,
    output reg pwm_out
);
    reg [15:0] cnt;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin cnt<=0; pwm_out<=0; end
        else if(en) begin
            cnt<=(cnt>=period-1)?0:cnt+1;
            pwm_out<=(cnt<duty);
        end
    end
endmodule
