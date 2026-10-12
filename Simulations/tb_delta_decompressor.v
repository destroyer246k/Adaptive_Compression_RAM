`timescale 1ns/1ps

module tb_delta_decompressor;

    reg clk;
    reg rst;

    reg [7:0] first_value_in;
    reg signed [8:0] delta_in;

    reg first_valid;
    reg delta_valid;
    reg last;

    wire [7:0] data_out;
    wire       valid_out;
    wire       done;


    // ==================================
    // UUT
    // ==================================

    delta_decompressor uut (

        .clk            (clk),
        .rst            (rst),

        .first_value_in (first_value_in),
        .delta_in       (delta_in),

        .first_valid    (first_valid),
        .delta_valid    (delta_valid),
        .last           (last),

        .data_out       (data_out),
        .valid_out      (valid_out),
        .done           (done)

    );


    // ==================================
    // CLOCK
    // ==================================

    always #5 clk = ~clk;


    // ==================================
    // STIMULUS
    // ==================================

    initial begin

        clk = 0;
        rst = 1;

        first_value_in = 0;
        delta_in       = 0;

        first_valid = 0;
        delta_valid = 0;
        last        = 0;


        // Reset
        #20;
        rst = 0;


        // ==================================
        // FIRST VALUE = 100
        // ==================================

        @(negedge clk);

        first_value_in = 100;
        first_valid    = 1;

        @(negedge clk);

        first_valid = 0;


        // ==================================
        // DELTA = +3
        // ==================================

        @(negedge clk);

        delta_in   = 9'sd3;
        delta_valid = 1;
        last        = 0;

        @(negedge clk);

        delta_valid = 0;


        // ==================================
        // DELTA = -2
        // ==================================

        @(negedge clk);

        delta_in   = -9'sd2;
        delta_valid = 1;
        last        = 0;

        @(negedge clk);

        delta_valid = 0;


        // ==================================
        // DELTA = +4
        // ==================================

        @(negedge clk);

        delta_in   = 9'sd4;
        delta_valid = 1;
        last        = 0;

        @(negedge clk);

        delta_valid = 0;


        // ==================================
        // DELTA = +1 LAST
        // ==================================

        @(negedge clk);

        delta_in   = 9'sd1;
        delta_valid = 1;
        last        = 1;

        @(negedge clk);

        delta_valid = 0;
        last        = 0;


        // Wait
        #50;

        $finish;

    end


    // ==================================
    // MONITOR
    // ==================================

    always @(posedge clk) begin

        if (valid_out) begin

            $display(
                "TIME = %0t | OUTPUT = %0d",
                $time,
                data_out
            );

        end

        if (done) begin

            $display("DELTA DECOMPRESSION DONE");

        end

    end

endmodule
