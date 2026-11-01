// Independent reference image: complete 8x8 bitmaps, MSB at the top-left.
// Each stored bit represents an 8x8 display-pixel square.
function [15:0] expected_pixel;
    input integer screen_x;
    input integer screen_y;
    integer letter;
    integer local_x;
    integer row;
    integer column;
    reg [63:0] bitmap;
    reg [15:0] colour;
    begin
        expected_pixel = 16'h0000;
        for (letter = 0; letter < 4; letter = letter + 1) begin
            local_x = screen_x - (168 + 80*letter);
            if (local_x >= 0 && local_x < 64 && screen_y >= 208 && screen_y < 272) begin
                row = (screen_y - 208) / 8;
                column = local_x / 8;
                case (letter)
                    0: begin bitmap = 64'hc3e7ffdbc3c3c3c3; colour = 16'hffff; end
                    1: begin bitmap = 64'hc3c3c3c3c3c3663c; colour = 16'hffe0; end
                    2: begin bitmap = 64'h7ec3c07e0303c37e; colour = 16'h07ff; end
                    3: begin bitmap = 64'hffff181818181818; colour = 16'h07e0; end
                    default: begin bitmap = 0; colour = 0; end
                endcase
                if (bitmap[63 - 8*row - column]) expected_pixel = colour;
            end
        end
    end
endfunction
