`timescale 1ns/1ps

module delta_compressor (
    input  wire        clk,
    input  wire        rst,

    input  wire [7:0]  data_in,
    input  wire        valid_in,
    input  wire        start,
    input  wire        last,

    output reg  [7:0]  first_value,
    output reg signed [8:0] delta_out,

    output reg        first_valid,
    output reg        delta_valid,
    output reg        delta_last,
    output reg        done
);

    localparam IDLE = 2'b00;
    localparam RUN  = 2'b01;
    localparam DONE = 2'b10;

    reg [1:0] state;

    reg [7:0] previous_value;


    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state          <= IDLE;
            previous_value <= 8'd0;

            first_value    <= 8'd0;
            delta_out      <= 9'sd0;

            first_valid    <= 1'b0;
            delta_valid    <= 1'b0;
            delta_last     <= 1'b0;
            done           <= 1'b0;

        end

        else begin

            // Default outputs
            first_valid <= 1'b0;
            delta_valid <= 1'b0;
            delta_last  <= 1'b0;
            done        <= 1'b0;


            case (state)

                // ==================================
                // IDLE
                // ==================================

                IDLE: begin

                    if (start && valid_in) begin

                        // First value is stored directly
                        first_value <= data_in;
                        first_valid <= 1'b1;

                        previous_value <= data_in;

                        if (last)
                            state <= DONE;
                        else
                            state <= RUN;

                    end

                end


                // ==================================
                // RUN
                // ==================================

                RUN: begin

                    if (valid_in) begin

                        // Calculate difference
                        delta_out <= $signed({1'b0, data_in})
                                   - $signed({1'b0, previous_value});

                        delta_valid <= 1'b1;

                        // Tell downstream that this is
                        // the final delta of the block
                        if (last)
                            delta_last <= 1'b1;

                        // Current value becomes previous
                        previous_value <= data_in;

                        if (last)
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