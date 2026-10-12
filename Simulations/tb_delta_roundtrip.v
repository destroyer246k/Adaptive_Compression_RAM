`timescale 1ns/1ps

module tb_delta_roundtrip;

    reg clk;
    reg rst;

    //========================================================
    // COMPRESSOR INPUTS
    //========================================================
    reg [7:0] data_in;
    reg valid_in;
    reg start;
    reg last;

    //========================================================
    // COMPRESSOR OUTPUTS
    //========================================================
    wire [7:0] first_value;
    wire signed [8:0] delta_out;

    wire first_valid;
    wire delta_valid;
    wire delta_last;          // CHANGED
    wire comp_done;

    //========================================================
    // DECOMPRESSOR INPUTS
    //========================================================
    reg [7:0] first_value_in;
    reg signed [8:0] delta_in;

    reg first_valid_in;
    reg delta_valid_in;
    reg delta_last_in;        // CHANGED

    //========================================================
    // DECOMPRESSOR OUTPUTS
    //========================================================
    wire [7:0] data_out;
    wire valid_out;
    wire decomp_done;

    //========================================================
    // ORIGINAL DATA
    //========================================================
    reg [7:0] original_data [0:4];

    integer i;
    integer output_count;
    integer error_count;

    //========================================================
    // COMPRESSOR
    //========================================================
    delta_compressor compressor_uut (
        .clk(clk),
        .rst(rst),

        .data_in(data_in),
        .valid_in(valid_in),
        .start(start),
        .last(last),

        .first_value(first_value),
        .delta_out(delta_out),

        .first_valid(first_valid),
        .delta_valid(delta_valid),
        .delta_last(delta_last),       // CHANGED
        .done(comp_done)
    );

    //========================================================
    // DECOMPRESSOR
    //========================================================
    delta_decompressor decompressor_uut (
        .clk(clk),
        .rst(rst),

        .first_value_in(first_value_in),
        .delta_in(delta_in),

        .first_valid(first_valid_in),
        .delta_valid(delta_valid_in),
        .delta_last(delta_last_in),    // CHANGED

        .data_out(data_out),
        .valid_out(valid_out),
        .done(decomp_done)
    );

    //========================================================
    // CLOCK
    //========================================================
    always #5 clk = ~clk;


    //========================================================
    // SEND COMPRESSOR OUTPUT TO DECOMPRESSOR
    //========================================================
    always @(posedge clk) begin

        // Default
        first_valid_in <= 1'b0;
        delta_valid_in <= 1'b0;
        delta_last_in  <= 1'b0;        // CHANGED

        //----------------------------------------------------
        // FIRST VALUE
        //----------------------------------------------------
        if (first_valid) begin

            first_value_in <= first_value;
            first_valid_in <= 1'b1;

            $display(
                "COMPRESSED FIRST = %0d",
                first_value
            );

        end

        //----------------------------------------------------
        // DELTA
        //----------------------------------------------------
        if (delta_valid) begin

            delta_in       <= delta_out;
            delta_valid_in <= 1'b1;

            // Pass actual last signal from compressor
            delta_last_in  <= delta_last;       // CHANGED

            $display(
                "COMPRESSED DELTA = %0d | LAST = %b",
                delta_out,
                delta_last
            );

        end

    end


    //========================================================
    // CHECK DECOMPRESSED OUTPUT
    //========================================================
    always @(posedge clk) begin

        if (valid_out) begin

            $display(
                "DECOMPRESSED = %0d | EXPECTED = %0d",
                data_out,
                original_data[output_count]
            );

            if (data_out != original_data[output_count]) begin

                error_count = error_count + 1;

                $display("ERROR!");

            end

            output_count = output_count + 1;

        end


        if (decomp_done) begin

            $display("");
            $display("================================");
            $display("DELTA ROUND-TRIP TEST COMPLETE");
            $display("Original bytes     = 5");

            $display(
                "Decompressed bytes = %0d",
                output_count
            );

            $display(
                "Errors             = %0d",
                error_count
            );

            if ((error_count == 0) &&
                (output_count == 5))

                $display(
                    "DELTA ROUND-TRIP TEST PASS"
                );

            else

                $display(
                    "DELTA ROUND-TRIP TEST FAIL"
                );

            $display("================================");

        end

    end


    //========================================================
    // STIMULUS
    //========================================================
    initial begin

        clk = 0;
        rst = 1;

        data_in  = 0;
        valid_in = 0;
        start    = 0;
        last     = 0;

        first_value_in = 0;
        delta_in       = 0;

        first_valid_in = 0;
        delta_valid_in = 0;
        delta_last_in  = 0;        // CHANGED

        output_count = 0;
        error_count  = 0;


        //----------------------------------------------------
        // ORIGINAL DATA
        //----------------------------------------------------
        original_data[0] = 8'd100;
        original_data[1] = 8'd103;
        original_data[2] = 8'd101;
        original_data[3] = 8'd105;
        original_data[4] = 8'd106;


        //----------------------------------------------------
        // RESET
        //----------------------------------------------------
        #20;
        rst = 0;


        //----------------------------------------------------
        // BYTE 0
        //----------------------------------------------------
        @(posedge clk);

        data_in  = 8'd100;
        valid_in = 1'b1;
        start    = 1'b1;
        last     = 1'b0;


        //----------------------------------------------------
        // BYTE 1
        //----------------------------------------------------
        @(posedge clk);

        data_in = 8'd103;
        start   = 1'b0;
        last    = 1'b0;


        //----------------------------------------------------
        // BYTE 2
        //----------------------------------------------------
        @(posedge clk);

        data_in = 8'd101;
        last    = 1'b0;


        //----------------------------------------------------
        // BYTE 3
        //----------------------------------------------------
        @(posedge clk);

        data_in = 8'd105;
        last    = 1'b0;


        //----------------------------------------------------
        // BYTE 4
        //----------------------------------------------------
        @(posedge clk);

        data_in = 8'd106;
        last    = 1'b1;


        //----------------------------------------------------
        // STOP INPUT
        //----------------------------------------------------
        @(posedge clk);

        valid_in = 1'b0;
        last     = 1'b0;


        //----------------------------------------------------
        // WAIT
        //----------------------------------------------------
        #300;

        $finish;

    end

endmodule