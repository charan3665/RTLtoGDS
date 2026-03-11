`timescale 1ns/1ps
module pll_controller(
    input wire clk, input wire rst_n,
    input wire psel, input wire pena, input wire pwrite, input wire [7:0] paddr, input wire [31:0] pwdata,
    output reg [31:0] prdata, output wire pready,
    output reg [7:0] fbdiv, output reg [3:0] refdiv, output reg [3:0] postdiv1, output reg [3:0] postdiv2,
    input wire pll_locked, output wire pll_rst_n
);
    reg pll_rst_reg;
    assign pready=1; assign pll_rst_n=pll_rst_reg;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin fbdiv<=8'd40; refdiv<=4'd1; postdiv1<=4'd1; postdiv2<=4'd1; pll_rst_reg<=0; prdata<=0; end
        else begin
            if(psel&&pena&&pwrite) case(paddr)
                8'h00: fbdiv<=pwdata[7:0]; 8'h04: refdiv<=pwdata[3:0];
                8'h08: postdiv1<=pwdata[3:0]; 8'h0C: postdiv2<=pwdata[3:0];
                8'h10: pll_rst_reg<=pwdata[0];
            endcase
            if(psel&&pena&&!pwrite) case(paddr)
                8'h00: prdata<={24'b0,fbdiv}; 8'h14: prdata<={31'b0,pll_locked};
                default: prdata<=32'hDEADBEEF;
            endcase
        end
    end
endmodule
