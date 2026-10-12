`timescale 1ns/1ps

module delta_adaptive_analyzer (

    input  wire [127:0] block_data,
    input  wire         block_valid,

    output reg  [1:0]   delta_mode,
    output reg          result_valid

);

    localparam RAW    = 2'b00;
    localparam DELTA4 = 2'b01;
    localparam DELTA8 = 2'b10;

    integer i;

    reg signed [8:0] delta;

    reg fits_4bit;
    reg fits_8bit;


    always @(*) begin

        // Default
        fits_4bit = 1'b1;
        fits_8bit = 1'b1;

        delta_mode  = RAW;
        result_valid = 1'b0;


        // Only analyze when block is valid
        if (block_valid) begin

            // Check all 15 deltas
            for (i = 1; i < 16; i = i + 1) begin

                delta =
                    $signed({1'b0, block_data[i*8 +: 8]}) -
                    $signed({1'b0, block_data[(i-1)*8 +: 8]});


                // Check 4-bit signed range
                if ((delta < -9'sd8) ||
                    (delta >  9'sd7)) begin

                    fits_4bit = 1'b0;

                end


                // Check 8-bit signed range
                if ((delta < -9'sd128) ||
                    (delta >  9'sd127)) begin

                    fits_8bit = 1'b0;

                end

            end


            // =========================================
            // SELECT MODE
            // =========================================

            if (fits_4bit)

                delta_mode = DELTA4;

            else if (fits_8bit)

                delta_mode = DELTA8;

            else

                delta_mode = RAW;


            result_valid = 1'b1;

        end

    end

endmodule