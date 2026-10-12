`timescale 1ns/1ps

module compression_output_formatter (

    input wire         clk,
    input wire         rst,

    input wire         valid_in,

    input wire [1:0]   selected_mode,

    // Original block
    input wire [127:0] raw_data,

    // DELTA4
    input wire [127:0] delta4_data,

    // DELTA8
    input wire [127:0] delta8_data,

    // RLE
    input wire [255:0] rle_data,
    input wire [4:0]   rle_run_count,

    output reg [255:0] compressed_data,
    output reg [8:0]   compressed_size,

    output reg         result_valid,
    output reg         done
);

    localparam RAW    = 2'b00;
    localparam DELTA4 = 2'b01;
    localparam DELTA8 = 2'b10;
    localparam RLE    = 2'b11;


    always @(posedge clk or posedge rst) begin

        if (rst) begin

            compressed_data <= 256'd0;
            compressed_size <= 9'd0;

            result_valid <= 1'b0;
            done         <= 1'b0;

        end

        else begin

            result_valid <= 1'b0;
            done         <= 1'b0;


            if (valid_in) begin

                case (selected_mode)

                    // ---------------------------------
                    // RAW
                    // ---------------------------------

                    RAW: begin

                        compressed_data <= {
                            128'd0,
                            raw_data
                        };

                        compressed_size <= 9'd128;

                    end


                    // ---------------------------------
                    // DELTA4
                    // ---------------------------------

                    DELTA4: begin

                        compressed_data <= {
                            128'd0,
                            delta4_data
                        };

                        compressed_size <= 9'd68;

                    end


                    // ---------------------------------
                    // DELTA8
                    // ---------------------------------

                    DELTA8: begin

                        compressed_data <= {
                            128'd0,
                            delta8_data
                        };

                        compressed_size <= 9'd128;

                    end


                    // ---------------------------------
                    // RLE
                    // ---------------------------------

                    RLE: begin

                        compressed_data <= rle_data;

                        compressed_size <=
                            rle_run_count * 16;

                    end


                    default: begin

                        compressed_data <= 256'd0;
                        compressed_size <= 9'd0;

                    end

                endcase


                result_valid <= 1'b1;
                done         <= 1'b1;

            end

        end

    end

endmodule