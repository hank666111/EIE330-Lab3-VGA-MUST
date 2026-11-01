`timescale 1ns/1ps

module vga_must_tb;
    reg sys_clk = 1'b0;
    reg sys_rst_n = 1'b1;
    wire hsync, vsync;
    wire [15:0] rgb;
    integer x = 0;
    integer y = 0;
    reg phase = 1'b0;
    integer n;
    integer pixels = 0;
    integer visible_pixels = 0;
    integer blanking_pixels = 0;
    integer hsync_high = 0;
    integer vsync_high = 0;
    integer glyph_pixels [0:3];
    integer coloured_pixels = 0;
    integer sync_file;
    integer frame_file;
    integer k;
    reg active;
    reg [15:0] expected_rgb;
    reg dumping = 1'b1;
    reg wanted_dump;
    time first_frame_end = 0;
    time second_frame_end = 0;

    vga_must dut (.sys_clk(sys_clk), .sys_rst_n(sys_rst_n), .hsync(hsync), .vsync(vsync), .rgb(rgb));
    always #10 sys_clk = ~sys_clk;

    `include "expected_pixels.vh"

    task advance_position;
        begin
            if (x == 799) begin
                x = 0;
                if (y == 524) y = 0;
                else y = y + 1;
            end else x = x + 1;
        end
    endtask

    task check_outputs;
        begin
            active = (x >= 144 && x < 784 && y >= 35 && y < 515);
            expected_rgb = active ? expected_pixel(x - 144, y - 35) : 16'h0000;
            if (hsync !== (x < 96) || vsync !== (y < 2))
                $fatal(1, "Top sync mismatch at x=%0d y=%0d phase=%0b time=%0t", x, y, phase, $time);
            if (rgb !== expected_rgb)
                $fatal(1, "Top colour mismatch at x=%0d y=%0d phase=%0b: got %04h expected %04h time=%0t", x, y, phase, rgb, expected_rgb, $time);
        end
    endtask

    task one_system_cycle;
        begin
            @(posedge sys_clk);
            phase = ~phase;
            if (phase) advance_position;
            #1; // Observe after the divider, counters and colour register settle.
            wanted_dump = (pixels < 810 || y <= 2 || y == 35 || y == 243 || y == 306 || y == 514 || (y >= 524 && x > 790));
            if (wanted_dump && !dumping) begin $dumpon; dumping = 1'b1; end
            if (!wanted_dump && dumping) begin $dumpoff; dumping = 1'b0; end
            check_outputs;
        end
    endtask

    initial begin
        $dumpfile("vga_must_tb.vcd");
        $dumpvars(0, vga_must_tb);
        for (k = 0; k < 4; k = k + 1) glyph_pixels[k] = 0;
        sync_file = $fopen("sync_edges.csv", "w");
        if (!sync_file) $fatal(1, "Could not create sync-edge log");
        $fdisplay(sync_file, "time_ns,reset_n,hsync,vsync");
        frame_file = $fopen("frame_rgb565.hex", "w");
        if (!frame_file) $fatal(1, "Could not create observed-frame file");
        #1 sys_rst_n = 1'b0;
        #1; check_outputs;
        #23 sys_rst_n = 1'b1;

        // Two complete frames, sampled at every system-clock rising edge.
        // The expected scan position is independent of the RTL counters.
        for (n = 0; n < 1680000; n = n + 1) begin
            one_system_cycle;
            if (phase) begin
                pixels = pixels + 1;
                if (active) begin
                    visible_pixels = visible_pixels + 1;
                    if (rgb != 0) begin
                        coloured_pixels = coloured_pixels + 1;
                        if ((x-144) >= 168 && (x-144) < 472)
                            glyph_pixels[((x-144)-168)/80] = glyph_pixels[((x-144)-168)/80] + 1;
                    end
                    if (pixels <= 420000) $fdisplay(frame_file, "%04h", rgb);
                end else blanking_pixels = blanking_pixels + 1;
                if (hsync) hsync_high = hsync_high + 1;
                if (vsync) vsync_high = vsync_high + 1;
                if (pixels == 420000) first_frame_end = $time;
                if (pixels == 840000) second_frame_end = $time;
            end
        end
        $fclose(frame_file);
        if (pixels != 840000 || visible_pixels != 614400 || blanking_pixels != 225600)
            $fatal(1, "Frame coverage mismatch: total=%0d active=%0d blank=%0d", pixels, visible_pixels, blanking_pixels);
        if (hsync_high != 100800 || vsync_high != 3200)
            $fatal(1, "Wrong sync duration: H=%0d V=%0d", hsync_high, vsync_high);
        if ((second_frame_end - first_frame_end) != 16800000)
            $fatal(1, "Wrong frame period: %0t", second_frame_end-first_frame_end);
        if (glyph_pixels[0] != 5120 || glyph_pixels[1] != 4096 ||
            glyph_pixels[2] != 4096 || glyph_pixels[3] != 3584 || coloured_pixels != 16896)
            $fatal(1, "Wrong glyph areas: M=%0d U=%0d S=%0d T=%0d", glyph_pixels[0], glyph_pixels[1], glyph_pixels[2], glyph_pixels[3]);

        // Reset at a non-clock instant while a coloured pixel is displayed.
        for (n = 0; n < 389430; n = n + 1) one_system_cycle;
        $dumpon; dumping = 1'b1;
        #5 sys_rst_n = 1'b0;
        x = 0; y = 0; phase = 1'b0;
        #1; check_outputs;
        repeat (2) @(negedge sys_clk);
        #3 sys_rst_n = 1'b1;
        for (n = 0; n < 840000; n = n + 1) one_system_cycle;
        if (x != 0 || y != 0) $fatal(1, "Restarted frame did not wrap correctly");

        $display("PASS vga_must_tb: 2 full frames; pixel_checks=%0d active=%0d blank=%0d; all 4 glyphs checked at every active pixel", pixels, visible_pixels, blanking_pixels);
        $display("Measured frame period=%0t; 25 MHz / (800*525) = 59.5238095 Hz; one-frame RGB565 output saved", second_frame_end-first_frame_end);
        $fclose(sync_file);
        $display("PASS reset: asynchronous clearing during active video and one full frame after release checked");
        $finish;
    end

    // This compact file records actual output edges throughout the full frames.
    always @(hsync or vsync or sys_rst_n) begin
        #0.001;
        if (sync_file) $fdisplay(sync_file, "%0.3f,%0b,%0b,%0b", $realtime, sys_rst_n, hsync, vsync);
    end

    initial begin
        #70000000;
        $fatal(1, "vga_must_tb timed out");
    end
endmodule
