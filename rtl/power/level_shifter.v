`timescale 1ns/1ps
// level_shifter.v - Multi-supply level shifter (0.7V <-> 0.85V)
module level_shifter (
    input  wire A,    // input at VDDA domain
    input  wire VDDA, // lower supply (e.g. 0.75V)
    input  wire VDDB, // higher supply (e.g. 0.85V)
    output wire Z     // output at VDDB domain
);
    // Behavioral model: level shift (same logic value, different voltage level)
    assign Z = A;  // In real design: CMOS level shifter circuit
endmodule
