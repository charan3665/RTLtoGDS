`timescale 1ns/1ps
module timer_counter(
    input wire clk, input wire rst_n,
    input wire [31:0] load, input wire [31:0] ctrl,
    output reg [31:0] cnt, output reg overflow
);
    // ctrl[0]=enable, ctrl[1]=auto-reload, ctrl[2]=count-up
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin cnt<=0; overflow<=0; end
        else begin overflow<=0;
            if(ctrl[0]) begin
                if(ctrl[2]) begin cnt<=cnt+1; if(cnt==32'hFFFFFFFF) begin overflow<=1; if(ctrl[1]) cnt<=load; end end
                else begin if(cnt==0) begin overflow<=1; if(ctrl[1]) cnt<=load; end else cnt<=cnt-1; end
            end
        end
    end
endmodule
