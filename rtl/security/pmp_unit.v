`timescale 1ns/1ps
// pmp_unit.v - Physical Memory Protection Unit (RISC-V PMP)
module pmp_unit #(parameter N_REGS=16, XLEN=64)(
    input wire [XLEN-1:0] paddr, input wire [1:0] priv_mode,
    input wire req_r, input wire req_w, input wire req_x,
    input wire [N_REGS*8-1:0]    pmpcfg,    // pmpNcfg packed
    input wire [N_REGS*XLEN-1:0] pmpaddr,   // pmpNaddr packed
    output reg fault
);
    integer i;
    reg [7:0] cfg; reg [XLEN-1:0] addr, base, napot_mask;
    reg match, any_match;
    always @(*) begin
        fault=0; any_match=0;
        for(i=0;i<N_REGS;i=i+1) begin
            cfg=pmpcfg[i*8+:8]; addr=pmpaddr[i*XLEN+:XLEN];
            match=0;
            case(cfg[4:3]) // A field
                2'b01: match=(paddr[XLEN-1:2]==addr[XLEN-3:0]); // TOR
                2'b10: match=(paddr[XLEN-1:3]==addr[XLEN-4:0]); // NA4
                2'b11: begin // NAPOT
                    napot_mask=~(addr^(addr+1));
                    match=((paddr&napot_mask)==(addr&napot_mask));
                end
                default: match=0;
            endcase
            if(match&&!any_match) begin
                any_match=1;
                if((req_r&&!cfg[0])||(req_w&&!cfg[1])||(req_x&&!cfg[2])) fault=1;
            end
        end
        // M-mode: if no match, allow; S/U-mode: if no match, deny
        if(!any_match && priv_mode!=2'b11) fault=1;
    end
endmodule
