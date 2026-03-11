`timescale 1ns/1ps
module usb_top #(parameter AW=32, DW=32)(
    input wire clk_usb, input wire rst_n,
    inout wire usb_dp, usb_dn,
    input  wire s_awvalid, input wire [AW-1:0] s_awaddr, output wire s_awready,
    input  wire s_wvalid, input wire [DW-1:0] s_wdata, output wire s_wready,
    output wire s_bvalid, output wire [1:0] s_bresp, input wire s_bready,
    input  wire s_arvalid, input wire [AW-1:0] s_araddr, output wire s_arready,
    output wire s_rvalid, output wire [DW-1:0] s_rdata, output wire [1:0] s_rresp, input wire s_rready,
    output wire usb_irq
);
    wire phy_rx_valid, phy_rx_data; wire phy_tx_en; wire phy_tx_data;
    usb_phy u_phy(.clk(clk_usb),.rst_n(rst_n),.dp(usb_dp),.dn(usb_dn),.rx_valid(phy_rx_valid),.rx_data(phy_rx_data),.tx_en(phy_tx_en),.tx_data(phy_tx_data));
    usb_sie u_sie(.clk(clk_usb),.rst_n(rst_n),.rx_valid(phy_rx_valid),.rx_data(phy_rx_data),.tx_en(phy_tx_en),.tx_data(phy_tx_data),.irq(usb_irq));
    assign s_awready=1; assign s_wready=1; assign s_bvalid=0; assign s_bresp=0;
    assign s_arready=1; assign s_rvalid=0; assign s_rdata=0; assign s_rresp=0;
endmodule
