`timescale 1ns/1ps

module tb_delta_adaptive_analyzer;

    reg [127:0] block_data;
    reg         block_valid;

    wire [1:0] delta_mode;
    wire       result_valid;

    integer error_count;


    //========================================================
    // MODE VALUES
    //========================================================

    localparam RAW    = 2'b00;
    localparam DELTA4 = 2'b01;
    localparam DELTA8 = 2'b10;


    //========================================================
    // DUT
    //========================================================

    delta_adaptive_analyzer uut (

        .block_data(block_data),
        .block_valid(block_valid),

        .delta_mode(delta_mode),
        .result_valid(result_valid)

    );


    //========================================================
    // TEST
    //========================================================

    initial begin

        block_data  = 128'd0;
        block_valid = 1'b0;

        error_count = 0;


        //====================================================
        // TEST 1
        // DELTA4
        //====================================================

        $display("");
        $display("================================");
        $display("TEST 1 : DELTA4");
        $display("================================");

        // Values:
        // 100,103,101,105,106,107,106,104,
        // 105,107,106,104,103,105,106,107

        block_data[7:0]     = 8'd100;
        block_data[15:8]    = 8'd103;
        block_data[23:16]   = 8'd101;
        block_data[31:24]   = 8'd105;
        block_data[39:32]   = 8'd106;
        block_data[47:40]   = 8'd107;
        block_data[55:48]   = 8'd106;
        block_data[63:56]   = 8'd104;
        block_data[71:64]   = 8'd105;
        block_data[79:72]   = 8'd107;
        block_data[87:80]   = 8'd106;
        block_data[95:88]   = 8'd104;
        block_data[103:96]  = 8'd103;
        block_data[111:104] = 8'd105;
        block_data[119:112] = 8'd106;
        block_data[127:120] = 8'd107;

        block_valid = 1'b1;

        #1;

        $display("MODE = %b", delta_mode);

        if (delta_mode == DELTA4)
            $display("PASS: DELTA4 selected");
        else begin
            $display("FAIL: Expected DELTA4");
            error_count = error_count + 1;
        end

        block_valid = 1'b0;


        //====================================================
        // TEST 2
        // DELTA8
        //====================================================

        $display("");
        $display("================================");
        $display("TEST 2 : DELTA8");
        $display("================================");

        block_data = 128'd0;

        // 0 → 40 → 20 → 60 → ...
        // Deltas are larger than 4-bit range
        // but within 8-bit range

        block_data[7:0]     = 8'd0;
        block_data[15:8]    = 8'd40;
        block_data[23:16]   = 8'd20;
        block_data[31:24]   = 8'd60;
        block_data[39:32]   = 8'd30;
        block_data[47:40]   = 8'd70;
        block_data[55:48]   = 8'd50;
        block_data[63:56]   = 8'd90;
        block_data[71:64]   = 8'd60;
        block_data[79:72]   = 8'd100;
        block_data[87:80]   = 8'd70;
        block_data[95:88]   = 8'd110;
        block_data[103:96]  = 8'd80;
        block_data[111:104] = 8'd120;
        block_data[119:112] = 8'd90;
        block_data[127:120] = 8'd130;

        block_valid = 1'b1;

        #1;

        $display("MODE = %b", delta_mode);

        if (delta_mode == DELTA8)
            $display("PASS: DELTA8 selected");
        else begin
            $display("FAIL: Expected DELTA8");
            error_count = error_count + 1;
        end

        block_valid = 1'b0;


        //====================================================
        // TEST 3
        // RAW
        //====================================================

        $display("");
        $display("================================");
        $display("TEST 3 : RAW");
        $display("================================");

        block_data = 128'd0;

        // 0 → 200 creates a delta of +200
        // which doesn't fit in signed 8-bit

        block_data[7:0]   = 8'd0;
        block_data[15:8]  = 8'd200;

        // Remaining bytes
        block_data[23:16]   = 8'd10;
        block_data[31:24]   = 8'd20;
        block_data[39:32]   = 8'd30;
        block_data[47:40]   = 8'd40;
        block_data[55:48]   = 8'd50;
        block_data[63:56]   = 8'd60;
        block_data[71:64]   = 8'd70;
        block_data[79:72]   = 8'd80;
        block_data[87:80]   = 8'd90;
        block_data[95:88]   = 8'd100;
        block_data[103:96]  = 8'd110;
        block_data[111:104] = 8'd120;
        block_data[119:112] = 8'd130;
        block_data[127:120] = 8'd140;

        block_valid = 1'b1;

        #1;

        $display("MODE = %b", delta_mode);

        if (delta_mode == RAW)
            $display("PASS: RAW selected");
        else begin
            $display("FAIL: Expected RAW");
            error_count = error_count + 1;
        end

        block_valid = 1'b0;


        //====================================================
        // FINAL RESULT
        //====================================================

        $display("");
        $display("================================");
        $display("DELTA ADAPTIVE ANALYZER TEST");
        $display("Errors = %0d", error_count);

        if (error_count == 0)
            $display("TEST PASS");
        else
            $display("TEST FAIL");

        $display("================================");

        $finish;

    end
    endmodule