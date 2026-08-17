`timescale 1ns / 1ps

module tb_ifm_buffer;

    parameter DATA_WIDTH = 8;
    parameter ARRAY_SIZE = 8;
    parameter ADDR_WIDTH = 3;

    localparam WORD_WIDTH = DATA_WIDTH * ARRAY_SIZE;
    localparam DEPTH      = (1 << ADDR_WIDTH);

    reg clk;
    reg rst_n;

    reg wr_en;
    reg [ADDR_WIDTH-1:0] wr_addr;
    reg [WORD_WIDTH-1:0] wr_data;
    wire wr_ready;
    reg wr_done;

    reg rd_en;
    reg [ADDR_WIDTH-1:0] rd_addr;
    wire signed [WORD_WIDTH-1:0] rd_data;
    wire rd_valid;
    reg rd_done;


    // ============================================================
    // DUT
    // ============================================================

    ifm_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .ARRAY_SIZE(ARRAY_SIZE),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk      (clk),
        .rst_n    (rst_n),

        .wr_en    (wr_en),
        .wr_addr  (wr_addr),
        .wr_data  (wr_data),
        .wr_ready (wr_ready),
        .wr_done  (wr_done),

        .rd_en    (rd_en),
        .rd_addr  (rd_addr),
        .rd_data  (rd_data),
        .rd_valid (rd_valid),
        .rd_done  (rd_done)
    );


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // TEST VARIABLES
    // ============================================================

    integer errors;
    integer i;

    reg [WORD_WIDTH-1:0] expected_data;
    reg [WORD_WIDTH-1:0] read_data;


    // ============================================================
    // CREATE TEST WORD
    // ============================================================

    task make_word;

        input integer base;

        begin
            expected_data = 0;

            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                expected_data[(i*DATA_WIDTH) +: DATA_WIDTH]
                    = base + i;
            end
        end

    endtask


    // ============================================================
    // WRITE ONE WORD
    // ============================================================

    task write_word;

        input integer address;
        input integer base;

        begin

            make_word(base);

            @(negedge clk);

            wr_addr = address;
            wr_data = expected_data;
            wr_en   = 1'b1;

            if (!wr_ready) begin
                $display(
                    "ERROR: wr_ready LOW before write. Address=%0d",
                    address
                );
                errors = errors + 1;
            end

            @(posedge clk);

            #1;

            wr_en = 1'b0;

            $display(
                "WRITE: addr=%0d data_base=%0d",
                address,
                base
            );

        end

    endtask


    // ============================================================
    // FINISH WRITE BUFFER
    // ============================================================

    task finish_write;

        begin

            @(negedge clk);

            wr_done = 1'b1;

            @(posedge clk);

            #1;

            wr_done = 1'b0;

            $display(
                "WR_DONE: wr_ready=%b rd_valid=%b",
                wr_ready,
                rd_valid
            );

        end

    endtask


    // ============================================================
    // READ ONE WORD
    // ============================================================

    task read_word;

        input integer address;
        input integer base;

        reg [WORD_WIDTH-1:0] expected;

        begin

            expected = 0;

            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                expected[(i*DATA_WIDTH) +: DATA_WIDTH]
                    = base + i;
            end

            @(negedge clk);

            rd_addr = address;
            rd_en   = 1'b1;

            if (!rd_valid) begin
                $display(
                    "ERROR: rd_valid LOW before read. Address=%0d",
                    address
                );
                errors = errors + 1;
            end

            @(posedge clk);

            #1;

            rd_en = 1'b0;

            read_data = rd_data;

            $display(
                "READ: addr=%0d data_base=%0d",
                address,
                base
            );

            if (read_data !== expected) begin

                $display("      FAIL");

                for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                    $display(
                        "      Weight[%0d]: expected=%0d got=%0d",
                        i,
                        $signed(
                            expected[(i*DATA_WIDTH) +: DATA_WIDTH]
                        ),
                        $signed(
                            read_data[(i*DATA_WIDTH) +: DATA_WIDTH]
                        )
                    );
                end

                errors = errors + 1;

            end
            else begin

                $display("      PASS");

            end

        end

    endtask


    // ============================================================
    // FINISH READ
    // ============================================================

    task finish_read;

        begin

            @(negedge clk);

            rd_done = 1'b1;

            @(posedge clk);

            #1;

            rd_done = 1'b0;

            $display(
                "RD_DONE: wr_ready=%b rd_valid=%b",
                wr_ready,
                rd_valid
            );

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        errors = 0;

        rst_n = 1'b0;

        wr_en   = 1'b0;
        wr_addr = 0;
        wr_data = 0;
        wr_done = 1'b0;

        rd_en   = 1'b0;
        rd_addr = 0;
        rd_done = 1'b0;


        // ========================================================
        // HEADER
        // ========================================================

        $display("");
        $display("==============================================");
        $display("        IFM PING-PONG BUFFER TEST");
        $display("==============================================");
        $display("");

        $display("DATA_WIDTH = %0d", DATA_WIDTH);
        $display("ARRAY_SIZE = %0d", ARRAY_SIZE);
        $display("WORD_WIDTH = %0d", WORD_WIDTH);
        $display("DEPTH      = %0d", DEPTH);
        $display("");


        // ========================================================
        // RESET
        // ========================================================

        repeat (3) @(posedge clk);

        rst_n = 1'b1;

        @(posedge clk);

        #1;

        $display("RESET RELEASED");
        $display("wr_ready = %b", wr_ready);
        $display("rd_valid = %b", rd_valid);
        $display("");


        // ========================================================
        // TEST 1
        // INITIAL WRITE
        // ========================================================

        $display("----------------------------------------------");
        $display("TEST 1: WRITE FIRST BUFFER");
        $display("----------------------------------------------");

        write_word(0, 10);
        write_word(1, 20);
        write_word(2, 30);


        // ========================================================
        // TEST 2
        // WR_DONE WITHOUT RD_DONE
        //
        // This is the critical ping-pong test.
        // A correct implementation should switch to buffer 2.
        // ========================================================

        $display("");
        $display("----------------------------------------------");
        $display("TEST 2: WR_DONE WITHOUT RD_DONE");
        $display("----------------------------------------------");

        finish_write;


        if (!wr_ready) begin
            $display("");
            $display("FAIL: wr_ready is LOW after wr_done.");
            $display("");
            $display("The write side has not switched to the");
            $display("other ping-pong buffer.");
            $display("");
            $display("This indicates a control FSM deadlock.");
            $display("");

            errors = errors + 1;
        end
        else begin
            $display("PASS: Write side switched buffers.");
        end


        if (!rd_valid) begin
            $display("");
            $display("FAIL: rd_valid is LOW after wr_done.");
            $display("");
            $display("The completed buffer should now be available");
            $display("for reading.");
            $display("");

            errors = errors + 1;
        end
        else begin
            $display("PASS: Completed buffer is available for reading.");
        end


        // ========================================================
        // TEST 3
        // TRY TO READ FIRST BUFFER
        // ========================================================

        $display("");
        $display("----------------------------------------------");
        $display("TEST 3: READ COMPLETED BUFFER");
        $display("----------------------------------------------");

        if (rd_valid) begin
            read_word(0, 10);
            read_word(1, 20);
            read_word(2, 30);
        end
        else begin
            $display("SKIPPED because rd_valid is LOW.");
        end


        // ========================================================
        // TEST 4
        // COMPLETE READ
        // ========================================================

        $display("");
        $display("----------------------------------------------");
        $display("TEST 4: RD_DONE WITHOUT WR_DONE");
        $display("----------------------------------------------");

        finish_read;


        if (wr_ready) begin
            $display("PASS: Write buffer available.");
        end
        else begin
            $display(
                "FAIL: wr_ready remains LOW after rd_done."
            );
            errors = errors + 1;
        end


        // ========================================================
        // TEST 5
        // SECOND BUFFER
        // ========================================================

        $display("");
        $display("----------------------------------------------");
        $display("TEST 5: WRITE SECOND BUFFER");
        $display("----------------------------------------------");

        if (wr_ready) begin

            write_word(0, 100);
            write_word(1, 110);
            write_word(2, 120);

            finish_write;

        end
        else begin
            $display("SKIPPED because wr_ready is LOW.");
        end


        // ========================================================
        // TEST 6
        // READ SECOND BUFFER
        // ========================================================

        $display("");
        $display("----------------------------------------------");
        $display("TEST 6: READ SECOND BUFFER");
        $display("----------------------------------------------");

        if (rd_valid) begin

            read_word(0, 100);
            read_word(1, 110);
            read_word(2, 120);

            finish_read;

        end
        else begin
            $display("SKIPPED because rd_valid is LOW.");
        end


        // ========================================================
        // TEST 7
        // SIMULTANEOUS DONE
        // ========================================================

        $display("");
        $display("----------------------------------------------");
        $display("TEST 7: SIMULTANEOUS WR_DONE + RD_DONE");
        $display("----------------------------------------------");

        @(negedge clk);

        wr_done = 1'b1;
        rd_done = 1'b1;

        @(posedge clk);

        #1;

        wr_done = 1'b0;
        rd_done = 1'b0;

        $display(
            "After simultaneous DONE: wr_ready=%b rd_valid=%b",
            wr_ready,
            rd_valid
        );


        // ========================================================
        // FINAL RESULT
        // ========================================================

        repeat (3) @(posedge clk);

        $display("");
        $display("==============================================");

        if (errors == 0) begin

            $display("       IFM BUFFER : PASS");
            $display("");
            $display("All ping-pong buffer tests passed.");

        end
        else begin

            $display("       IFM BUFFER : FAIL");
            $display("");
            $display(
                "Total errors detected = %0d",
                errors
            );

        end

        $display("==============================================");
        $display("");

        $finish;

    end


    // ============================================================
    // VCD
    // ============================================================

    initial begin
        $dumpfile("ifm_buffer.vcd");
        $dumpvars(0, tb_ifm_buffer);
    end

endmodule