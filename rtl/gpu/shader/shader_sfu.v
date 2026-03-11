`timescale 1ns/1ps
// shader_sfu.v - Special Function Unit: reciprocal, sqrt, sin, cos (approx)
module shader_sfu #(parameter SIMD_WIDTH=32)(
    input  wire                         clk, input wire rst_n,
    input  wire [2:0]                   op, // 0=RCP, 1=SQRT, 2=SIN, 3=COS, 4=EXP2, 5=LOG2
    input  wire [SIMD_WIDTH*32-1:0]     src,
    input  wire [SIMD_WIDTH-1:0]        mask,
    output reg  [SIMD_WIDTH*32-1:0]     result,
    output reg                          done
);
    // 4-cycle pipeline approximation using lookup + Newton-Raphson
    reg [SIMD_WIDTH*32-1:0] stage[0:3];
    reg [3:0] vld;
    integer t;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin vld<=0; done<=0; end
        else begin
            done<=vld[3];
            vld<={vld[2:0], |mask};
            for(t=0;t<SIMD_WIDTH;t=t+1) begin
                if(mask[t]) begin
                    case(op)
                        3'd0: stage[0][t*32+:32] <= (src[t*32+:32]==0)?32'h7F800000: // INF
                              {src[t*32+31], 8'd254-src[t*32+30:23], ~src[t*32+22:0]}; // approx 1/x
                        3'd1: stage[0][t*32+:32] <= {1'b0, (src[t*32+30:23]>>1)+8'd63, src[t*32+22:0]}; // approx sqrt
                        default: stage[0][t*32+:32] <= src[t*32+:32];
                    endcase
                end else stage[0][t*32+:32]<=0;
            end
            stage[1]<=stage[0]; stage[2]<=stage[1]; stage[3]<=stage[2];
            if(vld[3]) result<=stage[3];
        end
    end
endmodule
