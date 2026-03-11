`timescale 1ns/1ps
module clock_divider #(parameter DIV=2)(
    input wire clk_in, input wire rst_n,
    output reg clk_out
);
    generate
        if (DIV == 1) begin : gen_passthru
            assign clk_out = clk_in;
        end else begin : gen_div
            reg [$clog2(DIV)-1:0] cnt;
            always @(posedge clk_in or negedge rst_n) begin
                if(!rst_n) begin cnt<=0; clk_out<=0; end
                else begin cnt<=cnt+1; if(cnt==DIV/2-1) begin clk_out<=~clk_out; cnt<=0; end end
            end
        end
    endgenerate
endmodule
