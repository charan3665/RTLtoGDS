`timescale 1ns/1ps
module uart_fifo #(parameter DEPTH=16)(
    input wire clk, input wire rst_n,
    input wire wr_en, input wire [7:0] wr_data, output wire full,
    input wire rd_en, output reg [7:0] rd_data, output wire empty
);
    reg [7:0] mem[0:DEPTH-1]; reg [$clog2(DEPTH):0] cnt; reg [$clog2(DEPTH)-1:0] head, tail;
    assign full=(cnt==DEPTH); assign empty=(cnt==0);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin cnt<=0; head<=0; tail<=0; end
        else begin
            if(wr_en&&!full) begin mem[tail]<=wr_data; tail<=tail+1; cnt<=cnt+1; end
            if(rd_en&&!empty) begin rd_data<=mem[head]; head<=head+1; cnt<=cnt-1; end
        end
    end
endmodule
