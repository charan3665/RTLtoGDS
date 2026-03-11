// pcie_top.v - PCIe Gen4 x4 Controller Top Level
`timescale 1ns/1ps
module pcie_top #(parameter AW=64, DW=128, LANES=4)(
    input  wire         clk_pcie,   // 250 MHz ref
    input  wire         rst_n,
    // SerDes lanes (differential)
    input  wire [LANES-1:0] rxp, rxn,
    output wire [LANES-1:0] txp, txn,
    // AXI4 master (to SoC)
    output wire         m_awvalid, output wire [AW-1:0] m_awaddr, input wire m_awready,
    output wire         m_wvalid, output wire [DW-1:0] m_wdata, output wire [DW/8-1:0] m_wstrb, output wire m_wlast, input wire m_wready,
    input  wire         m_bvalid, input wire [1:0] m_bresp, output wire m_bready,
    output wire         m_arvalid, output wire [AW-1:0] m_araddr, input wire m_arready,
    input  wire         m_rvalid, input wire [DW-1:0] m_rdata, input wire [1:0] m_rresp, output wire m_rready,
    // AXI4 slave (from SoC)
    input  wire         s_awvalid, input wire [AW-1:0] s_awaddr, output wire s_awready,
    input  wire         s_wvalid, input wire [DW-1:0] s_wdata, output wire s_wready,
    output wire         s_bvalid, output wire [1:0] s_bresp, input wire s_bready,
    input  wire         s_arvalid, input wire [AW-1:0] s_araddr, output wire s_arready,
    output wire         s_rvalid, output wire [DW-1:0] s_rdata, output wire [1:0] s_rresp, input wire s_rready,
    output wire         pcie_irq,
    // Configuration (ECAM)
    input  wire [11:0]  cfg_reg_addr, input wire [31:0] cfg_wdata, input wire cfg_wr, output wire [31:0] cfg_rdata
);
    wire tl_tx_valid; wire [255:0] tl_tx_data;
    wire dl_tx_valid; wire [255:0] dl_tx_data;
    wire phy_tx_valid; wire [255:0] phy_tx_data;

    pcie_tl u_tl(.clk(clk_pcie),.rst_n(rst_n),
        .s_awvalid(s_awvalid),.s_awaddr(s_awaddr),.s_awready(s_awready),
        .s_wvalid(s_wvalid),.s_wdata(s_wdata),.s_wready(s_wready),
        .s_bvalid(s_bvalid),.s_bresp(s_bresp),.s_bready(s_bready),
        .s_arvalid(s_arvalid),.s_araddr(s_araddr),.s_arready(s_arready),
        .s_rvalid(s_rvalid),.s_rdata(s_rdata),.s_rresp(s_rresp),.s_rready(s_rready),
        .m_awvalid(m_awvalid),.m_awaddr(m_awaddr),.m_awready(m_awready),
        .m_wvalid(m_wvalid),.m_wdata(m_wdata),.m_wstrb(m_wstrb),.m_wlast(m_wlast),.m_wready(m_wready),
        .m_bvalid(m_bvalid),.m_bready(m_bready),
        .m_arvalid(m_arvalid),.m_araddr(m_araddr),.m_arready(m_arready),
        .m_rvalid(m_rvalid),.m_rdata(m_rdata),.m_rready(m_rready),
        .tx_valid(tl_tx_valid),.tx_data(tl_tx_data),
        .rx_valid(1'b0),.rx_data(256'b0));
    pcie_dll u_dll(.clk(clk_pcie),.rst_n(rst_n),.in_valid(tl_tx_valid),.in_data(tl_tx_data),.out_valid(dl_tx_valid),.out_data(dl_tx_data));
    pcie_phy #(.LANES(LANES)) u_phy(.clk_ref(clk_pcie),.rst_n(rst_n),.rxp(rxp),.rxn(rxn),.txp(txp),.txn(txn),.in_valid(dl_tx_valid),.in_data(dl_tx_data),.out_valid(),.out_data());
    pcie_config u_cfg(.clk(clk_pcie),.rst_n(rst_n),.reg_addr(cfg_reg_addr),.wdata(cfg_wdata),.wr(cfg_wr),.rdata(cfg_rdata));
    assign pcie_irq=1'b0;
endmodule
