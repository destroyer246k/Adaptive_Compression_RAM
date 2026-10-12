`timescale 1ns/1ps

module tb_metadata_ram;

    reg clk;
    reg rst;

    // Write
    reg        write_en;
    reg [3:0]  write_addr;
    reg [1:0]  write_mode;
    reg [7:0]  write_comp_addr;
    reg [7:0]  write_comp_size;

    // Read
    reg        read_en;
    reg [3:0]  read_addr;

    wire [1:0] read_mode;
    wire [7:0] read_comp_addr;
    wire [7:0] read_comp_size;
    wire       read_valid;

    integer errors;

    localparam RAW    = 2'b00;
    localparam DELTA4 = 2'b01;
    localparam DELTA8 = 2'b10;
    localparam RLE    = 2'b11;


    // =====================================================
    // DUT
    // =====================================================

    metadata_ram uut (

        .clk(clk),
        .rst(rst),

        .write_en(write_en),
        .write_addr(write_addr),

        .write_mode(write_mode),
        .write_comp_addr(write_comp_addr),
        .write_comp_size(write_comp_size),

        .read_en(read_en),
        .read_addr(read_addr),

        .read_mode(read_mode),
        .read_comp_addr(read_comp_addr),
        .read_comp_size(read_comp_size),

        .read_valid(read_valid)
    );


    // =====================================================
    // CLOCK
    // =====================================================

    always #5 clk = ~clk;


    // =====================================================
    // WRITE TASK
    // =====================================================

    task write_metadata;

        input [3:0] addr;
        input [1:0] mode;
        input [7:0] comp_addr;
        input [7:0] comp_size;

        begin

            @(negedge clk);

            write_addr      = addr;
            write_mode      = mode;
            write_comp_addr = comp_addr;
            write_comp_size = comp_size;
            write_en        = 1'b1;

            @(negedge clk);

            write_en = 1'b0;

        end

    endtask


    // =====================================================
    // READ TASK
    // =====================================================

    task read_metadata;

        input [3:0] addr;

        input [1:0] expected_mode;
        input [7:0] expected_comp_addr;
        input [7:0] expected_comp_size;

        begin

            @(negedge clk);

            read_addr = addr;
            read_en   = 1'b1;

            @(negedge clk);

            read_en = 1'b0;

            #1;

            $display(
                "Block %0d | Mode = %b | Address = %0d | Size = %0d",
                addr,
                read_mode,
                read_comp_addr,
                read_comp_size
            );

            if (read_mode != expected_mode) begin
                $display("  MODE FAIL");
                errors = errors + 1;
            end

            if (read_comp_addr != expected_comp_addr) begin
                $display("  ADDRESS FAIL");
                errors = errors + 1;
            end

            if (read_comp_size != expected_comp_size) begin
                $display("  SIZE FAIL");
                errors = errors + 1;
            end

        end

    endtask


    // =====================================================
    // TEST
    // =====================================================

    initial begin

        clk = 0;
        rst = 1;

        write_en = 0;
        write_addr = 0;
        write_mode = 0;
        write_comp_addr = 0;
        write_comp_size = 0;

        read_en = 0;
        read_addr = 0;

        errors = 0;


        // Reset
        #12;
        rst = 0;


        $display("");
        $display("METADATA RAM TEST");
        $display("-----------------");
        $display("");


        // =================================================
        // WRITE FOUR DIFFERENT MODES
        // =================================================

        // Block 0 = RAW
        write_metadata(
            4'd0,
            RAW,
            8'd0,
            8'd128
        );


        // Block 1 = DELTA4
        write_metadata(
            4'd1,
            DELTA4,
            8'd128,
            8'd68
        );


        // Block 2 = DELTA8
        write_metadata(
            4'd2,
            DELTA8,
            8'd196,
            8'd128
        );


        // Block 3 = RLE
        write_metadata(
            4'd3,
            RLE,
            8'd324,
            8'd48
        );


        // =================================================
        // READ BACK
        // =================================================

        read_metadata(
            4'd0,
            RAW,
            8'd0,
            8'd128
        );


        read_metadata(
            4'd1,
            DELTA4,
            8'd128,
            8'd68
        );


        read_metadata(
            4'd2,
            DELTA8,
            8'd196,
            8'd128
        );


        read_metadata(
            4'd3,
            RLE,
            8'd324,
            8'd48
        );


        // =================================================
        // RESULT
        // =================================================

        $display("");

        if (errors == 0) begin

            $display("ERRORS = 0");
            $display("METADATA RAM TEST PASS");

        end

        else begin

            $display("ERRORS = %0d", errors);
            $display("METADATA RAM TEST FAIL");

        end

        $finish;

    end

endmodule