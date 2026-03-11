// ============================================================
// itlb.v - Instruction TLB (fully-associative, 32 entries)
// Pseudo-LRU replacement, ASID-tagged
// ============================================================
`timescale 1ns/1ps

module itlb #(
    parameter VADDR_WIDTH = 39,
    parameter PADDR_WIDTH = 56,
    parameter ENTRIES     = 32,
    parameter ASID_WIDTH  = 16
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Lookup interface
    input  wire                     req_valid,
    input  wire [VADDR_WIDTH-1:0]   req_vaddr,
    input  wire [ASID_WIDTH-1:0]    req_asid,
    output reg                      resp_valid,
    output reg                      resp_miss,
    output reg  [PADDR_WIDTH-1:0]   resp_paddr,
    output reg  [7:0]               resp_perm,

    // Fill from MMU
    input  wire                     fill_valid,
    input  wire [VADDR_WIDTH-1:0]   fill_vaddr,
    input  wire [PADDR_WIDTH-1:0]   fill_paddr,
    input  wire [7:0]               fill_perm,
    input  wire [ASID_WIDTH-1:0]    fill_asid,
    input  wire                     fill_fault,

    // SFENCE.VMA
    input  wire                     sfence_valid,
    input  wire [VADDR_WIDTH-1:0]   sfence_vaddr,
    input  wire [ASID_WIDTH-1:0]    sfence_asid,
    input  wire                     sfence_all
);

    reg [VADDR_WIDTH-13:0]  tag    [0:ENTRIES-1];  // VPN
    reg [PADDR_WIDTH-13:0]  ppn    [0:ENTRIES-1];
    reg [7:0]               perm   [0:ENTRIES-1];
    reg [ASID_WIDTH-1:0]    asid   [0:ENTRIES-1];
    reg                     valid  [0:ENTRIES-1];
    reg                     global_bit [0:ENTRIES-1];

    // PLRU bits
    reg [ENTRIES-1:0]       plru;

    integer i;
    reg [$clog2(ENTRIES)-1:0] hit_idx, fill_idx;
    reg                       hit;

    always @(*) begin
        hit     = 1'b0;
        hit_idx = {$clog2(ENTRIES){1'b0}};
        for (i = 0; i < ENTRIES; i = i + 1) begin
            if (valid[i] && (tag[i] == req_vaddr[VADDR_WIDTH-1:12]) &&
                (asid[i] == req_asid || global_bit[i])) begin
                hit     = 1'b1;
                hit_idx = i[$clog2(ENTRIES)-1:0];
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < ENTRIES; i = i + 1) valid[i] <= 1'b0;
            plru <= {ENTRIES{1'b0}};
            resp_valid <= 1'b0;
        end else begin
            resp_valid <= req_valid;
            if (req_valid) begin
                resp_miss  <= !hit;
                resp_paddr <= hit ? {ppn[hit_idx], req_vaddr[11:0]} : {PADDR_WIDTH{1'b0}};
                resp_perm  <= hit ? perm[hit_idx] : 8'b0;
                if (hit) plru[hit_idx] <= 1'b1; // update LRU
            end

            // Fill on MMU response
            if (fill_valid && !fill_fault) begin
                // Find LRU entry (first 0 in plru, or 0 if all 1s)
                fill_idx = {$clog2(ENTRIES){1'b0}};
                for (i = 0; i < ENTRIES; i = i + 1)
                    if (!plru[i] && fill_idx == 0) fill_idx = i[$clog2(ENTRIES)-1:0];
                tag  [fill_idx] <= fill_vaddr[VADDR_WIDTH-1:12];
                ppn  [fill_idx] <= fill_paddr[PADDR_WIDTH-1:12];
                perm [fill_idx] <= fill_perm;
                asid [fill_idx] <= fill_asid;
                valid[fill_idx] <= 1'b1;
                global_bit[fill_idx] <= fill_perm[5]; // G bit
                plru <= {ENTRIES{1'b0}}; // reset PLRU on fill
            end

            // SFENCE.VMA invalidation
            if (sfence_valid) begin
                for (i = 0; i < ENTRIES; i = i + 1) begin
                    if (sfence_all || (!global_bit[i] && (asid[i] == sfence_asid ||
                        (tag[i] == sfence_vaddr[VADDR_WIDTH-1:12]))))
                        valid[i] <= 1'b0;
                end
            end
        end
    end

endmodule
