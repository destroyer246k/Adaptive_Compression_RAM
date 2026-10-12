`timescale 1ns/1ps

module tb_adaptive_selector;

    reg clk;
    reg rst;

    reg valid_in;
    reg [4:0] rle_run_count;
    reg [1:0] delta_mode;

    wire [1:0] selected_mode;
    wire [8:0] selected_size;
    wire result_valid;
    wire done;

    integer errors;

    // Mode definitions
    localparam RAW    = 2'b00;
    localparam DELTA4 = 2'b01;
    localparam DELTA8 = 2'b10;
    localparam RLE    = 2'b11;


    // =====================================================
    // DUT
    // =====================================================

    adaptive_selector uut (

        .clk(clk),
        .rst(rst),

        .valid_in(valid_in),

        .rle_run_count(rle_run_count),
        .delta_mode(delta_mode),

        .selected_mode(selected_mode),
        .selected_size(selected_size),

        .result_valid(result_valid),
        .done(done)
    );


    // =====================================================
    // CLOCK
    // =====================================================

    always #5 clk = ~clk;


    // =====================================================
    // TEST TASK
    // =====================================================

    task test_case;

        input [4:0] rle_runs;
        input [1:0] d_mode;

        input [1:0] expected_mode;
        input [8:0] expected_size;

        begin

            @(negedge clk);

            rle_run_count = rle_runs;
            delta_mode = d_mode;
            valid_in = 1'b1;

            @(negedge clk);

            valid_in = 1'b0;

            #1;

            $display(
                "RLE runs = %0d | Delta mode = %b | Selected = %b | Size = %0d",
                rle_runs,
                d_mode,
                selected_mode,
                selected_size
            );

            if (selected_mode != expected_mode) begin
                $display("MODE FAIL");
                errors = errors + 1;
            end

            if (selected_size != expected_size) begin
                $display("SIZE FAIL");
                errors = errors + 1;
            end

        end

    endtask


    // =====================================================
    // TEST
    // =====================================================

    initial begin

        clk = 0;
        rst = 1;

        valid_in = 0;
        rle_run_count = 0;
        delta_mode = RAW;

        errors = 0;

        #12;
        rst = 0;


        $display("");
        $display("ADAPTIVE SELECTOR TEST");
        $display("-----------------------");
        $display("");


        // =================================================
        // TEST 1
        //
        // RLE = 3 × 16 = 48
        // DELTA4 = 68
        //
        // Expected RLE
        // =================================================

        test_case(
            5'd3,
            DELTA4,
            RLE,
            9'd48
        );


        // =================================================
        // TEST 2
        //
        // RLE = 10 × 16 = 160
        // DELTA4 = 68
        //
        // Expected DELTA4
        // =================================================

        test_case(
            5'd10,
            DELTA4,
            DELTA4,
            9'd68
        );


        // =================================================
        // TEST 3
        //
        // RLE = 10 × 16 = 160
        // DELTA8 = 128
        //
        // Expected RAW
        //
        // RAW and DELTA8 are equal.
        // =================================================

        test_case(
            5'd10,
            DELTA8,
            RAW,
            9'd128
        );


        // =================================================
        // TEST 4
        //
        // RLE = 7 × 16 = 112
        // DELTA4 = 68
        //
        // Expected DELTA4
        // =================================================

        test_case(
            5'd7,
            DELTA4,
            DELTA4,
            9'd68
        );


        // =================================================
        // TEST 5
        //
        // RLE = 8 × 16 = 128
        // DELTA4 = 68
        //
        // Expected DELTA4
        // =================================================

        test_case(
            5'd8,
            DELTA4,
            DELTA4,
            9'd68
        );


        // =================================================
        // TEST 6
        //
        // RLE = 8 × 16 = 128
        // DELTA8 = 128
        //
        // Expected RAW
        // =================================================

        test_case(
            5'd8,
            DELTA8,
            RAW,
            9'd128
        );


        // =================================================
        // FINAL RESULT
        // =================================================

        $display("");

        if (errors == 0) begin

            $display("ERRORS = 0");
            $display("ADAPTIVE SELECTOR TEST PASS");

        end

        else begin

            $display("ERRORS = %0d", errors);
            $display("ADAPTIVE SELECTOR TEST FAIL");

        end

        $finish;

    end

endmodule