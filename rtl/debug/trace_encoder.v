`timescale 1ns/1ps
module trace_encoder #(parameter XLEN=64, INST_WIDTH=32)(
    input wire clk, input wire rst_n,
    input wire inst_valid, input wire [XLEN-1:0] inst_pc, input wire [INST_WIDTH-1:0] inst_data,
    input wire is_branch, input wire branch_taken, input wire [XLEN-1:0] branch_target,
    input wire trace_en,
    output reg [127:0] trace_out, output reg trace_valid,
    input wire trace_ready
);
    // Instruction trace encoder: produces compressed trace packets
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin trace_valid<=0; end
        else begin trace_valid<=0;
            if(trace_en&&inst_valid) begin
                trace_out<={branch_target,inst_pc,32'b0,inst_data,branch_taken,is_branch,1'b1,1'b0};
                trace_valid<=1;
            end
        end
    end
endmodule
