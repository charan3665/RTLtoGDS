`timescale 1ns/1ps
module i2c_master #(parameter CLK_DIV=50)(
    input wire clk, input wire rst_n,
    input wire [6:0] dev_addr, input wire [7:0] reg_addr, input wire [7:0] wr_data,
    input wire wr_en, input wire rd_en, output reg [7:0] rd_data, output reg done,
    inout wire sda, output reg scl
);
    reg sda_oe, sda_out; reg [7:0] shift; reg [3:0] bit_cnt; reg [7:0] div_cnt;
    reg [3:0] state;
    assign sda = sda_oe ? sda_out : 1'bz;
    localparam ST_IDLE=4'd0,ST_START=4'd1,ST_ADDR=4'd2,ST_ACK=4'd3,ST_DATA=4'd4,ST_STOP=4'd5;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin scl<=1; sda_oe<=0; sda_out<=1; done<=0; state<=ST_IDLE; div_cnt<=0; end
        else begin done<=0; div_cnt<=div_cnt+1;
            if(div_cnt==CLK_DIV/2-1) begin div_cnt<=0;
                case(state)
                    ST_IDLE: if(wr_en||rd_en) begin sda_oe<=1; sda_out<=0; state<=ST_START; shift<={dev_addr,wr_en?1'b0:1'b1}; bit_cnt<=7; end
                    ST_START: begin scl<=0; state<=ST_ADDR; end
                    ST_ADDR: begin scl<=~scl; if(scl) begin sda_out<=shift[7]; shift<={shift[6:0],1'b0}; if(bit_cnt==0) state<=ST_ACK; else bit_cnt<=bit_cnt-1; end end
                    ST_ACK: begin scl<=~scl; if(scl) begin sda_oe<=0; state<=ST_DATA; shift<=wr_data; bit_cnt<=7; end end
                    ST_DATA: begin scl<=~scl; sda_oe<=1; if(scl) begin sda_out<=shift[7]; shift<={shift[6:0],1'b0}; if(bit_cnt==0) state<=ST_STOP; else bit_cnt<=bit_cnt-1; end end
                    ST_STOP: begin scl<=1; sda_out<=1; done<=1; state<=ST_IDLE; end
                endcase
            end
        end
    end
endmodule
