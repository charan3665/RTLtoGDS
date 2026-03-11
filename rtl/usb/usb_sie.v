`timescale 1ns/1ps
module usb_sie(
    input wire clk, input wire rst_n,
    input wire rx_valid, input wire rx_data,
    output reg tx_en, output reg tx_data,
    output reg irq
);
    // Serial Interface Engine: NRZI decode, bit stuffing, packet detection
    reg [7:0] shift; reg [3:0] bit_cnt; reg [2:0] ones; reg active;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin shift<=0; bit_cnt<=0; ones<=0; active<=0; tx_en<=0; irq<=0; end
        else begin
            irq<=0;
            if(rx_valid) begin
                shift<={rx_data, shift[7:1]}; bit_cnt<=bit_cnt+1;
                if(rx_data) ones<=ones+1; else ones<=0;
                if(bit_cnt==7) begin irq<=1; bit_cnt<=0; end
            end
        end
    end
endmodule
