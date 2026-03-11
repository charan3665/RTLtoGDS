// ============================================================
// snoop_filter.v - Duplicate Tag Snoop Filter
// Reduces unnecessary snoops by tracking L1 tags at L2/L3 level
// ============================================================
`timescale 1ns/1ps

module snoop_filter #(
    parameter PADDR_WIDTH = 56,
    parameter N_L1        = 4,
    parameter SETS        = 1024,
    parameter WAYS        = 4
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // L1 cache lookup notification (for filter update)
    input  wire [N_L1-1:0]          l1_notify_valid,
    input  wire [N_L1*PADDR_WIDTH-1:0] l1_notify_addr,
    input  wire [N_L1-1:0]          l1_notify_install, // 1=install, 0=evict

    // Snoop filter query: which L1s hold this addr?
    input  wire                     sf_query_valid,
    input  wire [PADDR_WIDTH-1:0]   sf_query_addr,
    output reg                      sf_query_resp_valid,
    output reg  [N_L1-1:0]          sf_query_holders,  // bitmask of L1s with this line

    // Invalidation control
    input  wire                     sf_inv_valid,
    input  wire [PADDR_WIDTH-1:0]   sf_inv_addr
);

    localparam INDEX_BITS = $clog2(SETS);
    localparam OFFSET_BITS= 6;
    localparam TAG_BITS   = PADDR_WIDTH - INDEX_BITS - OFFSET_BITS;

    reg [TAG_BITS-1:0]  sf_tag    [0:SETS-1][0:WAYS-1];
    reg [N_L1-1:0]      sf_pres   [0:SETS-1][0:WAYS-1];  // presence bits
    reg                 sf_valid  [0:SETS-1][0:WAYS-1];
    reg [WAYS-1:0]      sf_plru   [0:SETS-1];

    integer i, j;
    reg [$clog2(WAYS)-1:0] qway;
    reg qhit;

    // Query lookup
    wire [INDEX_BITS-1:0] q_idx = sf_query_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    wire [TAG_BITS-1:0]   q_tag = sf_query_addr[PADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sf_query_resp_valid <= 1'b0;
            for (i=0;i<SETS;i=i+1) for(j=0;j<WAYS;j=j+1) sf_valid[i][j]<=1'b0;
        end else begin
            sf_query_resp_valid <= 1'b0;

            // Query
            if (sf_query_valid) begin
                sf_query_resp_valid <= 1'b1;
                sf_query_holders    <= {N_L1{1'b0}};
                for (j=0;j<WAYS;j=j+1)
                    if (sf_valid[q_idx][j] && sf_tag[q_idx][j]==q_tag)
                        sf_query_holders <= sf_pres[q_idx][j];
            end

            // Update on L1 install/evict
            for (i = 0; i < N_L1; i = i + 1) begin
                if (l1_notify_valid[i]) begin
                    automatic reg [INDEX_BITS-1:0] n_idx = l1_notify_addr[i*PADDR_WIDTH+OFFSET_BITS +: INDEX_BITS];
                    automatic reg [TAG_BITS-1:0]   n_tag = l1_notify_addr[i*PADDR_WIDTH+OFFSET_BITS+INDEX_BITS +: TAG_BITS];
                    automatic reg found = 0;
                    automatic reg [$clog2(WAYS)-1:0] free_w = 0;
                    for (j=0;j<WAYS;j=j+1) begin
                        if (!found) begin
                            if (sf_valid[n_idx][j] && sf_tag[n_idx][j]==n_tag) begin
                                if (l1_notify_install[i])
                                    sf_pres[n_idx][j] <= sf_pres[n_idx][j] | (1 << i);
                                else
                                    sf_pres[n_idx][j] <= sf_pres[n_idx][j] & ~(1 << i);
                                if (sf_pres[n_idx][j] == {N_L1{1'b0}})
                                    sf_valid[n_idx][j] <= 1'b0;
                                found = 1;
                            end
                            if (!sf_valid[n_idx][j]) free_w = j[$clog2(WAYS)-1:0];
                        end
                    end
                    if (!found && l1_notify_install[i]) begin
                        sf_tag  [n_idx][free_w] <= n_tag;
                        sf_pres [n_idx][free_w] <= (1 << i);
                        sf_valid[n_idx][free_w] <= 1'b1;
                    end
                end
            end

            // Invalidate
            if (sf_inv_valid) begin
                automatic reg [INDEX_BITS-1:0] inv_idx = sf_inv_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
                automatic reg [TAG_BITS-1:0]   inv_tag = sf_inv_addr[PADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];
                for (j=0;j<WAYS;j=j+1)
                    if (sf_valid[inv_idx][j] && sf_tag[inv_idx][j]==inv_tag)
                        sf_valid[inv_idx][j]<=1'b0;
            end
        end
    end

endmodule
