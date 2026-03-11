`timescale 1ns/1ps
module eth_mac(
    input wire clk, input wire rst_n,
    input wire [7:0] rx_byte, input wire rx_valid, input wire rx_sof, input wire rx_eof,
    output reg [7:0] tx_byte, output wire tx_req, input wire tx_sof, input wire tx_eof,
    output reg irq
);
    reg [7:0] rx_buf[0:2047]; reg [10:0] rx_ptr; reg [3:0] rx_state;
    reg [7:0] tx_buf[0:2047]; reg [10:0] tx_ptr, tx_len;
    // RX state machine
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin rx_ptr<=0; rx_state<=0; irq<=0; end
        else begin
            irq<=0;
            if(rx_sof) rx_ptr<=0;
            if(rx_valid) begin rx_buf[rx_ptr]<=rx_byte; rx_ptr<=rx_ptr+1; end
            if(rx_eof) begin irq<=1; end
        end
    end
    assign tx_req=(tx_ptr<tx_len);
    always @(posedge clk) if(tx_req) begin tx_byte<=tx_buf[tx_ptr]; tx_ptr<=tx_ptr+1; end
endmodule
