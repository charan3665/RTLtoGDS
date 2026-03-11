// ============================================================
// sram_sp_4096x64.v - Single-Port SRAM Macro Wrapper
// Depth=4096, Width=64-bit, foundry macro model
// ============================================================
`timescale 1ns/1ps

module sram_sp_4096x64 #(
    parameter DEPTH      = 4096,
    parameter WIDTH      = 64,
    parameter ADDR_BITS  = 12
)(
    input  wire                CK,   // clock
    input  wire                CSN,  // chip select (active low)
    input  wire                WEN,  // write enable (active low)
    input  wire [ADDR_BITS-1:0] A,   // address
    input  wire [WIDTH-1:0]    D,    // data in
    output reg  [WIDTH-1:0]    Q,    // data out
    input  wire [WIDTH-1:0]    BWE   // bit write enable (active high)
);
    // Behavioral model of foundry SRAM
    // Replace with actual Liberty/LEF/GDSII macro for tape-out
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    integer i;

    // Timing parameters (28nm SAED32 approximations)
    specify
        specparam tAA  = 0.35; // address access time
        specparam tWCYC= 0.65; // write cycle time
        (posedge CK) => (Q: D) = (0.35, 0.35);
    endspecify

    always @(posedge CK) begin
        if (!CSN) begin
            if (!WEN) begin
                // Byte-masked write
                for (i = 0; i < WIDTH; i = i + 1)
                    if (BWE[i]) mem[A][i] <= D[i];
            end
            Q <= mem[A];
        end
    end

    // Initialization (for simulation)
    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = {WIDTH{1'b0}};
    end

endmodule
