// ============================================================
// coherence_unit.v - MESI Coherence Protocol Engine
// Manages coherence transactions between L1/L2/L3 caches
// ============================================================
`timescale 1ns/1ps

module coherence_unit #(
    parameter PADDR_WIDTH = 56,
    parameter LINE_BITS   = 512,
    parameter N_AGENTS    = 4
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Snoop request from directory
    input  wire [N_AGENTS-1:0]      snoop_req_valid,
    input  wire [N_AGENTS*PADDR_WIDTH-1:0] snoop_req_addr,
    input  wire [N_AGENTS*2-1:0]    snoop_req_cmd,  // 00=INV, 01=FETCH_INV, 10=FETCH_SHARED
    output reg  [N_AGENTS-1:0]      snoop_resp_valid,
    output reg  [N_AGENTS*LINE_BITS-1:0] snoop_resp_data,
    output reg  [N_AGENTS-1:0]      snoop_resp_hit,

    // Cache read/write interface (to data array)
    output reg  [N_AGENTS-1:0]          cache_acc_valid,
    output reg  [N_AGENTS*PADDR_WIDTH-1:0] cache_acc_addr,
    output reg  [N_AGENTS*2-1:0]        cache_acc_cmd,
    input  wire [N_AGENTS-1:0]          cache_acc_hit,
    input  wire [N_AGENTS*LINE_BITS-1:0] cache_acc_data,

    // Directory update
    output reg  [PADDR_WIDTH-1:0]   dir_upd_addr,
    output reg  [N_AGENTS-1:0]      dir_upd_inv_mask,
    output reg                      dir_upd_valid,
    input  wire                     dir_upd_ready
);

    genvar g;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            snoop_resp_valid <= {N_AGENTS{1'b0}};
            cache_acc_valid  <= {N_AGENTS{1'b0}};
            dir_upd_valid    <= 1'b0;
        end else begin
            snoop_resp_valid <= {N_AGENTS{1'b0}};
            cache_acc_valid  <= {N_AGENTS{1'b0}};
            dir_upd_valid    <= 1'b0;

            for (i = 0; i < N_AGENTS; i = i + 1) begin
                if (snoop_req_valid[i]) begin
                    // Forward snoop to cache
                    cache_acc_valid[i] <= 1'b1;
                    cache_acc_addr[i*PADDR_WIDTH +: PADDR_WIDTH] <= snoop_req_addr[i*PADDR_WIDTH +: PADDR_WIDTH];
                    cache_acc_cmd [i*2 +: 2] <= snoop_req_cmd[i*2 +: 2];
                    snoop_resp_valid[i] <= 1'b1;
                    snoop_resp_hit[i]   <= cache_acc_hit[i];
                    snoop_resp_data[i*LINE_BITS +: LINE_BITS] <= cache_acc_data[i*LINE_BITS +: LINE_BITS];
                end
            end
        end
    end

endmodule
