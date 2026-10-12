`timescale 1ns/1ps

module adaptive_compression_memory_controller (

    input wire         clk,
    input wire         rst,

    // ============================================================
    // WRITE INPUT
    // ============================================================

    input wire         write_start,
    input wire [3:0]   block_addr,
    input wire [127:0] block_data,


    // ============================================================
    // COMPRESSED DATA RAM READ
    // ============================================================

    input wire         data_read_en,
    input wire [7:0]   data_read_addr,

    output wire [255:0] data_read_data,
    output wire         data_read_valid,


    // ============================================================
    // METADATA RAM READ
    // ============================================================

    input wire         metadata_read_en,
    input wire [3:0]   metadata_read_addr,

    output wire [1:0]   metadata_read_mode,
    output wire [7:0]   metadata_read_comp_addr,
    output wire [7:0]   metadata_read_comp_size,
    output wire         metadata_read_valid,


    // ============================================================
    // STATUS
    // ============================================================

    output wire write_done,
    output reg  busy

);


    // ============================================================
    // FSM STATES
    // ============================================================

    localparam IDLE       = 3'd0;
    localparam START      = 3'd1;
    localparam RLE_RUN    = 3'd2;
    localparam WAIT_RLE   = 3'd3;
    localparam SELECT     = 3'd4;
    localparam FORMAT     = 3'd5;
    localparam WRITE      = 3'd6;


    reg [2:0] state;


    // ============================================================
    // BLOCK REGISTERS
    // ============================================================

    reg [127:0] block_reg;

    reg [3:0] block_addr_reg;

    reg [3:0] byte_index;

    // One-shot flag so write_controller sees write_start for exactly
    // ONE clock (otherwise it re-triggers and stores the block twice).
    reg write_sent;


    // ============================================================
    // COMPRESSION READY FLAGS
    // ============================================================

    reg delta4_ready;
    reg delta8_ready;
    reg rle_ready;


    // ============================================================
    // RLE BYTE MUX
    // ============================================================

    reg [7:0] rle_data_byte;


    always @(*) begin

        case (byte_index)

            4'd0:
                rle_data_byte = block_reg[7:0];

            4'd1:
                rle_data_byte = block_reg[15:8];

            4'd2:
                rle_data_byte = block_reg[23:16];

            4'd3:
                rle_data_byte = block_reg[31:24];

            4'd4:
                rle_data_byte = block_reg[39:32];

            4'd5:
                rle_data_byte = block_reg[47:40];

            4'd6:
                rle_data_byte = block_reg[55:48];

            4'd7:
                rle_data_byte = block_reg[63:56];

            4'd8:
                rle_data_byte = block_reg[71:64];

            4'd9:
                rle_data_byte = block_reg[79:72];

            4'd10:
                rle_data_byte = block_reg[87:80];

            4'd11:
                rle_data_byte = block_reg[95:88];

            4'd12:
                rle_data_byte = block_reg[103:96];

            4'd13:
                rle_data_byte = block_reg[111:104];

            4'd14:
                rle_data_byte = block_reg[119:112];

            4'd15:
                rle_data_byte = block_reg[127:120];

            default:
                rle_data_byte = 8'd0;

        endcase

    end


    // ============================================================
    // DELTA ADAPTIVE ANALYZER
    // ============================================================

    wire [1:0] delta_mode;
    wire       delta_result_valid;


    delta_adaptive_analyzer u_analyzer (

        .block_data(block_reg),
        .block_valid(state != IDLE),

        .delta_mode(delta_mode),
        .result_valid(delta_result_valid)

    );


    // ============================================================
    // DELTA4 PACKER
    // ============================================================

    wire [127:0] delta4_data;
    wire         delta4_valid;
    wire         delta4_done;


    delta4_packer u_delta4 (

        .clk(clk),
        .rst(rst),

        .block_data(block_reg),
        .block_valid(state == START),

        .packed_data(delta4_data),
        .packed_valid(delta4_valid),
        .done(delta4_done)

    );


    // ============================================================
    // DELTA8 PACKER
    // ============================================================

    wire [127:0] delta8_data;
    wire         delta8_valid;
    wire         delta8_done;


    delta8_packer u_delta8 (

        .clk(clk),
        .rst(rst),

        .block_data(block_reg),
        .block_valid(state == START),

        .packed_data(delta8_data),
        .packed_valid(delta8_valid),
        .done(delta8_done)

    );


    // ============================================================
    // RLE COMPRESSOR
    // ============================================================

    wire [7:0] rle_symbol;
    wire [4:0] rle_count;

    wire rle_valid;
    wire rle_done;


    rle_compressor u_rle (

        .clk(clk),
        .rst(rst),

        .data_in(rle_data_byte),

        .valid_in(
            (state == START) ||
            (state == RLE_RUN)
        ),

        .start(
            state == START
        ),

        .last(
            (state == RLE_RUN) &&
            (byte_index == 4'd15)
        ),

        .symbol_out(rle_symbol),
        .count_out(rle_count),

        .valid_out(rle_valid),
        .done(rle_done)

    );


    // ============================================================
    // RLE STORAGE PACKER
    // ============================================================

    wire [255:0] rle_data;
    wire [4:0]   rle_run_count;

    wire rle_packed_valid;
    wire rle_storage_done;


    rle_storage_packer u_rle_storage (

        .clk(clk),
        .rst(rst),

        .symbol_in(rle_symbol),
        .count_in(rle_count),

        .valid_in(rle_valid),
        .done_in(rle_done),

        .packed_data(rle_data),
        .run_count(rle_run_count),

        .packed_valid(rle_packed_valid),
        .done(rle_storage_done)

    );


    // ============================================================
    // ADAPTIVE SELECTOR
    // ============================================================

    wire [1:0] selected_mode;
    wire [8:0] selected_size;

    wire selector_valid;
    wire selector_done;


    adaptive_selector u_selector (

        .clk(clk),
        .rst(rst),

        .valid_in(
            state == SELECT
        ),

        .rle_run_count(rle_run_count),
        .delta_mode(delta_mode),

        .selected_mode(selected_mode),
        .selected_size(selected_size),

        .result_valid(selector_valid),
        .done(selector_done)

    );


    // ============================================================
    // OUTPUT FORMATTER
    // ============================================================

    wire [255:0] formatted_data;
    wire [8:0]   formatted_size;

    wire formatter_valid;
    wire formatter_done;


    compression_output_formatter u_formatter (

        .clk(clk),
        .rst(rst),

        .valid_in(
            state == FORMAT
        ),

        .selected_mode(selected_mode),

        .raw_data(block_reg),

        .delta4_data(delta4_data),
        .delta8_data(delta8_data),

        .rle_data(rle_data),
        .rle_run_count(rle_run_count),

        .compressed_data(formatted_data),
        .compressed_size(formatted_size),

        .result_valid(formatter_valid),
        .done(formatter_done)

    );


    // ============================================================
    // WRITE CONTROLLER
    // ============================================================

    wire        data_ram_write_en;
    wire [7:0]  data_ram_write_addr;
    wire [255:0] data_ram_write_data;

    wire        metadata_write_en;
    wire [3:0]  metadata_write_addr;
    wire [1:0]  metadata_write_mode;
    wire [7:0]  metadata_write_comp_addr;
    wire [7:0]  metadata_write_comp_size;


    write_controller u_write_controller (

        .clk(clk),
        .rst(rst),

        .write_start(
            (state == WRITE) && !write_sent
        ),

        .compressed_data(formatted_data),
        .compressed_size(formatted_size),

        .selected_mode(selected_mode),

        .block_addr(block_addr_reg),

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


    // ============================================================
    // COMPRESSED DATA RAM
    // ============================================================

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


    // ============================================================
    // METADATA RAM
    // ============================================================

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


    // ============================================================
    // MAIN FSM
    // ============================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state <= IDLE;

            block_reg      <= 128'd0;
            block_addr_reg <= 4'd0;

            byte_index <= 4'd0;

            delta4_ready <= 1'b0;
            delta8_ready <= 1'b0;
            rle_ready    <= 1'b0;

            busy <= 1'b0;

            write_sent <= 1'b0;

        end

        else begin

            case (state)


                // =================================================
                // IDLE
                // =================================================

                IDLE: begin

                    busy <= 1'b0;

                    if (write_start) begin

                        block_reg <= block_data;

                        block_addr_reg <= block_addr;

                        byte_index <= 4'd0;

                        delta4_ready <= 1'b0;
                        delta8_ready <= 1'b0;
                        rle_ready    <= 1'b0;

                        busy <= 1'b1;

                        state <= START;

                    end

                end


                // =================================================
                // START
                // =================================================

                START: begin

                    // Byte 0 is supplied to RLE here.
                    // Delta4 and Delta8 also start here.

                    byte_index <= 4'd1;

                    state <= RLE_RUN;

                end


                // =================================================
                // RLE STREAM
                // =================================================

                RLE_RUN: begin

                    // Capture Delta results.
                    if (delta4_valid)
                        delta4_ready <= 1'b1;

                    if (delta8_valid)
                        delta8_ready <= 1'b1;

                    // Capture completed RLE storage.
                    if (rle_packed_valid)
                        rle_ready <= 1'b1;


                    if (byte_index == 4'd15) begin

                        state <= WAIT_RLE;

                    end

                    else begin

                        byte_index <= byte_index + 1'b1;

                    end

                end


                // =================================================
                // WAIT FOR RLE STORAGE
                // =================================================

                WAIT_RLE: begin

                    if (delta4_valid)
                        delta4_ready <= 1'b1;

                    if (delta8_valid)
                        delta8_ready <= 1'b1;

                    if (rle_packed_valid)
                        rle_ready <= 1'b1;


                    if (delta4_ready &&
                        delta8_ready &&
                        rle_ready) begin

                        state <= SELECT;

                    end

                end


                // =================================================
                // ADAPTIVE SELECTOR
                // =================================================

                SELECT: begin

                    // Selector receives:
                    // RLE run count
                    // Delta mode

                    state <= FORMAT;

                end


                // =================================================
                // FORMAT
                // =================================================

                FORMAT: begin

                    // Formatter receives the selected mode
                    // and corresponding compressed data.

                    state <= WRITE;

                end


                // =================================================
                // WRITE
                // =================================================

                WRITE: begin

                    write_sent <= 1'b1;

                    if (write_done) begin

                        write_sent <= 1'b0;

                        busy <= 1'b0;

                        state <= IDLE;

                    end

                end


                // =================================================
                // DEFAULT
                // =================================================

                default: begin

                    state <= IDLE;

                    busy <= 1'b0;

                end

            endcase

        end

    end

endmodule