`timescale 1ns/1ps

module tb_delta_compressor;

    reg clk;
    reg rst;

    reg [7:0] data_in;
    reg       valid_in;
    reg       start;
    reg       last;

    wire [7:0] first_value;
    wire signed [8:0] delta_out;

    wire first_valid;
    wire delta_valid;
    wire done;


    // ==================================
    // UUT INSTANTIATION
    // ==================================

    delta_compressor uut (

        .clk          (clk),
        .rst          (rst),

        .data_in      (data_in),
        .valid_in     (valid_in),
        .start        (start),
        .last         (last),

        .first_value  (first_value),
        .delta_out    (delta_out),

        .first_valid  (first_valid),
        .delta_valid  (delta_valid),
        .done         (done)

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

        data_in  = 0;
        valid_in = 0;
        start    = 0;
        last     = 0;


        // Reset
        #20;
        rst = 0;


        // ==================================
        // 100
        // ==================================

        @(negedge clk);

        data_in  = 100;
        valid_in = 1;
        start    = 1;
        last     = 0;


        // ==================================
        // 103
        // ==================================

        @(negedge clk);

        data_in  = 103;
        valid_in = 1;
        start    = 0;
        last     = 0;


        // ==================================
        // 101
        // ==================================

        @(negedge clk);

        data_in  = 101;
        valid_in = 1;
        start    = 0;
        last     = 0;


        // ==================================
        // 105
        // ==================================

        @(negedge clk);

        data_in  = 105;
        valid_in = 1;
        start    = 0;
        last     = 0;


        // ==================================
        // 106 - LAST
        // ==================================

        @(negedge clk);

        data_in  = 106;
        valid_in = 1;
        start    = 0;
        last     = 1;


        // Stop input
        @(negedge clk);

        valid_in = 0;
        last     = 0;


        // Wait
        #50;

        $finish;

    end


    // ==================================
    // MONITOR
    // ==================================

    always @(posedge clk) begin

        if (first_valid) begin

            $display(
                "TIME = %0t | FIRST VALUE = %0d",
                $time,
                first_value
            );

        end


        if (delta_valid) begin

            $display(
                "TIME = %0t | DELTA = %0d",
                $time,
                delta_out
            );

        end


        if (done) begin

            $display("DELTA COMPRESSION DONE");

        end

    end

endmodule
