`timescale 1ns/1ps
// isolation_cell.v - Level-up isolation cell (clamps output when power domain off)
module isolation_cell #(parameter CLAMP_VAL=1'b0)(
    input  wire         A,      // input from powered-down domain
    input  wire         ISO_EN, // isolation enable (1 = domain off, clamp output)
    output wire         Z       // output to always-on domain
);
    assign Z = ISO_EN ? CLAMP_VAL : A;
endmodule
