`timescale 1ns/1ps

module tb_compressed_data_ram;

    reg clk;
    reg rst;

    reg         write_en;
    reg [7:0]   write_addr;
    reg [255:0] write_data;

    reg         read_en;
    reg [7:0]   read_addr;

    wire [255:0] read_data;
    wire         read_valid;

    integer errors;


    // =====================================================
    // DUT
    // =====================================================

    compressed_data_ram uut (

        .clk(clk),
        .rst(rst),

        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),

        .read_en(read_en),
        .read_addr(read_addr),

        .read_data(read_data),
        .read_valid(read_valid)

    );


    // =====================================================
    // CLOCK
    // =====================================================

    always #5 clk = ~clk;


    // =====================================================
    // WRITE TASK
    // =====================================================

    task write_ram;

        input [7:0]   addr;
        input [255:0] data;

        begin

            @(negedge clk);

            write_addr = addr;
            write_data = data;
            write_en   = 1'b1;

            @(negedge clk);

            write_en = 1'b0;

        end

    endtask


    // =====================================================
    // READ + CHECK TASK
    // =====================================================

    task read_ram;

        input [7:0]   addr;
        input [255:0] expected;

        begin

            @(negedge clk);

            read_addr = addr;
            read_en   = 1'b1;

            @(negedge clk);

            read_en = 1'b0;

            #1;

            $display(
                "Address %0d | Data = %h",
                addr,
                read_data
            );

            if (read_data != expected) begin

                $display("  FAIL");
                errors = errors + 1;

            end

            else begin

                $display("  PASS");

            end

        end

    endtask


    // =====================================================
    // TEST
    // =====================================================

    initial begin

        clk = 0;
        rst = 1;

        write_en   = 0;
        write_addr = 0;
        write_data = 0;

        read_en   = 0;
        read_addr = 0;

        errors = 0;


        // Reset
        #12;
        rst = 0;


        $display("");
        $display("COMPRESSED DATA RAM TEST");
        $display("------------------------");
        $display("");


        // =================================================
        // WRITE TEST DATA
        // =================================================


        // -------------------------------------------------
        // Address 0
        // RAW example - 128 useful bits
        // -------------------------------------------------

        write_ram(
            8'd0,

            256'h00000000000000000000000000000000100F0E0D0C0B0A090807060504030201
        );


        // -------------------------------------------------
        // Address 1
        // DELTA4 packed example
        //
        // From our previous test:
        // 0000000000000001111111111114e364
        // -------------------------------------------------

        write_ram(
            8'd1,

            256'h000000000000000000000000000000000000000000000001111111111114e364
        );


        // -------------------------------------------------
        // Address 2
        // DELTA8 packed example
        //
        // From our previous DELTA8 test:
        // fb14f60ffb140aec0ffb14f650e23264
        // -------------------------------------------------

        write_ram(
            8'd2,

            256'h00000000000000000000000000000000fb14f60ffb140aec0ffb14f650e23264
        );


        // -------------------------------------------------
        // Address 3
        // RLE packed example
        //
        // (A,4)
        // (B,3)
        // (C,2)
        // (D,1)
        //
        // Lower 64 bits:
        // 0144 0243 0342 0441
        // -------------------------------------------------

        write_ram(
            8'd3,

            256'h0000000000000000000000000000000000000000000000000144024303420441
        );


        // =================================================
        // READ TEST DATA
        // =================================================

        read_ram(
            8'd0,

            256'h00000000000000000000000000000000100F0E0D0C0B0A090807060504030201
        );


        read_ram(
            8'd1,

            256'h000000000000000000000000000000000000000000000001111111111114e364
        );


        read_ram(
            8'd2,

            256'h00000000000000000000000000000000fb14f60ffb140aec0ffb14f650e23264
        );


        read_ram(
            8'd3,

            256'h0000000000000000000000000000000000000000000000000144024303420441
        );


        // =================================================
        // FINAL RESULT
        // =================================================

        $display("");

        if (errors == 0) begin

            $display("ERRORS = 0");
            $display("COMPRESSED DATA RAM TEST PASS");

        end

        else begin

            $display("ERRORS = %0d", errors);
            $display("COMPRESSED DATA RAM TEST FAIL");

        end

        $finish;

    end

endmodule