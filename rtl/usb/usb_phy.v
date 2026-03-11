`timescale 1ns/1ps
module usb_phy(
    input wire clk, input wire rst_n,
    inout wire dp, dn,
    output reg rx_valid, output reg rx_data,
    input wire tx_en, input wire tx_data
);
    reg dp_r, dn_r;
    always @(posedge clk) begin dp_r<=dp; dn_r<=dn; end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) rx_valid<=0;
        else begin rx_valid<=(dp_r^dn_r); rx_data<=dp_r; end
    end
    assign dp = tx_en ? tx_data : 1'bz;
    assign dn = tx_en ? ~tx_data: 1'bz;
endmodule
