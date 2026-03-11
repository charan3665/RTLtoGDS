// ============================================================
// l3_slice.v - L3 Cache Slice (4096 sets, 16-way)
// One of 4 banked slices of L3
// ============================================================
`timescale 1ns/1ps

module l3_slice #(
    parameter PADDR_WIDTH  = 56,
    parameter WAYS         = 16,
    parameter SETS         = 4096,
    parameter LINE_BYTES   = 64,
    parameter LINE_BITS    = 512
)(
    input  wire                     clk,
    input  wire                     rst_n,
    input  wire                     req_valid,
    input  wire [PADDR_WIDTH-1:0]   req_addr,
    input  wire                     req_wr,
    input  wire [LINE_BITS-1:0]     req_wdata,
    output wire                     req_ready,
    output reg                      resp_valid,
    output reg  [LINE_BITS-1:0]     resp_data,
    output reg                      dram_req_valid,
    output reg  [PADDR_WIDTH-1:0]   dram_req_addr,
    output reg                      dram_req_wr,
    output reg  [LINE_BITS-1:0]     dram_req_wdata,
    input  wire                     dram_resp_valid,
    input  wire [LINE_BITS-1:0]     dram_resp_data
);
    localparam INDEX_BITS  = $clog2(SETS);   // 12
    localparam OFFSET_BITS = $clog2(LINE_BYTES); // 6
    localparam TAG_BITS    = PADDR_WIDTH - INDEX_BITS - OFFSET_BITS;

    reg [TAG_BITS-1:0]  tags [0:SETS-1][0:WAYS-1];
    reg                 val  [0:SETS-1][0:WAYS-1];
    reg [LINE_BITS-1:0] data [0:SETS-1][0:WAYS-1];
    reg [WAYS-1:0]      lru  [0:SETS-1];

    wire [INDEX_BITS-1:0]  idx  = req_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
    wire [TAG_BITS-1:0]    tag  = req_addr[PADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];

    integer i, j;
    reg [WAYS-1:0]         hv;
    reg [$clog2(WAYS)-1:0] hw, vic;
    reg                    h;

    always @(*) begin
        h=0; hw=0; hv=0; vic=0;
        for(i=0;i<WAYS;i=i+1) begin
            if(val[idx][i]&&tags[idx][i]==tag) begin h=1;hw=i[$clog2(WAYS)-1:0];hv[i]=1; end
            if(!val[idx][i]) vic=i[$clog2(WAYS)-1:0];
        end
        if(h) vic=hw;
    end

    localparam ST_IDLE=2'd0, ST_DRAM=2'd1, ST_FILL=2'd2;
    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state<=ST_IDLE; resp_valid<=0; dram_req_valid<=0;
            for(i=0;i<SETS;i=i+1) for(j=0;j<WAYS;j=j+1) val[i][j]<=0;
        end else begin
            resp_valid<=0; dram_req_valid<=0;
            case(state)
                ST_IDLE: if(req_valid) begin
                    if(h) begin
                        resp_valid<=1; resp_data<=data[idx][hw];
                        if(req_wr) begin data[idx][hw]<=req_wdata; end
                    end else begin
                        dram_req_valid<=1; dram_req_addr<={req_addr[PADDR_WIDTH-1:OFFSET_BITS],{OFFSET_BITS{1'b0}}};
                        dram_req_wr<=0; state<=ST_DRAM;
                    end
                end
                ST_DRAM: begin
                    dram_req_valid<=1;
                    if(dram_resp_valid) begin
                        data[idx][vic]<=dram_resp_data; tags[idx][vic]<=tag; val[idx][vic]<=1;
                        resp_valid<=1; resp_data<=dram_resp_data;
                        state<=ST_IDLE;
                    end
                end
            endcase
        end
    end
    assign req_ready=(state==ST_IDLE);
endmodule
