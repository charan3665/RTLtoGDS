`timescale 1ns/1ps
module i2c_top(
    input wire clk, input wire rst_n,
    input wire psel, input wire pena, input wire pwrite, input wire [7:0] paddr, input wire [31:0] pwdata,
    output reg [31:0] prdata, output wire pready,
    inout wire sda, output wire scl, output wire irq
);
    reg [6:0] dev_addr_r; reg [7:0] reg_addr_r, wr_data_r; reg wr_en_r, rd_en_r;
    wire [7:0] rd_data; wire done;
    i2c_master u_m(.clk(clk),.rst_n(rst_n),.dev_addr(dev_addr_r),.reg_addr(reg_addr_r),.wr_data(wr_data_r),.wr_en(wr_en_r),.rd_en(rd_en_r),.rd_data(rd_data),.done(done),.sda(sda),.scl(scl));
    assign pready=1; assign irq=done;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin wr_en_r<=0; rd_en_r<=0; prdata<=0; end
        else begin wr_en_r<=0; rd_en_r<=0;
            if(psel&&pena&&pwrite) begin case(paddr) 8'h00:dev_addr_r<=pwdata[6:0]; 8'h04:wr_data_r<=pwdata[7:0]; 8'h08:wr_en_r<=pwdata[0]; endcase end
            if(psel&&pena&&!pwrite) prdata<={24'b0,rd_data};
        end
    end
endmodule
