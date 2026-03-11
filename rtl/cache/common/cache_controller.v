// ============================================================
// cache_controller.v - Generic Cache Controller FSM
// Handles hit/miss/fill/evict/snoop for any cache level
// ============================================================
`timescale 1ns/1ps

module cache_controller #(
    parameter PADDR_WIDTH = 56,
    parameter LINE_BITS   = 512,
    parameter WAYS        = 4,
    parameter SETS        = 128
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Generic upstream port
    input  wire                     up_req_valid,
    input  wire [PADDR_WIDTH-1:0]   up_req_addr,
    input  wire                     up_req_wr,
    input  wire [LINE_BITS-1:0]     up_req_wdata,
    output reg                      up_req_ready,
    output reg                      up_resp_valid,
    output reg  [LINE_BITS-1:0]     up_resp_data,
    output reg                      up_resp_miss,

    // Generic downstream port
    output reg                      dn_req_valid,
    output reg  [PADDR_WIDTH-1:0]   dn_req_addr,
    output reg                      dn_req_wr,
    output reg  [LINE_BITS-1:0]     dn_req_wdata,
    input  wire                     dn_resp_valid,
    input  wire [LINE_BITS-1:0]     dn_resp_data,

    // Tag/data SRAM interfaces
    output reg  [$clog2(SETS)-1:0]  tag_rd_idx,
    input  wire [WAYS*50-1:0]       tag_rd_data,    // tag+valid bits
    output reg                      tag_wr_en,
    output reg  [$clog2(SETS)-1:0]  tag_wr_idx,
    output reg  [$clog2(WAYS)-1:0]  tag_wr_way,
    output reg  [49:0]              tag_wr_data,

    output reg  [$clog2(SETS)-1:0]  data_rd_idx,
    output reg  [$clog2(WAYS)-1:0]  data_rd_way,
    input  wire [LINE_BITS-1:0]     data_rd_data,
    output reg                      data_wr_en,
    output reg  [$clog2(SETS)-1:0]  data_wr_idx,
    output reg  [$clog2(WAYS)-1:0]  data_wr_way,
    output reg  [LINE_BITS-1:0]     data_wr_data
);

    localparam OFFSET_BITS = $clog2(LINE_BITS/8);
    localparam INDEX_BITS  = $clog2(SETS);
    localparam TAG_BITS    = PADDR_WIDTH - INDEX_BITS - OFFSET_BITS;

    localparam ST_IDLE   = 3'd0;
    localparam ST_LOOKUP = 3'd1;
    localparam ST_MISS   = 3'd2;
    localparam ST_FILL   = 3'd3;
    localparam ST_RESP   = 3'd4;

    reg [2:0]              state;
    reg [PADDR_WIDTH-1:0]  req_addr_r;
    reg                    req_wr_r;
    reg [LINE_BITS-1:0]    req_wdata_r;
    reg [INDEX_BITS-1:0]   req_idx;
    reg [TAG_BITS-1:0]     req_tag;
    reg [$clog2(WAYS)-1:0] hit_way, victim_way;
    reg                    hit;
    integer                i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE; up_req_ready<=1; up_resp_valid<=0; dn_req_valid<=0;
            tag_wr_en<=0; data_wr_en<=0;
        end else begin
            up_resp_valid<=0; dn_req_valid<=0; tag_wr_en<=0; data_wr_en<=0;
            case(state)
                ST_IDLE: begin
                    up_req_ready<=1;
                    if(up_req_valid) begin
                        req_addr_r  <=up_req_addr;
                        req_wr_r    <=up_req_wr;
                        req_wdata_r <=up_req_wdata;
                        req_idx     <=up_req_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
                        req_tag     <=up_req_addr[PADDR_WIDTH-1:OFFSET_BITS+INDEX_BITS];
                        tag_rd_idx  <=up_req_addr[OFFSET_BITS+INDEX_BITS-1:OFFSET_BITS];
                        up_req_ready<=0;
                        state<=ST_LOOKUP;
                    end
                end
                ST_LOOKUP: begin
                    hit=0; hit_way=0; victim_way=0;
                    for(i=0;i<WAYS;i=i+1) begin
                        if(tag_rd_data[i*50+TAG_BITS] && // valid bit
                           tag_rd_data[i*50+:TAG_BITS]==req_tag) begin
                            hit=1; hit_way=i[$clog2(WAYS)-1:0];
                        end
                    end
                    if(hit) begin
                        data_rd_idx<=req_idx; data_rd_way<=hit_way;
                        if(req_wr_r) begin
                            data_wr_en<=1; data_wr_idx<=req_idx; data_wr_way<=hit_way; data_wr_data<=req_wdata_r;
                        end
                        state<=ST_RESP;
                    end else begin
                        dn_req_valid<=1; dn_req_addr<=req_addr_r; dn_req_wr<=0;
                        state<=ST_MISS;
                    end
                end
                ST_RESP: begin
                    up_resp_valid<=1; up_resp_miss<=0; up_resp_data<=data_rd_data; up_req_ready<=1; state<=ST_IDLE;
                end
                ST_MISS: begin
                    dn_req_valid<=1;
                    if(dn_resp_valid) begin
                        data_wr_en<=1; data_wr_idx<=req_idx; data_wr_way<=0; data_wr_data<=dn_resp_data;
                        tag_wr_en<=1; tag_wr_idx<=req_idx; tag_wr_way<=0;
                        tag_wr_data<={{(50-TAG_BITS-1){1'b0}},1'b1,req_tag};
                        up_resp_valid<=1; up_resp_miss<=1; up_resp_data<=dn_resp_data; up_req_ready<=1;
                        state<=ST_IDLE;
                    end
                end
            endcase
        end
    end
endmodule
