// ============================================================
// dtlb.v - Data TLB (fully-associative, 64 entries)
// Supports read/write permission check, ASID tagging
// ============================================================
`timescale 1ns/1ps

module dtlb #(
    parameter VADDR_WIDTH = 39,
    parameter PADDR_WIDTH = 56,
    parameter ENTRIES     = 64,
    parameter ASID_WIDTH  = 16
)(
    input  wire                     clk,
    input  wire                     rst_n,

    input  wire                     req_valid,
    input  wire [VADDR_WIDTH-1:0]   req_vaddr,
    input  wire [ASID_WIDTH-1:0]    req_asid,
    input  wire                     req_wr,
    output reg                      resp_valid,
    output reg                      resp_miss,
    output reg  [PADDR_WIDTH-1:0]   resp_paddr,
    output reg                      resp_fault,

    input  wire                     fill_valid,
    input  wire [VADDR_WIDTH-1:0]   fill_vaddr,
    input  wire [PADDR_WIDTH-1:0]   fill_paddr,
    input  wire [7:0]               fill_perm,
    input  wire [ASID_WIDTH-1:0]    fill_asid,
    input  wire                     fill_fault,

    input  wire                     sfence_valid,
    input  wire [VADDR_WIDTH-1:0]   sfence_vaddr,
    input  wire [ASID_WIDTH-1:0]    sfence_asid,
    input  wire                     sfence_all
);

    reg [VADDR_WIDTH-13:0]  tag  [0:ENTRIES-1];
    reg [PADDR_WIDTH-13:0]  ppn  [0:ENTRIES-1];
    reg [7:0]               perm [0:ENTRIES-1];
    reg [ASID_WIDTH-1:0]    asid [0:ENTRIES-1];
    reg                     valid[0:ENTRIES-1];
    reg [ENTRIES-1:0]       plru;

    integer i;
    reg [$clog2(ENTRIES)-1:0] hit_idx;
    reg                       hit;

    always @(*) begin
        hit     = 1'b0;
        hit_idx = {$clog2(ENTRIES){1'b0}};
        for (i = 0; i < ENTRIES; i = i + 1) begin
            if (valid[i] && tag[i] == req_vaddr[VADDR_WIDTH-1:12] && asid[i] == req_asid) begin
                hit = 1'b1; hit_idx = i[$clog2(ENTRIES)-1:0];
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i=0;i<ENTRIES;i=i+1) valid[i]<=1'b0;
            resp_valid<=1'b0; plru<={ENTRIES{1'b0}};
        end else begin
            resp_valid<=req_valid;
            if (req_valid) begin
                resp_miss  <= !hit;
                resp_paddr <= hit ? {ppn[hit_idx], req_vaddr[11:0]} : {PADDR_WIDTH{1'b0}};
                resp_fault <= hit ? (req_wr && !perm[hit_idx][2]) : 1'b0;
                if (hit) plru[hit_idx]<=1'b1;
            end
            if (fill_valid) begin
                automatic reg [$clog2(ENTRIES)-1:0] fi = {$clog2(ENTRIES){1'b0}};
                for (i=0;i<ENTRIES;i=i+1) if(!plru[i]) fi=i[$clog2(ENTRIES)-1:0];
                if (!fill_fault) begin
                    tag  [fi]<=fill_vaddr[VADDR_WIDTH-1:12];
                    ppn  [fi]<=fill_paddr[PADDR_WIDTH-1:12];
                    perm [fi]<=fill_perm;
                    asid [fi]<=fill_asid;
                    valid[fi]<=1'b1;
                    plru<={ENTRIES{1'b0}};
                end
            end
            if (sfence_valid) begin
                for (i=0;i<ENTRIES;i=i+1) begin
                    if (sfence_all || asid[i]==sfence_asid ||
                        tag[i]==sfence_vaddr[VADDR_WIDTH-1:12]) valid[i]<=1'b0;
                end
            end
        end
    end
endmodule
