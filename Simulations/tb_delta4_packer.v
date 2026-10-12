module tb_delta4_packer;

    reg clk;
    reg rst;

    reg [127:0] block_data;
    reg block_valid;

    wire [127:0] packed_data;
    wire packed_valid;
    wire done;

    delta4_packer uut (
        .clk(clk),
        .rst(rst),

        .block_data(block_data),
        .block_valid(block_valid),

        .packed_data(packed_data),
        .packed_valid(packed_valid),
        .done(done)
    );

    always #5 clk = ~clk;

    initial begin

        clk = 0;
        rst = 1;
        block_data = 128'd0;
        block_valid = 0;

        #12;
        rst = 0;

        /*
        Block:

        100
        103
        101
        105
        106
        107
        108
        109
        110
        111
        112
        113
        114
        115
        116
        117
        */

        block_data[7:0]     = 8'd100;
        block_data[15:8]    = 8'd103;
        block_data[23:16]   = 8'd101;
        block_data[31:24]   = 8'd105;
        block_data[39:32]   = 8'd106;
        block_data[47:40]   = 8'd107;
        block_data[55:48]   = 8'd108;
        block_data[63:56]   = 8'd109;
        block_data[71:64]   = 8'd110;
        block_data[79:72]   = 8'd111;
        block_data[87:80]   = 8'd112;
        block_data[95:88]   = 8'd113;
        block_data[103:96]  = 8'd114;
        block_data[111:104] = 8'd115;
        block_data[119:112] = 8'd116;
        block_data[127:120] = 8'd117;

        // Drive before positive edge
        @(negedge clk);
        block_valid = 1;

        @(negedge clk);
        block_valid = 0;

        wait(done);

        #1;

        $display("");
        $display("DELTA4 PACKER TEST");
        $display("-------------------");

        $display("First value = %0d", packed_data[7:0]);

        $display("Delta 1  = %b", packed_data[11:8]);
        $display("Delta 2  = %b", packed_data[15:12]);
        $display("Delta 3  = %b", packed_data[19:16]);
        $display("Delta 4  = %b", packed_data[23:20]);
        $display("Delta 5  = %b", packed_data[27:24]);

        $display("");
        $display("Packed data = %h", packed_data);
        $display("");

        $finish;
    end

endmodule