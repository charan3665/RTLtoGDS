`timescale 1ns/1ps
module debug_sbm #(parameter AW=64, DW=64)(
    input wire clk, input wire rst_n,
    input wire sbcs_rd, input wire sbcs_wr, input wire [AW-1:0] sbaddress,
    input wire [DW-1:0] sbdata_wr, output reg [DW-1:0] sbdata_rd,
    output reg sbbusy, output reg sberror,
    output reg m_arvalid, output reg [AW-1:0] m_araddr, input wire m_arready,
    input wire m_rvalid, input wire [DW-1:0] m_rdata, output wire m_rready,
    output reg m_awvalid, output reg [AW-1:0] m_awaddr, input wire m_awready,
    output reg m_wvalid, output reg [DW-1:0] m_wdata, input wire m_wready,
    input wire m_bvalid, output wire m_bready
);
    localparam ST_IDLE=2'd0,ST_RD=2'd1,ST_WR=2'd2,ST_WB=2'd3;
    reg [1:0] state;
    assign m_rready=1; assign m_bready=1;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin state<=ST_IDLE; sbbusy<=0; sberror<=0; m_arvalid<=0; m_awvalid<=0; m_wvalid<=0; end
        else begin
            case(state)
                ST_IDLE: begin sbbusy<=0;
                    if(sbcs_rd) begin m_arvalid<=1; m_araddr<=sbaddress; sbbusy<=1; state<=ST_RD; end
                    else if(sbcs_wr) begin m_awvalid<=1; m_awaddr<=sbaddress; sbbusy<=1; state<=ST_WR; end
                end
                ST_RD: begin if(m_arready) m_arvalid<=0; if(m_rvalid) begin sbdata_rd<=m_rdata; state<=ST_IDLE; end end
                ST_WR: begin if(m_awready) m_awvalid<=0; m_wvalid<=1; m_wdata<=sbdata_wr; if(m_wready) begin m_wvalid<=0; state<=ST_WB; end end
                ST_WB: begin if(m_bvalid) state<=ST_IDLE; end
            endcase
        end
    end
endmodule
