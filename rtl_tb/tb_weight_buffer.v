// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps

module tb_weight_buffer;

    parameter DATA_WIDTH = 8;
    parameter ARRAY_SIZE = 8;
    parameter ADDR_WIDTH = 10;

    localparam WORD_WIDTH = DATA_WIDTH * ARRAY_SIZE;

    reg clk;
    reg rst_n;

    reg we_A;
    reg [ADDR_WIDTH-1:0] addr_A;
    reg signed [WORD_WIDTH-1:0] din_A;

    reg ena_B;
    reg [ADDR_WIDTH-1:0] addr_B;
    wire signed [WORD_WIDTH-1:0] dout_B;


    // ============================================================
    // DUT
    // ============================================================

    weight_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .ARRAY_SIZE(ARRAY_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk    (clk),
        .rst_n  (rst_n),

        .we_A   (we_A),
        .addr_A (addr_A),
        .din_A  (din_A),

        .ena_B  (ena_B),
        .addr_B (addr_B),
        .dout_B(dout_B)
    );


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // ============================================================
    // TEST DATA
    // ============================================================

    reg signed [DATA_WIDTH-1:0] test_weights [0:ARRAY_SIZE-1];

    reg signed [DATA_WIDTH-1:0] expected_weights [0:ARRAY_SIZE-1];

    integer i;
    integer errors;


    // ============================================================
    // CREATE 64-BIT WORD FROM 8 SIGNED WEIGHTS
    // ============================================================

    task write_word;

        input [ADDR_WIDTH-1:0] address;

        begin

            @(negedge clk);

            addr_A = address;

            din_A = 0;

            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                din_A[(i*DATA_WIDTH) +: DATA_WIDTH] =
                    test_weights[i];
            end

            we_A = 1'b1;

            @(posedge clk);

            #1;

            we_A = 1'b0;

            $display(
                "WRITE: Address %0d",
                address
            );

            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin

                $display(
                    "       Weight[%0d] = %0d",
                    i,
                    test_weights[i]
                );

            end

        end

    endtask


    // ============================================================
    // READ AND CHECK ONE WORD
    // ============================================================

    task read_word;

        input [ADDR_WIDTH-1:0] address;

        begin

            @(negedge clk);

            addr_B = address;
            ena_B  = 1'b1;

            // Read occurs on next rising edge
            @(posedge clk);

            #1;

            ena_B = 1'b0;

            $display("");
            $display(
                "READ: Address %0d",
                address
            );

            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin

                if ($signed(
                    dout_B[(i*DATA_WIDTH) +: DATA_WIDTH]
                ) !== expected_weights[i]) begin

                    $display(
                        "       Weight[%0d] ERROR: Expected %0d, Got %0d",
                        i,
                        expected_weights[i],
                        $signed(
                            dout_B[(i*DATA_WIDTH) +: DATA_WIDTH]
                        )
                    );

                    errors = errors + 1;

                end
                else begin

                    $display(
                        "       Weight[%0d] = %0d : PASS",
                        i,
                        $signed(
                            dout_B[(i*DATA_WIDTH) +: DATA_WIDTH]
                        )
                    );

                end

            end

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        errors = 0;

        rst_n = 1'b0;

        we_A   = 1'b0;
        addr_A = 0;
        din_A  = 0;

        ena_B  = 1'b0;
        addr_B = 0;


        // ========================================================
        // TEST START
        // ========================================================

        $display("");
        $display("======================================");
        $display("       WEIGHT BUFFER TEST");
        $display("======================================");
        $display("");

        $display(
            "DATA_WIDTH  = %0d",
            DATA_WIDTH
        );

        $display(
            "ARRAY_SIZE  = %0d",
            ARRAY_SIZE
        );

        $display(
            "WORD_WIDTH  = %0d bits",
            WORD_WIDTH
        );

        $display(
            "ADDR_WIDTH  = %0d",
            ADDR_WIDTH
        );

        $display("");


        // ========================================================
        // RELEASE RESET
        // ========================================================

        @(posedge clk);

        rst_n = 1'b1;


        // ========================================================
        // TEST 1
        //
        // Address 10
        //
        // Mix positive and negative signed values
        // ========================================================

        test_weights[0] = -128;
        test_weights[1] = -100;
        test_weights[2] =  -64;
        test_weights[3] =  -1;
        test_weights[4] =   0;
        test_weights[5] =   1;
        test_weights[6] =  64;
        test_weights[7] = 127;

        for (i = 0; i < ARRAY_SIZE; i = i + 1)
            expected_weights[i] = test_weights[i];

        write_word(10);


        // ========================================================
        // TEST 2
        //
        // Address 25
        // ========================================================

        test_weights[0] =  12;
        test_weights[1] = -23;
        test_weights[2] =  45;
        test_weights[3] = -67;
        test_weights[4] =  89;
        test_weights[5] = -10;
        test_weights[6] =  31;
        test_weights[7] = -55;

        for (i = 0; i < ARRAY_SIZE; i = i + 1)
            expected_weights[i] = test_weights[i];

        write_word(25);


        // ========================================================
        // TEST 3
        //
        // Address 100
        // ========================================================

        test_weights[0] = -5;
        test_weights[1] = -10;
        test_weights[2] = -15;
        test_weights[3] = -20;
        test_weights[4] = 20;
        test_weights[5] = 15;
        test_weights[6] = 10;
        test_weights[7] = 5;

        for (i = 0; i < ARRAY_SIZE; i = i + 1)
            expected_weights[i] = test_weights[i];

        write_word(100);


        // ========================================================
        // READ ADDRESS 10
        // ========================================================

        test_weights[0] = -128;
        test_weights[1] = -100;
        test_weights[2] =  -64;
        test_weights[3] =  -1;
        test_weights[4] =   0;
        test_weights[5] =   1;
        test_weights[6] =  64;
        test_weights[7] = 127;

        for (i = 0; i < ARRAY_SIZE; i = i + 1)
            expected_weights[i] = test_weights[i];

        read_word(10);


        // ========================================================
        // READ ADDRESS 25
        // ========================================================

        test_weights[0] =  12;
        test_weights[1] = -23;
        test_weights[2] =  45;
        test_weights[3] = -67;
        test_weights[4] =  89;
        test_weights[5] = -10;
        test_weights[6] =  31;
        test_weights[7] = -55;

        for (i = 0; i < ARRAY_SIZE; i = i + 1)
            expected_weights[i] = test_weights[i];

        read_word(25);


        // ========================================================
        // READ ADDRESS 100
        // ========================================================

        test_weights[0] = -5;
        test_weights[1] = -10;
        test_weights[2] = -15;
        test_weights[3] = -20;
        test_weights[4] = 20;
        test_weights[5] = 15;
        test_weights[6] = 10;
        test_weights[7] = 5;

        for (i = 0; i < ARRAY_SIZE; i = i + 1)
            expected_weights[i] = test_weights[i];

        read_word(100);


        // ========================================================
        // TEST READ ENABLE
        //
        // dout_B should retain previous value when ena_B = 0
        // ========================================================

        $display("");
        $display("======================================");
        $display("       READ ENABLE TEST");
        $display("======================================");

        @(negedge clk);

        addr_B = 10;
        ena_B  = 1'b0;

        @(posedge clk);

        #1;

        if (dout_B !== dut.dout_B) begin
            $display("Read enable test: FAIL");
            errors = errors + 1;
        end
        else begin
            $display("Read enable test: PASS");
        end


        // ========================================================
        // FINAL RESULT
        // ========================================================

        #10;

        $display("");
        $display("======================================");

        if (errors == 0) begin

            $display("       WEIGHT BUFFER : PASS");
            $display("");
            $display("All weight read/write tests passed.");

        end
        else begin

            $display("       WEIGHT BUFFER : FAIL");
            $display("");
            $display("Total errors = %0d", errors);

        end

        $display("======================================");
        $display("");

        $finish;

    end


    // ============================================================
    // VCD
    // ============================================================

    initial begin
        $dumpfile("weight_buffer.vcd");
        $dumpvars(0, tb_weight_buffer);
    end

endmodule