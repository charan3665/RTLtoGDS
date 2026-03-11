`timescale 1ns/1ps
// dfs_controller.v - Dynamic Frequency Scaling Controller
// Changes PLL dividers based on workload and power targets
module dfs_controller #(parameter N_LEVELS=8)(
    input  wire         clk, input wire rst_n,
    input  wire [7:0]   workload_hint,    // 0=idle, 255=max load
    input  wire [7:0]   temp_reading,     // from thermal sensor
    input  wire [7:0]   volt_reading,     // from DVFS
    input  wire         pll_locked,
    output reg  [7:0]   pll_fbdiv,
    output reg  [3:0]   pll_postdiv,
    output reg          change_req,
    input  wire         change_ack,
    output reg  [2:0]   freq_level        // 0=lowest, 7=highest
);
    // Frequency table: [fbdiv, postdiv] for each level
    reg [7:0] freq_fbdiv  [0:N_LEVELS-1];
    reg [3:0] freq_postdiv[0:N_LEVELS-1];
    initial begin
        freq_fbdiv[0]=8'd10; freq_postdiv[0]=4'd8;  // 125 MHz
        freq_fbdiv[1]=8'd16; freq_postdiv[1]=4'd8;  // 200 MHz
        freq_fbdiv[2]=8'd20; freq_postdiv[2]=4'd8;  // 250 MHz
        freq_fbdiv[3]=8'd24; freq_postdiv[3]=4'd6;  // 400 MHz (approx)
        freq_fbdiv[4]=8'd28; freq_postdiv[4]=4'd4;  // 700 MHz (approx)
        freq_fbdiv[5]=8'd32; freq_postdiv[5]=4'd4;  // 800 MHz
        freq_fbdiv[6]=8'd36; freq_postdiv[6]=4'd4;  // 900 MHz
        freq_fbdiv[7]=8'd40; freq_postdiv[7]=4'd4;  // 1000 MHz
    end

    reg [7:0] hyst_cnt; reg [2:0] target_level;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin freq_level<=0; change_req<=0; hyst_cnt<=0; target_level<=0; end
        else begin
            change_req<=0;
            hyst_cnt<=hyst_cnt+1;
            if (hyst_cnt==8'hFF) begin
                // Compute target frequency based on workload and temperature
                if (temp_reading > 8'd120)       target_level<=3'd0;  // thermal throttle
                else if (workload_hint > 8'd200) target_level<=3'd7;  // max freq
                else if (workload_hint > 8'd160) target_level<=3'd6;
                else if (workload_hint > 8'd120) target_level<=3'd5;
                else if (workload_hint > 8'd80)  target_level<=3'd4;
                else if (workload_hint > 8'd40)  target_level<=3'd3;
                else if (workload_hint > 8'd16)  target_level<=3'd2;
                else                             target_level<=3'd1;

                if (target_level != freq_level) begin
                    pll_fbdiv   <= freq_fbdiv  [target_level];
                    pll_postdiv <= freq_postdiv[target_level];
                    change_req  <= 1'b1;
                end
            end
            if (change_ack) freq_level<=target_level;
        end
    end
endmodule
