`timescale 1ns/1ps
module eth_top #(parameter AW=64, DW=128)(
    input wire clk_eth, input wire rst_n,
    input wire [3:0] rgmii_rxd, input wire rgmii_rx_ctl, input wire rgmii_rxc,
    output wire [3:0] rgmii_txd, output wire rgmii_tx_ctl, output wire rgmii_txc,
    input  wire s_awvalid, input wire [AW-1:0] s_awaddr, output wire s_awready,
    input  wire s_wvalid,  input wire [DW-1:0] s_wdata, output wire s_wready,
    output wire s_bvalid,  output wire [1:0] s_bresp, input wire s_bready,
    input  wire s_arvalid, input wire [AW-1:0] s_araddr, output wire s_arready,
    output wire s_rvalid,  output wire [DW-1:0] s_rdata, output wire [1:0] s_rresp, input wire s_rready,
    output wire m_awvalid, output wire [AW-1:0] m_awaddr, input wire m_awready,
    output wire m_wvalid,  output wire [DW-1:0] m_wdata, output wire [DW/8-1:0] m_wstrb, output wire m_wlast, input wire m_wready,
    input wire  m_bvalid,  output wire m_bready,
    output wire m_arvalid, output wire [AW-1:0] m_araddr, input wire m_arready,
    input wire  m_rvalid,  input wire [DW-1:0] m_rdata, output wire m_rready,
    output wire eth_irq,
    input wire mdio_in, output wire mdio_out, output wire mdio_oe, output wire mdc
);
    wire [7:0] rx_byte; wire rx_byte_valid; wire rx_frame_start, rx_frame_end;
    wire [7:0] tx_byte; wire tx_byte_req; wire tx_frame_start, tx_frame_end;
    eth_phy_if u_phy(.clk(clk_eth),.rst_n(rst_n),.rgmii_rxd(rgmii_rxd),.rgmii_rx_ctl(rgmii_rx_ctl),.rgmii_rxc(rgmii_rxc),.rgmii_txd(rgmii_txd),.rgmii_tx_ctl(rgmii_tx_ctl),.rgmii_txc(rgmii_txc),.rx_byte(rx_byte),.rx_valid(rx_byte_valid),.rx_sof(rx_frame_start),.rx_eof(rx_frame_end),.tx_byte(tx_byte),.tx_req(tx_byte_req),.tx_sof(tx_frame_start),.tx_eof(tx_frame_end));
    eth_mac u_mac(.clk(clk_eth),.rst_n(rst_n),.rx_byte(rx_byte),.rx_valid(rx_byte_valid),.rx_sof(rx_frame_start),.rx_eof(rx_frame_end),.tx_byte(tx_byte),.tx_req(tx_byte_req),.tx_sof(tx_frame_start),.tx_eof(tx_frame_end),.irq(eth_irq));
    eth_mdio u_mdio(.clk(clk_eth),.rst_n(rst_n),.mdio_in(mdio_in),.mdio_out(mdio_out),.mdio_oe(mdio_oe),.mdc(mdc));
    assign s_awready=1; assign s_wready=1; assign s_bvalid=0; assign s_bresp=0;
    assign s_arready=1; assign s_rvalid=0; assign s_rdata=0; assign s_rresp=0;
    assign m_awvalid=0; assign m_awaddr=0; assign m_wvalid=0; assign m_wdata=0; assign m_wstrb=0; assign m_wlast=0; assign m_bready=1;
    assign m_arvalid=0; assign m_araddr=0; assign m_rready=1;
endmodule
