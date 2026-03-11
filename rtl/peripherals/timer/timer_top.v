`timescale 1ns/1ps
module timer_top #(parameter N_TIMERS=4)(
    input wire clk, input wire rst_n,
    input wire psel, input wire pena, input wire pwrite, input wire [7:0] paddr, input wire [31:0] pwdata,
    output reg [31:0] prdata, output wire pready,
    output wire [N_TIMERS-1:0] irq
);
    reg [31:0] load[0:N_TIMERS-1], ctrl[0:N_TIMERS-1];
    wire [31:0] cnt_out[0:N_TIMERS-1]; wire [N_TIMERS-1:0] ovf;
    assign pready=1; assign irq=ovf;
    genvar g;
    generate for(g=0;g<N_TIMERS;g=g+1) begin : gen_t
        timer_counter u(.clk(clk),.rst_n(rst_n),.load(load[g]),.ctrl(ctrl[g]),.cnt(cnt_out[g]),.overflow(ovf[g]));
    end endgenerate
    always @(posedge clk) begin
        if(psel&&pena&&pwrite) case(paddr[7:2]) default: load[paddr[3:2]]<=pwdata; endcase
        if(psel&&pena&&!pwrite) prdata<=cnt_out[paddr[3:2]];
    end
endmodule
