`timescale 1ns/1ps
module pcie_dll(
    input wire clk, input wire rst_n,
    input wire in_valid, input wire [255:0] in_data,
    output reg out_valid, output reg [255:0] out_data
);
    // Data Link Layer: LCRC, DLLP, ack/nak, retry buffer
    reg [255:0] retry_buf[0:15]; reg [3:0] rb_ptr; reg [3:0] seq;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin out_valid<=0; rb_ptr<=0; seq<=0; end
        else begin
            out_valid<=in_valid;
            if(in_valid) begin
                retry_buf[rb_ptr]<=in_data; rb_ptr<=rb_ptr+1;
                // Add sequence number and LCRC
                out_data<={in_data[255:16], seq, 8'hAA}; // simplified
                seq<=seq+1;
            end
        end
    end
endmodule
