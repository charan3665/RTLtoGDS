`timescale 1ns/1ps
module usb_endpoint #(parameter EP_TYPE=2'b10, EP_DIR=1'b0, FIFO_DEPTH=64)(
    input wire clk, input wire rst_n,
    input wire rx_valid, input wire [7:0] rx_data, output wire rx_ready,
    output reg tx_valid, output reg [7:0] tx_data, input wire tx_ready,
    input wire [3:0] ep_num, input wire stall_in, output reg halted
);
    reg [7:0] fifo[0:FIFO_DEPTH-1]; reg [$clog2(FIFO_DEPTH):0] cnt; reg [$clog2(FIFO_DEPTH)-1:0] head,tail;
    assign rx_ready=(cnt<FIFO_DEPTH)&&!halted;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin cnt<=0; head<=0; tail<=0; tx_valid<=0; halted<=0; end
        else begin
            halted<=stall_in;
            if(rx_valid&&rx_ready) begin fifo[tail]<=rx_data; tail<=tail+1; cnt<=cnt+1; end
            tx_valid<=(cnt>0)&&!halted;
            if(tx_valid&&tx_ready) begin tx_data<=fifo[head]; head<=head+1; cnt<=cnt-1; end
        end
    end
endmodule
