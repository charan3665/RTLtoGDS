`timescale 1ns/1ps
module debug_module #(parameter N_HARTS=2)(
    input wire clk, input wire rst_n,
    // DMI interface from JTAG DTM
    input wire dmi_valid, input wire [6:0] dmi_addr, input wire [31:0] dmi_wdata, input wire dmi_wr,
    output reg [31:0] dmi_rdata, output reg dmi_ready,
    // Hart debug interfaces
    output reg  [N_HARTS-1:0] hart_halt_req,
    input  wire [N_HARTS-1:0] hart_halted,
    output reg  [N_HARTS-1:0] hart_resume_req,
    input  wire [N_HARTS-1:0] hart_resumed,
    output reg  [N_HARTS-1:0] hart_reset_req,
    // System bus (for abstract commands)
    output reg  [63:0] sb_addr, output reg sb_rd, output reg sb_wr,
    output reg  [63:0] sb_wdata, input wire [63:0] sb_rdata, input wire sb_ready
);
    // Debug Module Registers (RISC-V Debug Spec v0.13)
    reg [31:0] dmcontrol, dmstatus, hartinfo, abstractcs, command;
    reg [31:0] progbuf[0:7], data[0:11];
    reg [1:0] cmderr;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin dmcontrol<=0; hart_halt_req<=0; hart_resume_req<=0; hart_reset_req<=0; dmi_ready<=0; cmderr<=0; end
        else begin dmi_ready<=dmi_valid;
            if(dmi_valid) begin
                if(dmi_wr) begin
                    case(dmi_addr)
                        7'h10: begin dmcontrol<=dmi_wdata; hart_halt_req<={N_HARTS{dmi_wdata[31]}}; hart_resume_req<={N_HARTS{dmi_wdata[30]}}; hart_reset_req<={N_HARTS{dmi_wdata[1]}}; end
                        7'h17: command<=dmi_wdata;
                        default: if(dmi_addr>=7'h20&&dmi_addr<7'h28) progbuf[dmi_addr-7'h20]<=dmi_wdata;
                    endcase
                end else begin
                    case(dmi_addr)
                        7'h10: dmi_rdata<=dmcontrol;
                        7'h11: dmi_rdata<={10'b0,hart_halted[0],2'b11,hart_resumed[0],hart_halted[0],6'b0,2'b11,2'b11};
                        7'h16: dmi_rdata<={2'b0,cmderr,20'b0,8'b0};
                        default: dmi_rdata<=32'h0;
                    endcase
                end
            end
        end
    end
endmodule
