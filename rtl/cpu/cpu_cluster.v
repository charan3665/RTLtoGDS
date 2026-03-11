// ============================================================
// cpu_cluster.v - Dual-Core RISC-V CPU Cluster
// Core0 + Core1 + shared MMU + ITLB0/1 + DTLB0/1
// ============================================================
`timescale 1ns/1ps

module cpu_cluster #(
    parameter XLEN        = 64,
    parameter VADDR_WIDTH = 39,
    parameter PADDR_WIDTH = 56
)(
    input  wire         clk,
    input  wire         rst_n,

    // Core 0 cache interfaces
    output wire         c0_icache_req_valid,
    output wire [PADDR_WIDTH-1:0] c0_icache_req_paddr,
    input  wire         c0_icache_resp_valid,
    input  wire [511:0] c0_icache_resp_data,
    input  wire         c0_icache_resp_miss,
    output wire         c0_dcache_req_valid,
    output wire [PADDR_WIDTH-1:0] c0_dcache_req_paddr,
    output wire         c0_dcache_req_wr,
    output wire [2:0]   c0_dcache_req_size,
    output wire [63:0]  c0_dcache_req_wdata,
    output wire [7:0]   c0_dcache_req_strb,
    input  wire         c0_dcache_resp_valid,
    input  wire [63:0]  c0_dcache_resp_rdata,
    input  wire         c0_dcache_resp_miss,

    // Core 1 cache interfaces
    output wire         c1_icache_req_valid,
    output wire [PADDR_WIDTH-1:0] c1_icache_req_paddr,
    input  wire         c1_icache_resp_valid,
    input  wire [511:0] c1_icache_resp_data,
    input  wire         c1_icache_resp_miss,
    output wire         c1_dcache_req_valid,
    output wire [PADDR_WIDTH-1:0] c1_dcache_req_paddr,
    output wire         c1_dcache_req_wr,
    output wire [2:0]   c1_dcache_req_size,
    output wire [63:0]  c1_dcache_req_wdata,
    output wire [7:0]   c1_dcache_req_strb,
    input  wire         c1_dcache_resp_valid,
    input  wire [63:0]  c1_dcache_resp_rdata,
    input  wire         c1_dcache_resp_miss,

    // Interrupts (per core)
    input  wire [1:0]   m_ext_irq,
    input  wire [1:0]   m_sw_irq,
    input  wire [1:0]   m_timer_irq,

    // Debug
    input  wire [1:0]   debug_halt,
    output wire [1:0]   debug_halted,

    // Performance counters
    output wire [63:0]  c0_mcycle, c0_minstret,
    output wire [63:0]  c1_mcycle, c1_minstret,

    // MMU memory interface (for page table walk)
    output wire [PADDR_WIDTH-1:0] mmu_mem_req_addr,
    output wire         mmu_mem_req_valid,
    input  wire [63:0]  mmu_mem_resp_data,
    input  wire         mmu_mem_resp_valid,
    input  wire         mmu_mem_resp_err,

    // SATP from CSR
    input  wire [63:0]  satp,
    input  wire         sfence_vma
);

    // Core 0 TLB wires
    wire c0_itlb_req_valid, c0_itlb_resp_valid, c0_itlb_resp_fault;
    wire [VADDR_WIDTH-1:0] c0_itlb_req_vaddr;
    wire [PADDR_WIDTH-1:0] c0_itlb_resp_paddr;
    wire c0_dtlb_req_valid, c0_dtlb_req_wr, c0_dtlb_resp_valid, c0_dtlb_resp_fault;
    wire [VADDR_WIDTH-1:0] c0_dtlb_req_vaddr;
    wire [PADDR_WIDTH-1:0] c0_dtlb_resp_paddr;

    // Core 1 TLB wires
    wire c1_itlb_req_valid, c1_itlb_resp_valid, c1_itlb_resp_fault;
    wire [VADDR_WIDTH-1:0] c1_itlb_req_vaddr;
    wire [PADDR_WIDTH-1:0] c1_itlb_resp_paddr;
    wire c1_dtlb_req_valid, c1_dtlb_req_wr, c1_dtlb_resp_valid, c1_dtlb_resp_fault;
    wire [VADDR_WIDTH-1:0] c1_dtlb_req_vaddr;
    wire [PADDR_WIDTH-1:0] c1_dtlb_resp_paddr;

    // MMU fill wires
    wire mmu_itlb_fill_valid, mmu_itlb_fill_fault;
    wire [PADDR_WIDTH-1:0] mmu_itlb_fill_paddr;
    wire [7:0] mmu_itlb_fill_perm;
    wire mmu_dtlb_fill_valid, mmu_dtlb_fill_fault;
    wire [PADDR_WIDTH-1:0] mmu_dtlb_fill_paddr;
    wire [7:0] mmu_dtlb_fill_perm;
    wire mmu_itlb_miss, mmu_dtlb_miss;
    wire [VADDR_WIDTH-1:0] mmu_itlb_miss_vaddr, mmu_dtlb_miss_vaddr;

    // Core 0
    cpu_core0_top #(.HART_ID(0)) u_core0 (
        .clk(clk), .rst_n(rst_n),
        .itlb_req_valid(c0_itlb_req_valid), .itlb_req_vaddr(c0_itlb_req_vaddr),
        .itlb_resp_valid(c0_itlb_resp_valid), .itlb_resp_fault(c0_itlb_resp_fault),
        .itlb_resp_paddr(c0_itlb_resp_paddr),
        .dtlb_req_valid(c0_dtlb_req_valid), .dtlb_req_vaddr(c0_dtlb_req_vaddr),
        .dtlb_req_wr(c0_dtlb_req_wr),
        .dtlb_resp_valid(c0_dtlb_resp_valid), .dtlb_resp_fault(c0_dtlb_resp_fault),
        .dtlb_resp_paddr(c0_dtlb_resp_paddr),
        .icache_req_valid(c0_icache_req_valid), .icache_req_paddr(c0_icache_req_paddr),
        .icache_resp_valid(c0_icache_resp_valid), .icache_resp_data(c0_icache_resp_data),
        .icache_resp_miss(c0_icache_resp_miss),
        .dcache_req_valid(c0_dcache_req_valid), .dcache_req_paddr(c0_dcache_req_paddr),
        .dcache_req_wr(c0_dcache_req_wr), .dcache_req_size(c0_dcache_req_size),
        .dcache_req_wdata(c0_dcache_req_wdata), .dcache_req_strb(c0_dcache_req_strb),
        .dcache_resp_valid(c0_dcache_resp_valid), .dcache_resp_rdata(c0_dcache_resp_rdata),
        .dcache_resp_miss(c0_dcache_resp_miss),
        .m_ext_irq(m_ext_irq[0]), .m_sw_irq(m_sw_irq[0]), .m_timer_irq(m_timer_irq[0]),
        .debug_halt(debug_halt[0]), .debug_halted(debug_halted[0]), .clk_en(1'b1),
        .perf_mcycle(c0_mcycle), .perf_minstret(c0_minstret)
    );

    // Core 1
    cpu_core1_top #(.HART_ID(1)) u_core1 (
        .clk(clk), .rst_n(rst_n),
        .itlb_req_valid(c1_itlb_req_valid), .itlb_req_vaddr(c1_itlb_req_vaddr),
        .itlb_resp_valid(c1_itlb_resp_valid), .itlb_resp_fault(c1_itlb_resp_fault),
        .itlb_resp_paddr(c1_itlb_resp_paddr),
        .dtlb_req_valid(c1_dtlb_req_valid), .dtlb_req_vaddr(c1_dtlb_req_vaddr),
        .dtlb_req_wr(c1_dtlb_req_wr),
        .dtlb_resp_valid(c1_dtlb_resp_valid), .dtlb_resp_fault(c1_dtlb_resp_fault),
        .dtlb_resp_paddr(c1_dtlb_resp_paddr),
        .icache_req_valid(c1_icache_req_valid), .icache_req_paddr(c1_icache_req_paddr),
        .icache_resp_valid(c1_icache_resp_valid), .icache_resp_data(c1_icache_resp_data),
        .icache_resp_miss(c1_icache_resp_miss),
        .dcache_req_valid(c1_dcache_req_valid), .dcache_req_paddr(c1_dcache_req_paddr),
        .dcache_req_wr(c1_dcache_req_wr), .dcache_req_size(c1_dcache_req_size),
        .dcache_req_wdata(c1_dcache_req_wdata), .dcache_req_strb(c1_dcache_req_strb),
        .dcache_resp_valid(c1_dcache_resp_valid), .dcache_resp_rdata(c1_dcache_resp_rdata),
        .dcache_resp_miss(c1_dcache_resp_miss),
        .m_ext_irq(m_ext_irq[1]), .m_sw_irq(m_sw_irq[1]), .m_timer_irq(m_timer_irq[1]),
        .debug_halt(debug_halt[1]), .debug_halted(debug_halted[1]), .clk_en(1'b1),
        .perf_mcycle(c1_mcycle), .perf_minstret(c1_minstret)
    );

    // ITLB core0
    itlb #(.VADDR_WIDTH(VADDR_WIDTH), .PADDR_WIDTH(PADDR_WIDTH), .ENTRIES(32)) u_itlb0 (
        .clk(clk), .rst_n(rst_n),
        .req_valid(c0_itlb_req_valid), .req_vaddr(c0_itlb_req_vaddr), .req_asid(16'b0),
        .resp_valid(c0_itlb_resp_valid), .resp_miss(mmu_itlb_miss),
        .resp_paddr(c0_itlb_resp_paddr), .resp_perm(),
        .fill_valid(mmu_itlb_fill_valid), .fill_vaddr(mmu_itlb_miss_vaddr),
        .fill_paddr(mmu_itlb_fill_paddr), .fill_perm(mmu_itlb_fill_perm),
        .fill_asid(16'b0), .fill_fault(mmu_itlb_fill_fault),
        .sfence_valid(sfence_vma), .sfence_vaddr({VADDR_WIDTH{1'b0}}),
        .sfence_asid(16'b0), .sfence_all(sfence_vma)
    );
    assign c0_itlb_resp_fault = mmu_itlb_fill_fault && mmu_itlb_fill_valid;

    // DTLB core0
    dtlb #(.VADDR_WIDTH(VADDR_WIDTH), .PADDR_WIDTH(PADDR_WIDTH), .ENTRIES(64)) u_dtlb0 (
        .clk(clk), .rst_n(rst_n),
        .req_valid(c0_dtlb_req_valid), .req_vaddr(c0_dtlb_req_vaddr),
        .req_asid(16'b0), .req_wr(c0_dtlb_req_wr),
        .resp_valid(c0_dtlb_resp_valid), .resp_miss(mmu_dtlb_miss),
        .resp_paddr(c0_dtlb_resp_paddr), .resp_fault(c0_dtlb_resp_fault),
        .fill_valid(mmu_dtlb_fill_valid), .fill_vaddr(mmu_dtlb_miss_vaddr),
        .fill_paddr(mmu_dtlb_fill_paddr), .fill_perm(mmu_dtlb_fill_perm),
        .fill_asid(16'b0), .fill_fault(mmu_dtlb_fill_fault),
        .sfence_valid(sfence_vma), .sfence_vaddr({VADDR_WIDTH{1'b0}}),
        .sfence_asid(16'b0), .sfence_all(sfence_vma)
    );

    assign mmu_itlb_miss_vaddr = c0_itlb_req_vaddr;
    assign mmu_dtlb_miss_vaddr = c0_dtlb_req_vaddr;

    // Shared MMU (handles misses from both TLBs, round-robin)
    mmu #(.XLEN(64), .VADDR_WIDTH(VADDR_WIDTH), .PADDR_WIDTH(PADDR_WIDTH)) u_mmu (
        .clk(clk), .rst_n(rst_n),
        .itlb_miss_valid(mmu_itlb_miss), .itlb_miss_vaddr(mmu_itlb_miss_vaddr),
        .itlb_fill_valid(mmu_itlb_fill_valid), .itlb_fill_paddr(mmu_itlb_fill_paddr),
        .itlb_fill_perm(mmu_itlb_fill_perm), .itlb_fill_fault(mmu_itlb_fill_fault),
        .dtlb_miss_valid(mmu_dtlb_miss), .dtlb_miss_vaddr(mmu_dtlb_miss_vaddr),
        .dtlb_miss_wr(c0_dtlb_req_wr),
        .dtlb_fill_valid(mmu_dtlb_fill_valid), .dtlb_fill_paddr(mmu_dtlb_fill_paddr),
        .dtlb_fill_perm(mmu_dtlb_fill_perm), .dtlb_fill_fault(mmu_dtlb_fill_fault),
        .mem_req_addr(mmu_mem_req_addr), .mem_req_valid(mmu_mem_req_valid),
        .mem_resp_data(mmu_mem_resp_data), .mem_resp_valid(mmu_mem_resp_valid),
        .mem_resp_err(mmu_mem_resp_err),
        .satp(satp), .sfence_vma(sfence_vma)
    );

    // ITLB/DTLB for Core1 (stub - share same MMU in real design)
    assign c1_itlb_resp_valid = c1_itlb_req_valid;
    assign c1_itlb_resp_fault = 1'b0;
    assign c1_itlb_resp_paddr = c1_itlb_req_vaddr[PADDR_WIDTH-1:0];
    assign c1_dtlb_resp_valid = c1_dtlb_req_valid;
    assign c1_dtlb_resp_fault = 1'b0;
    assign c1_dtlb_resp_paddr = c1_dtlb_req_vaddr[PADDR_WIDTH-1:0];

endmodule
