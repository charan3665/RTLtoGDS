`timescale 1ns/1ps
module debug_dtm(
    input wire tck, input wire tms, input wire tdi, output wire tdo, input wire trst_n,
    // DMI to debug module
    output reg dmi_valid, output reg [6:0] dmi_addr, output reg [31:0] dmi_wdata, output reg dmi_wr,
    input wire [31:0] dmi_rdata, input wire dmi_ready
);
    wire [3:0] ir; wire [40:0] dr_dmi; wire shift_dr, update_dr;
    jtag_tap u_tap(.tck(tck),.tms(tms),.tdi(tdi),.tdo(tdo),.trst_n(trst_n),
        .debug_req(),.dr_dmi_data(dr_dmi),.dr_dmi_resp(dmi_rdata),
        .shift_dr(shift_dr),.capture_dr(),.update_dr(update_dr),.ir_out(ir));
    always @(posedge tck or negedge trst_n) begin
        if(!trst_n) begin dmi_valid<=0; dmi_wr<=0; end
        else if(update_dr && ir==4'h5) begin
            dmi_valid<=1; dmi_addr<=dr_dmi[40:34]; dmi_wr<=dr_dmi[33:32]==2'b01;
            dmi_wdata<=dr_dmi[31:0];
        end else if(dmi_ready) dmi_valid<=0;
    end
endmodule
