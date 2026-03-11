`timescale 1ns/1ps
module uart_rx #(parameter CLK_DIV=868)(
    input wire clk, input wire rst_n,
    input wire rxd, output reg valid, output reg [7:0] data
);
    reg [9:0] div_cnt; reg [3:0] bit_cnt; reg [9:0] shift; reg active;
    reg rxd_r, rxd_rr;
    always @(posedge clk) begin rxd_r<=rxd; rxd_rr<=rxd_r; end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin valid<=0; active<=0; div_cnt<=0; bit_cnt<=0; end
        else begin
            valid<=0;
            if(!active&&!rxd_rr) begin active<=1; div_cnt<=CLK_DIV/2; bit_cnt<=9; end
            if(active) begin
                div_cnt<=div_cnt+1;
                if(div_cnt==CLK_DIV-1) begin div_cnt<=0; shift<={rxd_rr,shift[9:1]}; bit_cnt<=bit_cnt-1;
                    if(bit_cnt==0) begin data<=shift[8:1]; valid<=1; active<=0; end
                end
            end
        end
    end
endmodule
