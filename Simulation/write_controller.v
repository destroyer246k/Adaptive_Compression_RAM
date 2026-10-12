`timescale 1ns/1ps

module write_controller (

    input wire         clk,
    input wire         rst,

    // Compressed block input
    input wire         write_start,
    input wire [255:0] compressed_data,
    input wire [8:0]   compressed_size,
    input wire [1:0]   selected_mode,

    // Logical block address
    input wire [3:0]   block_addr,

    // Compressed Data RAM interface
    output reg         data_ram_write_en,
    output reg [7:0]   data_ram_write_addr,
    output reg [255:0] data_ram_write_data,

    // Metadata RAM interface
    output reg         metadata_write_en,
    output reg [3:0]   metadata_write_addr,
    output reg [1:0]   metadata_write_mode,
    output reg [7:0]   metadata_write_comp_addr,
    output reg [7:0]   metadata_write_comp_size,

    // Status
    output reg         write_done
);

    localparam IDLE       = 2'b00;
    localparam WRITE_DATA = 2'b01;
    localparam WRITE_META = 2'b10;
    localparam DONE       = 2'b11;

    reg [1:0] state;

    reg [7:0] compressed_addr;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            state <= IDLE;

            compressed_addr <= 8'd0;

            data_ram_write_en   <= 1'b0;
            data_ram_write_addr <= 8'd0;
            data_ram_write_data <= 256'd0;

            metadata_write_en        <= 1'b0;
            metadata_write_addr      <= 4'd0;
            metadata_write_mode      <= 2'b00;
            metadata_write_comp_addr <= 8'd0;
            metadata_write_comp_size <= 8'd0;

            write_done <= 1'b0;
        end

        else begin

            // Default: pulse signals low
            data_ram_write_en <= 1'b0;
            metadata_write_en <= 1'b0;
            write_done <= 1'b0;

            case (state)

                // --------------------------------
                // WAIT FOR NEW COMPRESSED BLOCK
                // --------------------------------
                IDLE: begin

                    if (write_start) begin

                        data_ram_write_addr <= compressed_addr;
                        data_ram_write_data <= compressed_data;

                        metadata_write_addr      <= block_addr;
                        metadata_write_mode      <= selected_mode;
                        metadata_write_comp_addr <= compressed_addr;
                        metadata_write_comp_size <= compressed_size[7:0];

                        state <= WRITE_DATA;
                    end

                end


                // --------------------------------
                // WRITE COMPRESSED DATA
                // --------------------------------
                WRITE_DATA: begin

                    data_ram_write_en <= 1'b1;

                    state <= WRITE_META;

                end


                // --------------------------------
                // WRITE METADATA
                // --------------------------------
                WRITE_META: begin

                    metadata_write_en <= 1'b1;

                    // Next compressed RAM location
                    compressed_addr <= compressed_addr + 1'b1;

                    state <= DONE;

                end


                // --------------------------------
                // FINISH
                // --------------------------------
                DONE: begin

                    write_done <= 1'b1;

                    state <= IDLE;

                end

            endcase

        end
    end

endmodule