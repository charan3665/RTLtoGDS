`timescale 1ns/1ps
module dma_arbiter #(parameter N=8, AW=64, DW=128)(
    input wire clk, input wire rst_n,
    input wire [N-1:0] req, input wire [N*AW-1:0] req_addr,
    input wire [N-1:0] req_wr, input wire [N*DW-1:0] req_data,
    output wire [N-1:0] grant, output reg [AW-1:0] bus_addr,
    output reg bus_wr, output reg [DW-1:0] bus_data,
    input wire bus_done
);
    reg [$clog2(N)-1:0] rr;
    integer i; reg [N-1:0] grant_r;
    assign grant=grant_r;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin grant_r<=0; rr<=0; end
        else begin
            if(!|grant_r && |req) begin
                for(i=0;i<N;i=i+1) begin
                    automatic integer nxt=(rr+i)%N;
                    if(req[nxt] && !|grant_r) begin grant_r<=(1<<nxt); bus_addr<=req_addr[nxt*AW+:AW]; bus_wr<=req_wr[nxt]; bus_data<=req_data[nxt*DW+:DW]; rr<=(nxt+1)%N; end
                end
            end else if(bus_done) grant_r<=0;
        end
    end
endmodule
