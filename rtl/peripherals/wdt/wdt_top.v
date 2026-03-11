`timescale 1ns/1ps
module wdt_top #(parameter TIMEOUT=32'hFFFFFF)(
    input wire clk, input wire rst_n,
    input wire psel, input wire pena, input wire pwrite, input wire [7:0] paddr, input wire [31:0] pwdata,
    output reg [31:0] prdata, output wire pready,
    output reg wdt_rst_n,  // watchdog reset (active low)
    output reg wdt_irq
);
    reg [31:0] cnt; reg en; reg [31:0] timeout_val;
    localparam KEY = 32'hDEADC0DE;
    assign pready=1;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin cnt<=0; en<=0; wdt_rst_n<=1; wdt_irq<=0; timeout_val<=TIMEOUT; end
        else begin wdt_irq<=0;
            if(psel&&pena&&pwrite) begin
                case(paddr)
                    8'h00: if(pwdata==KEY) cnt<=0;  // kick/service
                    8'h04: en<=pwdata[0];
                    8'h08: timeout_val<=pwdata;
                endcase
            end
            if(psel&&pena&&!pwrite) prdata<=(paddr==8'h0C)?cnt:en;
            if(en) begin cnt<=cnt+1;
                if(cnt==timeout_val-1) wdt_irq<=1;
                if(cnt>=timeout_val) begin wdt_rst_n<=0; end
            end
        end
    end
endmodule
