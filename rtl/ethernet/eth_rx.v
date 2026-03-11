`timescale 1ns/1ps
module eth_rx(
    input wire clk, input wire rst_n,
    input wire [7:0] rx_byte, input wire rx_valid, input wire rx_sof, input wire rx_eof,
    output reg [47:0] dst_mac, src_mac, output reg [15:0] eth_type,
    output reg payload_valid, output reg [7:0] payload_byte, output reg payload_last
);
    reg [5:0] byte_cnt;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin byte_cnt<=0; payload_valid<=0; end
        else begin
            payload_valid<=0; payload_last<=0;
            if(rx_sof) byte_cnt<=0;
            if(rx_valid) begin
                byte_cnt<=byte_cnt+1;
                case(byte_cnt)
                    6'd0: dst_mac[47:40]<=rx_byte;
                    6'd1: dst_mac[39:32]<=rx_byte;
                    6'd2: dst_mac[31:24]<=rx_byte;
                    6'd3: dst_mac[23:16]<=rx_byte;
                    6'd4: dst_mac[15:8] <=rx_byte;
                    6'd5: dst_mac[7:0]  <=rx_byte;
                    6'd6: src_mac[47:40]<=rx_byte;
                    6'd7: src_mac[39:32]<=rx_byte;
                    6'd8: src_mac[31:24]<=rx_byte;
                    6'd9: src_mac[23:16]<=rx_byte;
                    6'd10:src_mac[15:8] <=rx_byte;
                    6'd11:src_mac[7:0]  <=rx_byte;
                    6'd12:eth_type[15:8]<=rx_byte;
                    6'd13:eth_type[7:0] <=rx_byte;
                    default: begin payload_valid<=1; payload_byte<=rx_byte; end
                endcase
                if(rx_eof) payload_last<=1;
            end
        end
    end
endmodule
