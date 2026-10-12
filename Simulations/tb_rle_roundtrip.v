`timescale 1ns/1ps

module tb_rle_roundtrip;

    reg clk;
    reg rst;

    // ==================================================
    // COMPRESSOR INPUT
    // ==================================================

    reg [7:0] comp_data_in;
    reg       comp_valid_in;
    reg       comp_start;
    reg       comp_last;


    // ==================================================
    // COMPRESSOR OUTPUT
    // ==================================================

    wire [7:0] comp_symbol_out;
    wire [4:0] comp_count_out;
    wire       comp_valid_out;
    wire       comp_done;


    // ==================================================
    // DECOMPRESSOR INPUT
    // ==================================================

    reg [7:0] decomp_symbol_in;
    reg [4:0] decomp_count_in;
    reg       decomp_valid_in;
    reg       decomp_last_in;


    // ==================================================
    // DECOMPRESSOR OUTPUT
    // ==================================================

    wire [7:0] decomp_data_out;
    wire       decomp_valid_out;
    wire       decomp_done;


    // ==================================================
    // COMPRESSED DATA STORAGE
    // ==================================================

    reg [7:0] compressed_symbol [0:15];
    reg [4:0] compressed_count  [0:15];

    reg compressed_last [0:15];

    integer compressed_pairs;


    // ==================================================
    // ORIGINAL DATA
    // ==================================================

    reg [7:0] original_data [0:15];

    integer input_count;
    integer output_count;
    integer errors;


    // ==================================================
    // UUT 1 : RLE COMPRESSOR
    // ==================================================

    rle_compressor compressor_uut (

        .clk        (clk),
        .rst        (rst),

        .data_in    (comp_data_in),
        .valid_in   (comp_valid_in),
        .start      (comp_start),
        .last       (comp_last),

        .symbol_out (comp_symbol_out),
        .count_out  (comp_count_out),
        .valid_out  (comp_valid_out),
        .done        (comp_done)

    );


    // ==================================================
    // UUT 2 : RLE DECOMPRESSOR
    // ==================================================

    rle_decompressor decompressor_uut (

        .clk        (clk),
        .rst        (rst),

        .symbol_in  (decomp_symbol_in),
        .count_in   (decomp_count_in),
        .valid_in   (decomp_valid_in),
        .last_in    (decomp_last_in),

        .data_out   (decomp_data_out),
        .valid_out  (decomp_valid_out),
        .done        (decomp_done)

    );


    // ==================================================
    // CLOCK
    // ==================================================

    always #5 clk = ~clk;


    // ==================================================
    // CAPTURE COMPRESSED OUTPUT
    // ==================================================

    always @(posedge clk) begin

        if (comp_valid_out) begin

            compressed_symbol[compressed_pairs] = comp_symbol_out;
            compressed_count[compressed_pairs]  = comp_count_out;

            $display(
                "COMPRESSED: %c , %0d",
                comp_symbol_out,
                comp_count_out
            );

            compressed_pairs = compressed_pairs + 1;

        end

    end


    // ==================================================
    // CHECK DECOMPRESSED OUTPUT
    // ==================================================

    always @(posedge clk) begin

        if (decomp_valid_out) begin

            $display(
                "DECOMPRESSED: %c | EXPECTED: %c",
                decomp_data_out,
                original_data[output_count]
            );

            if (decomp_data_out != original_data[output_count]) begin

                $display("ERROR at byte %0d", output_count);

                errors = errors + 1;

            end

            output_count = output_count + 1;

        end

    end


    // ==================================================
    // SEND ONE BYTE TO COMPRESSOR
    // ==================================================

    task send_byte;

        input [7:0] data;
        input       first;
        input       final_byte;

        begin

            @(negedge clk);

            comp_data_in  = data;
            comp_valid_in = 1;
            comp_start   = first;
            comp_last    = final_byte;

            @(negedge clk);

            comp_valid_in = 0;
            comp_start   = 0;
            comp_last    = 0;

        end

    endtask


    // ==================================================
    // MAIN TEST
    // ==================================================

    integer i;

    initial begin

        clk = 0;
        rst = 1;

        comp_data_in  = 0;
        comp_valid_in = 0;
        comp_start    = 0;
        comp_last     = 0;

        decomp_symbol_in = 0;
        decomp_count_in  = 0;
        decomp_valid_in  = 0;
        decomp_last_in   = 0;

        compressed_pairs = 0;
        input_count      = 0;
        output_count     = 0;
        errors           = 0;


        // ==================================================
        // ORIGINAL DATA
        // ==================================================

        original_data[0] = "A";
        original_data[1] = "A";
        original_data[2] = "A";
        original_data[3] = "A";

        original_data[4] = "B";
        original_data[5] = "B";
        original_data[6] = "B";

        original_data[7] = "C";
        original_data[8] = "C";


        // ==================================================
        // RESET
        // ==================================================

        #20;
        rst = 0;


        // ==================================================
        // SEND ORIGINAL DATA
        // ==================================================

        send_byte("A", 1, 0);
        send_byte("A", 0, 0);
        send_byte("A", 0, 0);
        send_byte("A", 0, 0);

        send_byte("B", 0, 0);
        send_byte("B", 0, 0);
        send_byte("B", 0, 0);

        send_byte("C", 0, 0);
        send_byte("C", 0, 1);


        // Wait for compressor to finish
        #50;


        // ==================================================
        // FEED COMPRESSED DATA TO DECOMPRESSOR
        // ==================================================

        for (i = 0; i < compressed_pairs; i = i + 1) begin

            @(negedge clk);

            decomp_symbol_in = compressed_symbol[i];
            decomp_count_in  = compressed_count[i];
            decomp_valid_in  = 1;

            if (i == compressed_pairs - 1)
                decomp_last_in = 1;
            else
                decomp_last_in = 0;


            @(negedge clk);

            decomp_valid_in = 0;
            decomp_last_in  = 0;


            // Wait for decompressor to finish
            repeat (compressed_count[i] + 1)
                @(negedge clk);

        end


        // ==================================================
        // FINAL RESULT
        // ==================================================

        #30;

        if (errors == 0 && output_count == 9) begin

            $display("");
            $display("======================================");
            $display("       RLE ROUND-TRIP TEST PASS");
            $display("======================================");
            $display("Original bytes     = 9");
            $display("Compressed pairs   = %0d", compressed_pairs);
            $display("Decompressed bytes = %0d", output_count);
            $display("Errors             = %0d", errors);
            $display("======================================");

        end
        else begin

            $display("");
            $display("======================================");
            $display("       RLE ROUND-TRIP TEST FAIL");
            $display("======================================");
            $display("Original bytes     = 9");
            $display("Compressed pairs   = %0d", compressed_pairs);
            $display("Decompressed bytes = %0d", output_count);
            $display("Errors             = %0d", errors);
            $display("======================================");

        end

        $finish;

    end

endmodule