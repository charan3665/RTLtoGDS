`timescale 1ns/1ps
module spi_master #(parameter CLK_DIV=4)(
    input wire clk, input wire rst_n,
    input wire [7:0] tx_data, input wire tx_valid, output wire tx_ready,
    output reg [7:0] rx_data, output reg rx_valid,
    output reg sclk, output reg mosi, input wire miso,
    output reg cs_n
);
    reg [4:0] cnt; reg [7:0] shift_tx, shift_rx; reg active;
    reg [2:0] div;
    assign tx_ready=!active;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin sclk<=0; cs_n<=1; mosi<=0; active<=0; cnt<=0; div<=0; rx_valid<=0; end
        else begin
            rx_valid<=0;
            if(tx_valid&&!active) begin shift_tx<=tx_data; active<=1; cs_n<=0; cnt<=0; div<=0; end
            if(active) begin
                div<=div+1;
                if(div==CLK_DIV/2-1) begin div<=0; sclk<=~sclk;
                    if(!sclk) begin mosi<=shift_tx[7]; shift_tx<={shift_tx[6:0],1'b0}; end
                    else begin shift_rx<={shift_rx[6:0],miso}; cnt<=cnt+1;
                        if(cnt==7) begin rx_data<={shift_rx[6:0],miso}; rx_valid<=1; active<=0; cs_n<=1; end
                    end
                end
            end
        end
    end
endmodule
