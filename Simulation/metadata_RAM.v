`timescale 1ns/1ps

module metadata_ram (

    input wire         clk,
    input wire         rst,

    // Write interface
    input wire         write_en,
    input wire [3:0]   write_addr,

    input wire [1:0]   write_mode,
    input wire [7:0]   write_comp_addr,
    input wire [7:0]   write_comp_size,

    // Read interface
    input wire         read_en,
    input wire [3:0]   read_addr,

    output reg [1:0]   read_mode,
    output reg [7:0]   read_comp_addr,
    output reg [7:0]   read_comp_size,

    output reg         read_valid
);

    reg [31:0] mem [0:15];

    integer i;

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            read_mode      <= 2'b00;
            read_comp_addr <= 8'd0;
            read_comp_size <= 8'd0;
            read_valid     <= 1'b0;

            // Clear metadata RAM
            for (i = 0; i < 16; i = i + 1)
                mem[i] <= 32'd0;

        end

        else begin

            read_valid <= 1'b0;

            // -----------------------------
            // WRITE
            // -----------------------------
            if (write_en) begin

                mem[write_addr] <= {
                    write_comp_size,
                    write_comp_addr,
                    14'd0,
                    write_mode
                };

            end


            // -----------------------------
            // READ
            // -----------------------------
            if (read_en) begin

                read_mode <= mem[read_addr][1:0];

                read_comp_addr <= mem[read_addr][23:16];

                read_comp_size <= mem[read_addr][31:24];

                read_valid <= 1'b1;

            end

        end

    end

endmodule