`timescale 1ns/1ps

module delta8_packer (
    input  wire         clk,
    input  wire         rst,

    input  wire [127:0] block_data,
    input  wire         block_valid,

    output reg [127:0]  packed_data,
    output reg          packed_valid,
    output reg          done
);

    integer i;

    reg signed [8:0] delta;
    reg signed [7:0] delta8;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            packed_data  <= 128'd0;
            packed_valid <= 1'b0;
            done         <= 1'b0;
        end

        else begin

            packed_valid <= 1'b0;
            done         <= 1'b0;

            if (block_valid) begin

                // First byte
                packed_data[7:0] <= block_data[7:0];

                // Pack 15 deltas
                for (i = 1; i < 16; i = i + 1) begin

                    delta =
                        $signed({1'b0, block_data[i*8 +: 8]}) -
                        $signed({1'b0, block_data[(i-1)*8 +: 8]});

                    delta8 = delta[7:0];

                    packed_data[i*8 +: 8] <= delta8;
                end

                packed_valid <= 1'b1;
                done         <= 1'b1;
            end
        end
    end

endmodule