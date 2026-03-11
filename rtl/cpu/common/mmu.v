// ============================================================
// mmu.v - Memory Management Unit: SV39 Page Table Walker
// Supports 3-level page table walk (Sv39: 39-bit virtual)
// ============================================================
`timescale 1ns/1ps

module mmu #(
    parameter XLEN        = 64,
    parameter VADDR_WIDTH = 39,
    parameter PADDR_WIDTH = 56
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // ITLB miss interface
    input  wire                     itlb_miss_valid,
    input  wire [VADDR_WIDTH-1:0]   itlb_miss_vaddr,
    output reg                      itlb_fill_valid,
    output reg  [PADDR_WIDTH-1:0]   itlb_fill_paddr,
    output reg  [7:0]               itlb_fill_perm,
    output reg                      itlb_fill_fault,

    // DTLB miss interface
    input  wire                     dtlb_miss_valid,
    input  wire [VADDR_WIDTH-1:0]   dtlb_miss_vaddr,
    input  wire                     dtlb_miss_wr,
    output reg                      dtlb_fill_valid,
    output reg  [PADDR_WIDTH-1:0]   dtlb_fill_paddr,
    output reg  [7:0]               dtlb_fill_perm,
    output reg                      dtlb_fill_fault,

    // Memory interface for page table reads (AXI4-lite)
    output reg  [PADDR_WIDTH-1:0]   mem_req_addr,
    output reg                      mem_req_valid,
    input  wire [XLEN-1:0]          mem_resp_data,
    input  wire                     mem_resp_valid,
    input  wire                     mem_resp_err,

    // SATP register (from CSR unit)
    input  wire [XLEN-1:0]          satp,

    // Flush TLBs
    input  wire                     sfence_vma
);

    // SV39 page table entry structure
    // [63:54] reserved, [53:10] PPN[2:0], [9:8] RSW, [7:0] DAGUXWRV
    localparam PTE_V = 0; // valid
    localparam PTE_R = 1; // readable
    localparam PTE_W = 2; // writable
    localparam PTE_X = 3; // executable
    localparam PTE_U = 4; // user
    localparam PTE_G = 5; // global
    localparam PTE_A = 6; // accessed
    localparam PTE_D = 7; // dirty

    // Sv39 walk: 3 levels, 9-bit VPN per level
    // VA[38:30]=VPN[2], VA[29:21]=VPN[1], VA[20:12]=VPN[0], VA[11:0]=offset

    localparam ST_IDLE  = 3'd0;
    localparam ST_L2    = 3'd1;
    localparam ST_L1    = 3'd2;
    localparam ST_L0    = 3'd3;
    localparam ST_FILL  = 3'd4;
    localparam ST_FAULT = 3'd5;

    reg [2:0]             state;
    reg [VADDR_WIDTH-1:0] vaddr_latch;
    reg                   is_itlb;
    reg                   is_write;
    reg [PADDR_WIDTH-1:0] pt_base;  // current page table base PA
    reg [XLEN-1:0]        pte;
    reg [1:0]             level;

    // Extract PPN from PTE: bits[53:10]
    wire [43:0]  pte_ppn   = pte[53:10];
    wire [8:0]   vpn2      = vaddr_latch[38:30];
    wire [8:0]   vpn1      = vaddr_latch[29:21];
    wire [8:0]   vpn0      = vaddr_latch[20:12];
    wire [11:0]  voffset   = vaddr_latch[11:0];

    // SATP fields: MODE[63:60], ASID[59:44], PPN[43:0]
    wire [43:0]  satp_ppn  = satp[43:0];
    wire [3:0]   satp_mode = satp[63:60];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state           <= ST_IDLE;
            itlb_fill_valid <= 1'b0;
            dtlb_fill_valid <= 1'b0;
            mem_req_valid   <= 1'b0;
        end else begin
            itlb_fill_valid <= 1'b0;
            dtlb_fill_valid <= 1'b0;
            mem_req_valid   <= 1'b0;

            case (state)
                ST_IDLE: begin
                    if (itlb_miss_valid || dtlb_miss_valid) begin
                        is_itlb     <= itlb_miss_valid;
                        is_write    <= dtlb_miss_valid && dtlb_miss_wr;
                        vaddr_latch <= itlb_miss_valid ? itlb_miss_vaddr : dtlb_miss_vaddr;
                        pt_base     <= {satp_ppn, 12'b0};
                        level       <= 2'd2;
                        // Issue L2 table read
                        mem_req_addr  <= {satp_ppn, 12'b0} + ({35'b0, (itlb_miss_valid ? itlb_miss_vaddr[38:30] : dtlb_miss_vaddr[38:30])} << 3);
                        mem_req_valid <= (satp_mode == 4'h8); // Sv39 enabled
                        state         <= (satp_mode == 4'h8) ? ST_L2 : ST_FILL;
                        if (satp_mode != 4'h8) begin
                            // Bare mode: paddr = vaddr
                            itlb_fill_paddr <= itlb_miss_vaddr[PADDR_WIDTH-1:0];
                            itlb_fill_perm  <= 8'hFF;
                            itlb_fill_fault <= 1'b0;
                            dtlb_fill_paddr <= dtlb_miss_vaddr[PADDR_WIDTH-1:0];
                            dtlb_fill_perm  <= 8'hFF;
                            dtlb_fill_fault <= 1'b0;
                            itlb_fill_valid <= itlb_miss_valid;
                            dtlb_fill_valid <= dtlb_miss_valid;
                        end
                    end
                end

                ST_L2, ST_L1, ST_L0: begin
                    if (mem_resp_valid) begin
                        pte <= mem_resp_data;
                        if (mem_resp_err || !mem_resp_data[PTE_V]) begin
                            state <= ST_FAULT;
                        end else if (mem_resp_data[PTE_R] || mem_resp_data[PTE_X]) begin
                            // Leaf PTE found
                            state <= ST_FILL;
                            pte   <= mem_resp_data;
                        end else begin
                            // Non-leaf: descend
                            pt_base  <= {mem_resp_data[53:10], 12'b0};
                            level    <= level - 1;
                            if (level == 2'd2) begin
                                mem_req_addr  <= {mem_resp_data[53:10], 12'b0} + ({35'b0, vpn1} << 3);
                                state <= ST_L1;
                            end else if (level == 2'd1) begin
                                mem_req_addr  <= {mem_resp_data[53:10], 12'b0} + ({35'b0, vpn0} << 3);
                                state <= ST_L0;
                            end else begin
                                state <= ST_FAULT;
                            end
                            mem_req_valid <= 1'b1;
                        end
                    end
                end

                ST_FILL: begin
                    // Check permission
                    if (is_write && !pte[PTE_W]) begin
                        state <= ST_FAULT;
                    end else if (!is_itlb && !pte[PTE_R]) begin
                        state <= ST_FAULT;
                    end else if (is_itlb && !pte[PTE_X]) begin
                        state <= ST_FAULT;
                    end else begin
                        // Fill TLB
                        if (is_itlb) begin
                            itlb_fill_paddr <= {pte[53:10], voffset};
                            itlb_fill_perm  <= pte[7:0];
                            itlb_fill_fault <= 1'b0;
                            itlb_fill_valid <= 1'b1;
                        end else begin
                            dtlb_fill_paddr <= {pte[53:10], voffset};
                            dtlb_fill_perm  <= pte[7:0];
                            dtlb_fill_fault <= 1'b0;
                            dtlb_fill_valid <= 1'b1;
                        end
                        state <= ST_IDLE;
                    end
                end

                ST_FAULT: begin
                    if (is_itlb) begin
                        itlb_fill_paddr <= {PADDR_WIDTH{1'b0}};
                        itlb_fill_perm  <= 8'b0;
                        itlb_fill_fault <= 1'b1;
                        itlb_fill_valid <= 1'b1;
                    end else begin
                        dtlb_fill_paddr <= {PADDR_WIDTH{1'b0}};
                        dtlb_fill_perm  <= 8'b0;
                        dtlb_fill_fault <= 1'b1;
                        dtlb_fill_valid <= 1'b1;
                    end
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
