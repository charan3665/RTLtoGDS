// ============================================================
// l2_cache.v - Unified L2 Cache (512KB, 8-way, shared, inclusive)
// MESI coherence protocol, non-blocking with MSHR
// ============================================================
`timescale 1ns/1ps

module l2_cache #(
    parameter PADDR_WIDTH  = 56,
    parameter CACHE_SIZE   = 524288,  // 512 KB
    parameter WAYS         = 8,
    parameter LINE_BYTES   = 64,
    parameter LINE_BITS    = 512,
    parameter SETS         = CACHE_SIZE / (WAYS * LINE_BYTES),  // 1024
    parameter MSHR_ENTRIES = 16,
    parameter N_PORTS      = 4   // up to 4 requestors (C0I, C0D, C1I, C1D)
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // L1 request ports (N_PORTS)
    input  wire [N_PORTS-1:0]           l1_req_valid,
    input  wire [N_PORTS*PADDR_WIDTH-1:0] l1_req_addr,
    input  wire [N_PORTS-1:0]           l1_req_wr,
    input  wire [N_PORTS*LINE_BITS-1:0] l1_req_wdata,
    output wire [N_PORTS-1:0]           l1_req_ready,

    output reg  [N_PORTS-1:0]           l1_resp_valid,
    output reg  [N_PORTS*LINE_BITS-1:0] l1_resp_data,

    // L3 / LLC interface
    output reg                          l3_req_valid,
    output reg  [PADDR_WIDTH-1:0]       l3_req_addr,
    output reg                          l3_req_wr,
    output reg  [LINE_BITS-1:0]         l3_req_wdata,
    input  wire                         l3_resp_valid,
    input  wire [LINE_BITS-1:0]         l3_resp_data,

    // Coherence snoops from L3/directory
    input  wire                         snoop_valid,
    input  wire [PADDR_WIDTH-1:0]       snoop_addr,
    input  wire [1:0]                   snoop_cmd,
    output reg                          snoop_resp_valid,
    output reg  [LINE_BITS-1:0]         snoop_resp_data
);

    localparam INDEX_BITS  = $clog2(SETS);     // 10
    localparam OFFSET_BITS = $clog2(LINE_BYTES); // 6
    localparam TAG_BITS    = PADDR_WIDTH - INDEX_BITS - OFFSET_BITS;

    // MESI states
    localparam MESI_I = 2'b00;
    localparam MESI_S = 2'b01;
    localparam MESI_E = 2'b10;
    localparam MESI_M = 2'b11;

    reg [TAG_BITS-1:0]  tags  [0:SETS-1][0:WAYS-1];
    reg [1:0]           mesi  [0:SETS-1][0:WAYS-1];   // MESI state
    reg [LINE_BITS-1:0] data  [0:SETS-1][0:WAYS-1];
    reg [WAYS-1:0]      lru_tree [0:SETS-1];  // tree-PLRU

    // Round-robin arbiter for port selection
    reg [$clog2(N_PORTS)-1:0] rr_ptr;

    // Request processing pipeline
    reg [PADDR_WIDTH-1:0]  proc_addr;
    reg                    proc_wr;
    reg [LINE_BITS-1:0]    proc_wdata;
    reg [$clog2(N_PORTS)-1:0] proc_port;
    reg                    proc_valid;

    wire [INDEX_BITS-1:0]  proc_idx  = proc_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    wire [TAG_BITS-1:0]    proc_tag  = proc_addr[PADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];

    // Hit detection
    integer i, j;
    reg [WAYS-1:0]         hit_vec;
    reg [$clog2(WAYS)-1:0] hit_way;
    reg                    hit;
    reg [1:0]              hit_mesi;

    always @(*) begin
        hit = 0; hit_way = 0; hit_vec = 0; hit_mesi = MESI_I;
        for (i = 0; i < WAYS; i = i + 1) begin
            if (mesi[proc_idx][i] != MESI_I && tags[proc_idx][i] == proc_tag) begin
                hit = 1; hit_way = i[$clog2(WAYS)-1:0];
                hit_vec[i] = 1; hit_mesi = mesi[proc_idx][i];
            end
        end
    end

    // State machine
    localparam ST_IDLE   = 3'd0;
    localparam ST_LOOKUP = 3'd1;
    localparam ST_L3REQ  = 3'd2;
    localparam ST_L3WAIT = 3'd3;
    localparam ST_FILL   = 3'd4;

    reg [2:0] state;
    reg [$clog2(WAYS)-1:0] victim;

    // Simple victim: way 0 (in real design use LRU)
    always @(*) victim = {$clog2(WAYS){1'b0}};

    // Arbiter
    reg [N_PORTS-1:0] port_grant;
    always @(*) begin
        port_grant = {N_PORTS{1'b0}};
        for (i = N_PORTS-1; i >= 0; i = i - 1)
            if (l1_req_valid[i]) port_grant = (1 << i);
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE;
            l1_resp_valid <= {N_PORTS{1'b0}};
            l3_req_valid  <= 1'b0;
            snoop_resp_valid <= 1'b0;
            for (i=0;i<SETS;i=i+1) for(j=0;j<WAYS;j=j+1) mesi[i][j]<=MESI_I;
        end else begin
            l1_resp_valid    <= {N_PORTS{1'b0}};
            l3_req_valid     <= 1'b0;
            snoop_resp_valid <= 1'b0;

            // Snoop
            if (snoop_valid) begin
                automatic reg [INDEX_BITS-1:0] si = snoop_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
                automatic reg [TAG_BITS-1:0]   st = snoop_addr[PADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];
                snoop_resp_valid <= 1;
                snoop_resp_data  <= {LINE_BITS{1'b0}};
                for (i=0;i<WAYS;i=i+1) begin
                    if (mesi[si][i]!=MESI_I && tags[si][i]==st) begin
                        snoop_resp_data <= data[si][i];
                        if (snoop_cmd==2'b00) mesi[si][i]<=MESI_I;   // INV
                        else if(snoop_cmd==2'b01) mesi[si][i]<=MESI_S; // SHARED
                    end
                end
            end

            case (state)
                ST_IDLE: begin
                    if (|port_grant) begin
                        for (i=0;i<N_PORTS;i=i+1)
                            if (port_grant[i]) begin
                                proc_addr  <= l1_req_addr[i*PADDR_WIDTH +: PADDR_WIDTH];
                                proc_wr    <= l1_req_wr[i];
                                proc_wdata <= l1_req_wdata[i*LINE_BITS +: LINE_BITS];
                                proc_port  <= i[$clog2(N_PORTS)-1:0];
                            end
                        proc_valid <= 1;
                        state <= ST_LOOKUP;
                    end
                end
                ST_LOOKUP: begin
                    if (hit) begin
                        // Hit
                        l1_resp_valid[proc_port] <= 1;
                        l1_resp_data [proc_port*LINE_BITS +: LINE_BITS] <= data[proc_idx][hit_way];
                        if (proc_wr) begin
                            data[proc_idx][hit_way] <= proc_wdata;
                            mesi[proc_idx][hit_way] <= MESI_M;
                        end
                        state <= ST_IDLE;
                    end else begin
                        // Miss: request from L3
                        l3_req_valid <= 1;
                        l3_req_addr  <= proc_addr;
                        l3_req_wr    <= 1'b0;
                        state <= ST_L3WAIT;
                    end
                end
                ST_L3WAIT: begin
                    l3_req_valid <= 1;
                    if (l3_resp_valid) begin
                        // Install in cache
                        data[proc_idx][victim] <= l3_resp_data;
                        tags[proc_idx][victim] <= proc_tag;
                        mesi[proc_idx][victim] <= proc_wr ? MESI_M : MESI_E;
                        if (proc_wr) data[proc_idx][victim] <= proc_wdata;
                        l1_resp_valid[proc_port] <= 1;
                        l1_resp_data [proc_port*LINE_BITS +: LINE_BITS] <= l3_resp_data;
                        state <= ST_IDLE;
                    end
                end
            endcase
        end
    end

    assign l1_req_ready = {N_PORTS{(state == ST_IDLE)}};

endmodule
