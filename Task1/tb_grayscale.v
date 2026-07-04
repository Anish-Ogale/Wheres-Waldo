module tb_grayscale;
    reg  [23:0] pixel_in;
    wire [7:0]  gray_out;

    parameter TOTAL_PIXELS = 411 * 486;
    reg [23:0] mem [0:TOTAL_PIXELS-1];
    integer i, outfile;

    grayscale uut (.pixel_in(pixel_in), .gray_out(gray_out));

    initial begin
        $readmemh("input_pixels.mem", mem);
        outfile = $fopen("output_pixels.mem", "w");

        for (i = 0; i < TOTAL_PIXELS; i = i + 1) begin
            pixel_in = mem[i];
            #1;
            $fwrite(outfile, "%02X\n", gray_out);
        end

        $fclose(outfile);
        $finish;
    end
endmodule