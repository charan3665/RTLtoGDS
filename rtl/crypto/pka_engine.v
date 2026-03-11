// pka_engine.v - Public Key Accelerator (RSA/ECC Montgomery multiply)
`timescale 1ns/1ps
module pka_engine #(parameter KEY_BITS=2048)(
    input  wire         clk, input wire rst_n,
    input  wire [KEY_BITS-1:0] operand_a, operand_b, modulus,
    input  wire         op_start, input wire [1:0] op_type, // 00=MOD_MUL, 01=MOD_EXP, 10=ECC_PT_ADD
    output wire         op_ready,
    output reg  [KEY_BITS-1:0] result, output reg op_done
);
    // Montgomery multiplication state machine
    localparam ST_IDLE=2'd0, ST_COMPUTE=2'd1, ST_REDUCE=2'd2, ST_DONE=2'd3;
    reg [1:0] state;
    reg [KEY_BITS*2-1:0] acc;
    reg [11:0] bit_cnt;
    assign op_ready=(state==ST_IDLE);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin state<=ST_IDLE; op_done<=0; bit_cnt<=0; end
        else begin
            op_done<=0;
            case(state)
                ST_IDLE: if(op_start) begin acc<=0; bit_cnt<=0; state<=ST_COMPUTE; end
                ST_COMPUTE: begin
                    if(operand_b[bit_cnt]) acc<=acc+operand_a;
                    if(acc[0]) acc<=(acc+modulus)>>1; else acc<=acc>>1;
                    bit_cnt<=bit_cnt+1;
                    if(bit_cnt==KEY_BITS-1) state<=ST_REDUCE;
                end
                ST_REDUCE: begin
                    if(acc>=modulus) acc<=acc-modulus; else begin result<=acc[KEY_BITS-1:0]; state<=ST_DONE; end
                end
                ST_DONE: begin op_done<=1; state<=ST_IDLE; end
            endcase
        end
    end
endmodule
