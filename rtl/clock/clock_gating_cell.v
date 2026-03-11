`timescale 1ns/1ps
// clock_gating_cell.v - ICG (Integrated Clock Gating) Cell
// Latch-based glitch-free clock gate
module clock_gating_cell (
    input  wire CK,    // clock input
    input  wire EN,    // enable (from register)
    input  wire TE,    // test enable (scan)
    output wire Q      // gated clock output
);
    reg latch_q;
    // Negative-edge latch (transparent when CK=0)
    always @(CK or EN or TE) begin
        if (!CK) latch_q <= EN | TE;
    end
    assign Q = CK & latch_q;
endmodule
