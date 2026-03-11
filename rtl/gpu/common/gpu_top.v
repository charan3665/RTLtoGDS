// ============================================================
// gpu_top.v - GPU Top Level Integration
// ============================================================
`timescale 1ns/1ps
module gpu_top #(
    parameter N_SMs      = 4,     // shader multiprocessors
    parameter SIMD_WIDTH = 32,
    parameter AW         = 64,
    parameter DW         = 128
)(
    input  wire         clk, input wire rst_n,
    // AXI4 slave (command/register interface)
    input  wire         s_awvalid, input wire [AW-1:0] s_awaddr, output wire s_awready,
    input  wire         s_wvalid,  input wire [DW-1:0] s_wdata,  output wire s_wready,
    output wire         s_bvalid,  output wire [1:0] s_bresp, input wire s_bready,
    input  wire         s_arvalid, input wire [AW-1:0] s_araddr, output wire s_arready,
    output wire         s_rvalid,  output wire [DW-1:0] s_rdata, output wire [1:0] s_rresp, input wire s_rready,
    // AXI4 master (DMA to DRAM)
    output wire         m_arvalid, output wire [AW-1:0] m_araddr, input wire m_arready,
    input  wire         m_rvalid,  input wire [DW-1:0] m_rdata,   output wire m_rready,
    output wire         m_awvalid, output wire [AW-1:0] m_awaddr,  input wire m_awready,
    output wire         m_wvalid,  output wire [DW-1:0] m_wdata,   input wire m_wready,
    input  wire         m_bvalid,  input wire [1:0] m_bresp, output wire m_bready,
    // Interrupt
    output wire         gpu_irq,
    // Power gating
    input  wire         clk_en
);
    // GPU command processor
    wire cmd_dispatch; wire [5:0] cmd_warp_id; wire [31:0] cmd_pc; wire [SIMD_WIDTH-1:0] cmd_mask;
    gpu_command_proc u_cmd(.clk(clk),.rst_n(rst_n),
        .s_awvalid(s_awvalid),.s_awaddr(s_awaddr),.s_awready(s_awready),
        .s_wvalid(s_wvalid),.s_wdata(s_wdata),.s_wready(s_wready),
        .s_bvalid(s_bvalid),.s_bresp(s_bresp),.s_bready(s_bready),
        .s_arvalid(s_arvalid),.s_araddr(s_araddr),.s_arready(s_arready),
        .s_rvalid(s_rvalid),.s_rdata(s_rdata),.s_rresp(s_rresp),.s_rready(s_rready),
        .dispatch_valid(cmd_dispatch),.dispatch_warp_id(cmd_warp_id),
        .dispatch_pc(cmd_pc),.dispatch_mask(cmd_mask),.gpu_irq(gpu_irq));
    // Shader cores
    genvar g;
    generate for(g=0;g<N_SMs;g=g+1) begin : gen_sm
        shader_core #(.SIMD_WIDTH(SIMD_WIDTH)) u_sm(
            .clk(clk),.rst_n(rst_n),
            .dispatch_valid(cmd_dispatch&&cmd_warp_id[5:2]==g[1:0]),.dispatch_warp_id(cmd_warp_id),.dispatch_pc(cmd_pc),.dispatch_mask(cmd_mask),.dispatch_ready(),.dispatch_scalar({SIMD_WIDTH*32{1'b0}}),
            .retire_valid(),.retire_warp_id(),.retire_mask(),
            .ifetch_pc(),.ifetch_valid(),.ifetch_data(128'b0),.ifetch_valid_resp(1'b0),
            .mem_req_valid(),.mem_req_addr(),.mem_req_wr(),.mem_req_data(),.mem_resp_valid({SIMD_WIDTH{1'b0}}),.mem_resp_data({SIMD_WIDTH*32{1'b0}}));
    end endgenerate
    assign m_arvalid=0; assign m_araddr=0; assign m_rready=1; assign m_awvalid=0; assign m_awaddr=0; assign m_wvalid=0; assign m_wdata=0; assign m_bready=1;
endmodule
