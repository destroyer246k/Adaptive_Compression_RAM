`timescale 1ns/1ps

module rle_compressor (
    input  wire       clk,
    input  wire       rst,

    input  wire [7:0] data_in,
    input  wire       valid_in,
    input  wire       start,
    input  wire       last,

    output reg  [7:0] symbol_out,
    output reg  [4:0] count_out,
    output reg        valid_out,
    output reg        done
);

    // FSM states
    localparam IDLE  = 2'b00;
    localparam RUN   = 2'b01;
    localparam FLUSH = 2'b10;
    localparam DONE  = 2'b11;

    reg [1:0] state;

    reg [7:0] current_symbol;
    reg [4:0] run_count;


    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state          <= IDLE;
            current_symbol <= 8'd0;
            run_count      <= 5'd0;

            symbol_out     <= 8'd0;
            count_out      <= 5'd0;
            valid_out      <= 1'b0;
            done           <= 1'b0;

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

                    if (start && valid_in) begin

                        current_symbol <= data_in;
                        run_count      <= 5'd1;

                        if (last)
                            state <= FLUSH;
                        else
                            state <= RUN;

                    end

                end


                // ==================================
                // RUN
                // ==================================

                RUN: begin

                    if (valid_in) begin

                        // Same symbol
                        if (data_in == current_symbol) begin

                            run_count <= run_count + 1'b1;

                            // Last byte belongs to this run
                            if (last)
                                state <= FLUSH;

                        end


                        // Different symbol
                        else begin

                            // Output previous run
                            symbol_out <= current_symbol;
                            count_out  <= run_count;
                            valid_out  <= 1'b1;

                            // Start new run
                            current_symbol <= data_in;
                            run_count      <= 5'd1;

                            // If this is the last byte,
                            // the new run must also be flushed.
                            if (last)
                                state <= FLUSH;

                        end

                    end

                end


                // ==================================
                // FLUSH
                // ==================================

                FLUSH: begin

                    // Output final run
                    symbol_out <= current_symbol;
                    count_out  <= run_count;
                    valid_out  <= 1'b1;

                    state <= DONE;

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