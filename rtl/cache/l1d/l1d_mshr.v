// ============================================================
// l1d_mshr.v - Miss Status Holding Register
// Tracks outstanding L1D cache misses, merges same-line requests
// ============================================================
`timescale 1ns/1ps

module l1d_mshr #(
    parameter MSHR_ENTRIES = 8,
    parameter PADDR_WIDTH  = 56,
    parameter XLEN         = 64,
    parameter LINE_BITS    = 512,
    parameter PREG_BITS    = 7,
    parameter ROB_BITS     = 7
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Miss allocation
    input  wire                     alloc_valid,
    input  wire [PADDR_WIDTH-1:0]   alloc_addr,
    input  wire                     alloc_wr,
    input  wire [XLEN-1:0]          alloc_wdata,
    input  wire [7:0]               alloc_strb,
    input  wire [PREG_BITS-1:0]     alloc_prd,
    input  wire [ROB_BITS-1:0]      alloc_rob_tag,
    output wire                     alloc_ready,
    output wire [$clog2(MSHR_ENTRIES)-1:0] alloc_id,

    // Merge check
    input  wire [PADDR_WIDTH-1:0]   merge_addr,
    output wire                     merge_hit,
    output wire [$clog2(MSHR_ENTRIES)-1:0] merge_id,

    // Fill interface
    input  wire                     fill_valid,
    input  wire [$clog2(MSHR_ENTRIES)-1:0] fill_id,
    input  wire [LINE_BITS-1:0]     fill_data,

    // Wakeup output (to LSU/ROB)
    output reg                      wakeup_valid,
    output reg  [PREG_BITS-1:0]     wakeup_prd,
    output reg  [ROB_BITS-1:0]      wakeup_rob_tag,
    output reg  [XLEN-1:0]          wakeup_data,

    // Flush
    input  wire                     flush
);

    reg [MSHR_ENTRIES-1:0]    mshr_valid;
    reg [PADDR_WIDTH-1:0]     mshr_addr   [0:MSHR_ENTRIES-1];
    reg                       mshr_wr     [0:MSHR_ENTRIES-1];
    reg [XLEN-1:0]            mshr_wdata  [0:MSHR_ENTRIES-1];
    reg [7:0]                 mshr_strb   [0:MSHR_ENTRIES-1];
    reg [PREG_BITS-1:0]       mshr_prd    [0:MSHR_ENTRIES-1];
    reg [ROB_BITS-1:0]        mshr_rob    [0:MSHR_ENTRIES-1];
    reg [LINE_BITS-1:0]       mshr_data   [0:MSHR_ENTRIES-1];
    reg [MSHR_ENTRIES-1:0]    mshr_filled;

    integer i;
    reg [$clog2(MSHR_ENTRIES)-1:0] free_entry;
    reg free_found;

    // Find free entry
    always @(*) begin
        free_found = 0; free_entry = {$clog2(MSHR_ENTRIES){1'b0}};
        for (i = 0; i < MSHR_ENTRIES; i = i + 1)
            if (!mshr_valid[i] && !free_found) begin free_entry = i[$clog2(MSHR_ENTRIES)-1:0]; free_found = 1; end
    end

    // Merge detection (same cache line)
    reg [$clog2(MSHR_ENTRIES)-1:0] merge_id_r;
    reg merge_hit_r;
    always @(*) begin
        merge_hit_r = 0; merge_id_r = {$clog2(MSHR_ENTRIES){1'b0}};
        for (i = 0; i < MSHR_ENTRIES; i = i + 1)
            if (mshr_valid[i] && (mshr_addr[i][PADDR_WIDTH-1:6] == merge_addr[PADDR_WIDTH-1:6])) begin
                merge_hit_r = 1; merge_id_r = i[$clog2(MSHR_ENTRIES)-1:0];
            end
    end
    assign merge_hit = merge_hit_r;
    assign merge_id  = merge_id_r;
    assign alloc_ready = free_found;
    assign alloc_id    = free_entry;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            mshr_valid  <= {MSHR_ENTRIES{1'b0}};
            mshr_filled <= {MSHR_ENTRIES{1'b0}};
            wakeup_valid<= 1'b0;
        end else begin
            wakeup_valid <= 1'b0;
            if (alloc_valid && free_found) begin
                mshr_valid[free_entry] <= 1'b1;
                mshr_addr [free_entry] <= alloc_addr;
                mshr_wr   [free_entry] <= alloc_wr;
                mshr_wdata[free_entry] <= alloc_wdata;
                mshr_strb [free_entry] <= alloc_strb;
                mshr_prd  [free_entry] <= alloc_prd;
                mshr_rob  [free_entry] <= alloc_rob_tag;
                mshr_filled[free_entry]<= 1'b0;
            end
            if (fill_valid) begin
                mshr_data[fill_id]   <= fill_data;
                mshr_filled[fill_id] <= 1'b1;
                // Wakeup dependent load
                if (!mshr_wr[fill_id]) begin
                    wakeup_valid   <= 1'b1;
                    wakeup_prd     <= mshr_prd[fill_id];
                    wakeup_rob_tag <= mshr_rob[fill_id];
                    // Extract data
                    wakeup_data    <= fill_data[mshr_addr[fill_id][5:3]*64 +: 64];
                end
                mshr_valid[fill_id] <= 1'b0;
            end
        end
    end

endmodule
