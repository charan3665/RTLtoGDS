`timescale 1ns/1ps
// retention_flop.v - Retention flip-flop with save/restore
// Stores state in low-leakage shadow register during power-down
module retention_flop #(parameter WIDTH=1)(
    input  wire             CK,     // clock
    input  wire             D,      // data input
    output reg              Q,      // data output
    input  wire             RET,    // retention mode (active high: save to shadow)
    input  wire             NRET,   // restore mode (active high: restore from shadow)
    input  wire             SE,     // scan enable
    input  wire             SI,     // scan input
    output wire             SO      // scan output
);
    reg shadow;
    always @(posedge CK) begin
        if (SE) Q <= SI;
        else if (NRET) Q <= shadow;
        else Q <= D;
    end
    always @(posedge RET) shadow <= Q; // save on retention entry
    assign SO = Q;
endmodule
