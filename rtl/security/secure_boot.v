`timescale 1ns/1ps
// secure_boot.v - Secure Boot Controller (verifies firmware hash)
module secure_boot(
    input wire clk, input wire rst_n,
    input wire boot_req, output reg boot_ok, output reg boot_fail,
    input wire [255:0] fw_hash, input wire [255:0] ref_hash,
    output reg [1:0] sec_state  // 00=idle, 01=verify, 10=ok, 11=fail
);
    localparam ST_IDLE=2'd0,ST_VERIFY=2'd1,ST_OK=2'd2,ST_FAIL=2'd3;
    reg [7:0] delay;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin sec_state<=ST_IDLE; boot_ok<=0; boot_fail<=0; delay<=0; end
        else begin
            case(sec_state)
                ST_IDLE: if(boot_req) begin sec_state<=ST_VERIFY; delay<=0; end
                ST_VERIFY: begin delay<=delay+1;
                    if(delay==8'hFF) begin
                        if(fw_hash==ref_hash) begin sec_state<=ST_OK; boot_ok<=1; end
                        else begin sec_state<=ST_FAIL; boot_fail<=1; end
                    end
                end
                ST_OK, ST_FAIL: begin end
            endcase
        end
    end
endmodule
