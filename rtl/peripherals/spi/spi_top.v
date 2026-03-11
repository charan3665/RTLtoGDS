`timescale 1ns/1ps
module spi_top #(parameter N_CS=4)(
    input wire clk, input wire rst_n,
    input wire psel, input wire pena, input wire pwrite, input wire [7:0] paddr, input wire [31:0] pwdata,
    output reg [31:0] prdata, output wire pready,
    output wire sclk, output reg [N_CS-1:0] cs_n, output wire mosi, input wire miso,
    output wire irq
);
    reg [7:0] tx_reg; reg tx_wr; wire [7:0] rx_data; wire rx_valid;
    spi_master u_m(.clk(clk),.rst_n(rst_n),.tx_data(tx_reg),.tx_valid(tx_wr),.tx_ready(),.rx_data(rx_data),.rx_valid(rx_valid),.sclk(sclk),.mosi(mosi),.miso(miso),.cs_n(cs_n[0]));
    assign pready=1; assign irq=rx_valid;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin tx_wr<=0; prdata<=0; end
        else begin tx_wr<=0;
            if(psel&&pena&&pwrite) begin tx_reg<=pwdata[7:0]; tx_wr<=1; end
            if(psel&&pena&&!pwrite) prdata<={24'b0,rx_data};
        end
    end
endmodule
