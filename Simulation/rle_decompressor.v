`timescale 1ns/1ps

module rle_decompressor (
    input  wire       clk,
    input  wire       rst,

    input  wire [7:0] symbol_in,
    input  wire [4:0] count_in,
    input  wire       valid_in,
    input  wire       last_in,

    output reg  [7:0] data_out,
    output reg        valid_out,
    output reg        done
);

    // FSM states
    localparam IDLE   = 2'b00;
    localparam OUTPUT = 2'b01;
    localparam DONE   = 2'b10;

    reg [1:0] state;

    reg [7:0] current_symbol;
    reg [4:0] remaining_count;
    reg       current_last;


    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state           <= IDLE;

            current_symbol  <= 8'd0;
            remaining_count <= 5'd0;
            current_last    <= 1'b0;

            data_out        <= 8'd0;
            valid_out       <= 1'b0;
            done            <= 1'b0;

        end

        else begin

            // Default outputs
            valid_out <= 1'b0;
            done      <= 1'b0;


            case (state)

                // ==================================
                // IDLE
                // ==================================

                IDLE: begin

                    if (valid_in) begin

                        current_symbol  <= symbol_in;
                        remaining_count <= count_in;
                        current_last    <= last_in;

                        state <= OUTPUT;

                    end

                end


                // ==================================
                // OUTPUT
                // ==================================

                OUTPUT: begin

                    // Output current symbol
                    data_out  <= current_symbol;
                    valid_out <= 1'b1;

                    // More copies remaining
                    if (remaining_count > 1) begin

                        remaining_count <= remaining_count - 1'b1;

                    end

                    // This was the final copy
                    else begin

                        remaining_count <= 0;

                        if (current_last)
                            state <= DONE;
                        else
                            state <= IDLE;

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