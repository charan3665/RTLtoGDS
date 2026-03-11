`timescale 1ns/1ps
module pcie_config(
    input wire clk, input wire rst_n,
    input wire [11:0] reg_addr, input wire [31:0] wdata, input wire wr,
    output reg [31:0] rdata
);
    reg [31:0] cfg[0:4095];
    // PCIe Type 0 Configuration Space Header
    initial begin
        cfg[0]=32'hDEAD1172; // VendorID=0x1172, DeviceID=0xDEAD
        cfg[1]=32'h00100007; // Command/Status
        cfg[2]=32'h06800000; // ClassCode=0x068000 (Other Bridge), RevID=0
        cfg[3]=32'h00800000; // BIST/Header/LatencyTimer/CacheLineSize
        cfg[4]=32'h00000004; // BAR0 (64-bit memory, non-pref)
        cfg[5]=32'h00000000; // BAR0 upper
        for(integer i=6;i<4096;i=i+1) cfg[i]=32'h0;
    end
    always @(posedge clk) begin if(wr) cfg[reg_addr]<=wdata; rdata<=cfg[reg_addr]; end
endmodule
