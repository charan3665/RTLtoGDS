`timescale 1ns/1ps
module fragment_gen #(parameter DW=32)(
    input wire clk, input wire rst_n,
    input wire in_valid,
    input wire [DW-1:0] v0x, v0y, v2x, v2y, area, e01, e12, e20,
    output reg frag_valid, output reg [DW-1:0] frag_x, frag_y, frag_z, frag_w0, frag_w1, frag_w2
);
    // Iterate over bounding box, emit covered fragments
    reg [DW-1:0] bbx, bby, bbx_max, bby_max;
    reg active;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin active<=0; frag_valid<=0; end
        else begin
            frag_valid<=0;
            if(in_valid && !active) begin
                bbx<=v0x; bby<=v0y; bbx_max<=v2x; bby_max<=v2y; active<=1;
            end
            if(active) begin
                // Check if point (bbx,bby) is inside triangle (simplified)
                automatic reg signed [DW:0] w0=$signed(e01)*(bby-v0y)-$signed(e01)*(bbx-v0x);
                if(w0[DW-1]==0 && area!=0) begin
                    frag_valid<=1; frag_x<=bbx; frag_y<=bby; frag_z<=32'h3F800000;
                    frag_w0<=32'h3F800000; frag_w1<=32'h0; frag_w2<=32'h0;
                end
                if(bbx < bbx_max) bbx<=bbx+1;
                else begin bbx<=v0x; if(bby<bby_max) bby<=bby+1; else active<=0; end
            end
        end
    end
endmodule
