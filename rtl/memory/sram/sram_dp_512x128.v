// ============================================================
// sram_dp_512x128.v - Dual-Port SRAM Macro Wrapper (1R1W)
// Depth=512, Width=128-bit
// ============================================================
`timescale 1ns/1ps

module sram_dp_512x128 #(
    parameter DEPTH     = 512,
    parameter WIDTH     = 128,
    parameter ADDR_BITS = 9
)(
    // Write port
    input  wire                WCLK,
    input  wire                WCSN,
    input  wire                WWEN,
    input  wire [ADDR_BITS-1:0] WADDR,
    input  wire [WIDTH-1:0]    WD,
    input  wire [WIDTH-1:0]    WBWE,
    // Read port
    input  wire                RCLK,
    input  wire                RCSN,
    input  wire [ADDR_BITS-1:0] RADDR,
    output reg  [WIDTH-1:0]    RQ
);
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    integer i;

    specify
        specparam tRCYC = 0.55;
        specparam tWCYC = 0.65;
    endspecify

    always @(posedge WCLK) begin
        if (!WCSN && !WWEN) begin
            for (i = 0; i < WIDTH; i = i + 1)
                if (WBWE[i]) mem[WADDR][i] <= WD[i];
        end
    end
    always @(posedge RCLK) begin
        if (!RCSN) RQ <= mem[RADDR];
    end

    initial for (i=0;i<DEPTH;i=i+1) mem[i]={WIDTH{1'b0}};
endmodule
