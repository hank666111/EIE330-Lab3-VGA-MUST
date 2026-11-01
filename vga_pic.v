`timescale 1ns/1ns

module vga_pic (
    input  wire        vga_clk,
    input  wire        sys_rst_n,
    input  wire [9:0]  pix_x,
    input  wire [9:0]  pix_y,
    output reg  [15:0] pix_data
);

localparam [15:0] BLACK  = 16'h0000;
localparam [15:0] WHITE  = 16'hffff;
localparam [15:0] YELLOW = 16'hffe0;
localparam [15:0] CYAN   = 16'h07ff;
localparam [15:0] GREEN  = 16'h07e0;

// Each bitmap cell occupies an 8 by 8 block of screen pixels.
localparam [9:0] M_X = 10'd168;
localparam [9:0] U_X = 10'd248;
localparam [9:0] S_X = 10'd328;
localparam [9:0] T_X = 10'd408;
localparam [9:0] TEXT_Y = 10'd208;
localparam [9:0] SIZE = 10'd64;

// One byte per row, with bit 7 on the left. M follows the lab handout.
parameter [7:0] M_ROW_0 = 8'b1100_0011;
parameter [7:0] M_ROW_1 = 8'b1110_0111;
parameter [7:0] M_ROW_2 = 8'b1111_1111;
parameter [7:0] M_ROW_3 = 8'b1101_1011;
parameter [7:0] M_ROW_4 = 8'b1100_0011;
parameter [7:0] M_ROW_5 = 8'b1100_0011;
parameter [7:0] M_ROW_6 = 8'b1100_0011;
parameter [7:0] M_ROW_7 = 8'b1100_0011;

parameter [7:0] U_ROW_0 = 8'b1100_0011;
parameter [7:0] U_ROW_1 = 8'b1100_0011;
parameter [7:0] U_ROW_2 = 8'b1100_0011;
parameter [7:0] U_ROW_3 = 8'b1100_0011;
parameter [7:0] U_ROW_4 = 8'b1100_0011;
parameter [7:0] U_ROW_5 = 8'b1100_0011;
parameter [7:0] U_ROW_6 = 8'b0110_0110;
parameter [7:0] U_ROW_7 = 8'b0011_1100;

parameter [7:0] S_ROW_0 = 8'b0111_1110;
parameter [7:0] S_ROW_1 = 8'b1100_0011;
parameter [7:0] S_ROW_2 = 8'b1100_0000;
parameter [7:0] S_ROW_3 = 8'b0111_1110;
parameter [7:0] S_ROW_4 = 8'b0000_0011;
parameter [7:0] S_ROW_5 = 8'b0000_0011;
parameter [7:0] S_ROW_6 = 8'b1100_0011;
parameter [7:0] S_ROW_7 = 8'b0111_1110;

parameter [7:0] T_ROW_0 = 8'b1111_1111;
parameter [7:0] T_ROW_1 = 8'b1111_1111;
parameter [7:0] T_ROW_2 = 8'b0001_1000;
parameter [7:0] T_ROW_3 = 8'b0001_1000;
parameter [7:0] T_ROW_4 = 8'b0001_1000;
parameter [7:0] T_ROW_5 = 8'b0001_1000;
parameter [7:0] T_ROW_6 = 8'b0001_1000;
parameter [7:0] T_ROW_7 = 8'b0001_1000;

wire in_m_box;
wire in_u_box;
wire in_s_box;
wire in_t_box;
wire [2:0] m_char_x;
wire [2:0] u_char_x;
wire [2:0] s_char_x;
wire [2:0] t_char_x;
wire [2:0] char_y;

assign in_m_box = (pix_x >= M_X) && (pix_x < M_X + SIZE)
               && (pix_y >= TEXT_Y) && (pix_y < TEXT_Y + SIZE);
assign in_u_box = (pix_x >= U_X) && (pix_x < U_X + SIZE)
               && (pix_y >= TEXT_Y) && (pix_y < TEXT_Y + SIZE);
assign in_s_box = (pix_x >= S_X) && (pix_x < S_X + SIZE)
               && (pix_y >= TEXT_Y) && (pix_y < TEXT_Y + SIZE);
assign in_t_box = (pix_x >= T_X) && (pix_x < T_X + SIZE)
               && (pix_y >= TEXT_Y) && (pix_y < TEXT_Y + SIZE);

// Box origins are multiples of eight. Inside a 64-pixel box, these
// three-bit cell offsets run from 0 to 7, including across a bit-field wrap.
assign m_char_x = pix_x[5:3] - M_X[5:3];
assign u_char_x = pix_x[5:3] - U_X[5:3];
assign s_char_x = pix_x[5:3] - S_X[5:3];
assign t_char_x = pix_x[5:3] - T_X[5:3];
assign char_y = pix_y[5:3] - TEXT_Y[5:3];

always @(posedge vga_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        pix_data <= BLACK;
    else if (in_m_box) begin
        case (char_y)
            3'd0: pix_data <= M_ROW_0[3'd7 - m_char_x] ? WHITE : BLACK;
            3'd1: pix_data <= M_ROW_1[3'd7 - m_char_x] ? WHITE : BLACK;
            3'd2: pix_data <= M_ROW_2[3'd7 - m_char_x] ? WHITE : BLACK;
            3'd3: pix_data <= M_ROW_3[3'd7 - m_char_x] ? WHITE : BLACK;
            3'd4: pix_data <= M_ROW_4[3'd7 - m_char_x] ? WHITE : BLACK;
            3'd5: pix_data <= M_ROW_5[3'd7 - m_char_x] ? WHITE : BLACK;
            3'd6: pix_data <= M_ROW_6[3'd7 - m_char_x] ? WHITE : BLACK;
            3'd7: pix_data <= M_ROW_7[3'd7 - m_char_x] ? WHITE : BLACK;
            default: pix_data <= BLACK;
        endcase
    end
    else if (in_u_box) begin
        case (char_y)
            3'd0: pix_data <= U_ROW_0[3'd7 - u_char_x] ? YELLOW : BLACK;
            3'd1: pix_data <= U_ROW_1[3'd7 - u_char_x] ? YELLOW : BLACK;
            3'd2: pix_data <= U_ROW_2[3'd7 - u_char_x] ? YELLOW : BLACK;
            3'd3: pix_data <= U_ROW_3[3'd7 - u_char_x] ? YELLOW : BLACK;
            3'd4: pix_data <= U_ROW_4[3'd7 - u_char_x] ? YELLOW : BLACK;
            3'd5: pix_data <= U_ROW_5[3'd7 - u_char_x] ? YELLOW : BLACK;
            3'd6: pix_data <= U_ROW_6[3'd7 - u_char_x] ? YELLOW : BLACK;
            3'd7: pix_data <= U_ROW_7[3'd7 - u_char_x] ? YELLOW : BLACK;
            default: pix_data <= BLACK;
        endcase
    end
    else if (in_s_box) begin
        case (char_y)
            3'd0: pix_data <= S_ROW_0[3'd7 - s_char_x] ? CYAN : BLACK;
            3'd1: pix_data <= S_ROW_1[3'd7 - s_char_x] ? CYAN : BLACK;
            3'd2: pix_data <= S_ROW_2[3'd7 - s_char_x] ? CYAN : BLACK;
            3'd3: pix_data <= S_ROW_3[3'd7 - s_char_x] ? CYAN : BLACK;
            3'd4: pix_data <= S_ROW_4[3'd7 - s_char_x] ? CYAN : BLACK;
            3'd5: pix_data <= S_ROW_5[3'd7 - s_char_x] ? CYAN : BLACK;
            3'd6: pix_data <= S_ROW_6[3'd7 - s_char_x] ? CYAN : BLACK;
            3'd7: pix_data <= S_ROW_7[3'd7 - s_char_x] ? CYAN : BLACK;
            default: pix_data <= BLACK;
        endcase
    end
    else if (in_t_box) begin
        case (char_y)
            3'd0: pix_data <= T_ROW_0[3'd7 - t_char_x] ? GREEN : BLACK;
            3'd1: pix_data <= T_ROW_1[3'd7 - t_char_x] ? GREEN : BLACK;
            3'd2: pix_data <= T_ROW_2[3'd7 - t_char_x] ? GREEN : BLACK;
            3'd3: pix_data <= T_ROW_3[3'd7 - t_char_x] ? GREEN : BLACK;
            3'd4: pix_data <= T_ROW_4[3'd7 - t_char_x] ? GREEN : BLACK;
            3'd5: pix_data <= T_ROW_5[3'd7 - t_char_x] ? GREEN : BLACK;
            3'd6: pix_data <= T_ROW_6[3'd7 - t_char_x] ? GREEN : BLACK;
            3'd7: pix_data <= T_ROW_7[3'd7 - t_char_x] ? GREEN : BLACK;
            default: pix_data <= BLACK;
        endcase
    end
    else
        pix_data <= BLACK;
end

endmodule
