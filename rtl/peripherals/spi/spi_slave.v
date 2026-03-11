`timescale 1ns/1ps
module spi_slave(
    input wire clk, input wire rst_n,
    input wire sclk, input wire mosi, output reg miso, input wire cs_n,
    input wire [7:0] tx_data, output reg [7:0] rx_data, output reg rx_valid
);
    reg [7:0] shift; reg [2:0] cnt;
    always @(posedge sclk or posedge cs_n) begin
        if(cs_n) begin cnt<=0; rx_valid<=0; end
        else begin shift<={shift[6:0],mosi}; cnt<=cnt+1; if(cnt==7) begin rx_data<={shift[6:0],mosi}; rx_valid<=1; end else rx_valid<=0; end
    end
    always @(negedge sclk or posedge cs_n) begin
        if(cs_n) miso<=0;
        else miso<=tx_data[7-cnt];
    end
endmodule
