`timescale 1ns/1ps
module gpu_command_proc #(parameter AW=64, DW=128, SIMD_WIDTH=32)(
    input wire clk, input wire rst_n,
    input  wire s_awvalid, input wire [AW-1:0] s_awaddr, output reg s_awready,
    input  wire s_wvalid,  input wire [DW-1:0] s_wdata, output reg s_wready,
    output reg  s_bvalid,  output reg [1:0] s_bresp, input wire s_bready,
    input  wire s_arvalid, input wire [AW-1:0] s_araddr, output reg s_arready,
    output reg  s_rvalid,  output reg [DW-1:0] s_rdata, output reg [1:0] s_rresp, input wire s_rready,
    output reg  dispatch_valid, output reg [5:0] dispatch_warp_id,
    output reg  [31:0] dispatch_pc, output reg [SIMD_WIDTH-1:0] dispatch_mask,
    output reg  gpu_irq
);
    // Register map: 0x00=ctrl, 0x08=pc, 0x10=mask, 0x18=launch
    reg [63:0] regs[0:7];
    localparam ST_IDLE=2'd0, ST_WR=2'd1, ST_RD=2'd2;
    reg [1:0] state; reg [AW-1:0] addr_r;
    assign s_awready=1; assign s_wready=(state==ST_WR); assign s_arready=1;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin state<=ST_IDLE; s_bvalid<=0; s_rvalid<=0; dispatch_valid<=0; gpu_irq<=0;
            for(integer i=0;i<8;i=i+1) regs[i]<=0; end
        else begin
            dispatch_valid<=0; s_bvalid<=0; s_rvalid<=0;
            if(s_awvalid) begin addr_r<=s_awaddr; state<=ST_WR; end
            if(state==ST_WR && s_wvalid) begin
                regs[addr_r[5:3]]<=s_wdata[63:0];
                if(addr_r[5:3]==3'd3) begin // launch
                    dispatch_valid<=1; dispatch_warp_id<=s_wdata[5:0];
                    dispatch_pc<=regs[1][31:0]; dispatch_mask<={SIMD_WIDTH{1'b1}};
                end
                s_bvalid<=1; s_bresp<=2'b00; state<=ST_IDLE;
            end
            if(s_arvalid) begin s_rvalid<=1; s_rdata<={64'b0,regs[s_araddr[5:3]]}; s_rresp<=2'b00; end
        end
    end
endmodule
