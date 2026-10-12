`timescale 1ns/1ps

module tb_adaptive_compression_memory_controller;

    reg clk;
    reg rst;

    reg         write_start;
    reg [3:0]   block_addr;
    reg [127:0] block_data;

    reg         data_read_en;
    reg [7:0]   data_read_addr;

    reg         metadata_read_en;
    reg [3:0]   metadata_read_addr;

    wire [255:0] data_read_data;
    wire         data_read_valid;

    wire [1:0] metadata_read_mode;
    wire [7:0] metadata_read_comp_addr;
    wire [7:0] metadata_read_comp_size;
    wire       metadata_read_valid;

    wire write_done;
    wire busy;

    integer errors;


    adaptive_compression_memory_controller dut (

        .clk(clk),
        .rst(rst),

        .write_start(write_start),
        .block_addr(block_addr),
        .block_data(block_data),

        .data_read_en(data_read_en),
        .data_read_addr(data_read_addr),

        .metadata_read_en(metadata_read_en),
        .metadata_read_addr(metadata_read_addr),

        .data_read_data(data_read_data),
        .data_read_valid(data_read_valid),

        .metadata_read_mode(metadata_read_mode),
        .metadata_read_comp_addr(metadata_read_comp_addr),
        .metadata_read_comp_size(metadata_read_comp_size),
        .metadata_read_valid(metadata_read_valid),

        .write_done(write_done),
        .busy(busy)
    );


    always #5 clk = ~clk;


    task write_block;
        input [3:0] test_addr;
        input [127:0] test_data;

        begin

           
            @(negedge clk);

            while (write_done == 1'b1)
                @(negedge clk);

           
            block_addr  = test_addr;
            block_data  = test_data;
            write_start = 1'b1;

           
            @(negedge clk);
            write_start = 1'b0;

           
            wait(write_done == 1'b1);

            #1;

            $display("WRITE DONE | Block = %0d", test_addr);


            @(negedge clk);

        end
    endtask


    // ============================================================
    // READ / CHECK TASK
    // ============================================================

    task read_check;

        input [3:0]    test_addr;
        input [7:0]    expected_comp_addr;
        input [1:0]    expected_mode;
        input [7:0]    expected_size;
        input [255:0]  expected_data;

        begin

            @(negedge clk);

            // Request compressed data
            data_read_addr = expected_comp_addr;
            data_read_en   = 1'b1;

            // Request metadata
            metadata_read_addr = test_addr;
            metadata_read_en   = 1'b1;

            @(negedge clk);

            data_read_en     = 1'b0;
            metadata_read_en = 1'b0;

            // Wait for both RAM outputs
            wait(data_read_valid && metadata_read_valid);

            #1;

            $display("");
            $display(
                "READ | Block = %0d | Mode = %02b | Size = %0d",
                test_addr,
                metadata_read_mode,
                metadata_read_comp_size
            );

            // ====================================================
            // DEBUG INFORMATION
            // ====================================================

            $display(
                "DEBUG | Metadata Compressed Address = %0d",
                metadata_read_comp_addr
            );

            $display(
                "DEBUG | Requested Data Address      = %0d",
                expected_comp_addr
            );

            $display(
                "DEBUG | Metadata Block Address      = %0d",
                test_addr
            );

            // ====================================================
            // DATA CHECK
            // ====================================================

            if (data_read_data != expected_data) begin

                $display("  DATA FAIL");
                $display("  Expected = %064h", expected_data);
                $display("  Got      = %064h", data_read_data);

                errors = errors + 1;

            end
            else begin

                $display("  DATA PASS");

            end

            // ====================================================
            // MODE CHECK
            // ====================================================

            if (metadata_read_mode != expected_mode) begin

                $display("  MODE FAIL");
                $display("  Expected Mode = %02b", expected_mode);
                $display("  Got Mode      = %02b", metadata_read_mode);

                errors = errors + 1;

            end
            else begin

                $display("  MODE PASS");

            end

            // ====================================================
            // SIZE CHECK
            // ====================================================

            if (metadata_read_comp_size != expected_size) begin

                $display("  SIZE FAIL");
                $display("  Expected Size = %0d", expected_size);
                $display("  Got Size      = %0d",
                         metadata_read_comp_size);

                errors = errors + 1;

            end
            else begin

                $display("  SIZE PASS");

            end

            // ====================================================
            // COMPRESSED ADDRESS CHECK
            // ====================================================

            if (metadata_read_comp_addr != expected_comp_addr) begin

                $display("  COMP ADDRESS FAIL");
                $display("  Expected Address = %0d",
                         expected_comp_addr);
                $display("  Got Address      = %0d",
                         metadata_read_comp_addr);

                errors = errors + 1;

            end
            else begin

                $display("  COMP ADDRESS PASS");

            end

        end

    endtask


    // ============================================================
    // MAIN
    // ============================================================

    initial begin

        clk = 1'b0;
        rst = 1'b1;

        write_start = 1'b0;

        block_addr = 4'd0;
        block_data = 128'd0;

        data_read_en   = 1'b0;
        data_read_addr = 8'd0;

        metadata_read_en   = 1'b0;
        metadata_read_addr = 4'd0;

        errors = 0;

        #20;
        rst = 1'b0;


        $display("");
        $display("==============================================");
        $display("FULL ADAPTIVE MEMORY CONTROLLER TEST");
        $display("==============================================");


        // ========================================================
        // BLOCK 0
        // DELTA4
        // Bytes = 01 02 03 ... 0F 10
        // ========================================================

        write_block(
            4'd0,
            128'h100F0E0D0C0B0A090807060504030201
        );


        // ========================================================
        // BLOCK 1
        // DELTA4
        // Bytes = 64 67 68 69 ... 74 75
        // ========================================================

        write_block(
            4'd1,
            128'h7574737271706F6E6D6C6B6A69686764
        );


        // ========================================================
        // BLOCK 2
        // RAW
        //
        // Delta8 is exactly 128 bits, so selector chooses RAW
        // because RAW and DELTA8 are tied.
        // ========================================================

        write_block(
            4'd2,
            128'hF5FAE6EAF0E0D2C8D2BED2C0C8C87864
        );


        // ========================================================
        // BLOCK 3
        // RLE
        //
        // Runs:
        // 41 x 8
        // 42 x 3
        // 43 x 3
        // 44 x 2
        //
        // Expected compressed size = 4 * 16 = 64 bits
        // ========================================================

        write_block(
            4'd3,
            128'h44444343434242424141414141414141
        );


        // ========================================================
        // READ BACK BLOCK 0
        // ========================================================

        read_check(
            4'd0,
            8'd0,
            2'b01,
            8'd68,

            // DELTA4:
            // first byte = 01
            // all 15 deltas = +1 = 1
            256'h0000000000000000000000000000000000000000000000011111111111111101
        );


        // ========================================================
        // READ BACK BLOCK 1
        // ========================================================

        read_check(
            4'd1,
            8'd1,
            2'b01,
            8'd68,

            // First byte = 64
            // Delta1 = 67 - 64 = 3
            // Remaining deltas = +1
            256'h0000000000000000000000000000000000000000000000011111111111111364
        );


        // ========================================================
        // READ BACK BLOCK 2
        // ========================================================

        read_check(
            4'd2,
            8'd2,
            2'b00,
            8'd128,

            // RAW
            256'h00000000000000000000000000000000F5FAE6EAF0E0D2C8D2BED2C0C8C87864
        );


        // ========================================================
        // READ BACK BLOCK 3
        // ========================================================

        read_check(
            4'd3,
            8'd3,
            2'b11,
            8'd64,

            // RLE:
            // 41 x 8
            // 42 x 3
            // 43 x 3
            // 44 x 2
            //
            // pair format = {000,count,symbol}
            //
            // Pair0 = 00008_41
            // Pair1 = 00003_42
            // Pair2 = 00003_43
            // Pair3 = 00002_44
            256'h00000000000000000000000000000000000000000000000244034303420841
        );


        // ========================================================
        // FINAL RESULT
        // ========================================================

        $display("");
        $display("==============================================");
        $display("ERRORS = %0d", errors);

        if (errors == 0)
            $display("FULL ADAPTIVE MEMORY CONTROLLER TEST PASS");
        else
            $display("FULL ADAPTIVE MEMORY CONTROLLER TEST FAIL");

        $display("==============================================");
        $display("");

        #20;
        $finish;

    end

endmodule