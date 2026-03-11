// ============================================================
// shader_core.v - SIMT Shader Core (32-wide warp, 8 warps)
// SIMD execution of vertex/fragment shaders
// ============================================================
`timescale 1ns/1ps
module shader_core #(
    parameter SIMD_WIDTH = 32,  // threads per warp
    parameter N_WARPS    = 8,
    parameter REG_FILE   = 64,  // registers per thread
    parameter XLEN       = 32
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         dispatch_valid,
    input  wire [5:0]                   dispatch_warp_id,
    input  wire [31:0]                  dispatch_pc,
    input  wire [SIMD_WIDTH-1:0]        dispatch_mask,    // active thread mask
    output wire                         dispatch_ready,
    input  wire [SIMD_WIDTH*XLEN-1:0]   dispatch_scalar,  // scalar uniform data
    output reg                          retire_valid,
    output reg  [5:0]                   retire_warp_id,
    output reg  [SIMD_WIDTH-1:0]        retire_mask,
    // Instruction fetch from shader instruction cache
    output reg  [31:0]                  ifetch_pc,
    output reg                          ifetch_valid,
    input  wire [127:0]                 ifetch_data,  // 4 instructions
    input  wire                         ifetch_valid_resp,
    // SIMD memory interface
    output reg  [SIMD_WIDTH-1:0]        mem_req_valid,
    output reg  [SIMD_WIDTH*32-1:0]     mem_req_addr,
    output reg  [SIMD_WIDTH-1:0]        mem_req_wr,
    output reg  [SIMD_WIDTH*XLEN-1:0]   mem_req_data,
    input  wire [SIMD_WIDTH-1:0]        mem_resp_valid,
    input  wire [SIMD_WIDTH*XLEN-1:0]   mem_resp_data
);
    // Warp PC registers
    reg [31:0]  warp_pc   [0:N_WARPS-1];
    reg [SIMD_WIDTH-1:0] warp_mask[0:N_WARPS-1];
    reg [N_WARPS-1:0]   warp_active;
    reg [N_WARPS-1:0]   warp_stall;

    // Vector register file: [warp][reg][thread]
    reg [XLEN-1:0]  vrf [0:N_WARPS-1][0:REG_FILE-1][0:SIMD_WIDTH-1];

    // Warp scheduler (round-robin)
    reg [$clog2(N_WARPS)-1:0] sched_ptr;
    reg [$clog2(N_WARPS)-1:0] active_warp;
    reg                        exec_valid;

    integer i, t;

    // Dispatch new warp
    assign dispatch_ready = !warp_active[dispatch_warp_id[2:0]];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            warp_active <= {N_WARPS{1'b0}};
            warp_stall  <= {N_WARPS{1'b0}};
            sched_ptr   <= {$clog2(N_WARPS){1'b0}};
            exec_valid  <= 1'b0;
            retire_valid<= 1'b0;
            ifetch_valid<= 1'b0;
            mem_req_valid <= {SIMD_WIDTH{1'b0}};
        end else begin
            retire_valid  <= 1'b0;
            ifetch_valid  <= 1'b0;
            mem_req_valid <= {SIMD_WIDTH{1'b0}};

            if (dispatch_valid && dispatch_ready) begin
                warp_pc  [dispatch_warp_id[2:0]] <= dispatch_pc;
                warp_mask[dispatch_warp_id[2:0]] <= dispatch_mask;
                warp_active[dispatch_warp_id[2:0]] <= 1'b1;
            end

            // Schedule: pick next active non-stalled warp
            for (i = 0; i < N_WARPS; i = i + 1) begin
                automatic integer w = (sched_ptr + i) % N_WARPS;
                if (warp_active[w] && !warp_stall[w]) begin
                    active_warp <= w[$clog2(N_WARPS)-1:0];
                    exec_valid  <= 1'b1;
                    sched_ptr   <= (w + 1) % N_WARPS;
                    i = N_WARPS; // break
                end
            end

            // Fetch instruction for active warp
            if (exec_valid) begin
                ifetch_valid <= 1'b1;
                ifetch_pc    <= warp_pc[active_warp];
            end

            // Execute (simplified ALU for active threads)
            if (ifetch_valid_resp) begin
                automatic reg [31:0] instr = ifetch_data[31:0];
                automatic reg [4:0] rd = instr[11:7];
                automatic reg [4:0] rs1= instr[19:15];
                automatic reg [4:0] rs2= instr[24:20];
                // Execute on all active threads
                for (t = 0; t < SIMD_WIDTH; t = t + 1) begin
                    if (warp_mask[active_warp][t]) begin
                        case (instr[6:0])
                            7'b0110011: vrf[active_warp][rd][t] <=
                                vrf[active_warp][rs1][t] + vrf[active_warp][rs2][t]; // ADD
                            7'b0100011: begin // STORE
                                mem_req_valid[t] <= 1'b1;
                                mem_req_addr [t*32 +: 32] <= vrf[active_warp][rs1][t] + {{20{instr[31]}},instr[31:25],instr[11:7]};
                                mem_req_wr   [t] <= 1'b1;
                                mem_req_data [t*XLEN +: XLEN] <= vrf[active_warp][rs2][t];
                            end
                            default: begin end
                        endcase
                    end
                end
                warp_pc[active_warp] <= warp_pc[active_warp] + 4;
                // Simple retire after 1 instruction (real: when warp completes)
                if (warp_pc[active_warp] >= 32'hFFFF0000) begin
                    warp_active[active_warp] <= 1'b0;
                    retire_valid   <= 1'b1;
                    retire_warp_id <= {3'b0, active_warp};
                    retire_mask    <= warp_mask[active_warp];
                end
            end
        end
    end
endmodule
