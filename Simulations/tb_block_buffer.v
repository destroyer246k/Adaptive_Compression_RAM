`timescale 1ns/1ps

module tb_block_buffer;

    reg clk;
    reg rst;

    reg [7:0] data_in;
    reg valid_in;
    reg start;

    wire [127:0] block_data;
    wire block_ready;

    integer i;
    integer error_count;


    //========================================================
    // DUT
    //========================================================

    block_buffer uut (
        .clk(clk),
        .rst(rst),

        .data_in(data_in),
        .valid_in(valid_in),
        .start(start),

        .block_data(block_data),
        .block_ready(block_ready)
    );


    //========================================================
    // CLOCK
    //========================================================

    always #5 clk = ~clk;


    //========================================================
    // CHECK BLOCK
    //========================================================

    always @(posedge clk) begin

        if (block_ready) begin

            $display("");
            $display("================================");
            $display("BLOCK READY");
            $display("================================");

            for (i = 0; i < 16; i = i + 1) begin

                if (block_data[i*8 +: 8] != (i + 1)) begin

                    $display(
                        "ERROR: Byte %0d | Expected = %0d | Got = %0d",
                        i,
                        i + 1,
                        block_data[i*8 +: 8]
                    );

                    error_count = error_count + 1;

                end

                else begin

                    $display(
                        "Byte %0d | Expected = %0d | Got = %0d",
                        i,
                        i + 1,
                        block_data[i*8 +: 8]
                    );

                end

            end


            $display("");
            $display("Errors = %0d", error_count);

            if (error_count == 0)
                $display("BLOCK BUFFER TEST PASS");
            else
                $display("BLOCK BUFFER TEST FAIL");

            $display("================================");

        end

    end


    //========================================================
    // STIMULUS
    //========================================================

    initial begin

        clk = 0;
        rst = 1;

        data_in  = 8'd0;
        valid_in = 1'b0;
        start    = 1'b0;

        error_count = 0;


        //====================================================
        // RESET
        //====================================================

        #20;
        rst = 0;


        //====================================================
        // FIRST BYTE
        //====================================================

        @(negedge clk);

        data_in  = 8'd1;
        valid_in = 1'b1;
        start    = 1'b1;


        //====================================================
        // REMAINING BYTES
        //====================================================

        for (i = 2; i <= 16; i = i + 1) begin

            @(negedge clk);

            data_in = i;
            start   = 1'b0;

        end


        //====================================================
        // STOP INPUT
        //====================================================

        @(negedge clk);

        valid_in = 1'b0;
        start    = 1'b0;


        //====================================================
        // WAIT
        //====================================================

        #100;

        $finish;

    end

endmodule