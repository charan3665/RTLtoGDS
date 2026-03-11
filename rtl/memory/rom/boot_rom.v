// ============================================================
// boot_rom.v - Boot ROM (4KB, 32-bit words, 1024 entries)
// Contains minimal RISC-V boot code
// ============================================================
`timescale 1ns/1ps

module boot_rom #(
    parameter DEPTH     = 1024,  // 4KB / 4 bytes per word
    parameter WIDTH     = 32,
    parameter ADDR_BITS = 10,
    parameter BASE_ADDR = 64'h0000_0000_0001_0000
)(
    input  wire                     clk,
    input  wire                     cs_n,
    input  wire [ADDR_BITS-1:0]     addr,
    output reg  [WIDTH-1:0]         dout,
    output reg                      valid
);
    reg [WIDTH-1:0] rom [0:DEPTH-1];
    integer i;

    // Minimal RV64 boot code (jump to DRAM base + init sequence)
    initial begin
        // auipc x1, 0          // x1 = PC
        rom[0]  = 32'h00000097; // auipc x1, 0
        rom[1]  = 32'h00C08093; // addi x1, x1, 12  (skip header)
        // li x2, 0x80000000    // DRAM base
        rom[2]  = 32'h80000137; // lui x2, 0x80000
        rom[3]  = 32'h00010067; // jalr x0, 0(x2)   // jump to DRAM
        // Fill rest with NOPs
        for (i = 4; i < DEPTH; i = i + 1)
            rom[i] = 32'h00000013; // nop (addi x0, x0, 0)
    end

    always @(posedge clk) begin
        if (!cs_n) begin
            dout  <= rom[addr];
            valid <= 1'b1;
        end else begin
            valid <= 1'b0;
        end
    end

endmodule
