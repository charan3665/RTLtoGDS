// ============================================================
// config_rom.v - Configuration ROM (device tree blob, 2KB)
// Stores SoC configuration: memory map, clock frequencies, etc.
// ============================================================
`timescale 1ns/1ps

module config_rom #(
    parameter DEPTH     = 512,
    parameter WIDTH     = 32,
    parameter ADDR_BITS = 9
)(
    input  wire                     clk,
    input  wire                     cs_n,
    input  wire [ADDR_BITS-1:0]     addr,
    output reg  [WIDTH-1:0]         dout,
    output reg                      valid
);
    reg [WIDTH-1:0] rom [0:DEPTH-1];
    integer i;

    // Device tree blob (FDT) stub entries
    initial begin
        // Magic, totalsize, off_dt_struct, off_dt_strings, etc.
        rom[0] = 32'hD00DFEED; // FDT magic
        rom[1] = 32'h00000800; // totalsize = 2KB
        rom[2] = 32'h00000038; // off_dt_struct
        rom[3] = 32'h00000600; // off_dt_strings
        rom[4] = 32'h00000028; // off_mem_rsvmap
        rom[5] = 32'h00000011; // FDT version = 17
        rom[6] = 32'h00000010; // last_comp_version = 16
        rom[7] = 32'h00000000; // boot_cpuid_phys = 0
        // Memory map entries
        rom[8]  = 32'h80000000; // DRAM base (high)
        rom[9]  = 32'h00000000; // DRAM base (low)
        rom[10] = 32'h00000000; // DRAM size (high)
        rom[11] = 32'h40000000; // DRAM size (low) = 1GB
        for (i = 12; i < DEPTH; i = i + 1) rom[i] = 32'h0;
    end

    always @(posedge clk) begin
        if (!cs_n) begin dout <= rom[addr]; valid <= 1'b1; end
        else valid <= 1'b0;
    end

endmodule
