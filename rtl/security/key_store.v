`timescale 1ns/1ps
// key_store.v - Secure Key Storage (fuse-backed OTP model)
module key_store #(parameter N_KEYS=8, KEY_BITS=256)(
    input wire clk, input wire rst_n,
    input wire [2:0] key_sel, output reg [KEY_BITS-1:0] key_out, output reg key_valid,
    input wire lock,  // once locked, keys are not readable in plaintext
    input wire sec_debug_en,  // security debug enable
    // OTP program interface (one-time)
    input wire otp_prog_en, input wire [2:0] otp_key_sel, input wire [KEY_BITS-1:0] otp_key_in
);
    reg [KEY_BITS-1:0] key_store [0:N_KEYS-1];
    reg locked;
    integer i;
    initial for(i=0;i<N_KEYS;i=i+1) key_store[i]={KEY_BITS{1'b0}};
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin key_valid<=0; locked<=0; end
        else begin
            if(lock) locked<=1;
            if(otp_prog_en&&!locked) key_store[otp_key_sel]<=otp_key_in;
            key_valid<= (!locked||sec_debug_en);
            key_out<=key_store[key_sel];
        end
    end
endmodule
