`timescale 1ns/1ps
module tb_rle_compressor;
reg clk;
reg rst;

reg [7:0] data_in;
reg       valid_in;
reg       start;
reg       last;
wire [7:0] symbol_out;
wire [4:0] count_out;
wire       valid_out;
wire       done;


    // =========================
    // UUT INSTANTIATION
    // =========================

rle_compressor uut (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .valid_in(valid_in),
        .start(start),
        .last (last),
        .symbol_out(symbol_out),
        .count_out(count_out),
        .valid_out(valid_out),
        .done(done)
    );


    // =========================
    // CLOCK
    // =========================

    always #5 clk = ~clk;


    // =========================
    // STIMULUS
    // =========================

    initial begin

        // Initial values
        clk      = 0;
        rst      = 1;

        data_in  = 8'd0;
        valid_in = 0;
        start    = 0;
        last     = 0;

        // Reset
        #10;
        rst = 0;


        // -------------------------
        // Send A
        // -------------------------

        @(negedge clk);
        data_in  = "A";
        valid_in = 1;
        start    = 1;
        last     = 0;


        // -------------------------
        // Send A
        // -------------------------

        @(negedge clk);
        data_in  = "A";
        valid_in = 1;
        start    = 0;
        last     = 0;


        // -------------------------
        // Send A
        // -------------------------

        @(negedge clk);
        data_in  = "A";
        valid_in = 1;
        start    = 0;
        last     = 0;


        // -------------------------
        // Send A
        // -------------------------

        @(negedge clk);
        data_in  = "A";
        valid_in = 1;
        start    = 0;
        last     = 0;


        // -------------------------
        // Send B
        // -------------------------

        @(negedge clk);
        data_in  = "B";
        valid_in = 1;
        start    = 0;
        last     = 0;


        // -------------------------
        // Send B
        // -------------------------

        @(negedge clk);
        data_in  = "B";
        valid_in = 1;
        start    = 0;
        last     = 0;


        // -------------------------
        // Send B
        // -------------------------

        @(negedge clk);
        data_in  = "B";
        valid_in = 1;
        start    = 0;
        last     = 0;


        // -------------------------
        // Send C
        // -------------------------

        @(negedge clk);
        data_in  = "C";
        valid_in = 1;
        start    = 0;
        last     = 0;


        // -------------------------
        // Send C - LAST
        // -------------------------

        @(negedge clk);
        data_in  = "C";
        valid_in = 1;
        start    = 0;
        last     = 1;


        // Stop input
        @(negedge clk);
        valid_in = 0;
        last     = 0;


        // Wait
        #500;

        $finish;

    end


    // =========================
    // MONITOR
    // =========================

    always @(posedge clk) begin

        if (valid_out) begin
            $display(
                "TIME = %0t | SYMBOL = %c | COUNT = %0d",
                $time,
                symbol_out,
                count_out
            );
        end

        if (done) begin
            $display("RLE DONE");
        end

    end

endmodule
