// ============================================================
// l2_directory.v - Cache Coherence Directory for L2
// Tracks L1 sharers for each L2 line, supports MESI protocol
// ============================================================
`timescale 1ns/1ps

module l2_directory #(
    parameter SETS       = 1024,
    parameter WAYS       = 8,
    parameter INDEX_BITS = 10,
    parameter N_L1       = 4    // 4 L1 caches (C0I,C0D,C1I,C1D)
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Directory access
    input  wire                     acc_en,
    input  wire [INDEX_BITS-1:0]    acc_idx,
    input  wire [$clog2(WAYS)-1:0]  acc_way,
    input  wire [1:0]               acc_cmd,   // 00=RD, 01=INV, 10=UPD_SHARED, 11=UPD_EXCL
    input  wire [$clog2(N_L1)-1:0]  acc_src,   // requesting L1
    output reg  [N_L1-1:0]          dir_sharers,
    output reg  [1:0]               dir_state,  // MESI

    // Invalidation broadcast
    output reg  [N_L1-1:0]          inv_mask,
    output reg                      inv_valid,
    input  wire [N_L1-1:0]          inv_ack
);

    reg [N_L1-1:0] sharers [0:SETS-1][0:WAYS-1];
    reg [1:0]      state   [0:SETS-1][0:WAYS-1]; // MESI

    integer i, j;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            inv_valid <= 0;
            for (i=0;i<SETS;i=i+1) for(j=0;j<WAYS;j=j+1) begin
                sharers[i][j]<=0; state[i][j]<=2'b00;
            end
        end else begin
            inv_valid <= 0;
            if (acc_en) begin
                dir_sharers <= sharers[acc_idx][acc_way];
                dir_state   <= state  [acc_idx][acc_way];
                case (acc_cmd)
                    2'b00: begin // Read (Shared)
                        sharers[acc_idx][acc_way] <= sharers[acc_idx][acc_way] | (1 << acc_src);
                        if (state[acc_idx][acc_way] == 2'b10) // E->S on new sharer
                            state[acc_idx][acc_way] <= 2'b01;
                        else if (state[acc_idx][acc_way] == 2'b00)
                            state[acc_idx][acc_way] <= 2'b01;
                    end
                    2'b01: begin // Invalidate
                        inv_mask  <= sharers[acc_idx][acc_way] & ~(1 << acc_src);
                        inv_valid <= |(sharers[acc_idx][acc_way] & ~(1 << acc_src));
                        sharers[acc_idx][acc_way] <= (1 << acc_src);
                        state[acc_idx][acc_way]   <= 2'b11; // M
                    end
                    2'b10: begin // Update sharer
                        sharers[acc_idx][acc_way] <= sharers[acc_idx][acc_way] | (1 << acc_src);
                        state[acc_idx][acc_way]   <= 2'b01; // S
                    end
                    2'b11: begin // Exclusive
                        inv_mask  <= sharers[acc_idx][acc_way];
                        inv_valid <= |sharers[acc_idx][acc_way];
                        sharers[acc_idx][acc_way] <= (1 << acc_src);
                        state[acc_idx][acc_way]   <= 2'b10; // E
                    end
                endcase
            end
        end
    end

endmodule
