`timescale 1ns/1ps

module write_path_integration (

    input wire         clk,
    input wire         rst,

    // Write request
    input wire         write_start,
    input wire [3:0]   block_addr,

    input wire [1:0]   selected_mode,
    input wire [8:0]   compressed_size,
    input wire [255:0] compressed_data,

    // Read request for verification / future read controller
    input wire         data_read_en,
    input wire [7:0]   data_read_addr,

    input wire         metadata_read_en,
    input wire [3:0]   metadata_read_addr,

    // Read outputs
    output wire [255:0] data_read_data,
    output wire         data_read_valid,

    output wire [1:0]   metadata_read_mode,
    output wire [7:0]   metadata_read_comp_addr,
    output wire [7:0]   metadata_read_comp_size,
    output wire         metadata_read_valid,

    // Status
    output wire         write_done
);

    // --------------------------------------------
    // Write Controller signals
    // --------------------------------------------

    wire        data_ram_write_en;
    wire [7:0]  data_ram_write_addr;
    wire [255:0] data_ram_write_data;

    wire        metadata_write_en;
    wire [3:0]  metadata_write_addr;
    wire [1:0]  metadata_write_mode;
    wire [7:0]  metadata_write_comp_addr;
    wire [7:0]  metadata_write_comp_size;


    // --------------------------------------------
    // Write Controller
    // --------------------------------------------

    write_controller u_write_controller (

        .clk(clk),
        .rst(rst),

        .write_start(write_start),
        .compressed_data(compressed_data),
        .compressed_size(compressed_size),
        .selected_mode(selected_mode),
        .block_addr(block_addr),

        .data_ram_write_en(data_ram_write_en),
        .data_ram_write_addr(data_ram_write_addr),
        .data_ram_write_data(data_ram_write_data),

        .metadata_write_en(metadata_write_en),
        .metadata_write_addr(metadata_write_addr),
        .metadata_write_mode(metadata_write_mode),
        .metadata_write_comp_addr(metadata_write_comp_addr),
        .metadata_write_comp_size(metadata_write_comp_size),

        .write_done(write_done)
    );


    // --------------------------------------------
    // Compressed Data RAM
    // --------------------------------------------

    compressed_data_ram u_data_ram (

        .clk(clk),
        .rst(rst),

        .write_en(data_ram_write_en),
        .write_addr(data_ram_write_addr),
        .write_data(data_ram_write_data),

        .read_en(data_read_en),
        .read_addr(data_read_addr),

        .read_data(data_read_data),
        .read_valid(data_read_valid)
    );


    // --------------------------------------------
    // Metadata RAM
    // --------------------------------------------

    metadata_ram u_metadata_ram (

        .clk(clk),
        .rst(rst),

        .write_en(metadata_write_en),
        .write_addr(metadata_write_addr),
        .write_mode(metadata_write_mode),
        .write_comp_addr(metadata_write_comp_addr),
        .write_comp_size(metadata_write_comp_size),

        .read_en(metadata_read_en),
        .read_addr(metadata_read_addr),

        .read_mode(metadata_read_mode),
        .read_comp_addr(metadata_read_comp_addr),
        .read_comp_size(metadata_read_comp_size),
        .read_valid(metadata_read_valid)
    );

endmodule