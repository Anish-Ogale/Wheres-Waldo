`timescale 1ns / 1ps

module tb_max_pool;

    parameter WIDTH = 4;

    reg clk;
    reg rst;

    reg signed [7:0] pixel;
    reg signed [7:0] pixel_prev;

    reg valid_in;

    wire signed [7:0] pooled;
    wire valid_out;


    // ============================================================
    // DUT
    // ============================================================

    max_pool #(
        .WIDTH(WIDTH)
    ) dut (
        .clk        (clk),
        .rst        (rst),
        .pixel      (pixel),
        .pixel_prev (pixel_prev),
        .pooled     (pooled),
        .valid_in   (valid_in),
        .valid_out  (valid_out)
    );


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // SIGNED TEST IMAGE
    //
    //    -10    5    -3     7
    //      2   -8     9    -1
    //     -4    6    -7    12
    //      8   -2     3    -5
    //
    // Expected 2x2 max pool, stride 1:
    //
    //      5     9     9
    //      6     9    12
    //      8     6    12
    // ============================================================

    reg signed [7:0] image [0:WIDTH-1][0:WIDTH-1];


    // Expected output
    reg signed [7:0] expected [0:WIDTH-2][0:WIDTH-2];


    integer x;
    integer y;

    integer output_count;
    integer error_count;


    // ============================================================
    // SEND ONE PIXEL
    // ============================================================

    task send_pixel;

        input integer row;
        input integer col;

        begin

            @(negedge clk);

            pixel = image[row][col];

            if (row == 0)
                pixel_prev = 8'sd0;
            else
                pixel_prev = image[row-1][col];

            valid_in = 1'b1;

            @(negedge clk);

            valid_in = 1'b0;

        end

    endtask


    // ============================================================
    // OUTPUT CHECKER
    // ============================================================

    always @(posedge clk) begin

        if (valid_out) begin

            output_count = output_count + 1;

            $display(
                "TIME=%0t : OUTPUT[%0d] = %0d",
                $time,
                output_count,
                pooled
            );

            if (pooled !== expected[
                    (output_count-1) / (WIDTH-1)
                ][
                    (output_count-1) % (WIDTH-1)
                ]) begin

                $display(
                    "             ERROR: Expected %0d, Got %0d",
                    expected[
                        (output_count-1) / (WIDTH-1)
                    ][
                        (output_count-1) % (WIDTH-1)
                    ],
                    pooled
                );

                error_count = error_count + 1;

            end
            else begin

                $display("             PASS");

            end

        end

    end


    // ============================================================
    // TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Initialize signals
        // --------------------------------------------------------

        rst         = 1'b1;
        pixel       = 8'sd0;
        pixel_prev  = 8'sd0;
        valid_in    = 1'b0;

        output_count = 0;
        error_count  = 0;


        // --------------------------------------------------------
        // Initialize signed image
        // --------------------------------------------------------

        image[0][0] = -10;
        image[0][1] =   5;
        image[0][2] =  -3;
        image[0][3] =   7;

        image[1][0] =   2;
        image[1][1] =  -8;
        image[1][2] =   9;
        image[1][3] =  -1;

        image[2][0] =  -4;
        image[2][1] =   6;
        image[2][2] =  -7;
        image[2][3] =  12;

        image[3][0] =   8;
        image[3][1] =  -2;
        image[3][2] =   3;
        image[3][3] =  -5;


        // --------------------------------------------------------
        // Expected results
        // --------------------------------------------------------

        expected[0][0] =  5;
        expected[0][1] =  9;
        expected[0][2] =  9;

        expected[1][0] =  6;
        expected[1][1] =  9;
        expected[1][2] = 12;

        expected[2][0] =  8;
        expected[2][1] =  6;
        expected[2][2] = 12;


        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        repeat(2) @(posedge clk);

        rst = 1'b0;


        // --------------------------------------------------------
        // Print test information
        // --------------------------------------------------------

        $display("");
        $display("======================================");
        $display("      SIGNED MAX POOL TEST");
        $display("======================================");
        $display("");

        $display("Input image:");

        $display(" %4d %4d %4d %4d",
                 image[0][0],
                 image[0][1],
                 image[0][2],
                 image[0][3]);

        $display(" %4d %4d %4d %4d",
                 image[1][0],
                 image[1][1],
                 image[1][2],
                 image[1][3]);

        $display(" %4d %4d %4d %4d",
                 image[2][0],
                 image[2][1],
                 image[2][2],
                 image[2][3]);

        $display(" %4d %4d %4d %4d",
                 image[3][0],
                 image[3][1],
                 image[3][2],
                 image[3][3]);

        $display("");

        $display("Expected output:");

        $display(" %4d %4d %4d",
                 expected[0][0],
                 expected[0][1],
                 expected[0][2]);

        $display(" %4d %4d %4d",
                 expected[1][0],
                 expected[1][1],
                 expected[1][2]);

        $display(" %4d %4d %4d",
                 expected[2][0],
                 expected[2][1],
                 expected[2][2]);

        $display("");

        $display("Starting test...");
        $display("");


        // --------------------------------------------------------
        // Send entire image
        // --------------------------------------------------------

        for (y = 0; y < WIDTH; y = y + 1) begin

            for (x = 0; x < WIDTH; x = x + 1) begin

                send_pixel(y, x);

            end

        end


        // --------------------------------------------------------
        // Wait for pipeline to finish
        // --------------------------------------------------------

        repeat(5) @(posedge clk);


        // --------------------------------------------------------
        // Final result
        // --------------------------------------------------------

        $display("");
        $display("======================================");

        if ((error_count == 0) &&
            (output_count == (WIDTH-1)*(WIDTH-1))) begin

            $display("       SIGNED TEST : PASS");
            $display("");
            $display("All %0d outputs are correct.",
                     output_count);

        end
        else begin

            $display("       SIGNED TEST : FAIL");
            $display("");
            $display("Expected outputs : %0d",
                     (WIDTH-1)*(WIDTH-1));

            $display("Received outputs : %0d",
                     output_count);

            $display("Errors           : %0d",
                     error_count);

        end

        $display("======================================");
        $display("");


        $finish;

    end


    // ============================================================
    // VCD WAVEFORM
    // ============================================================

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_max_pool);
    end

endmodule