`timescale 1ns/1ps
module triangle_setup #(parameter DW=32)(
    input wire clk, input wire rst_n,
    input wire tri_valid, input wire [DW-1:0] v0x, v0y, v1x, v1y, v2x, v2y,
    output wire ready,
    output reg  out_valid, output reg [DW-1:0] area, e01, e12, e20
);
    // Compute 2D edge equations: e = (v1-v0) x (p-v0)
    // Area = (v1-v0) x (v2-v0)
    assign ready=1'b1;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) out_valid<=0;
        else begin
            out_valid<=tri_valid;
            if(tri_valid) begin
                area <= (v1x-v0x)*(v2y-v0y) - (v1y-v0y)*(v2x-v0x);
                e01  <= (v1x-v0x); e12 <= (v2x-v1x); e20 <= (v0x-v2x);
            end
        end
    end
endmodule
