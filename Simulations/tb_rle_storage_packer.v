`timescale 1ns/1ps

module tb_rle_storage_packer;

    reg clk;
    reg rst;

    reg [7:0] data_in;
    reg valid_in;
    reg start;
    reg last;

    wire [7:0] symbol_out;
    wire [4:0] count_out;
    wire rle_valid;
    wire rle_done;

    wire [255:0] packed_data;
    wire [4:0] run_count;
    wire packed_valid;
    wire packed_done;

    integer errors;


    // =========================================================
    // RLE COMPRESSOR
    // =========================================================

    rle_compressor rle_uut (

        .clk(clk),
        .rst(rst),

        .data_in(data_in),
        .valid_in(valid_in),
        .start(start),
        .last(last),

        .symbol_out(symbol_out),
        .count_out(count_out),
        .valid_out(rle_valid),
        .done(rle_done)
    );


    // =========================================================
    // RLE STORAGE PACKER
    // =========================================================

    rle_storage_packer storage_uut (

        .clk(clk),
        .rst(rst),

        .symbol_in(symbol_out),
        .count_in(count_out),

        .valid_in(rle_valid),
        .done_in(rle_done),

        .packed_data(packed_data),
        .run_count(run_count),

        .packed_valid(packed_valid),
        .done(packed_done)
    );


    // =========================================================
    // CLOCK
    // =========================================================

    always #5 clk = ~clk;


    // =========================================================
    // SEND BYTE TASK
    // =========================================================

    task send_byte;

        input [7:0] value;
        input       is_start;
        input       is_last;

        begin

            @(negedge clk);

            data_in  = value;
            valid_in = 1'b1;
            start    = is_start;
            last     = is_last;

            @(negedge clk);

            valid_in = 1'b0;
            start    = 1'b0;
            last     = 1'b0;

        end

    endtask


    // =========================================================
    // TEST
    // =========================================================

    initial begin

        clk = 0;

        rst = 1;

        data_in  = 8'd0;
        valid_in = 1'b0;
        start    = 1'b0;
        last     = 1'b0;

        errors = 0;


        // Reset
        #12;
        rst = 1'b0;


        /*
         * TEST BLOCK
         *
         * A A A A
         * B B B
         * C C
         * D
         *
         * Expected:
         *
         * (A,4)
         * (B,3)
         * (C,2)
         * (D,1)
         */

        send_byte(8'h41, 1'b1, 1'b0); // A
        send_byte(8'h41, 1'b0, 1'b0); // A
        send_byte(8'h41, 1'b0, 1'b0); // A
        send_byte(8'h41, 1'b0, 1'b0); // A

        send_byte(8'h42, 1'b0, 1'b0); // B
        send_byte(8'h42, 1'b0, 1'b0); // B
        send_byte(8'h42, 1'b0, 1'b0); // B

        send_byte(8'h43, 1'b0, 1'b0); // C
        send_byte(8'h43, 1'b0, 1'b0); // C

        // Last byte
        send_byte(8'h44, 1'b0, 1'b1); // D


        // Wait for storage packer
        wait(packed_done);

        #1;


        // =====================================================
        // DISPLAY
        // =====================================================

        $display("");
        $display("RLE STORAGE PACKER TEST");
        $display("------------------------");
        $display("");

        $display("Run count = %0d", run_count);

        $display("");
        $display("Pair 0 = %h", packed_data[15:0]);
        $display("Pair 1 = %h", packed_data[31:16]);
        $display("Pair 2 = %h", packed_data[47:32]);
        $display("Pair 3 = %h", packed_data[63:48]);

        $display("");
        $display("Packed data = %h", packed_data);
        $display("");


        // =====================================================
        // CHECK RUN COUNT
        // =====================================================

        if (run_count == 4)
            $display("Run count PASS");
        else begin
            $display("Run count FAIL");
            errors = errors + 1;
        end


        // =====================================================
        // CHECK PAIR 0
        //
        // A = 41
        // count = 4
        // 000 00100 01000001
        // = 0441
        // =====================================================

        if (packed_data[15:0] == 16'h0441)
            $display("Pair 0 (A,4) PASS");
        else begin
            $display("Pair 0 (A,4) FAIL");
            errors = errors + 1;
        end


        // =====================================================
        // CHECK PAIR 1
        // B = 42
        // count = 3
        // = 0342
        // =====================================================

        if (packed_data[31:16] == 16'h0342)
            $display("Pair 1 (B,3) PASS");
        else begin
            $display("Pair 1 (B,3) FAIL");
            errors = errors + 1;
        end


        // =====================================================
        // CHECK PAIR 2
        // C = 43
        // count = 2
        // = 0243
        // =====================================================

        if (packed_data[47:32] == 16'h0243)
            $display("Pair 2 (C,2) PASS");
        else begin
            $display("Pair 2 (C,2) FAIL");
            errors = errors + 1;
        end


        // =====================================================
        // CHECK PAIR 3
        // D = 44
        // count = 1
        // = 0144
        // =====================================================

        if (packed_data[63:48] == 16'h0144)
            $display("Pair 3 (D,1) PASS");
        else begin
            $display("Pair 3 (D,1) FAIL");
            errors = errors + 1;
        end


        // =====================================================
        // FINAL RESULT
        // =====================================================

        if (errors == 0) begin

            $display("");
            $display("ERRORS = 0");
            $display("RLE STORAGE PACKER TEST PASS");

        end

        else begin

            $display("");
            $display("ERRORS = %0d", errors);
            $display("RLE STORAGE PACKER TEST FAIL");

        end


        $finish;

    end

endmodule