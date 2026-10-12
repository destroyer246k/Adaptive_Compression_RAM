`timescale 1ns/1ps

module tb_write_path_integration;

    reg clk;
    reg rst;

    reg        write_start;
    reg [3:0]  block_addr;
    reg [1:0]  selected_mode;
    reg [8:0]  compressed_size;
    reg [255:0] compressed_data;

    reg        data_read_en;
    reg [7:0]  data_read_addr;

    reg        metadata_read_en;
    reg [3:0]  metadata_read_addr;

    wire [255:0] data_read_data;
    wire         data_read_valid;

    wire [1:0] metadata_read_mode;
    wire [7:0] metadata_read_comp_addr;
    wire [7:0] metadata_read_comp_size;
    wire       metadata_read_valid;

    wire write_done;

    integer errors;

    // --------------------------------------------
    // DUT
    // --------------------------------------------

    write_path_integration dut (

        .clk(clk),
        .rst(rst),

        .write_start(write_start),
        .block_addr(block_addr),

        .selected_mode(selected_mode),
        .compressed_size(compressed_size),
        .compressed_data(compressed_data),

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

        .write_done(write_done)
    );


    // --------------------------------------------
    // CLOCK
    // --------------------------------------------

    always #5 clk = ~clk;


    // --------------------------------------------
    // WRITE TASK
    // --------------------------------------------

    task write_block;

        input [3:0]   b_addr;
        input [1:0]   mode;
        input [8:0]   size;
        input [255:0] data;

        begin

            @(negedge clk);

            block_addr      = b_addr;
            selected_mode   = mode;
            compressed_size = size;
            compressed_data = data;

            write_start = 1'b1;

            @(negedge clk);
            write_start = 1'b0;

            wait(write_done == 1'b1);

            #1;

            $display(
                "WRITE | Block = %0d | Mode = %02b | Size = %0d",
                b_addr, mode, size
            );

        end

    endtask


    // --------------------------------------------
    // READ AND CHECK TASK
    // --------------------------------------------

    task read_and_check;

        input [3:0]   b_addr;
        input [1:0]   expected_mode;
        input [8:0]   expected_size;
        input [255:0] expected_data;
        input [7:0]   expected_comp_addr;

        begin

            @(negedge clk);

            data_read_addr     = expected_comp_addr;
            data_read_en       = 1'b1;

            metadata_read_addr = b_addr;
            metadata_read_en   = 1'b1;

            @(negedge clk);

            data_read_en     = 1'b0;
            metadata_read_en = 1'b0;

            wait(data_read_valid && metadata_read_valid);

            #1;

            $display("");
            $display(
                "READ | Block = %0d",
                b_addr
            );

            // DATA
            if (data_read_data != expected_data) begin
                $display("  DATA FAIL");
                errors = errors + 1;
            end
            else begin
                $display("  DATA PASS");
            end

            // MODE
            if (metadata_read_mode != expected_mode) begin
                $display("  MODE FAIL");
                errors = errors + 1;
            end
            else begin
                $display("  MODE PASS");
            end

            // SIZE
            if (metadata_read_comp_size != expected_size[7:0]) begin
                $display("  SIZE FAIL");
                errors = errors + 1;
            end
            else begin
                $display("  SIZE PASS");
            end

            // COMPRESSED ADDRESS
            if (metadata_read_comp_addr != expected_comp_addr) begin
                $display("  COMP ADDRESS FAIL");
                errors = errors + 1;
            end
            else begin
                $display("  COMP ADDRESS PASS");
            end

        end

    endtask


    // --------------------------------------------
    // MAIN TEST
    // --------------------------------------------

    initial begin

        clk = 1'b0;
        rst = 1'b1;

        write_start = 1'b0;

        block_addr = 4'd0;
        selected_mode = 2'b00;
        compressed_size = 9'd0;
        compressed_data = 256'd0;

        data_read_en = 1'b0;
        data_read_addr = 8'd0;

        metadata_read_en = 1'b0;
        metadata_read_addr = 4'd0;

        errors = 0;

        #20;
        rst = 1'b0;

        $display("");
        $display("==============================================");
        $display("WRITE PATH INTEGRATION TEST");
        $display("==============================================");


        // ----------------------------------------
        // WRITE FOUR BLOCKS
        // ----------------------------------------

        write_block(
            4'd0,
            2'b00,
            9'd128,
            256'h00000000000000000000000000000000100F0E0D0C0B0A090807060504030201
        );

        write_block(
            4'd1,
            2'b01,
            9'd68,
            256'h000000000000000000000000000000000000000000000001111111111114E364
        );

        write_block(
            4'd2,
            2'b10,
            9'd128,
            256'h00000000000000000000000000000000FB14F60FFB140AEC0FFB14F650E23264
        );

        write_block(
            4'd3,
            2'b11,
            9'd64,
            256'h000000000000000000000000000000000000000000000000000000000144024303420441
        );


        // ----------------------------------------
        // READ FOUR BLOCKS
        // ----------------------------------------

        read_and_check(
            4'd0,
            2'b00,
            9'd128,
            256'h00000000000000000000000000000000100F0E0D0C0B0A090807060504030201,
            8'd0
        );

        read_and_check(
            4'd1,
            2'b01,
            9'd68,
            256'h000000000000000000000000000000000000000000000001111111111114E364,
            8'd1
        );

        read_and_check(
            4'd2,
            2'b10,
            9'd128,
            256'h00000000000000000000000000000000FB14F60FFB140AEC0FFB14F650E23264,
            8'd2
        );

        read_and_check(
            4'd3,
            2'b11,
            9'd64,
            256'h000000000000000000000000000000000000000000000000000000000144024303420441,
            8'd3
        );


        // ----------------------------------------
        // RESULT
        // ----------------------------------------

        $display("");
        $display("ERRORS = %0d", errors);

        if (errors == 0)
            $display("WRITE PATH INTEGRATION TEST PASS");
        else
            $display("WRITE PATH INTEGRATION TEST FAIL");

        $display("");

        #20;
        $finish;

    end

endmodule