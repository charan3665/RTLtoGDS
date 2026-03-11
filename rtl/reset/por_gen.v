`timescale 1ns/1ps
// por_gen.v - Power-On Reset Generator
module por_gen #(parameter POR_CYCLES=255)(
    input  wire VDD,    // supply (logic 1 when power OK)
    input  wire clk,
    output wire por_n   // active-low POR (deasserted after POR_CYCLES)
);
    reg [$clog2(POR_CYCLES):0] cnt;
    reg por_r;
    always @(posedge clk) begin
        if(!VDD) begin cnt<=0; por_r<=0; end
        else begin if(cnt<POR_CYCLES) cnt<=cnt+1; else por_r<=1; end
    end
    assign por_n=por_r;
endmodule
