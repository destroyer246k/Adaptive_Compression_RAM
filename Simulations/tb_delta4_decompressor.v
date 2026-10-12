`timescale 1ns/1ps

module tb_delta4_decompressor;

    reg clk;
    reg rst;

    reg [127:0] packed_data;
    reg packed_valid;

    wire [7:0] data_out;
    wire valid_out;
    wire done;

    integer output_count;
    integer errors;

    reg [7:0] expected [0:15];

    delta4_decompressor uut (
        .clk(clk),
        .rst(rst),

        .packed_data(packed_data),
        .packed_valid(packed_valid),

        .data_out(data_out),
        .valid_out(valid_out),
        .done(done)
    );

    // Clock
    always #5 clk = ~clk;

    initial begin

        clk = 0;
        rst = 1;
        packed_data = 128'd0;
        packed_valid = 0;

        output_count = 0;
        errors = 0;

        // Expected original data
        expected[0]  = 8'd100;
        expected[1]  = 8'd103;
        expected[2]  = 8'd101;
        expected[3]  = 8'd105;
        expected[4]  = 8'd106;
        expected[5]  = 8'd107;
        expected[6]  = 8'd108;
        expected[7]  = 8'd109;
        expected[8]  = 8'd110;
        expected[9]  = 8'd111;
        expected[10] = 8'd112;
        expected[11] = 8'd113;
        expected[12] = 8'd114;
        expected[13] = 8'd115;
        expected[14] = 8'd116;
        expected[15] = 8'd117;

        // Reset
        #12;
        rst = 0;

        /*
        Packed DELTA4 data:

        First value = 100

        Delta 1  = +3
        Delta 2  = -2
        Delta 3  = +4
        Delta 4  = +1
        Delta 5  = +1
        ...
        Delta 15 = +1

        Previously obtained:
        0000000000000001111111111114e364
        */

        packed_data = 128'h0000000000000001111111111114e364;

        // Send packed block
        @(negedge clk);
        packed_valid = 1'b1;

        @(negedge clk);
        packed_valid = 1'b0;

        // Wait until decompression finishes
        wait(done);

        #1;

        $display("");
        $display("DELTA4 DECOMPRESSOR TEST");
        $display("-------------------------");
        $display("");

        if (errors == 0 && output_count == 16) begin
            $display("Output bytes = %0d", output_count);
            $display("Errors       = %0d", errors);
            $display("DELTA4 DECOMPRESSOR TEST PASS");
        end
        else begin
            $display("Output bytes = %0d", output_count);
            $display("Errors       = %0d", errors);
            $display("DELTA4 DECOMPRESSOR TEST FAIL");
        end

        $finish;
    end


    // Check every decompressed byte
    always @(posedge clk) begin

        if (valid_out) begin

            $display(
                "Byte %0d | Got = %0d | Expected = %0d",
                output_count,
                data_out,
                expected[output_count]
            );

            if (data_out != expected[output_count]) begin
                errors = errors + 1;
            end

            output_count = output_count + 1;
        end

    end

endmodule