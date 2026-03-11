`timescale 1ps/1ps
module pll_core(
    input wire refclk, input wire rst_n, input wire test_mode,
    input wire [7:0] fbdiv, input wire [3:0] refdiv, input wire [3:0] postdiv1, input wire [3:0] postdiv2,
    output reg clk_out, output reg locked
);
    real period_ps; integer lock_cnt;
    initial begin period_ps=1000.0; lock_cnt=0; clk_out=0; locked=0; end
    always @(posedge refclk or negedge rst_n) begin
        if(!rst_n) begin locked<=0; lock_cnt<=0; end
        else begin lock_cnt<=lock_cnt+1; if(lock_cnt>100) locked<=1; end
    end
    always begin
        #500 clk_out=~clk_out; // 1 GHz default (500ps half period)
    end
endmodule
