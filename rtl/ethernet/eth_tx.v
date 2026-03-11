`timescale 1ns/1ps
module eth_tx(
    input wire clk, input wire rst_n,
    input wire [47:0] dst_mac, src_mac, input wire [15:0] eth_type,
    input wire [7:0] payload_byte, input wire payload_valid, input wire payload_last,
    output reg [7:0] tx_byte, output reg tx_valid, output reg tx_sof, output reg tx_eof
);
    reg [5:0] hdr_cnt; reg tx_hdr;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin hdr_cnt<=0; tx_hdr<=0; tx_valid<=0; tx_sof<=0; tx_eof<=0; end
        else begin
            tx_valid<=0; tx_sof<=0; tx_eof<=0;
            if(payload_valid && !tx_hdr) begin tx_hdr<=1; hdr_cnt<=0; end
            if(tx_hdr) begin
                tx_valid<=1;
                case(hdr_cnt)
                    6'd0: begin tx_byte<=dst_mac[47:40]; tx_sof<=1; end
                    6'd1: tx_byte<=dst_mac[39:32]; 6'd2: tx_byte<=dst_mac[31:24];
                    6'd3: tx_byte<=dst_mac[23:16]; 6'd4: tx_byte<=dst_mac[15:8];
                    6'd5: tx_byte<=dst_mac[7:0];   6'd6: tx_byte<=src_mac[47:40];
                    6'd7: tx_byte<=src_mac[39:32]; 6'd8: tx_byte<=src_mac[31:24];
                    6'd9: tx_byte<=src_mac[23:16]; 6'd10:tx_byte<=src_mac[15:8];
                    6'd11:tx_byte<=src_mac[7:0];   6'd12:tx_byte<=eth_type[15:8];
                    6'd13:tx_byte<=eth_type[7:0];  default: begin tx_byte<=payload_byte; if(payload_last) begin tx_eof<=1; tx_hdr<=0; end end
                endcase
                if(hdr_cnt<14) hdr_cnt<=hdr_cnt+1;
            end
        end
    end
endmodule
