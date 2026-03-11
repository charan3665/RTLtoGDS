// ============================================================
// regfile_2r1w_32x64.v - 2R1W Register File (32x64)
// ============================================================
`timescale 1ns/1ps

module regfile_2r1w_32x64 #(
    parameter DEPTH     = 32,
    parameter WIDTH     = 64,
    parameter NRP       = 2,  // read ports
    parameter NWP       = 1   // write ports
)(
    input  wire                     clk,
    input  wire                     rst_n,
    // Read ports
    input  wire [NRP*$clog2(DEPTH)-1:0] rd_addr,
    output wire [NRP*WIDTH-1:0]     rd_data,
    // Write ports
    input  wire [NWP-1:0]           wr_en,
    input  wire [NWP*$clog2(DEPTH)-1:0] wr_addr,
    input  wire [NWP*WIDTH-1:0]     wr_data
);
    localparam ADDR_BITS = $clog2(DEPTH);

    reg [WIDTH-1:0] mem [0:31];
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) for(i=0;i<32;i=i+1) mem[i]<={64{1'b0}};
        else for(i=0;i<NWP;i=i+1)
            if(wr_en[i]) mem[wr_addr[i*ADDR_BITS+:ADDR_BITS]]<=wr_data[i*WIDTH+:WIDTH];
    end
    genvar g;
    generate for(g=0;g<NRP;g=g+1) begin : gen_rp
        assign rd_data[g*WIDTH+:WIDTH] = mem[rd_addr[g*ADDR_BITS+:ADDR_BITS]];
    end endgenerate
endmodule
