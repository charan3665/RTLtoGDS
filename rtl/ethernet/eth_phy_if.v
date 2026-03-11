`timescale 1ns/1ps
module eth_phy_if(
    input wire clk, input wire rst_n,
    input wire [3:0] rgmii_rxd, input wire rgmii_rx_ctl, input wire rgmii_rxc,
    output reg [3:0] rgmii_txd, output reg rgmii_tx_ctl, output wire rgmii_txc,
    output reg [7:0] rx_byte, output reg rx_valid, output reg rx_sof, output reg rx_eof,
    input wire [7:0] tx_byte, output wire tx_req, input wire tx_sof, input wire tx_eof
);
    reg [3:0] rxd_r; reg rxctl_r;
    always @(posedge rgmii_rxc) begin rxd_r<=rgmii_rxd; rxctl_r<=rgmii_rx_ctl; end
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin rx_valid<=0; rx_sof<=0; rx_eof<=0; end
        else begin rx_valid<=rxctl_r; rx_byte<={rxd_r,rxd_r}; rx_sof<=rxctl_r&&!rx_valid; rx_eof<=!rxctl_r&&rx_valid; end
    end
    assign rgmii_txc=clk;
    assign tx_req=1'b0;
    always @(posedge clk) begin rgmii_txd<=tx_byte[7:4]; rgmii_tx_ctl<=tx_sof||tx_eof; end
endmodule
