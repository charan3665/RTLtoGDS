// ============================================================
// physical_regfile.v - Physical Register File
// 128 entries x 64-bit, 10 read ports, 6 write ports
// ============================================================
`timescale 1ns/1ps

module physical_regfile #(
    parameter XLEN       = 64,
    parameter PHYS_REGS  = 128,
    parameter PREG_BITS  = 7,
    parameter RD_PORTS   = 10,
    parameter WR_PORTS   = 6
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Read ports
    input  wire [RD_PORTS*PREG_BITS-1:0] rd_addr,
    output wire [RD_PORTS*XLEN-1:0]     rd_data,

    // Write ports
    input  wire [WR_PORTS-1:0]           wr_en,
    input  wire [WR_PORTS*PREG_BITS-1:0] wr_addr,
    input  wire [WR_PORTS*XLEN-1:0]      wr_data,

    // Busy bit read (for issue queue wakeup)
    input  wire [PREG_BITS-1:0]         busy_rd_addr,
    output wire                          busy_rd_data
);

    // Register file array (implemented as flip-flops for simulation)
    reg [XLEN-1:0]  regfile [0:PHYS_REGS-1];
    reg             busy    [0:PHYS_REGS-1];

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < PHYS_REGS; i = i + 1) begin
                regfile[i] <= {XLEN{1'b0}};
                busy[i]    <= 1'b0;
            end
        end else begin
            for (i = 0; i < WR_PORTS; i = i + 1) begin
                if (wr_en[i]) begin
                    regfile[wr_addr[i*PREG_BITS +: PREG_BITS]] <= wr_data[i*XLEN +: XLEN];
                    busy   [wr_addr[i*PREG_BITS +: PREG_BITS]] <= 1'b0; // clear busy on write
                end
            end
        end
    end

    // Asynchronous reads
    genvar g;
    generate
        for (g = 0; g < RD_PORTS; g = g + 1) begin : gen_rd
            assign rd_data[g*XLEN +: XLEN] = regfile[rd_addr[g*PREG_BITS +: PREG_BITS]];
        end
    endgenerate

    assign busy_rd_data = busy[busy_rd_addr];

endmodule
