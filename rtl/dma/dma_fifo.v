`timescale 1ns/1ps
module dma_fifo #(parameter DW=128, DEPTH=16)(
    input wire clk, input wire rst_n,
    input wire wr_en, input wire [DW-1:0] wr_data, output wire wr_full,
    output reg rd_valid, output reg [DW-1:0] rd_data, input wire rd_en, output wire rd_empty
);
    reg [DW-1:0] mem[0:DEPTH-1]; reg [$clog2(DEPTH):0] cnt; reg [$clog2(DEPTH)-1:0] head,tail;
    assign wr_full=(cnt==DEPTH); assign rd_empty=(cnt==0);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin cnt<=0; head<=0; tail<=0; rd_valid<=0; end
        else begin
            if(wr_en&&!wr_full) begin mem[tail]<=wr_data; tail<=tail+1; cnt<=cnt+1; end
            if(rd_en&&!rd_empty) begin rd_data<=mem[head]; head<=head+1; cnt<=cnt-1; rd_valid<=1; end
            else rd_valid<=0;
        end
    end
endmodule
