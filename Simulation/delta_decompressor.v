`timescale 1ns/1ps

module delta_decompressor (
    input  wire              clk,
    input  wire              rst,

    input  wire [7:0]        first_value_in,
    input  wire signed [8:0] delta_in,

    input  wire              first_valid,
    input  wire              delta_valid,
    input  wire              delta_last,

    output reg  [7:0]        data_out,
    output reg               valid_out,
    output reg               done
);

    localparam IDLE = 2'b00;
    localparam RUN  = 2'b01;
    localparam DONE = 2'b10;

    reg [1:0] state;

    // Keep the current reconstructed value
    reg [7:0] current_value;

    // Temporary signed value for addition
    reg signed [8:0] next_value;


    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state         <= IDLE;
            current_value <= 8'd0;
            next_value    <= 9'sd0;

            data_out      <= 8'd0;
            valid_out     <= 1'b0;
            done          <= 1'b0;

        end

        else begin

            valid_out <= 1'b0;
            done      <= 1'b0;


            case (state)

                // ==================================
                // IDLE
                // ==================================

                IDLE: begin

                    if (first_valid) begin

                        current_value <= first_value_in;

                        data_out      <= first_value_in;
                        valid_out     <= 1'b1;

                        state <= RUN;

                    end

                end


                // ==================================
                // RUN
                // ==================================

                RUN: begin

                    if (delta_valid) begin

                        // Signed addition
                        next_value =
                            $signed({1'b0, current_value})
                            + delta_in;

                        // Store reconstructed value
                        current_value <= next_value[7:0];

                        // Output reconstructed value
                        data_out  <= next_value[7:0];
                        valid_out <= 1'b1;

                        // delta_last tells us that this
                        // is the final delta of the block
                        if (delta_last)
                            state <= DONE;

                    end

                end


                // ==================================
                // DONE
                // ==================================

                DONE: begin

                    done  <= 1'b1;
                    state <= IDLE;

                end

            endcase

        end

    end

endmodule 