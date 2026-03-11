// ============================================================
// csr_unit.v - Control and Status Register Unit
// Implements RV64 Zicsr: Machine, Supervisor, User CSRs
// ============================================================
`timescale 1ns/1ps

module csr_unit #(
    parameter XLEN = 64,
    parameter HART_ID = 0
)(
    input  wire             clk,
    input  wire             rst_n,

    // CSR instruction interface
    input  wire             csr_valid,
    input  wire [11:0]      csr_addr,
    input  wire [1:0]       csr_op,     // 00=READ, 01=WRITE, 10=SET, 11=CLEAR
    input  wire [XLEN-1:0]  csr_wdata,
    output reg  [XLEN-1:0]  csr_rdata,
    output reg              csr_ill,    // illegal CSR access

    // Trap interface
    input  wire             trap_valid,
    input  wire [XLEN-1:0]  trap_pc,
    input  wire [XLEN-1:0]  trap_cause,
    input  wire [XLEN-1:0]  trap_tval,
    input  wire [1:0]       trap_priv,  // target privilege level

    // Exception return
    input  wire             xret_valid,
    input  wire [1:0]       xret_priv,  // MRET=11, SRET=01, URET=00
    output reg  [XLEN-1:0]  xret_pc,

    // Interrupt inputs
    input  wire             m_ext_irq,
    input  wire             m_sw_irq,
    input  wire             m_timer_irq,

    // Current privilege mode output
    output reg  [1:0]       priv_mode,

    // Performance counters
    output reg  [63:0]      mcycle,
    output reg  [63:0]      minstret,

    // Trap vector
    output reg  [XLEN-1:0]  tvec_out
);

    // Machine-level CSRs
    reg [XLEN-1:0]  mstatus, misa, medeleg, mideleg;
    reg [XLEN-1:0]  mie, mtvec, mcounteren;
    reg [XLEN-1:0]  mscratch, mepc, mcause, mtval, mip;
    reg [XLEN-1:0]  pmpcfg0, pmpaddr0;

    // Supervisor CSRs
    reg [XLEN-1:0]  sstatus, sie, stvec, scounteren;
    reg [XLEN-1:0]  sscratch, sepc, scause, stval, sip, satp;

    // misa: RV64IMAFDC
    wire [XLEN-1:0] misa_val = {2'b10, {(XLEN-28){1'b0}}, 26'b00000001000100101100000101};

    // mstatus field extraction
    wire mstatus_mie  = mstatus[3];
    wire mstatus_mpie = mstatus[7];
    wire [1:0] mstatus_mpp = mstatus[12:11];
    wire mstatus_sie  = mstatus[1];
    wire mstatus_spie = mstatus[5];
    wire mstatus_spp  = mstatus[8];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priv_mode  <= 2'b11; // Machine mode
            mstatus    <= 64'h0000000A00000000; // SXL=MXL=2 (64-bit)
            misa       <= misa_val;
            medeleg    <= 64'h0;
            mideleg    <= 64'h0;
            mie        <= 64'h0;
            mtvec      <= 64'h80000000;
            mepc       <= 64'h0;
            mcause     <= 64'h0;
            mtval      <= 64'h0;
            mip        <= 64'h0;
            sepc       <= 64'h0;
            scause     <= 64'h0;
            stvec      <= 64'h0;
            satp       <= 64'h0;
            mcycle     <= 64'h0;
            minstret   <= 64'h0;
            csr_ill    <= 1'b0;
        end else begin
            // Cycle counter
            mcycle   <= mcycle + 1;
            if (csr_valid) minstret <= minstret + 1;

            // Update mip from interrupt inputs
            mip[11] <= m_ext_irq;
            mip[3]  <= m_sw_irq;
            mip[7]  <= m_timer_irq;

            csr_ill <= 1'b0;

            // Trap handling
            if (trap_valid) begin
                if (trap_priv == 2'b11) begin // M-mode trap
                    mepc   <= trap_pc;
                    mcause <= trap_cause;
                    mtval  <= trap_tval;
                    mstatus[7]    <= mstatus[3]; // MPIE = MIE
                    mstatus[3]    <= 1'b0;        // MIE = 0
                    mstatus[12:11]<= priv_mode;   // MPP = current priv
                    priv_mode     <= 2'b11;
                    tvec_out      <= mtvec;
                end else begin // S-mode trap
                    sepc  <= trap_pc;
                    scause<= trap_cause;
                    stval <= trap_tval;
                    mstatus[5]    <= mstatus[1];
                    mstatus[1]    <= 1'b0;
                    mstatus[8]    <= priv_mode[0];
                    priv_mode     <= 2'b01;
                    tvec_out      <= stvec;
                end
            end

            // Exception return
            if (xret_valid) begin
                if (xret_priv == 2'b11) begin // MRET
                    priv_mode   <= mstatus_mpp;
                    mstatus[3]  <= mstatus[7];  // MIE = MPIE
                    mstatus[7]  <= 1'b1;         // MPIE = 1
                    mstatus[12:11] <= 2'b00;     // MPP = U
                    xret_pc     <= mepc;
                end else begin // SRET
                    priv_mode   <= {1'b0, mstatus_spp};
                    mstatus[1]  <= mstatus[5];
                    mstatus[5]  <= 1'b1;
                    mstatus[8]  <= 1'b0;
                    xret_pc     <= sepc;
                end
            end

            // CSR read/write
            if (csr_valid) begin
                // Read
                case (csr_addr)
                    12'h300: csr_rdata <= mstatus;
                    12'h301: csr_rdata <= misa_val;
                    12'h302: csr_rdata <= medeleg;
                    12'h303: csr_rdata <= mideleg;
                    12'h304: csr_rdata <= mie;
                    12'h305: csr_rdata <= mtvec;
                    12'h340: csr_rdata <= mscratch;
                    12'h341: csr_rdata <= mepc;
                    12'h342: csr_rdata <= mcause;
                    12'h343: csr_rdata <= mtval;
                    12'h344: csr_rdata <= mip;
                    12'hF14: csr_rdata <= HART_ID;
                    12'hB00: csr_rdata <= mcycle;
                    12'hB02: csr_rdata <= minstret;
                    12'h100: csr_rdata <= sstatus;
                    12'h104: csr_rdata <= sie;
                    12'h105: csr_rdata <= stvec;
                    12'h140: csr_rdata <= sscratch;
                    12'h141: csr_rdata <= sepc;
                    12'h142: csr_rdata <= scause;
                    12'h143: csr_rdata <= stval;
                    12'h144: csr_rdata <= sip;
                    12'h180: csr_rdata <= satp;
                    default: begin csr_rdata <= {XLEN{1'b0}}; csr_ill <= 1'b1; end
                endcase

                // Write/set/clear
                if (csr_op != 2'b00) begin
                    reg [XLEN-1:0] new_val;
                    case (csr_op)
                        2'b01: new_val = csr_wdata;
                        2'b10: new_val = csr_rdata | csr_wdata;
                        2'b11: new_val = csr_rdata & ~csr_wdata;
                        default: new_val = csr_wdata;
                    endcase
                    case (csr_addr)
                        12'h300: mstatus  <= new_val;
                        12'h302: medeleg  <= new_val;
                        12'h303: mideleg  <= new_val;
                        12'h304: mie      <= new_val;
                        12'h305: mtvec    <= new_val;
                        12'h340: mscratch <= new_val;
                        12'h341: mepc     <= new_val;
                        12'h105: stvec    <= new_val;
                        12'h140: sscratch <= new_val;
                        12'h180: satp     <= new_val;
                    endcase
                end
            end
        end
    end

endmodule
