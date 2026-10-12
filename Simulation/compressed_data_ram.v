`timescale 1ns/1ps

module compressed_data_ram (

    input wire         clk,
    input wire         rst,

    // Write interface
    input wire         write_en,
    input wire [7:0]   write_addr,
    input wire [255:0] write_data,

    // Read interface
    input wire         read_en,
    input wire [7:0]   read_addr,

    output reg [255:0] read_data,
    output reg         read_valid

);

    // 256 entries × 256 bits
    reg [255:0] mem [0:255];

    integer i;

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            read_data  <= 256'd0;
            read_valid <= 1'b0;

            // Clear RAM
            for (i = 0; i < 256; i = i + 1)
                mem[i] <= 256'd0;

        end

        else begin

            read_valid <= 1'b0;

            // -----------------------------
            // WRITE
            // -----------------------------
            if (write_en) begin

                mem[write_addr] <= write_data;

            end


            // -----------------------------
            // READ
            // -----------------------------
            if (read_en) begin

                read_data  <= mem[read_addr];
                read_valid <= 1'b1;

            end

        end

    end

endmodule