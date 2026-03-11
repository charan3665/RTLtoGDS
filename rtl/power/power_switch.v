`timescale 1ns/1ps
// power_switch.v - HSVT/SLVT power switch cell (header switch)
module power_switch #(parameter WIDTH=32)(
    input  wire         VDD,      // always-on supply
    input  wire         SW_EN,    // switch enable (active high)
    output wire         VDD_SW,   // switched supply output
    output wire         ACK       // power good acknowledgment
);
    // Behavioral model: switch connects VDD to VDD_SW when SW_EN=1
    assign VDD_SW = SW_EN ? VDD : 1'b0;
    assign ACK    = SW_EN; // in real cell: delayed ack after ramp-up
endmodule
