`timescale 1ns/1ps

module tb_rle_decompressor;

    reg clk;
    reg rst;

    reg [7:0] symbol_in;
    reg [4:0] count_in;
    reg       valid_in;
    reg       last_in;

    wire [7:0] data_out;
    wire       valid_out;
    wire       done;


    // ==================================
    // UUT INSTANTIATION
    // ==================================

    rle_decompressor uut (
        .clk        (clk),
        .rst        (rst),

        .symbol_in  (symbol_in),
        .count_in   (count_in),
        .valid_in   (valid_in),
        .last_in    (last_in),

        .data_out   (data_out),
        .valid_out  (valid_out),
        .done        (done)
    );


    // ==================================
    // CLOCK
    // ==================================

    always #5 clk = ~clk;


    // ==================================
    // STIMULUS
    // ==================================

    initial begin

    clk       = 0;
    rst       = 1;

    symbol_in = 0;
    count_in  = 0;
    valid_in  = 0;
    last_in   = 0;

    // Reset
    #10;
    rst = 0;


    // =========================
    // A,4
    // =========================

    @(negedge clk);

    symbol_in = "A";
    count_in  = 4;
    valid_in  = 1;
    last_in   = 0;

    @(negedge clk);
    valid_in = 0;


    // Wait for A run to finish
    repeat(5) @(negedge clk);


    // =========================
    // B,3
    // =========================

    symbol_in = "B";
    count_in  = 3;
    valid_in  = 1;
    last_in   = 0;

    @(negedge clk);
    valid_in = 0;


    // Wait for B run to finish
    repeat(4) @(negedge clk);


    // =========================
    // C,2
    // =========================

    symbol_in = "C";
    count_in  = 2;
    valid_in  = 1;
    last_in   = 1;

    @(negedge clk);
    valid_in = 0;
    last_in  = 0;


    // Wait
    #100;

    $finish;

end

    // ==================================
    // MONITOR
    // ==================================

    always @(posedge clk) begin

        if (valid_out) begin

            $display(
                "TIME = %0t | OUTPUT = %c",
                $time,
                data_out
            );

        end

        if (done) begin

            $display("RLE DECOMPRESSION DONE");

        end

    end

endmodule