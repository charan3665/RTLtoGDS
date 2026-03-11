`timescale 1ns/1ps
module gpio_pad (
    input wire OEN, input wire I, output wire O, inout wire PAD,
    input wire PUE, input wire PDE  // pull-up/down enables
);
    assign PAD = OEN ? I : 1'bz;
    assign O   = PAD;
    // Internal pull (model only)
    assign PAD = PUE ? 1'bz : (PDE ? 1'b0 : 1'bz);
endmodule
