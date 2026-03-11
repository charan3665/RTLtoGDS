// rng_engine.v - TRNG + DRBG (AES-CTR based)
`timescale 1ns/1ps
module rng_engine (
    input  wire         clk, input wire rst_n,
    input  wire         req_valid, output wire req_ready,
    output reg  [127:0] rng_out, output reg rng_valid,
    input  wire [127:0] entropy_in, input wire entropy_valid  // from ring oscillator
);
    reg [127:0] key_reg, ctr_reg, seed_reg;
    reg [1:0] state;
    localparam ST_IDLE=2'd0, ST_RESEED=2'd1, ST_GEN=2'd2;
    // AES-CTR DRBG
    wire [127:0] aes_out; wire aes_valid;
    reg aes_req;
    aes_engine u_aes(.clk(clk),.rst_n(rst_n),.plaintext(ctr_reg),.key(key_reg),.mode(2'b00),.valid_in(aes_req),.ready(),.iv(128'b0),.ciphertext(aes_out),.valid_out(aes_valid));
    assign req_ready=(state==ST_IDLE);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin state<=ST_IDLE; rng_valid<=0; aes_req<=0; key_reg<=128'h0; ctr_reg<=128'h1; end
        else begin
            rng_valid<=0; aes_req<=0;
            case(state)
                ST_IDLE: begin
                    if(entropy_valid) begin key_reg<=key_reg^entropy_in; state<=ST_RESEED; end
                    else if(req_valid) begin aes_req<=1; state<=ST_GEN; end
                end
                ST_RESEED: begin seed_reg<=key_reg; state<=ST_IDLE; end
                ST_GEN: begin
                    if(aes_valid) begin rng_out<=aes_out; rng_valid<=1; ctr_reg<=ctr_reg+1; state<=ST_IDLE; end
                end
            endcase
        end
    end
endmodule
