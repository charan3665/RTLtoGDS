`timescale 1ns/1ps
// firewall.v - AXI4 Firewall: enforces access control policies
module firewall #(parameter AW=64, N_RULES=16)(
    input wire clk, input wire rst_n,
    // Transaction to check
    input wire [AW-1:0] req_addr, input wire req_wr,
    input wire [3:0] req_master_id,
    output reg req_allow, output reg req_deny,
    // Rule configuration (APB)
    input wire rule_wr, input wire [3:0] rule_idx,
    input wire [AW-1:0] rule_base, rule_mask,
    input wire [15:0] rule_allow_mstr,  // bitmask of allowed masters
    input wire [1:0] rule_perm          // 00=none, 01=ro, 10=wo, 11=rw
);
    reg [AW-1:0] base[0:N_RULES-1], mask[0:N_RULES-1];
    reg [15:0] amask[0:N_RULES-1];
    reg [1:0] perm[0:N_RULES-1];
    reg [N_RULES-1:0] en;
    integer i;
    always @(posedge clk) if(rule_wr) begin base[rule_idx]<=rule_base; mask[rule_idx]<=rule_mask; amask[rule_idx]<=rule_allow_mstr; perm[rule_idx]<=rule_perm; en[rule_idx]<=1; end
    always @(*) begin
        req_allow=0; req_deny=0;
        for(i=0;i<N_RULES;i=i+1) begin
            if(en[i] && (req_addr&mask[i])==base[i]) begin
                if(amask[i][req_master_id] && ((req_wr&&perm[i][1])||(!req_wr&&perm[i][0]))) req_allow=1;
                else req_deny=1;
            end
        end
        if(!req_allow&&!req_deny) req_allow=1; // default allow
    end
endmodule
