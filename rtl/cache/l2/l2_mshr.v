`timescale 1ns/1ps
module l2_mshr #(parameter MSHR_ENTRIES=16, PADDR_WIDTH=56, LINE_BITS=512)(
    input wire clk, input wire rst_n,
    input wire alloc_valid, input wire [PADDR_WIDTH-1:0] alloc_addr,
    output wire alloc_ready, output wire [$clog2(MSHR_ENTRIES)-1:0] alloc_id,
    input wire fill_valid, input wire [$clog2(MSHR_ENTRIES)-1:0] fill_id,
    input wire [LINE_BITS-1:0] fill_data,
    output reg wakeup_valid, output reg [$clog2(MSHR_ENTRIES)-1:0] wakeup_id,
    output reg [LINE_BITS-1:0] wakeup_data,
    input wire flush
);
    reg [MSHR_ENTRIES-1:0] valid;
    reg [PADDR_WIDTH-1:0] addr[0:MSHR_ENTRIES-1];
    reg [LINE_BITS-1:0] data[0:MSHR_ENTRIES-1];
    integer i; reg [$clog2(MSHR_ENTRIES)-1:0] free_e; reg free_f;
    always @(*) begin free_f=0; free_e=0; for(i=0;i<MSHR_ENTRIES;i=i+1) if(!valid[i]&&!free_f) begin free_e=i[$clog2(MSHR_ENTRIES)-1:0]; free_f=1; end end
    assign alloc_ready=free_f; assign alloc_id=free_e;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n||flush) begin valid<=0; wakeup_valid<=0; end
        else begin
            wakeup_valid<=0;
            if(alloc_valid&&free_f) begin valid[free_e]<=1; addr[free_e]<=alloc_addr; end
            if(fill_valid) begin data[fill_id]<=fill_data; valid[fill_id]<=0; wakeup_valid<=1; wakeup_id<=fill_id; wakeup_data<=fill_data; end
        end
    end
endmodule
