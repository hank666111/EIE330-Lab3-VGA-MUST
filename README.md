# EIE330 Lab 3: VGA MUST display

The design displays M, U, S and T together in a 640 by 480 window. The 50 MHz input clock is divided to a 25 MHz pixel clock. The glyphs use 8 by 8 bitmaps enlarged eight times.

The Verilog files at the repository root are convenient previews. Download and extract **Lab3_VGA_Source.zip** for the project with separate RTL and sim directories, reproducible checks, plotted waveform data, synthesis results, and the course simulator support files with their license. The archive README explains the tool versions and evidence limits.

Top module: `vga_must`. Inputs: `sys_clk`, `sys_rst_n`; outputs: `hsync`, `vsync`, `rgb[15:0]`. Reset is active low.

Four module testbenches have passed in Icarus Verilog. Full-frame RGB output matches the independent bitmap model. These ideal RTL checks do not establish physical FPGA timing closure. Virtual-board evidence and the report are maintained separately.

The timing design follows the EIE330 Lab 3 lecture; the M bitmap follows the lab handout. The implementation and verification were prepared with AI assistance and require group review.
