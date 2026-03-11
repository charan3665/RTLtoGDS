`timescale 1ns/1ps
// dvfs_controller.v - Dynamic Voltage and Frequency Scaling Controller
module dvfs_controller #(parameter N_LEVELS=8)(
    input  wire         clk, input wire rst_n,
    input  wire [2:0]   requested_level,   // 0=lowest, 7=highest
    input  wire         dvfs_en,
    output reg  [9:0]   vout_target_mv,    // to voltage regulator
    output reg  [7:0]   pll_fbdiv,         // to PLL
    output reg  [3:0]   pll_postdiv,
    input  wire         volt_pg,            // voltage power good
    input  wire         pll_locked,
    output reg          dvfs_done,
    output reg  [2:0]   current_level
);
    // DVFS table: [vout_mv, fbdiv, postdiv]
    reg [9:0] dvfs_v [0:N_LEVELS-1];
    reg [7:0] dvfs_f [0:N_LEVELS-1];
    reg [3:0] dvfs_d [0:N_LEVELS-1];
    initial begin
        dvfs_v[0]=750;  dvfs_f[0]=10; dvfs_d[0]=8;  // 125 MHz, 0.75V
        dvfs_v[1]=775;  dvfs_f[1]=16; dvfs_d[1]=8;  // 200 MHz, 0.775V
        dvfs_v[2]=800;  dvfs_f[2]=20; dvfs_d[2]=8;  // 250 MHz, 0.8V
        dvfs_v[3]=810;  dvfs_f[3]=24; dvfs_d[3]=6;  // 400 MHz, 0.81V
        dvfs_v[4]=825;  dvfs_f[4]=28; dvfs_d[4]=4;  // 700 MHz, 0.825V
        dvfs_v[5]=840;  dvfs_f[5]=32; dvfs_d[5]=4;  // 800 MHz, 0.84V
        dvfs_v[6]=850;  dvfs_f[6]=36; dvfs_d[6]=4;  // 900 MHz, 0.85V
        dvfs_v[7]=950;  dvfs_f[7]=40; dvfs_d[7]=4;  // 1000 MHz, 0.95V
    end

    localparam ST_IDLE=2'd0, ST_VOLT=2'd1, ST_FREQ=2'd2, ST_DONE=2'd3;
    reg [1:0] state;
    reg [2:0] tgt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin state<=ST_IDLE; current_level<=0; dvfs_done<=0; vout_target_mv<=850; pll_fbdiv<=40; pll_postdiv<=4; end
        else begin dvfs_done<=0;
            case (state)
                ST_IDLE: if(dvfs_en && requested_level!=current_level) begin tgt<=requested_level; state<=ST_VOLT; end
                ST_VOLT: begin
                    vout_target_mv<=dvfs_v[tgt];
                    if(volt_pg) begin pll_fbdiv<=dvfs_f[tgt]; pll_postdiv<=dvfs_d[tgt]; state<=ST_FREQ; end
                end
                ST_FREQ: if(pll_locked) begin current_level<=tgt; dvfs_done<=1; state<=ST_IDLE; end
                ST_DONE: state<=ST_IDLE;
            endcase
        end
    end
endmodule
