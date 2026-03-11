// ============================================================
// jtag_tap.v - JTAG Test Access Port (IEEE 1149.1)
// Supports: IDCODE, BYPASS, SAMPLE/PRELOAD, DEBUG access
// ============================================================
`timescale 1ns/1ps
module jtag_tap #(
    parameter IDCODE_VAL = 32'h00000001
)(
    input  wire         tck, input wire tms, input wire tdi, output reg tdo,
    input  wire         trst_n,
    // DR outputs
    output wire         debug_req,
    output wire [40:0]  dr_dmi_data,
    input  wire [31:0]  dr_dmi_resp,
    output wire         shift_dr, capture_dr, update_dr,
    output wire [3:0]   ir_out  // current IR
);
    // TAP state machine (16 states)
    localparam TEST_LOGIC_RESET=4'h0, RUN_TEST_IDLE=4'h1;
    localparam SELECT_DR=4'h2, CAPTURE_DR=4'h3, SHIFT_DR=4'h4, EXIT1_DR=4'h5;
    localparam PAUSE_DR=4'h6, EXIT2_DR=4'h7, UPDATE_DR=4'h8;
    localparam SELECT_IR=4'h9, CAPTURE_IR=4'hA, SHIFT_IR=4'hB, EXIT1_IR=4'hC;
    localparam PAUSE_IR=4'hD, EXIT2_IR=4'hE, UPDATE_IR=4'hF;

    reg [3:0] tap_state;
    reg [3:0] ir, ir_shift;
    reg [40:0] dr_shift;
    reg [31:0] idcode_reg;

    localparam IR_IDCODE=4'h1, IR_BYPASS=4'hF, IR_DEBUG=4'h5, IR_DTMCS=4'h6;

    // TAP state transitions
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) tap_state <= TEST_LOGIC_RESET;
        else case(tap_state)
            TEST_LOGIC_RESET: tap_state <= tms ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
            RUN_TEST_IDLE:    tap_state <= tms ? SELECT_DR : RUN_TEST_IDLE;
            SELECT_DR:        tap_state <= tms ? SELECT_IR : CAPTURE_DR;
            CAPTURE_DR:       tap_state <= tms ? EXIT1_DR : SHIFT_DR;
            SHIFT_DR:         tap_state <= tms ? EXIT1_DR : SHIFT_DR;
            EXIT1_DR:         tap_state <= tms ? UPDATE_DR : PAUSE_DR;
            PAUSE_DR:         tap_state <= tms ? EXIT2_DR : PAUSE_DR;
            EXIT2_DR:         tap_state <= tms ? UPDATE_DR : SHIFT_DR;
            UPDATE_DR:        tap_state <= tms ? SELECT_DR : RUN_TEST_IDLE;
            SELECT_IR:        tap_state <= tms ? TEST_LOGIC_RESET : CAPTURE_IR;
            CAPTURE_IR:       tap_state <= tms ? EXIT1_IR : SHIFT_IR;
            SHIFT_IR:         tap_state <= tms ? EXIT1_IR : SHIFT_IR;
            EXIT1_IR:         tap_state <= tms ? UPDATE_IR : PAUSE_IR;
            PAUSE_IR:         tap_state <= tms ? EXIT2_IR : PAUSE_IR;
            EXIT2_IR:         tap_state <= tms ? UPDATE_IR : SHIFT_IR;
            UPDATE_IR:        tap_state <= tms ? SELECT_DR : RUN_TEST_IDLE;
        endcase
    end

    // IR register
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) ir <= IR_IDCODE;
        else begin
            if (tap_state == CAPTURE_IR) ir_shift <= 4'b0001;
            else if (tap_state == SHIFT_IR) ir_shift <= {tdi, ir_shift[3:1]};
            else if (tap_state == UPDATE_IR) ir <= ir_shift;
        end
    end

    // DR register
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin dr_shift <= {41{1'b0}}; idcode_reg <= IDCODE_VAL; end
        else begin
            if (tap_state == CAPTURE_DR) begin
                case (ir)
                    IR_IDCODE: dr_shift <= {9'b0, idcode_reg};
                    IR_DEBUG:  dr_shift <= 41'b0;
                    default:   dr_shift <= {40'b0, 1'b0};
                endcase
            end else if (tap_state == SHIFT_DR) begin
                case (ir)
                    IR_IDCODE: dr_shift <= {tdi, dr_shift[40:1]};
                    IR_BYPASS: dr_shift <= {40'b0, tdi};
                    IR_DEBUG:  dr_shift <= {tdi, dr_shift[40:1]};
                    default:   dr_shift <= {tdi, dr_shift[40:1]};
                endcase
            end
        end
    end

    // TDO output
    always @(negedge tck) begin
        case (tap_state)
            SHIFT_DR: begin
                case (ir)
                    IR_IDCODE: tdo <= dr_shift[0];
                    IR_BYPASS: tdo <= dr_shift[0];
                    IR_DEBUG:  tdo <= dr_shift[0];
                    default:   tdo <= 1'b0;
                endcase
            end
            SHIFT_IR: tdo <= ir_shift[0];
            default:  tdo <= 1'b0;
        endcase
    end

    assign shift_dr    = (tap_state == SHIFT_DR);
    assign capture_dr  = (tap_state == CAPTURE_DR);
    assign update_dr   = (tap_state == UPDATE_DR);
    assign ir_out      = ir;
    assign debug_req   = (ir == IR_DEBUG) && update_dr;
    assign dr_dmi_data = dr_shift;

endmodule
