`timescale 1ns/1ps

module block_buffer (
    input  wire         clk,
    input  wire         rst,

    input  wire [7:0]   data_in,
    input  wire         valid_in,
    input  wire         start,

    output reg [127:0]  block_data,
    output reg         block_ready
);

    // Byte counter
    reg [3:0] byte_count;

    // Temporary 16-byte storage
    reg [127:0] buffer;


    always @(posedge clk or posedge rst) begin

        if (rst) begin

            byte_count  <= 4'd0;
            buffer      <= 128'd0;

            block_data  <= 128'd0;
            block_ready <= 1'b0;

        end

        else begin

            // Default
            block_ready <= 1'b0;


            // ==========================================
            // START NEW BLOCK
            // ==========================================

            if (start && valid_in) begin

                buffer[7:0] <= data_in;

                byte_count <= 4'd1;

            end


            // ==========================================
            // RECEIVE REMAINING BYTES
            // ==========================================

            else if (valid_in) begin

                buffer[byte_count*8 +: 8] <= data_in;

                // Byte 15 received
                if (byte_count == 4'd15) begin

                    block_data <= {data_in, buffer[119:0]};
                    block_ready <= 1'b1;

                    byte_count <= 4'd0;

                end

                else begin

                    byte_count <= byte_count + 1'b1;

                end

            end

        end

    end

endmodule