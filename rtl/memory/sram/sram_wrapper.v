// ============================================================
// sram_wrapper.v - Parameterizable SRAM Wrapper
// Selects appropriate SRAM macro based on parameters
// ============================================================
`timescale 1ns/1ps

module sram_wrapper #(
    parameter DEPTH      = 256,
    parameter WIDTH      = 64,
    parameter DUAL_PORT  = 0,
    parameter MEM_TYPE   = "SP"  // SP or DP
)(
    input  wire                     clk,
    input  wire                     clk_b,   // only for DP
    input  wire                     cs_n,
    input  wire                     we_n,
    input  wire [$clog2(DEPTH)-1:0] addr,
    input  wire [$clog2(DEPTH)-1:0] addr_b,  // only for DP
    input  wire [WIDTH-1:0]         din,
    input  wire [WIDTH-1:0]         bwe,
    output wire [WIDTH-1:0]         dout,
    output wire [WIDTH-1:0]         dout_b   // only for DP
);
    // Behavioral model; replaced by macro in implementation
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    integer i;
    reg [WIDTH-1:0] dout_r, dout_b_r;

    always @(posedge clk) begin
        if (!cs_n && !we_n)
            for (i=0;i<WIDTH;i=i+1) if(bwe[i]) mem[addr][i]<=din[i];
        dout_r <= mem[addr];
    end
    always @(posedge clk_b) begin
        dout_b_r <= mem[addr_b];
    end

    assign dout   = dout_r;
    assign dout_b = dout_b_r;

    initial for(i=0;i<DEPTH;i=i+1) mem[i]={WIDTH{1'b0}};
endmodule
