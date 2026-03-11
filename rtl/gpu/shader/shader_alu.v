`timescale 1ns/1ps
module shader_alu #(parameter SIMD_WIDTH=32, XLEN=32)(
    input  wire                         clk,
    input  wire [2:0]                   op,
    input  wire [SIMD_WIDTH*XLEN-1:0]   src1, src2,
    input  wire [SIMD_WIDTH-1:0]        mask,
    output reg  [SIMD_WIDTH*XLEN-1:0]   result,
    output reg  [SIMD_WIDTH-1:0]        result_valid
);
    integer t;
    always @(*) begin
        for(t=0;t<SIMD_WIDTH;t=t+1) begin
            result_valid[t]=mask[t];
            case(op)
                3'd0: result[t*XLEN+:XLEN]=src1[t*XLEN+:XLEN]+src2[t*XLEN+:XLEN]; // ADD
                3'd1: result[t*XLEN+:XLEN]=src1[t*XLEN+:XLEN]-src2[t*XLEN+:XLEN]; // SUB
                3'd2: result[t*XLEN+:XLEN]=src1[t*XLEN+:XLEN]*src2[t*XLEN+:XLEN]; // MUL
                3'd3: result[t*XLEN+:XLEN]=src1[t*XLEN+:XLEN]&src2[t*XLEN+:XLEN]; // AND
                3'd4: result[t*XLEN+:XLEN]=src1[t*XLEN+:XLEN]|src2[t*XLEN+:XLEN]; // OR
                3'd5: result[t*XLEN+:XLEN]=src1[t*XLEN+:XLEN]^src2[t*XLEN+:XLEN]; // XOR
                3'd6: result[t*XLEN+:XLEN]=$signed(src1[t*XLEN+:XLEN])<$signed(src2[t*XLEN+:XLEN])?32'd1:32'd0;
                3'd7: result[t*XLEN+:XLEN]=src1[t*XLEN+:XLEN]>>src2[t*XLEN+4:t*XLEN]; // SHR
            endcase
        end
    end
endmodule
