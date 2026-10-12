`timescale 1ns/1ps
// Board-level test: writes all 8 patterns through the real button/switch
// path, then checks the 7-segment output and LED slice 0 for each.
module tb_pine_s7_top;
    reg         clk = 0;
    reg  [15:0] sw  = 16'd0;
    reg         key0 = 1, key3 = 1;      // active-low: 1 = released
    wire [15:0] led;
    wire sa,sb,sc,sd,se,sf,sg,spd, d1,d2,d3,d4;

    pine_s7_top #(.TICK_BITS(2), .SCAN_BITS(6)) dut (
        .osc_clk_100mhz(clk), .KEY_0(key0), .KEY_3(key3), .SLIDE_SW(sw), .LED(led),
        .SIG_A(sa),.SIG_B(sb),.SIG_C(sc),.SIG_D(sd),.SIG_E(se),.SIG_F(sf),.SIG_G(sg),.SIG_PD(spd),
        .SEL_DISP1(d1),.SEL_DISP2(d2),.SEL_DISP3(d3),.SEL_DISP4(d4));

    always #5 clk = ~clk;

    // ---- decode 7-seg (active-low segs, active-low selects = module defaults)
    function [3:0] dec; input [6:0] g_to_a; begin
        case (g_to_a)
            7'b0111111: dec=0; 7'b0000110: dec=1; 7'b1011011: dec=2; 7'b1001111: dec=3;
            7'b1100110: dec=4; 7'b1101101: dec=5; 7'b1111101: dec=6; 7'b0000111: dec=7;
            7'b1111111: dec=8; 7'b1101111: dec=9; default: dec=4'hF;
        endcase end endfunction

    reg [3:0] seen [0:3];
    wire [6:0] segs = ~{sg,sf,se,sd,sc,sb,sa};
    always @(posedge clk) begin
        // physical DIS1..DIS4 are driven by SEL_DISP3, SEL_DISP4, SEL_DISP1, SEL_DISP2
        if (!d3) seen[0] <= dec(segs);
        if (!d4) seen[1] <= dec(segs);
        if (!d1) seen[2] <= dec(segs);
        if (!d2) seen[3] <= dec(segs);
    end

    task press_write; begin
        key0 = 0; repeat (200) @(posedge clk);
        key0 = 1; repeat (200) @(posedge clk);
    end endtask

    integer p, errors, got_size;
    reg [1:0] exp_mode [0:7];
    integer   exp_size [0:7];

    initial begin
        errors = 0;
        exp_mode[0]=1; exp_size[0]=68;
        exp_mode[1]=1; exp_size[1]=68;
        exp_mode[2]=0; exp_size[2]=128;
        exp_mode[3]=3; exp_size[3]=64;
        exp_mode[4]=3; exp_size[4]=16;
        exp_mode[5]=0; exp_size[5]=128;
        exp_mode[6]=3; exp_size[6]=32;
        exp_mode[7]=1; exp_size[7]=68;

        repeat (50) @(posedge clk);          // power-on reset

        for (p = 0; p < 8; p = p + 1) begin
            sw[2:0] = p;  sw[7:4] = p;  sw[15:12] = 4'd0;
            repeat (20) @(posedge clk);
            press_write;
            repeat (3000) @(posedge clk);    // core + readback + display scan
            got_size = seen[1]*100 + seen[2]*10 + seen[3];
            $display("pattern %0d -> mode %0d size %0d bits | LED slice0 = %04h",
                     p, seen[0], got_size, led);
            if (seen[0] !== exp_mode[p] || got_size !== exp_size[p]) begin
                errors = errors + 1;
                $display("   ** MISMATCH: expected mode %0d size %0d", exp_mode[p], exp_size[p]);
            end
        end

        // Spot-check LED slice for the 4 vectors with known payloads
        sw[7:4]=0; sw[15:12]=0; repeat(3000) @(posedge clk);
        if (led !== 16'h1101) begin errors=errors+1; $display("** blk0 slice0 %04h != 1101", led); end
        sw[7:4]=1; repeat(3000) @(posedge clk);
        if (led !== 16'h1364) begin errors=errors+1; $display("** blk1 slice0 %04h != 1364", led); end
        sw[7:4]=2; repeat(3000) @(posedge clk);
        if (led !== 16'h7864) begin errors=errors+1; $display("** blk2 slice0 %04h != 7864", led); end
        sw[7:4]=3; repeat(3000) @(posedge clk);
        if (led !== 16'h0841) begin errors=errors+1; $display("** blk3 slice0 %04h != 0841", led); end

        // Re-view an earlier block after other writes (persistence)
        sw[7:4]=3; sw[15:12]=4'd1; repeat(3000) @(posedge clk);
        $display("blk3 slice1 = %04h", led);

        // Manual reset clears metadata
        key3 = 0; repeat (200) @(posedge clk); key3 = 1; repeat (3000) @(posedge clk);
        sw[7:4]=3;
        $display("after KEY_3 reset: blk3 shows %0d.%0d%0d%0d", seen[0],seen[1],seen[2],seen[3]);
        if (seen[0]!==0 || seen[1]!==0 || seen[2]!==0 || seen[3]!==0) errors=errors+1;

        $display("\nERRORS = %0d  ->  %s", errors, errors==0 ? "PASS" : "FAIL");
        $finish;
    end
endmodule
