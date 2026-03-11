`timescale 1ns/1ps
module gpio_top #(parameter N=32)(
    input wire clk, input wire rst_n,
    input wire psel, input wire pena, input wire pwrite, input wire [7:0] paddr, input wire [N-1:0] pwdata,
    output reg [N-1:0] prdata, output wire pready,
    input wire [N-1:0] gpio_in, output wire [N-1:0] gpio_out, output wire [N-1:0] gpio_oe,
    output wire irq
);
    reg [N-1:0] dir_reg, out_reg, int_en, int_pol;
    wire [N-1:0] int_stat = (gpio_in ^ int_pol) & int_en;
    assign gpio_oe=dir_reg; assign gpio_out=out_reg; assign pready=1; assign irq=|int_stat;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin dir_reg<=0; out_reg<=0; int_en<=0; int_pol<=0; prdata<=0; end
        else begin
            if(psel&&pena&&pwrite) case(paddr) 8'h00:dir_reg<=pwdata; 8'h04:out_reg<=pwdata; 8'h08:int_en<=pwdata; 8'h0C:int_pol<=pwdata; endcase
            if(psel&&pena&&!pwrite) case(paddr) 8'h00:prdata<=dir_reg; 8'h04:prdata<=out_reg; 8'h10:prdata<=gpio_in; 8'h14:prdata<=int_stat; default:prdata<=0; endcase
        end
    end
endmodule
