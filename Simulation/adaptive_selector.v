`timescale 1ns/1ps

module adaptive_selector (

    input wire         clk,
    input wire         rst,

    input wire         valid_in,

    // RLE
    input wire [4:0]   rle_run_count,

    // Delta analyzer result
    input wire [1:0]   delta_mode,

    // Selected result
    output reg [1:0]   selected_mode,
    output reg [8:0]   selected_size,

    output reg         result_valid,
    output reg         done
);

    // Mode encoding
    localparam RAW    = 2'b00;
    localparam DELTA4 = 2'b01;
    localparam DELTA8 = 2'b10;
    localparam RLE    = 2'b11;

    reg [8:0] rle_size;
    reg [8:0] delta_size;

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            selected_mode <= RAW;
            selected_size <= 9'd128;

            result_valid <= 1'b0;
            done         <= 1'b0;

        end

        else begin

            result_valid <= 1'b0;
            done         <= 1'b0;

            if (valid_in) begin

                // RLE storage size
                rle_size = rle_run_count * 16;

                // Determine Delta size
                case (delta_mode)

                    DELTA4:
                        delta_size = 9'd68;

                    DELTA8:
                        delta_size = 9'd128;

                    default:
                        delta_size = 9'd128;

                endcase


                // Default = RAW
                selected_mode <= RAW;
                selected_size <= 9'd128;


                // Compare RLE and Delta
                if (rle_size < 128) begin

                    if (delta_size < rle_size) begin

                        selected_mode <= delta_mode;
                        selected_size <= delta_size;

                    end

                    else begin

                        selected_mode <= RLE;
                        selected_size <= rle_size;

                    end

                end

                else begin

                    if (delta_size < 128) begin

                        selected_mode <= delta_mode;
                        selected_size <= delta_size;

                    end

                end


                result_valid <= 1'b1;
                done         <= 1'b1;

            end

        end

    end

endmodule