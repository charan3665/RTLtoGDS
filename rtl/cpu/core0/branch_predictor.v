// ============================================================
// branch_predictor.v - Hybrid TAGE + GShare Branch Predictor
// TAGE: 4 tagged components + bimodal base
// ============================================================
`timescale 1ns/1ps

module branch_predictor #(
    parameter VADDR_WIDTH = 39,
    parameter BIMODAL_SIZE= 4096,   // 2^12
    parameter GHR_LENGTH  = 64,     // global history register bits
    parameter TAGE_TABLES = 4,
    parameter TAGE_ENTRIES= 1024,   // entries per TAGE table
    parameter TAGE_TAG_BITS= 9
)(
    input  wire                     clk,
    input  wire                     rst_n,

    // Prediction request
    input  wire                     pred_req_valid,
    input  wire [VADDR_WIDTH-1:0]   pred_req_pc,
    output reg                      pred_taken,
    output reg  [VADDR_WIDTH-1:0]   pred_target,
    output reg  [2:0]               pred_provider,  // which table provided

    // Update on branch resolution
    input  wire                     upd_valid,
    input  wire [VADDR_WIDTH-1:0]   upd_pc,
    input  wire                     upd_taken,
    input  wire [VADDR_WIDTH-1:0]   upd_target,
    input  wire [2:0]               upd_provider,
    input  wire                     upd_mispred
);

    // Global History Register
    reg [GHR_LENGTH-1:0] ghr;

    // Bimodal table (2-bit saturating counters)
    reg [1:0] bimodal [0:BIMODAL_SIZE-1];

    // TAGE tables: tag, 3-bit counter, useful bit
    reg [TAGE_TAG_BITS-1:0] tage_tag    [0:TAGE_TABLES-1][0:TAGE_ENTRIES-1];
    reg [2:0]               tage_ctr    [0:TAGE_TABLES-1][0:TAGE_ENTRIES-1];
    reg                     tage_useful [0:TAGE_TABLES-1][0:TAGE_ENTRIES-1];

    // History lengths per table (geometric series)
    integer hist_len [0:TAGE_TABLES-1];
    initial begin
        hist_len[0] =  5;
        hist_len[1] = 11;
        hist_len[2] = 25;
        hist_len[3] = 56;
    end

    // Index functions
    function [$clog2(TAGE_ENTRIES)-1:0] tage_index;
        input [VADDR_WIDTH-1:0] pc;
        input [GHR_LENGTH-1:0]  h;
        input integer           len;
        begin
            tage_index = (pc[$clog2(TAGE_ENTRIES)+1:2] ^ h[$clog2(TAGE_ENTRIES)-1:0]);
        end
    endfunction

    function [TAGE_TAG_BITS-1:0] tage_compute_tag;
        input [VADDR_WIDTH-1:0] pc;
        input [GHR_LENGTH-1:0]  h;
        begin
            tage_compute_tag = pc[TAGE_TAG_BITS+1:2] ^ h[TAGE_TAG_BITS-1:0];
        end
    endfunction

    integer t;
    reg [$clog2(TAGE_ENTRIES)-1:0] tidx [0:TAGE_TABLES-1];
    reg [TAGE_TAG_BITS-1:0]        ttag [0:TAGE_TABLES-1];
    reg [TAGE_TABLES-1:0]          thit;

    always @(*) begin
        for (t = 0; t < TAGE_TABLES; t = t + 1) begin
            tidx[t] = tage_index(pred_req_pc, ghr, hist_len[t]);
            ttag[t] = tage_compute_tag(pred_req_pc, ghr);
            thit[t] = (tage_tag[t][tidx[t]] == ttag[t]);
        end
    end

    // Prediction logic
    always @(*) begin
        pred_taken    = bimodal[pred_req_pc[$clog2(BIMODAL_SIZE)+1:2]][1];
        pred_target   = pred_req_pc + 4;
        pred_provider = 3'd0; // bimodal
        // Check TAGE tables from longest history first
        for (t = TAGE_TABLES-1; t >= 0; t = t - 1) begin
            if (thit[t]) begin
                pred_taken    = tage_ctr[t][tidx[t]][2];
                pred_provider = t + 1;
            end
        end
    end

    // Update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ghr <= {GHR_LENGTH{1'b0}};
        end else if (upd_valid) begin
            // Update GHR
            ghr <= {ghr[GHR_LENGTH-2:0], upd_taken};

            // Update bimodal
            begin
                automatic reg [$clog2(BIMODAL_SIZE)-1:0] bidx = upd_pc[$clog2(BIMODAL_SIZE)+1:2];
                if (upd_taken)
                    bimodal[bidx] <= (bimodal[bidx] == 2'b11) ? 2'b11 : bimodal[bidx] + 1;
                else
                    bimodal[bidx] <= (bimodal[bidx] == 2'b00) ? 2'b00 : bimodal[bidx] - 1;
            end

            // Update providing TAGE table
            if (upd_provider > 0) begin
                automatic integer pt = upd_provider - 1;
                automatic reg [$clog2(TAGE_ENTRIES)-1:0] pi = tage_index(upd_pc, {ghr[GHR_LENGTH-2:0], upd_taken}, hist_len[pt]);
                if (upd_taken)
                    tage_ctr[pt][pi] <= (tage_ctr[pt][pi] == 3'b111) ? 3'b111 : tage_ctr[pt][pi] + 1;
                else
                    tage_ctr[pt][pi] <= (tage_ctr[pt][pi] == 3'b000) ? 3'b000 : tage_ctr[pt][pi] - 1;

                // Useful bit update
                if (upd_mispred)
                    tage_useful[pt][pi] <= 1'b0;
            end
        end
    end

endmodule
