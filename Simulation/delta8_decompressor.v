`timescale 1ns/1ps

module delta8_decompressor (
    input  wire         clk,
    input  wire         rst,

    input  wire [127:0] packed_data,
    input  wire         packed_valid,

    output reg [7:0]    data_out,
    output reg          valid_out,
    output reg          done
);

    localparam IDLE = 2'b00;
    localparam RUN  = 2'b01;
    localparam DONE = 2'b10;

    reg [1:0] state;

    reg [7:0] current_value;
    reg signed [7:0] delta8;

    reg [3:0] delta_count;

    reg signed [8:0] next_value;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            state         <= IDLE;

            current_value <= 8'd0;
            delta8        <= 8'sd0;
            delta_count   <= 4'd0;
            next_value    <= 9'sd0;

            data_out      <= 8'd0;
            valid_out     <= 1'b0;
            done          <= 1'b0;
        end

        else begin

            valid_out <= 1'b0;
            done      <= 1'b0;

            case (state)

                // -----------------------------
                // First byte
                // -----------------------------
                IDLE: begin

                    if (packed_valid) begin

                        current_value <= packed_data[7:0];

                        data_out <= packed_data[7:0];
                        valid_out <= 1'b1;

                        delta_count <= 4'd1;

                        state <= RUN;
                    end

                end


                // -----------------------------
                // Decode 15 deltas
                // -----------------------------
                RUN: begin

                    if (delta_count <= 4'd15) begin

                        // Extract 8-bit signed delta
                        delta8 = packed_data[
                            8 + ((delta_count - 1) * 8) +: 8
                        ];

                        // Current value + signed delta
                        next_value =
                            $signed({1'b0, current_value})
                            + $signed(delta8);

                        current_value <= next_value[7:0];

                        data_out <= next_value[7:0];
                        valid_out <= 1'b1;

                        if (delta_count == 4'd15) begin
                            state <= DONE;
                        end
                        else begin
                            delta_count <= delta_count + 1'b1;
                        end

                    end

                end


                // -----------------------------
                // Finished
                // -----------------------------
                DONE: begin

                    done <= 1'b1;
                    state <= IDLE;

                end

            endcase
        end
    end

endmodule