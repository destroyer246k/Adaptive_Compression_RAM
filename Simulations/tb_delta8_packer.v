`timescale 1ns/1ps

module tb_delta8_packer;

    reg clk;
    reg rst;

    reg [127:0] block_data;
    reg block_valid;

    wire [127:0] packed_data;
    wire packed_valid;
    wire done;

    integer i;
    integer errors;

    // Clock
    always #5 clk = ~clk;

    delta8_packer uut (
        .clk(clk),
        .rst(rst),

        .block_data(block_data),
        .block_valid(block_valid),

        .packed_data(packed_data),
        .packed_valid(packed_valid),
        .done(done)
    );

    initial begin

        clk = 0;
        rst = 1;
        block_data = 128'd0;
        block_valid = 0;
        errors = 0;

        #12;
        rst = 0;

        /*
        Test block:

        100
        150
        120
        200
        190
        210
        205
        220
        200
        210
        230
        225
        240
        230
        250
        245

        Deltas:

        +50
        -30
        +80
        -10
        +20
        -5
        +15
        -20
        +10
        +20
        -5
        +15
        -10
        +20
        -5
        */

        block_data[7:0]     = 8'd100;
        block_data[15:8]    = 8'd150;
        block_data[23:16]   = 8'd120;
        block_data[31:24]   = 8'd200;
        block_data[39:32]   = 8'd190;
        block_data[47:40]   = 8'd210;
        block_data[55:48]   = 8'd205;
        block_data[63:56]   = 8'd220;
        block_data[71:64]   = 8'd200;
        block_data[79:72]   = 8'd210;
        block_data[87:80]   = 8'd230;
        block_data[95:88]   = 8'd225;
        block_data[103:96]  = 8'd240;
        block_data[111:104] = 8'd230;
        block_data[119:112] = 8'd250;
        block_data[127:120] = 8'd245;

        // Send block
        @(negedge clk);
        block_valid = 1'b1;

        @(negedge clk);
        block_valid = 1'b0;

        // Wait for packer
        wait(done);

        #1;

        $display("");
        $display("DELTA8 PACKER TEST");
        $display("-------------------");

        // Check first value
        if (packed_data[7:0] == 8'd100)
            $display("First value PASS");
        else begin
            $display("First value FAIL");
            errors = errors + 1;
        end

        // Delta 1 = +50
        if (packed_data[15:8] == 8'h32)
            $display("Delta 1  (+50) PASS");
        else begin
            $display("Delta 1  (+50) FAIL");
            errors = errors + 1;
        end

        // Delta 2 = -30
        if (packed_data[23:16] == 8'hE2)
            $display("Delta 2  (-30) PASS");
        else begin
            $display("Delta 2  (-30) FAIL");
            errors = errors + 1;
        end

        // Delta 3 = +80
        if (packed_data[31:24] == 8'h50)
            $display("Delta 3  (+80) PASS");
        else begin
            $display("Delta 3  (+80) FAIL");
            errors = errors + 1;
        end

        // Delta 4 = -10
        if (packed_data[39:32] == 8'hF6)
            $display("Delta 4  (-10) PASS");
        else begin
            $display("Delta 4  (-10) FAIL");
            errors = errors + 1;
        end

        // Delta 5 = +20
        if (packed_data[47:40] == 8'h14)
            $display("Delta 5  (+20) PASS");
        else begin
            $display("Delta 5  (+20) FAIL");
            errors = errors + 1;
        end

        // Delta 6 = -5
        if (packed_data[55:48] == 8'hFB)
            $display("Delta 6  (-5) PASS");
        else begin
            $display("Delta 6  (-5) FAIL");
            errors = errors + 1;
        end

        // Delta 7 = +15
        if (packed_data[63:56] == 8'h0F)
            $display("Delta 7  (+15) PASS");
        else begin
            $display("Delta 7  (+15) FAIL");
            errors = errors + 1;
        end

        // Delta 8 = -20
        if (packed_data[71:64] == 8'hEC)
            $display("Delta 8  (-20) PASS");
        else begin
            $display("Delta 8  (-20) FAIL");
            errors = errors + 1;
        end

        // Delta 9 = +10
        if (packed_data[79:72] == 8'h0A)
            $display("Delta 9  (+10) PASS");
        else begin
            $display("Delta 9  (+10) FAIL");
            errors = errors + 1;
        end

        // Delta 10 = +20
        if (packed_data[87:80] == 8'h14)
            $display("Delta 10 (+20) PASS");
        else begin
            $display("Delta 10 (+20) FAIL");
            errors = errors + 1;
        end

        // Delta 11 = -5
        if (packed_data[95:88] == 8'hFB)
            $display("Delta 11 (-5) PASS");
        else begin
            $display("Delta 11 (-5) FAIL");
            errors = errors + 1;
        end

        // Delta 12 = +15
        if (packed_data[103:96] == 8'h0F)
            $display("Delta 12 (+15) PASS");
        else begin
            $display("Delta 12 (+15) FAIL");
            errors = errors + 1;
        end

        // Delta 13 = -10
        if (packed_data[111:104] == 8'hF6)
            $display("Delta 13 (-10) PASS");
        else begin
            $display("Delta 13 (-10) FAIL");
            errors = errors + 1;
        end

        // Delta 14 = +20
        if (packed_data[119:112] == 8'h14)
            $display("Delta 14 (+20) PASS");
        else begin
            $display("Delta 14 (+20) FAIL");
            errors = errors + 1;
        end

        // Delta 15 = -5
        if (packed_data[127:120] == 8'hFB)
            $display("Delta 15 (-5) PASS");
        else begin
            $display("Delta 15 (-5) FAIL");
            errors = errors + 1;
        end

        $display("");
        $display("Packed data = %h", packed_data);
        $display("");

        if (errors == 0) begin
            $display("ERRORS = 0");
            $display("DELTA8 PACKER TEST PASS");
        end
        else begin
            $display("ERRORS = %0d", errors);
            $display("DELTA8 PACKER TEST FAIL");
        end

        $finish;
    end

endmodule