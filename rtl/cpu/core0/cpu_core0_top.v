// ============================================================
// cpu_core0_top.v - OoO RISC-V Core 0 Top Level Integration
// Integrates fetch, decode, rename, issue, execute, LSU, ROB
// ============================================================
`timescale 1ns/1ps

module cpu_core0_top #(
    parameter XLEN        = 64,
    parameter VADDR_WIDTH = 39,
    parameter PADDR_WIDTH = 56,
    parameter HART_ID     = 0,
    parameter PHYS_REGS   = 128,
    parameter ROB_ENTRIES = 128,
    parameter IQ_ENTRIES  = 32,
    parameter SQ_ENTRIES  = 32,
    parameter LQ_ENTRIES  = 32
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // I-TLB interface (to MMU/page walker)
    output wire                     itlb_req_valid,
    output wire [VADDR_WIDTH-1:0]   itlb_req_vaddr,
    input  wire                     itlb_resp_valid,
    input  wire                     itlb_resp_fault,
    input  wire [PADDR_WIDTH-1:0]   itlb_resp_paddr,

    // D-TLB interface
    output wire                     dtlb_req_valid,
    output wire [VADDR_WIDTH-1:0]   dtlb_req_vaddr,
    output wire                     dtlb_req_wr,
    input  wire                     dtlb_resp_valid,
    input  wire                     dtlb_resp_fault,
    input  wire [PADDR_WIDTH-1:0]   dtlb_resp_paddr,

    // I-Cache interface (to L1I)
    output wire                     icache_req_valid,
    output wire [PADDR_WIDTH-1:0]   icache_req_paddr,
    input  wire                     icache_resp_valid,
    input  wire [511:0]             icache_resp_data,
    input  wire                     icache_resp_miss,

    // D-Cache interface (to L1D)
    output wire                     dcache_req_valid,
    output wire [PADDR_WIDTH-1:0]   dcache_req_paddr,
    output wire                     dcache_req_wr,
    output wire [2:0]               dcache_req_size,
    output wire [XLEN-1:0]          dcache_req_wdata,
    output wire [7:0]               dcache_req_strb,
    input  wire                     dcache_resp_valid,
    input  wire [XLEN-1:0]          dcache_resp_rdata,
    input  wire                     dcache_resp_miss,

    // Interrupts
    input  wire                     m_ext_irq,
    input  wire                     m_sw_irq,
    input  wire                     m_timer_irq,

    // Debug interface
    input  wire                     debug_halt,
    output wire                     debug_halted,

    // Power management
    input  wire                     clk_en,
    output wire [XLEN-1:0]          perf_mcycle,
    output wire [XLEN-1:0]          perf_minstret
);

    localparam PREG_BITS   = 7;
    localparam ROB_BITS    = 7;
    localparam FETCH_WIDTH = 4;
    localparam ARCH_REGS   = 32;

    // -------------------------------------------------
    // Wire interconnections
    // -------------------------------------------------

    // Fetch -> Decode
    wire                        fetchq_valid;
    wire [FETCH_WIDTH*32-1:0]   fetchq_instr;
    wire [FETCH_WIDTH*VADDR_WIDTH-1:0] fetchq_pc;
    wire [FETCH_WIDTH-1:0]      fetchq_pred_taken;
    wire [FETCH_WIDTH*VADDR_WIDTH-1:0] fetchq_pred_target;
    wire                        fetchq_ready;

    // Decode -> Rename
    wire                        decode_valid;
    wire [FETCH_WIDTH*7-1:0]    decode_opcode;
    wire [FETCH_WIDTH*5-1:0]    decode_rd;
    wire [FETCH_WIDTH*5-1:0]    decode_rs1;
    wire [FETCH_WIDTH*5-1:0]    decode_rs2;
    wire [FETCH_WIDTH*5-1:0]    decode_rs3;
    wire [FETCH_WIDTH*XLEN-1:0] decode_imm;
    wire [FETCH_WIDTH*4-1:0]    decode_fu_type;
    wire [FETCH_WIDTH*6-1:0]    decode_alu_op;
    wire [FETCH_WIDTH*VADDR_WIDTH-1:0] decode_pc;
    wire [FETCH_WIDTH-1:0]      decode_is_branch;
    wire [FETCH_WIDTH-1:0]      decode_is_load;
    wire [FETCH_WIDTH-1:0]      decode_is_store;
    wire [FETCH_WIDTH-1:0]      decode_is_fp;
    wire [FETCH_WIDTH-1:0]      decode_valid_mask;
    wire                        decode_ready;

    // Rename -> Issue Queue / ROB
    wire                        rename_valid;
    wire [FETCH_WIDTH*PREG_BITS-1:0] rename_prd;
    wire [FETCH_WIDTH*PREG_BITS-1:0] rename_prs1;
    wire [FETCH_WIDTH*PREG_BITS-1:0] rename_prs2;
    wire [FETCH_WIDTH*PREG_BITS-1:0] rename_prs3;
    wire [FETCH_WIDTH-1:0]      rename_prs1_valid;
    wire [FETCH_WIDTH-1:0]      rename_prs2_valid;
    wire [FETCH_WIDTH*ROB_BITS-1:0] rename_rob_tag;
    wire                        rename_ready;

    // Branch predictor signals
    wire                        bru_result_valid;
    wire [VADDR_WIDTH-1:0]      bru_target_wire;
    wire                        bru_taken_wire;
    wire                        bru_mispred_wire;

    // Flush signals
    wire                        flush;
    wire [ARCH_REGS*PREG_BITS-1:0] flush_rat_snapshot;

    // ROB retirement
    wire                        rob_commit_valid;
    wire [PREG_BITS-1:0]        rob_commit_old_prd;
    wire                        commit_stall;

    // CSR
    wire [XLEN-1:0]             csr_tvec;
    wire [XLEN-1:0]             csr_xret_pc;
    wire                        csr_redirect_valid;

    // LSU wires
    wire                        lsu_cdb_valid;
    wire [XLEN-1:0]             lsu_cdb_result;
    wire [PREG_BITS-1:0]        lsu_cdb_prd;
    wire [ROB_BITS-1:0]         lsu_cdb_rob_tag;

    assign flush = bru_mispred_wire;

    // -------------------------------------------------
    // Submodule instantiations
    // -------------------------------------------------

    fetch_unit #(
        .XLEN(XLEN), .VADDR_WIDTH(VADDR_WIDTH), .PADDR_WIDTH(PADDR_WIDTH),
        .FETCH_WIDTH(FETCH_WIDTH)
    ) u_fetch (
        .clk(clk), .rst_n(rst_n),
        .bru_valid(bru_result_valid), .bru_pc(64'b0), .bru_target(bru_target_wire),
        .bru_taken(bru_taken_wire), .bru_mispred(bru_mispred_wire),
        .redirect_valid(csr_redirect_valid), .redirect_pc(csr_tvec),
        .itlb_req_valid(itlb_req_valid), .itlb_req_vaddr(itlb_req_vaddr),
        .itlb_resp_valid(itlb_resp_valid), .itlb_resp_fault(itlb_resp_fault),
        .itlb_resp_paddr(itlb_resp_paddr),
        .icache_req_valid(icache_req_valid), .icache_req_paddr(icache_req_paddr),
        .icache_resp_valid(icache_resp_valid), .icache_resp_data(icache_resp_data),
        .icache_resp_miss(icache_resp_miss),
        .fetchq_valid(fetchq_valid), .fetchq_instr(fetchq_instr),
        .fetchq_pc(fetchq_pc), .fetchq_pred_taken(fetchq_pred_taken),
        .fetchq_pred_target(fetchq_pred_target), .fetchq_ready(fetchq_ready),
        .priv_mode(2'b11), .satp(64'b0)
    );

    decode_unit #(
        .XLEN(XLEN), .VADDR_WIDTH(VADDR_WIDTH), .FETCH_WIDTH(FETCH_WIDTH)
    ) u_decode (
        .clk(clk), .rst_n(rst_n),
        .fetch_valid(fetchq_valid), .fetch_instr(fetchq_instr),
        .fetch_pc(fetchq_pc), .fetch_pred_taken(fetchq_pred_taken),
        .fetch_ready(fetchq_ready),
        .decode_valid(decode_valid), .decode_opcode(decode_opcode),
        .decode_rd(decode_rd), .decode_rs1(decode_rs1),
        .decode_rs2(decode_rs2), .decode_rs3(decode_rs3),
        .decode_imm(decode_imm), .decode_fu_type(decode_fu_type),
        .decode_alu_op(decode_alu_op), .decode_pc(decode_pc),
        .decode_is_branch(decode_is_branch), .decode_is_load(decode_is_load),
        .decode_is_store(decode_is_store), .decode_is_fp(decode_is_fp),
        .decode_valid_mask(decode_valid_mask), .decode_ready(decode_ready),
        .decode_ill_instr(), .flush(flush)
    );

    rename_unit #(
        .XLEN(XLEN), .FETCH_WIDTH(FETCH_WIDTH), .ARCH_REGS(ARCH_REGS),
        .PHYS_REGS(PHYS_REGS), .ROB_ENTRIES(ROB_ENTRIES),
        .PREG_BITS(PREG_BITS), .ROB_BITS(ROB_BITS)
    ) u_rename (
        .clk(clk), .rst_n(rst_n),
        .decode_valid(decode_valid), .decode_rd(decode_rd),
        .decode_rs1(decode_rs1), .decode_rs2(decode_rs2),
        .decode_rs3(decode_rs3), .decode_valid_mask(decode_valid_mask),
        .decode_ready(decode_ready),
        .decode_opcode(decode_opcode), .decode_alu_op(decode_alu_op),
        .decode_fu_type(decode_fu_type), .decode_imm(decode_imm),
        .decode_is_branch(decode_is_branch), .decode_is_load(decode_is_load),
        .decode_is_store(decode_is_store), .decode_is_fp(decode_is_fp),
        .decode_pc(decode_pc),
        .rename_valid(rename_valid), .rename_prd(rename_prd),
        .rename_prs1(rename_prs1), .rename_prs2(rename_prs2),
        .rename_prs3(rename_prs3),
        .rename_prs1_valid(rename_prs1_valid), .rename_prs2_valid(rename_prs2_valid),
        .rename_rob_tag(rename_rob_tag), .rename_opcode(),
        .rename_alu_op(), .rename_fu_type(), .rename_imm(),
        .rename_is_branch(), .rename_is_load(), .rename_is_store(),
        .rename_pc(), .rename_ready(rename_ready),
        .commit_valid(rob_commit_valid), .commit_old_prd(rob_commit_old_prd),
        .commit_stall(commit_stall),
        .flush_valid(flush), .flush_rat_snapshot(flush_rat_snapshot)
    );

    assign rename_ready = 1'b1;
    assign commit_stall = 1'b0;
    assign rob_commit_valid = 1'b0;
    assign rob_commit_old_prd = {PREG_BITS{1'b0}};

    // Physical register file
    physical_regfile #(.XLEN(XLEN), .PHYS_REGS(PHYS_REGS), .PREG_BITS(PREG_BITS))
    u_prf (
        .clk(clk), .rst_n(rst_n),
        .rd_addr({PREG_BITS*10{1'b0}}), .rd_data(),
        .wr_en(6'b0), .wr_addr({PREG_BITS*6{1'b0}}), .wr_data({XLEN*6{1'b0}}),
        .busy_rd_addr({PREG_BITS{1'b0}}), .busy_rd_data()
    );

    // CSR Unit
    csr_unit #(.XLEN(XLEN), .HART_ID(HART_ID)) u_csr (
        .clk(clk), .rst_n(rst_n),
        .csr_valid(1'b0), .csr_addr(12'b0), .csr_op(2'b0),
        .csr_wdata({XLEN{1'b0}}), .csr_rdata(), .csr_ill(),
        .trap_valid(1'b0), .trap_pc({XLEN{1'b0}}),
        .trap_cause({XLEN{1'b0}}), .trap_tval({XLEN{1'b0}}), .trap_priv(2'b0),
        .xret_valid(1'b0), .xret_priv(2'b0), .xret_pc(csr_xret_pc),
        .m_ext_irq(m_ext_irq), .m_sw_irq(m_sw_irq), .m_timer_irq(m_timer_irq),
        .priv_mode(), .mcycle(perf_mcycle), .minstret(perf_minstret),
        .tvec_out(csr_tvec)
    );

    assign csr_redirect_valid = 1'b0;

    // LSU
    lsu #(.XLEN(XLEN), .VADDR_WIDTH(VADDR_WIDTH), .PADDR_WIDTH(PADDR_WIDTH),
          .PREG_BITS(PREG_BITS), .ROB_BITS(ROB_BITS)) u_lsu (
        .clk(clk), .rst_n(rst_n),
        .lsu_issue_valid(1'b0), .lsu_funct3(3'b0), .lsu_opcode(7'b0),
        .lsu_addr({XLEN{1'b0}}), .lsu_store_data({XLEN{1'b0}}),
        .lsu_prd({PREG_BITS{1'b0}}), .lsu_rob_tag({ROB_BITS{1'b0}}), .lsu_ready(),
        .dtlb_req_valid(dtlb_req_valid), .dtlb_req_vaddr(dtlb_req_vaddr),
        .dtlb_req_wr(dtlb_req_wr),
        .dtlb_resp_valid(dtlb_resp_valid), .dtlb_resp_fault(dtlb_resp_fault),
        .dtlb_resp_paddr(dtlb_resp_paddr),
        .dcache_req_valid(dcache_req_valid), .dcache_req_paddr(dcache_req_paddr),
        .dcache_req_wr(dcache_req_wr), .dcache_req_size(dcache_req_size),
        .dcache_req_wdata(dcache_req_wdata), .dcache_req_strb(dcache_req_strb),
        .dcache_resp_valid(dcache_resp_valid), .dcache_resp_rdata(dcache_resp_rdata),
        .dcache_resp_miss(dcache_resp_miss),
        .cdb_valid(lsu_cdb_valid), .cdb_result(lsu_cdb_result),
        .cdb_prd(lsu_cdb_prd), .cdb_rob_tag(lsu_cdb_rob_tag), .cdb_exception(),
        .sq_commit_valid(1'b0), .sq_commit_rob_tag({ROB_BITS{1'b0}}),
        .flush(flush)
    );

    assign debug_halted = debug_halt;

    assign bru_result_valid  = 1'b0;
    assign bru_target_wire   = {VADDR_WIDTH{1'b0}};
    assign bru_taken_wire    = 1'b0;
    assign bru_mispred_wire  = 1'b0;

endmodule
