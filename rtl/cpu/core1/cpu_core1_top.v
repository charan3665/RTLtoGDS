// ============================================================
// cpu_core1_top.v - Core 1 (HART_ID=1), same architecture as core0
// ============================================================
`timescale 1ns/1ps

module cpu_core1_top #(
    parameter XLEN        = 64,
    parameter VADDR_WIDTH = 39,
    parameter PADDR_WIDTH = 56,
    parameter HART_ID     = 1
)(
    input  wire                     clk,
    input  wire                     rst_n,
    output wire                     itlb_req_valid,
    output wire [VADDR_WIDTH-1:0]   itlb_req_vaddr,
    input  wire                     itlb_resp_valid,
    input  wire                     itlb_resp_fault,
    input  wire [PADDR_WIDTH-1:0]   itlb_resp_paddr,
    output wire                     dtlb_req_valid,
    output wire [VADDR_WIDTH-1:0]   dtlb_req_vaddr,
    output wire                     dtlb_req_wr,
    input  wire                     dtlb_resp_valid,
    input  wire                     dtlb_resp_fault,
    input  wire [PADDR_WIDTH-1:0]   dtlb_resp_paddr,
    output wire                     icache_req_valid,
    output wire [PADDR_WIDTH-1:0]   icache_req_paddr,
    input  wire                     icache_resp_valid,
    input  wire [511:0]             icache_resp_data,
    input  wire                     icache_resp_miss,
    output wire                     dcache_req_valid,
    output wire [PADDR_WIDTH-1:0]   dcache_req_paddr,
    output wire                     dcache_req_wr,
    output wire [2:0]               dcache_req_size,
    output wire [63:0]              dcache_req_wdata,
    output wire [7:0]               dcache_req_strb,
    input  wire                     dcache_resp_valid,
    input  wire [63:0]              dcache_resp_rdata,
    input  wire                     dcache_resp_miss,
    input  wire                     m_ext_irq,
    input  wire                     m_sw_irq,
    input  wire                     m_timer_irq,
    input  wire                     debug_halt,
    output wire                     debug_halted,
    input  wire                     clk_en,
    output wire [63:0]              perf_mcycle,
    output wire [63:0]              perf_minstret
);
    cpu_core0_top #(.XLEN(XLEN), .VADDR_WIDTH(VADDR_WIDTH),
                    .PADDR_WIDTH(PADDR_WIDTH), .HART_ID(HART_ID))
    u_core1 (
        .clk(clk), .rst_n(rst_n),
        .itlb_req_valid(itlb_req_valid), .itlb_req_vaddr(itlb_req_vaddr),
        .itlb_resp_valid(itlb_resp_valid), .itlb_resp_fault(itlb_resp_fault),
        .itlb_resp_paddr(itlb_resp_paddr),
        .dtlb_req_valid(dtlb_req_valid), .dtlb_req_vaddr(dtlb_req_vaddr),
        .dtlb_req_wr(dtlb_req_wr),
        .dtlb_resp_valid(dtlb_resp_valid), .dtlb_resp_fault(dtlb_resp_fault),
        .dtlb_resp_paddr(dtlb_resp_paddr),
        .icache_req_valid(icache_req_valid), .icache_req_paddr(icache_req_paddr),
        .icache_resp_valid(icache_resp_valid), .icache_resp_data(icache_resp_data),
        .icache_resp_miss(icache_resp_miss),
        .dcache_req_valid(dcache_req_valid), .dcache_req_paddr(dcache_req_paddr),
        .dcache_req_wr(dcache_req_wr), .dcache_req_size(dcache_req_size),
        .dcache_req_wdata(dcache_req_wdata), .dcache_req_strb(dcache_req_strb),
        .dcache_resp_valid(dcache_resp_valid), .dcache_resp_rdata(dcache_resp_rdata),
        .dcache_resp_miss(dcache_resp_miss),
        .m_ext_irq(m_ext_irq), .m_sw_irq(m_sw_irq), .m_timer_irq(m_timer_irq),
        .debug_halt(debug_halt), .debug_halted(debug_halted),
        .clk_en(clk_en), .perf_mcycle(perf_mcycle), .perf_minstret(perf_minstret)
    );
endmodule
