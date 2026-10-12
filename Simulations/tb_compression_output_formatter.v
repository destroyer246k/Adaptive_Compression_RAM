`timescale 1ns/1ps

module tb_compression_output_formatter;

    reg clk;
    reg rst;

    reg         valid_in;
    reg [1:0]   selected_mode;

    reg [127:0] raw_data;
    reg [127:0] delta4_data;
    reg [127:0] delta8_data;

    reg [255:0] rle_data;
    reg [4:0]   rle_run_count;

    wire [255:0] compressed_data;
    wire [8:0]   compressed_size;

    wire result_valid;
    wire done;

    integer errors;


    localparam RAW    = 2'b00;
    localparam DELTA4 = 2'b01;
    localparam DELTA8 = 2'b10;
    localparam RLE    = 2'b11;


    // =====================================================
    // DUT
    // =====================================================

    compression_output_formatter uut (

        .clk(clk),
        .rst(rst),

        .valid_in(valid_in),
        .selected_mode(selected_mode),

        .raw_data(raw_data),
        .delta4_data(delta4_data),
        .delta8_data(delta8_data),

        .rle_data(rle_data),
        .rle_run_count(rle_run_count),

        .compressed_data(compressed_data),
        .compressed_size(compressed_size),

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

    task test_mode;

        input [1:0]   mode;
        input [255:0] expected_data;
        input [8:0]   expected_size;

        begin

            @(negedge clk);

            selected_mode = mode;
            valid_in      = 1'b1;

            @(negedge clk);

            valid_in = 1'b0;

            #1;

            $display(
                "Mode = %b | Size = %0d | Data = %h",
                selected_mode,
                compressed_size,
                compressed_data
            );

            if (compressed_size != expected_size) begin
                $display("  SIZE FAIL");
                errors = errors + 1;
            end
            else begin
                $display("  SIZE PASS");
            end

            if (compressed_data != expected_data) begin
                $display("  DATA FAIL");
                errors = errors + 1;
            end
            else begin
                $display("  DATA PASS");
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
        selected_mode = RAW;

        raw_data   = 128'd0;
        delta4_data = 128'd0;
        delta8_data = 128'd0;

        rle_data = 256'd0;
        rle_run_count = 0;

        errors = 0;


        // Reset
        #12;
        rst = 0;


        $display("");
        $display("COMPRESSION OUTPUT FORMATTER TEST");
        $display("----------------------------------");
        $display("");


        // =================================================
        // TEST DATA
        // =================================================

        raw_data =
            128'h100F0E0D0C0B0A090807060504030201;

        delta4_data =
            128'h0000000000000001111111111114E364;

        delta8_data =
            128'hFB14F60FFB140AEC0FFB14F650E23264;

        rle_data =
            256'h0000000000000000000000000000000000000000000000000144024303420441;

        rle_run_count = 5'd4;


        // =================================================
        // RAW
        // =================================================

        test_mode(
            RAW,

            256'h00000000000000000000000000000000100F0E0D0C0B0A090807060504030201,

            9'd128
        );


        // =================================================
        // DELTA4
        // =================================================

        test_mode(
            DELTA4,

            256'h000000000000000000000000000000000000000000000001111111111114E364,

            9'd68
        );


        // =================================================
        // DELTA8
        // =================================================

        test_mode(
            DELTA8,

            256'h00000000000000000000000000000000FB14F60FFB140AEC0FFB14F650E23264,

            9'd128
        );


        // =================================================
        // RLE
        // =================================================

        test_mode(
            RLE,

            256'h0000000000000000000000000000000000000000000000000144024303420441,

            9'd64
        );


        // =================================================
        // FINAL RESULT
        // =================================================

        $display("");

        if (errors == 0) begin

            $display("ERRORS = 0");
            $display("COMPRESSION OUTPUT FORMATTER TEST PASS");

        end

        else begin

            $display("ERRORS = %0d", errors);
            $display("COMPRESSION OUTPUT FORMATTER TEST FAIL");

        end

        $finish;

    end

endmodule