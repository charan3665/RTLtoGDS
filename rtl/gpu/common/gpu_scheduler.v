`timescale 1ns/1ps
module gpu_scheduler #(parameter N_SMs=4, N_WARPS=8)(
    input wire clk, input wire rst_n,
    input  wire dispatch_valid, input wire [5:0] warp_id, input wire [31:0] pc, input wire [31:0] mask,
    output reg  [N_SMs-1:0] sm_dispatch_valid, output reg [$clog2(N_SMs)-1:0] sm_id_sel,
    input  wire [N_SMs-1:0] sm_ready,
    input  wire [N_SMs-1:0] sm_done, output reg done_ack
);
    reg [$clog2(N_SMs)-1:0] rr;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin sm_dispatch_valid<=0; rr<=0; done_ack<=0; end
        else begin
            sm_dispatch_valid<=0; done_ack<=0;
            if(dispatch_valid && sm_ready[rr]) begin
                sm_dispatch_valid[rr]<=1; sm_id_sel<=rr; rr<=rr+1;
            end
            if(|sm_done) done_ack<=1;
        end
    end
endmodule
