`timescale 1ns/1ps
module pcie_tl #(parameter AW=64, DW=128)(
    input wire clk, input wire rst_n,
    input  wire s_awvalid, input wire [AW-1:0] s_awaddr, output wire s_awready,
    input  wire s_wvalid, input wire [DW-1:0] s_wdata, output wire s_wready,
    output wire s_bvalid, output wire [1:0] s_bresp, input wire s_bready,
    input  wire s_arvalid, input wire [AW-1:0] s_araddr, output wire s_arready,
    output wire s_rvalid, output wire [DW-1:0] s_rdata, output wire [1:0] s_rresp, input wire s_rready,
    output wire m_awvalid, output wire [AW-1:0] m_awaddr, input wire m_awready,
    output wire m_wvalid, output wire [DW-1:0] m_wdata, output wire [DW/8-1:0] m_wstrb, output wire m_wlast, input wire m_wready,
    input wire m_bvalid, output wire m_bready,
    output wire m_arvalid, output wire [AW-1:0] m_araddr, input wire m_arready,
    input wire m_rvalid, input wire [DW-1:0] m_rdata, output wire m_rready,
    output reg tx_valid, output reg [255:0] tx_data,
    input wire rx_valid, input wire [255:0] rx_data
);
    // Transaction Layer: packs AXI transactions into TLPs
    // MRd TLP: [7:0]=fmt_type, [31:25]=length, [63:32]=requester_id+tag, [95:32]=addr
    localparam MRD = 8'h00; localparam MWR = 8'h40;
    assign s_awready=1; assign s_wready=1; assign s_bvalid=0; assign s_bresp=0;
    assign s_arready=1; assign s_rvalid=0; assign s_rdata=0; assign s_rresp=0;
    assign m_awvalid=0; assign m_awaddr=0; assign m_wvalid=0; assign m_wdata=0; assign m_wstrb=0; assign m_wlast=0; assign m_bready=1;
    assign m_arvalid=0; assign m_araddr=0; assign m_rready=1;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) tx_valid<=0;
        else begin
            tx_valid<=s_arvalid;
            if(s_arvalid) tx_data<={160'b0, s_araddr, 8'h00, MRD};
        end
    end
endmodule
