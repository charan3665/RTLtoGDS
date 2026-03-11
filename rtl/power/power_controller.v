`timescale 1ns/1ps
// power_controller.v - Power Domain Controller (per domain FSM)
module power_controller #(parameter PD_ID=0)(
    input  wire         clk, input wire rst_n,
    input  wire         pwr_req,  // power up request
    input  wire         pwr_off,  // power down request
    output reg          sw_en,    // power switch enable
    input  wire         sw_ack,   // power switch ack
    output reg          iso_en,   // isolation enable
    output reg          ret_en,   // retention enable (save)
    output reg          rst_assert,// domain reset
    output reg          pwr_ack,  // power state ack to PMU
    output reg  [1:0]   pd_state  // 00=off, 01=on, 10=retention
);
    localparam ST_OFF=3'd0, ST_ISO=3'd1, ST_SW=3'd2, ST_DEISO=3'd3, ST_ON=3'd4, ST_SAVE=3'd5, ST_RET=3'd6;
    reg [2:0] state; reg [7:0] delay;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin state<=ST_OFF; sw_en<=0; iso_en<=1; ret_en<=0; rst_assert<=1; pwr_ack<=0; pd_state<=2'b00; end
        else begin pwr_ack<=0;
            case(state)
                ST_OFF: if(pwr_req) begin iso_en<=1; rst_assert<=1; state<=ST_SW; end
                ST_SW:  begin sw_en<=1; delay<=delay+1; if(sw_ack||delay==8'hFF) begin delay<=0; state<=ST_DEISO; end end
                ST_DEISO: begin rst_assert<=0; delay<=delay+1; if(delay==8'hFF) begin iso_en<=0; state<=ST_ON; pwr_ack<=1; pd_state<=2'b01; end end
                ST_ON:  begin if(pwr_off) begin iso_en<=1; ret_en<=1; state<=ST_SAVE; end end
                ST_SAVE:begin delay<=delay+1; if(delay==8'h0F) begin ret_en<=0; sw_en<=0; delay<=0; state<=ST_OFF; pwr_ack<=1; pd_state<=2'b00; end end
            endcase
        end
    end
endmodule
