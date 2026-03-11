// ============================================================
// sha256_engine.v - SHA-256 Hash Engine
// Processes 512-bit message blocks, outputs 256-bit digest
// ============================================================
`timescale 1ns/1ps
module sha256_engine (
    input  wire         clk, input wire rst_n,
    input  wire [511:0] msg_block,
    input  wire         msg_valid, input wire msg_first, input wire msg_last,
    output wire         ready,
    output reg  [255:0] digest, output reg digest_valid
);
    // SHA-256 constants K[0..63]
    reg [31:0] K [0:63];
    initial begin
        K[0]=32'h428a2f98; K[1]=32'h71374491; K[2]=32'hb5c0fbcf; K[3]=32'he9b5dba5;
        K[4]=32'h3956c25b; K[5]=32'h59f111f1; K[6]=32'h923f82a4; K[7]=32'hab1c5ed5;
        K[8]=32'hd807aa98; K[9]=32'h12835b01; K[10]=32'h243185be; K[11]=32'h550c7dc3;
        K[12]=32'h72be5d74; K[13]=32'h80deb1fe; K[14]=32'h9bdc06a7; K[15]=32'hc19bf174;
        // (abbreviated - full 64 constants in real implementation)
        for(integer i=16;i<64;i=i+1) K[i]=32'h0;
    end

    // Initial hash values (H0..H7)
    localparam H0_INIT = 32'h6a09e667, H1_INIT = 32'hbb67ae85;
    localparam H2_INIT = 32'h3c6ef372, H3_INIT = 32'ha54ff53a;
    localparam H4_INIT = 32'h510e527f, H5_INIT = 32'h9b05688c;
    localparam H6_INIT = 32'h1f83d9ab, H7_INIT = 32'h5be0cd19;

    reg [31:0] H0,H1,H2,H3,H4,H5,H6,H7;
    reg [31:0] a,b,c,d,e,f,g,h;
    reg [31:0] W [0:63];
    reg [6:0]  round;
    reg        active;

    function [31:0] rotr;
        input [31:0] x; input [4:0] n;
        begin rotr = (x>>n) | (x<<(32-n)); end
    endfunction

    function [31:0] Ch;
        input [31:0] e,f,g;
        begin Ch=(e&f)^(~e&g); end
    endfunction

    function [31:0] Maj;
        input [31:0] a,b,c;
        begin Maj=(a&b)^(a&c)^(b&c); end
    endfunction

    assign ready = !active;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            H0<=H0_INIT; H1<=H1_INIT; H2<=H2_INIT; H3<=H3_INIT;
            H4<=H4_INIT; H5<=H5_INIT; H6<=H6_INIT; H7<=H7_INIT;
            active<=0; digest_valid<=0; round<=0;
        end else begin
            digest_valid<=0;
            if (msg_valid && !active) begin
                if (msg_first) begin H0<=H0_INIT; H1<=H1_INIT; H2<=H2_INIT; H3<=H3_INIT; H4<=H4_INIT; H5<=H5_INIT; H6<=H6_INIT; H7<=H7_INIT; end
                // Load message schedule W[0..15]
                for(integer i=0;i<16;i=i+1) W[i]<=msg_block[(15-i)*32+:32];
                a<=H0; b<=H1; c<=H2; d<=H3; e<=H4; f<=H5; g<=H6; h<=H7;
                active<=1; round<=0;
            end else if (active) begin
                // Expand message schedule W[16..63]
                if (round >= 16) begin
                    automatic reg [31:0] s0 = rotr(W[round-15],7)^rotr(W[round-15],18)^(W[round-15]>>3);
                    automatic reg [31:0] s1 = rotr(W[round-2],17)^rotr(W[round-2],19)^(W[round-2]>>10);
                    W[round] <= W[round-16] + s0 + W[round-7] + s1;
                end
                // SHA-256 compression round
                begin
                    automatic reg [31:0] S1  = rotr(e,6)^rotr(e,11)^rotr(e,25);
                    automatic reg [31:0] ch  = Ch(e,f,g);
                    automatic reg [31:0] tmp1= h + S1 + ch + K[round] + W[round];
                    automatic reg [31:0] S0  = rotr(a,2)^rotr(a,13)^rotr(a,22);
                    automatic reg [31:0] maj = Maj(a,b,c);
                    automatic reg [31:0] tmp2= S0 + maj;
                    h<=g; g<=f; f<=e; e<=d+tmp1; d<=c; c<=b; b<=a; a<=tmp1+tmp2;
                end
                round<=round+1;
                if(round==63) begin
                    H0<=H0+a; H1<=H1+b; H2<=H2+c; H3<=H3+d;
                    H4<=H4+e; H5<=H5+f; H6<=H6+g; H7<=H7+h;
                    active<=0;
                    if(msg_last) begin
                        digest<={H0+a,H1+b,H2+c,H3+d,H4+e,H5+f,H6+g,H7+h};
                        digest_valid<=1;
                    end
                end
            end
        end
    end
endmodule
