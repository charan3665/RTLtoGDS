`timescale 1ns/1ps
module crypto_top #(parameter AW=64, DW=128)(
    input wire clk, input wire rst_n,
    input  wire s_awvalid, input wire [AW-1:0] s_awaddr, output wire s_awready,
    input  wire s_wvalid, input wire [DW-1:0] s_wdata, output wire s_wready,
    output wire s_bvalid, output wire [1:0] s_bresp, input wire s_bready,
    input  wire s_arvalid, input wire [AW-1:0] s_araddr, output wire s_arready,
    output wire s_rvalid, output wire [DW-1:0] s_rdata, output wire [1:0] s_rresp, input wire s_rready,
    output wire crypto_irq
);
    // Register interface (simplified)
    reg [127:0] key_reg, data_reg, result_reg;
    reg [1:0] mode_reg;
    reg op_start;
    wire [127:0] aes_out; wire aes_vld;
    wire [255:0] sha_dig; wire sha_vld;
    wire [127:0] rng_out; wire rng_vld;

    aes_engine u_aes(.clk(clk),.rst_n(rst_n),.plaintext(data_reg),.key(key_reg),.mode(mode_reg),.valid_in(op_start&&mode_reg==0),.ready(),.iv(128'b0),.ciphertext(aes_out),.valid_out(aes_vld));
    sha256_engine u_sha(.clk(clk),.rst_n(rst_n),.msg_block({data_reg,data_reg,data_reg,data_reg}),.msg_valid(op_start&&mode_reg==1),.msg_first(1'b1),.msg_last(1'b1),.ready(),.digest(sha_dig),.digest_valid(sha_vld));
    rng_engine u_rng(.clk(clk),.rst_n(rst_n),.req_valid(op_start&&mode_reg==2),.req_ready(),.rng_out(rng_out),.rng_valid(rng_vld),.entropy_in(128'hDEADBEEF_CAFEF00D_12345678_9ABCDEF0),.entropy_valid(1'b1));

    // Tie off AXI ports (stub)
    assign s_awready=1; assign s_wready=1; assign s_bvalid=0; assign s_bresp=0;
    assign s_arready=1; assign s_rvalid=0; assign s_rdata=0; assign s_rresp=0;
    assign crypto_irq=aes_vld|sha_vld|rng_vld;

    always @(posedge clk) op_start<=s_awvalid&&s_wvalid;
endmodule
