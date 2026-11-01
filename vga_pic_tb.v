`timescale 1ns/1ps

module vga_pic_tb;
    reg vga_clk = 1'b0;
    reg sys_rst_n = 1'b1;
    reg [9:0] pix_x = 10'h3ff;
    reg [9:0] pix_y = 10'h3ff;
    wire [15:0] pix_data;
    reg [15:0] previous_data;
    reg [15:0] expected_data;
    integer row;
    integer column;
    integer samples = 0;
    reg dumping = 1'b1;
    reg wanted_dump;

    vga_pic dut (.vga_clk(vga_clk), .sys_rst_n(sys_rst_n), .pix_x(pix_x), .pix_y(pix_y), .pix_data(pix_data));
    always #20 vga_clk = ~vga_clk;
    `include "expected_pixels.vh"

    task sample_pixel;
        input integer x;
        input integer y;
        begin
            @(negedge vga_clk);
            previous_data = pix_data;
            pix_x = x;
            pix_y = y;
            expected_data = expected_pixel(x, y);
            #1;
            if (pix_data !== previous_data)
                $fatal(1, "Pixel changed before rising edge at x=%0d y=%0d", x, y);
            @(posedge vga_clk);
            #1;
            if (pix_data !== expected_data)
                $fatal(1, "Pixel mismatch x=%0d y=%0d: got %04h expected %04h", x, y, pix_data, expected_data);
            samples = samples + 1;
        end
    endtask

    initial begin
        $dumpfile("vga_pic_tb.vcd");
        $dumpvars(0, vga_pic_tb);
        #1 sys_rst_n = 1'b0;
        #1;
        if (pix_data !== 16'h0000) $fatal(1, "Pixel reset failed");
        #11 sys_rst_n = 1'b1;
        // Check every screen coordinate, including every on/off bitmap cell.
        for (row = 0; row < 480; row = row + 1) begin
            wanted_dump = (row == 0 || row == 208 || row == 215 || row == 271 || row == 272);
            if (wanted_dump && !dumping) begin $dumpon; dumping = 1'b1; end
            if (!wanted_dump && dumping) begin $dumpoff; dumping = 1'b0; end
            for (column = 0; column < 640; column = column + 1)
                sample_pixel(column, row);
        end
        sample_pixel(640, 208);
        sample_pixel(168, 480);
        sample_pixel(1023, 1023);
        $dumpon;
        sample_pixel(168, 208); // A white M pixel must clear immediately on reset.
        #5 sys_rst_n = 1'b0;
        #1;
        if (pix_data !== 16'h0000) $fatal(1, "Asynchronous pixel reset failed");
        repeat (2) @(posedge vga_clk);
        #1;
        if (pix_data !== 16'h0000) $fatal(1, "Characters appeared while reset was held");
        @(negedge vga_clk); #3 sys_rst_n = 1'b1;
        sample_pixel(168, 208);
        sample_pixel(471, 271);
        $display("PASS vga_pic_tb: %0d registered pixel samples; complete 640x480 bitmap image, four glyphs, box/gap boundaries, invalid coordinates, reset and release checked", samples);
        $finish;
    end

    initial begin
        #15000000;
        $fatal(1, "vga_pic_tb timed out");
    end
endmodule
