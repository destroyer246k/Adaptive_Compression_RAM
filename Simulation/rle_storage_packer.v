`timescale 1ns/1ps

module rle_storage_packer (

    input wire         clk,
    input wire         rst,

    input wire [7:0]   symbol_in,
    input wire [4:0]   count_in,

    input wire         valid_in,
    input wire         done_in,

    output reg [255:0] packed_data,
    output reg [4:0]   run_count,

    output reg         packed_valid,
    output reg         done
);

    reg [255:0] buffer;
    reg [4:0]   pair_count;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            buffer        <= 256'd0;
            pair_count    <= 5'd0;

            packed_data   <= 256'd0;
            run_count     <= 5'd0;

            packed_valid  <= 1'b0;
            done          <= 1'b0;
        end

        else begin

            packed_valid <= 1'b0;
            done         <= 1'b0;

            // Store RLE pair
            if (valid_in) begin

                buffer[pair_count*16 +: 16]
                    <= {3'b000, count_in, symbol_in};

                pair_count <= pair_count + 1'b1;

            end

            // RLE compressor finished
            if (done_in) begin

                packed_data  <= buffer;
                run_count    <= pair_count;

                packed_valid <= 1'b1;
                done         <= 1'b1;

                buffer       <= 256'd0;
                pair_count   <= 5'd0;

            end

        end

    end

endmodule