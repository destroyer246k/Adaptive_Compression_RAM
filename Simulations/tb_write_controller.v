`timescale 1ns/1ps

module tb_write_controller;

    reg clk;
    reg rst;

    reg         write_start;
    reg [255:0] compressed_data;
    reg [8:0]   compressed_size;
    reg [1:0]   selected_mode;
    reg [3:0]   block_addr;

    wire        data_ram_write_en;
    wire [7:0]  data_ram_write_addr;
    wire [255:0] data_ram_write_data;

    wire        metadata_write_en;
    wire [3:0]  metadata_write_addr;
    wire [1:0]  metadata_write_mode;
    wire [7:0]  metadata_write_comp_addr;
    wire [7:0]  metadata_write_comp_size;

    wire write_done;

    integer errors;

    // DUT
    write_controller dut (

        .clk(clk),
        .rst(rst),

        .write_start(write_start),
        .compressed_data(compressed_data),
        .compressed_size(compressed_size),
        .selected_mode(selected_mode),
        .block_addr(block_addr),

        .data_ram_write_en(data_ram_write_en),
        .data_ram_write_addr(data_ram_write_addr),
        .data_ram_write_data(data_ram_write_data),

        .metadata_write_en(metadata_write_en),
        .metadata_write_addr(metadata_write_addr),
        .metadata_write_mode(metadata_write_mode),
        .metadata_write_comp_addr(metadata_write_comp_addr),
        .metadata_write_comp_size(metadata_write_comp_size),

        .write_done(write_done)
    );

    // Clock: 10 ns
    always #5 clk = ~clk;


    // ------------------------------------------------
    // TASK TO TEST ONE WRITE
    // ------------------------------------------------

    task test_write;

        input [3:0]   test_block_addr;
        input [1:0]   test_mode;
        input [8:0]   test_size;
        input [255:0] test_data;
        input [7:0]   expected_comp_addr;

        begin

            // Apply inputs on falling edge
            @(negedge clk);

            block_addr      = test_block_addr;
            selected_mode   = test_mode;
            compressed_size = test_size;
            compressed_data = test_data;

            write_start = 1'b1;

            @(negedge clk);
            write_start = 1'b0;

            // Wait for write_done
            wait(write_done == 1'b1);

            #1;

            $display("");
            $display("Block = %0d | Mode = %02b | Size = %0d",
                     test_block_addr,
                     test_mode,
                     test_size);

            $display("Data Address = %0d | Metadata Address = %0d",
                     data_ram_write_addr,
                     metadata_write_addr);

            $display("Compressed Address = %0d",
                     metadata_write_comp_addr);


            // ----------------------------------------
            // CHECK DATA RAM ADDRESS
            // ----------------------------------------

            if (data_ram_write_addr != expected_comp_addr) begin
                $display("  DATA ADDRESS FAIL");
                errors = errors + 1;
            end
            else begin
                $display("  DATA ADDRESS PASS");
            end


            // ----------------------------------------
            // CHECK DATA
            // ----------------------------------------

            if (data_ram_write_data != test_data) begin
                $display("  DATA FAIL");
                errors = errors + 1;
            end
            else begin
                $display("  DATA PASS");
            end


            // ----------------------------------------
            // CHECK METADATA ADDRESS
            // ----------------------------------------

            if (metadata_write_addr != test_block_addr) begin
                $display("  METADATA ADDRESS FAIL");
                errors = errors + 1;
            end
            else begin
                $display("  METADATA ADDRESS PASS");
            end


            // ----------------------------------------
            // CHECK MODE
            // ----------------------------------------

            if (metadata_write_mode != test_mode) begin
                $display("  MODE FAIL");
                errors = errors + 1;
            end
            else begin
                $display("  MODE PASS");
            end


            // ----------------------------------------
            // CHECK COMPRESSED SIZE
            // ----------------------------------------

            if (metadata_write_comp_size != test_size[7:0]) begin
                $display("  SIZE FAIL");
                errors = errors + 1;
            end
            else begin
                $display("  SIZE PASS");
            end


            // ----------------------------------------
            // CHECK COMPRESSED ADDRESS
            // ----------------------------------------

            if (metadata_write_comp_addr != expected_comp_addr) begin
                $display("  COMP ADDRESS FAIL");
                errors = errors + 1;
            end
            else begin
                $display("  COMP ADDRESS PASS");
            end

        end

    endtask


    // ------------------------------------------------
    // MAIN TEST
    // ------------------------------------------------

    initial begin

        clk = 1'b0;
        rst = 1'b1;

        write_start    = 1'b0;
        compressed_data = 256'd0;
        compressed_size = 9'd0;
        selected_mode   = 2'b00;
        block_addr      = 4'd0;

        errors = 0;

        #20;
        rst = 1'b0;


        $display("");
        $display("==============================================");
        $display("WRITE CONTROLLER TEST");
        $display("==============================================");


        // --------------------------------------------
        // BLOCK 0 : RAW
        // --------------------------------------------

        test_write(
            4'd0,
            2'b00,
            9'd128,
            256'h00000000000000000000000000000000100F0E0D0C0B0A090807060504030201,
            8'd0
        );


        // --------------------------------------------
        // BLOCK 1 : DELTA4
        // --------------------------------------------

        test_write(
            4'd1,
            2'b01,
            9'd68,
            256'h000000000000000000000000000000000000000000000001111111111114E364,
            8'd1
        );


        // --------------------------------------------
        // BLOCK 2 : DELTA8
        // --------------------------------------------

        test_write(
            4'd2,
            2'b10,
            9'd128,
            256'h00000000000000000000000000000000FB14F60FFB140AEC0FFB14F650E23264,
            8'd2
        );


        // --------------------------------------------
        // BLOCK 3 : RLE
        // --------------------------------------------

        test_write(
            4'd3,
            2'b11,
            9'd64,
            256'h000000000000000000000000000000000000000000000000000000000144024303420441,
            8'd3
        );


        // --------------------------------------------
        // FINAL RESULT
        // --------------------------------------------

        $display("");
        $display("ERRORS = %0d", errors);

        if (errors == 0)
            $display("WRITE CONTROLLER TEST PASS");
        else
            $display("WRITE CONTROLLER TEST FAIL");

        $display("");

        #20;
        $finish;

    end

endmodule