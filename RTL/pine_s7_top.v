`timescale 1ns/1ps

// =====================================================================
// PINE S7 (XC7S15-FTGB196-1) demo wrapper for
// adaptive_compression_memory_controller
//
// The core has 128-bit inputs / 256-bit outputs, far more than the board
// exposes, so this wrapper feeds it from built-in test blocks and shows
// the result on the 7-segment display and LEDs.
//
// CONTROLS
//   SLIDE_SW[2:0]   test pattern (see pattern_rom below)
//   SLIDE_SW[7:4]   block address: write target AND the block being viewed
//   SLIDE_SW[15:12] which 16-bit slice (0..15) of the stored 256-bit
//                   compressed word is shown on LED[15:0]
//   KEY_0           write the selected pattern to the selected block
//   KEY_3           reset (buttons are ACTIVE-LOW per the board manual)
//
// 7-SEGMENT  ->  [mode].[size in bits, 3 digits]
//   mode: 0 = RAW, 1 = DELTA4, 2 = DELTA8, 3 = RLE
//   e.g.  "1.068" = DELTA4, 68 bits stored (vs 128 raw)
// =====================================================================
module pine_s7_top #(
    // The manual does not document display polarity - if the display is
    // blank, dim or shows garbage, flip these two.
    parameter SEG_ACTIVE_LOW = 1,   // 1: segment lit by driving 0
    parameter SEL_ACTIVE_LOW = 1,   // 1: digit enabled by driving 0
    // Debounce sample tick = 2^TICK_BITS clocks (17 -> 1.3 ms @ 100 MHz).
    // Reduced in simulation only.
    parameter TICK_BITS      = 17,
    // Display scan counter width (18 -> ~381 Hz per digit @ 100 MHz).
    // Reduced in simulation only.
    parameter SCAN_BITS      = 18
)(
    input  wire        osc_clk_100mhz,

    input  wire        KEY_0,
    input  wire        KEY_3,
    input  wire [15:0] SLIDE_SW,

    output wire [15:0] LED,

    output wire        SIG_A, SIG_B, SIG_C, SIG_D, SIG_E, SIG_F, SIG_G, SIG_PD,
    output wire        SEL_DISP1, SEL_DISP2, SEL_DISP3, SEL_DISP4
);

    wire clk = osc_clk_100mhz;

    // -----------------------------------------------------------------
    // Input synchronisers
    // -----------------------------------------------------------------
    reg [15:0] sw_s1 = 16'd0, sw_s2 = 16'd0;
    reg        k0_s1 = 1'b1, k0_s2 = 1'b1;
    reg        k3_s1 = 1'b1, k3_s2 = 1'b1;

    always @(posedge clk) begin
        sw_s1 <= SLIDE_SW;  sw_s2 <= sw_s1;
        k0_s1 <= KEY_0;     k0_s2 <= k0_s1;
        k3_s1 <= KEY_3;     k3_s2 <= k3_s1;
    end

    // -----------------------------------------------------------------
    // Debounce (8 consecutive "pressed" samples) - buttons are active-low
    // -----------------------------------------------------------------
    reg [TICK_BITS-1:0] tick_cnt = 0;
    wire tick = (tick_cnt == {TICK_BITS{1'b1}});
    always @(posedge clk) tick_cnt <= tick_cnt + 1'b1;

    reg [7:0] k0_hist = 8'hFF;
    reg [7:0] k3_hist = 8'hFF;
    reg       k0_pressed = 1'b0, k3_pressed = 1'b0;
    reg       k0_prev    = 1'b0;

    always @(posedge clk) begin
        if (tick) begin
            k0_hist <= {k0_hist[6:0], k0_s2};
            k3_hist <= {k3_hist[6:0], k3_s2};
        end
        if (k0_hist == 8'h00) k0_pressed <= 1'b1;
        else if (k0_hist == 8'hFF) k0_pressed <= 1'b0;
        if (k3_hist == 8'h00) k3_pressed <= 1'b1;
        else if (k3_hist == 8'hFF) k3_pressed <= 1'b0;
        k0_prev <= k0_pressed;
    end

    wire write_pulse_req = k0_pressed & ~k0_prev;   // one clock per press

    // -----------------------------------------------------------------
    // Power-on reset + manual reset (registered -> glitch-free async reset)
    // -----------------------------------------------------------------
    reg [3:0] por_cnt = 4'd0;
    reg       rst     = 1'b1;
    always @(posedge clk) begin
        if (por_cnt != 4'hF) por_cnt <= por_cnt + 1'b1;
        rst <= (por_cnt != 4'hF) | k3_pressed;
    end

    // -----------------------------------------------------------------
    // Test patterns (byte 0 = bits [7:0])
    // -----------------------------------------------------------------
    reg [127:0] pattern;
    always @(*) begin
        case (sw_s2[2:0])
            3'd0: pattern = 128'h100F0E0D0C0B0A090807060504030201; // +1 ramp        -> DELTA4
            3'd1: pattern = 128'h7574737271706F6E6D6C6B6A69686764; // ramp, one +3   -> DELTA4
            3'd2: pattern = 128'hF5FAE6EAF0E0D2C8D2BED2C0C8C87864; // irregular      -> RAW
            3'd3: pattern = 128'h44444343434242424141414141414141; // 4 runs         -> RLE
            3'd4: pattern = 128'h00000000000000000000000000000000; // all zeros      -> RLE (1 run)
            3'd5: pattern = 128'hFF00FF00FF00FF00FF00FF00FF00FF00; // alternating    -> RAW
            3'd6: pattern = 128'hFFFFFFFFFFFFFFFF0000000000000000; // 2 runs         -> RLE
            3'd7: pattern = 128'hE1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0; // -1 ramp        -> DELTA4
        endcase
    end

    // -----------------------------------------------------------------
    // Compression core
    // -----------------------------------------------------------------
    wire [3:0] blk_addr = sw_s2[7:4];

    wire         busy, write_done;
    wire [255:0] data_read_data;
    wire [1:0]   meta_mode;
    wire [7:0]   meta_comp_addr;
    wire [7:0]   meta_comp_size;

    // Only accept a new write while the core is idle
    wire write_start = write_pulse_req & ~busy;

    adaptive_compression_memory_controller u_core (
        .clk                     (clk),
        .rst                     (rst),

        .write_start             (write_start),
        .block_addr              (blk_addr),
        .block_data              (pattern),

        // Continuous read-back: metadata of the selected block, then the
        // compressed word it points at (two registered stages).
        .data_read_en            (1'b1),
        .data_read_addr          (meta_comp_addr),
        .data_read_data          (data_read_data),
        .data_read_valid         (),

        .metadata_read_en        (1'b1),
        .metadata_read_addr      (blk_addr),
        .metadata_read_mode      (meta_mode),
        .metadata_read_comp_addr (meta_comp_addr),
        .metadata_read_comp_size (meta_comp_size),
        .metadata_read_valid     (),

        .write_done              (write_done),
        .busy                    (busy)
    );

    // -----------------------------------------------------------------
    // LEDs: 16-bit slice of the stored compressed word
    // -----------------------------------------------------------------
    reg [15:0] slice;
    always @(*) slice = data_read_data[sw_s2[15:12]*16 +: 16];
    assign LED = slice;

    // -----------------------------------------------------------------
    // 7-segment: [mode].[hundreds][tens][ones of size in bits]
    // -----------------------------------------------------------------
    wire [3:0] d_mode = {2'b00, meta_mode};
    wire [3:0] d_h    = meta_comp_size / 8'd100;
    wire [3:0] d_t    = (meta_comp_size / 8'd10) % 4'd10;
    wire [3:0] d_o    = meta_comp_size % 8'd10;

    reg [SCAN_BITS-1:0] scan = 0;
    always @(posedge clk) scan <= scan + 1'b1;

    reg [3:0] digit;
    reg [3:0] sel_oh;   // one-hot, active-high internally
    reg       dp;
    always @(*) begin
        case (scan[SCAN_BITS-1:SCAN_BITS-2])
            2'd0: begin digit = d_mode; sel_oh = 4'b0001; dp = 1'b1; end
            2'd1: begin digit = d_h;    sel_oh = 4'b0010; dp = 1'b0; end
            2'd2: begin digit = d_t;    sel_oh = 4'b0100; dp = 1'b0; end
            default: begin digit = d_o; sel_oh = 4'b1000; dp = 1'b0; end
        endcase
    end

    reg [6:0] seg_g_to_a;   // {g,f,e,d,c,b,a}, active-high
    always @(*) begin
        case (digit)
            4'd0: seg_g_to_a = 7'b0111111;
            4'd1: seg_g_to_a = 7'b0000110;
            4'd2: seg_g_to_a = 7'b1011011;
            4'd3: seg_g_to_a = 7'b1001111;
            4'd4: seg_g_to_a = 7'b1100110;
            4'd5: seg_g_to_a = 7'b1101101;
            4'd6: seg_g_to_a = 7'b1111101;
            4'd7: seg_g_to_a = 7'b0000111;
            4'd8: seg_g_to_a = 7'b1111111;
            4'd9: seg_g_to_a = 7'b1101111;
            default: seg_g_to_a = 7'b0000000;
        endcase
    end

    wire [7:0] seg_out = SEG_ACTIVE_LOW ? ~{dp, seg_g_to_a} :  {dp, seg_g_to_a};
    wire [3:0] sel_out = SEL_ACTIVE_LOW ? ~sel_oh           :  sel_oh;

    assign {SIG_PD, SIG_G, SIG_F, SIG_E, SIG_D, SIG_C, SIG_B, SIG_A} = seg_out;
    // Digit-select order corrected after the first test on real hardware:
    // physical display DIS1..DIS4 (left to right) = mode, hundreds, tens, ones.
    // sel_out[0]=mode, [1]=hundreds, [2]=tens, [3]=ones
    assign SEL_DISP3 = sel_out[0];   // physical DIS1 (leftmost)
    assign SEL_DISP4 = sel_out[1];   // physical DIS2
    assign SEL_DISP1 = sel_out[2];   // physical DIS3
    assign SEL_DISP2 = sel_out[3];   // physical DIS4 (rightmost)

endmodule
