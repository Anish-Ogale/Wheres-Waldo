`timescale 1ns / 1ps

module tb_Morphology;

    parameter WIDTH  = 256;
    parameter HEIGHT = 256;
    parameter DELAY  = 2*WIDTH + 4;

    reg clk, rst;
    reg [7:0] pixel_in;
    reg valid_in;
    wire [7:0] pixel_out;
    wire valid_out;

    integer i;
    integer outfile;

    reg [7:0] image_mem [0:WIDTH*HEIGHT-1];

    Morphology #(.WIDTH(WIDTH), .DELAY(DELAY)) uut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .pixel_in(pixel_in),
        .valid_out(valid_out),
        .pixel_out(pixel_out)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $readmemh("input_image.hex", image_mem);
        outfile = $fopen("output_image.hex", "w");

        rst = 1; valid_in = 0; pixel_in = 0;
        #20;
        rst = 0;

        // Feeds the real image, one pixel per clock
        for (i = 0; i < WIDTH*HEIGHT; i = i + 1) begin
            @(posedge clk);
            pixel_in = image_mem[i];
            valid_in = 1;
        end

        // Feed dummy pixels just to push the last rows through the pipeline
        for (i = 0; i < DELAY; i = i + 1) begin
            @(posedge clk);
            pixel_in = 8'h00;
            valid_in = 1;
        end

        @(posedge clk);
        valid_in = 0;
        #20;

        $fclose(outfile);
        $display("Done. Output written to output_image.hex");
        $finish;
    end

    always @(posedge clk) begin
        if (valid_out)
            $fwrite(outfile, "%02h\n", pixel_out);
    end

endmodule