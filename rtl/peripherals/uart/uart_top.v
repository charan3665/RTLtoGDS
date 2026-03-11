`timescale 1ns/1ps
module uart_top #(parameter CLK_FREQ=1_000_000_00, BAUD=115200)(
    input wire clk, input wire rst_n,
    input wire psel, input wire pena, input wire pwrite,
    input wire [7:0] paddr, input wire [31:0] pwdata,
    output reg [31:0] prdata, output wire pready, output reg pslverr,
    input wire rxd, output wire txd, output wire irq
);
    wire tx_empty, rx_full, rx_valid; wire [7:0] rx_data, tx_data;
    reg [7:0] tx_reg; reg tx_wr;
    uart_tx u_tx(.clk(clk),.rst_n(rst_n),.data(tx_reg),.wr(tx_wr),.txd(txd),.empty(tx_empty));
    uart_rx u_rx(.clk(clk),.rst_n(rst_n),.rxd(rxd),.valid(rx_valid),.data(rx_data));
    uart_fifo u_rxfifo(.clk(clk),.rst_n(rst_n),.wr_en(rx_valid),.wr_data(rx_data),.rd_en(psel&&pena&&!pwrite&&paddr==8'h04),.rd_data(rx_data),.full(rx_full),.empty());
    assign pready=1; assign irq=(rx_valid||tx_empty);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin prdata<=0; tx_wr<=0; pslverr<=0; end
        else begin
            tx_wr<=0;
            if(psel&&pena&&pwrite) begin
                case(paddr)
                    8'h00: begin tx_reg<=pwdata[7:0]; tx_wr<=1; end
                endcase
            end
            if(psel&&pena&&!pwrite) begin
                case(paddr)
                    8'h04: prdata<={24'b0,rx_data};
                    8'h08: prdata<={30'b0,rx_full,tx_empty};
                    default: prdata<=32'hDEAD;
                endcase
            end
        end
    end
endmodule
