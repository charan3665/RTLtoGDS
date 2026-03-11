`timescale 1ns/1ps
module eth_crc(
    input wire clk, input wire rst_n, input wire init,
    input wire [7:0] data_in, input wire data_valid,
    output reg [31:0] crc_out
);
    // CRC-32 for Ethernet (polynomial 0x04C11DB7)
    localparam POLY=32'h04C11DB7;
    reg [31:0] crc; integer i;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n||init) crc<=32'hFFFFFFFF;
        else if(data_valid) begin
            for(i=0;i<8;i=i+1) begin
                if((crc[31]^data_in[7-i])) crc<={crc[30:0],1'b0}^POLY;
                else crc<={crc[30:0],1'b0};
            end
        end
    end
    assign crc_out=~crc;
endmodule
