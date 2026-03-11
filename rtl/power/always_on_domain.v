`timescale 1ns/1ps
// always_on_domain.v - Always-On domain logic (PMU, RTC, wake logic)
module always_on_domain (
    input  wire         clk_ao,   // always-on clock (32kHz or 25MHz)
    input  wire         por_n,    // power-on reset
    input  wire         ext_irq,  // external interrupt/wakeup
    input  wire [15:0]  wake_src, // wakeup source mask
    output reg          sys_rst_n,
    output reg          pwr_on_req,     // request main power on
    output reg  [10:0]  pd_pwr_en,      // power domain enables
    output reg  [15:0]  clk_en,         // clock enables to clock gen
    input  wire [10:0]  pd_pwr_ack,     // power domain ack
    input  wire         pll_locked,
    output reg          soc_ready       // SoC is fully up
);
    localparam ST_OFF=3'd0, ST_PWR_UP=3'd1, ST_CLK_UP=3'd2, ST_ACTIVE=3'd3, ST_SLEEP=3'd4;
    reg [2:0] state; reg [15:0] delay_cnt;

    always @(posedge clk_ao or negedge por_n) begin
        if (!por_n) begin state<=ST_PWR_UP; pwr_on_req<=0; pd_pwr_en<=0; clk_en<=0; sys_rst_n<=0; soc_ready<=0; delay_cnt<=0; end
        else begin
            case (state)
                ST_PWR_UP: begin
                    pwr_on_req<=1; pd_pwr_en<=11'h7FF; // enable all domains
                    delay_cnt<=delay_cnt+1;
                    if(delay_cnt==16'hFFFF) state<=ST_CLK_UP;
                end
                ST_CLK_UP: begin
                    clk_en<=16'hFFFF; sys_rst_n<=1;
                    if(pll_locked) begin soc_ready<=1; state<=ST_ACTIVE; end
                end
                ST_ACTIVE: begin
                    if(ext_irq && !(|wake_src)) state<=ST_SLEEP;
                end
                ST_SLEEP: begin
                    clk_en<=16'h0001; // keep only AO clock
                    pd_pwr_en<=11'h001; // keep AO domain
                    soc_ready<=0;
                    if(|(ext_irq & wake_src[7:0])) state<=ST_PWR_UP;
                end
            endcase
        end
    end
endmodule
