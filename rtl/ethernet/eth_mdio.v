`timescale 1ns/1ps
module eth_mdio(
    input wire clk, input wire rst_n,
    input wire mdio_in, output reg mdio_out, output reg mdio_oe, output reg mdc,
    // Register interface
    input wire [4:0] phy_addr, input wire [4:0] reg_addr,
    input wire [15:0] wr_data, input wire wr_en, output reg [15:0] rd_data, output reg done
);
    reg [5:0] bit_cnt; reg [31:0] shift;
    reg [1:0] state; localparam ST_IDLE=0,ST_TX=1,ST_RX=2;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin mdc<=0; mdio_oe<=0; bit_cnt<=0; done<=0; state<=ST_IDLE; end
        else begin
            mdc<=~mdc; done<=0;
            case(state)
                ST_IDLE: if(wr_en) begin shift<={2'b01,wr_en?2'b01:2'b10,phy_addr,reg_addr,2'b10,wr_data}; bit_cnt<=32; mdio_oe<=1; state<=ST_TX; end
                ST_TX: if(mdc) begin mdio_out<=shift[31]; shift<={shift[30:0],1'b0}; bit_cnt<=bit_cnt-1; if(bit_cnt==1) begin mdio_oe<=0; state<=ST_IDLE; done<=1; end end
            endcase
        end
    end
endmodule
