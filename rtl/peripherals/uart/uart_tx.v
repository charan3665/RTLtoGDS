`timescale 1ns/1ps
module uart_tx #(parameter CLK_DIV=868)(
    input wire clk, input wire rst_n,
    input wire [7:0] data, input wire wr,
    output reg txd, output reg empty
);
    reg [9:0] shift; reg [9:0] div_cnt; reg [3:0] bit_cnt; reg active;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin txd<=1; empty<=1; active<=0; div_cnt<=0; bit_cnt<=0; end
        else begin
            if(wr&&!active) begin shift<={1'b1,data,1'b0}; active<=1; empty<=0; bit_cnt<=10; end
            if(active) begin
                div_cnt<=div_cnt+1;
                if(div_cnt==CLK_DIV-1) begin div_cnt<=0; txd<=shift[0]; shift<={1'b1,shift[9:1]}; bit_cnt<=bit_cnt-1; if(bit_cnt==1) begin active<=0; empty<=1; end end
            end
        end
    end
endmodule
