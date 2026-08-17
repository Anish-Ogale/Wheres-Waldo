`timescale 1ns / 1ps

module tb_ofm_buffer;

    parameter DATA_WIDTH = 8;
    parameter ARRAY_SIZE = 8;
    parameter ADDR_WIDTH = 3;

    localparam WORD_WIDTH = DATA_WIDTH * ARRAY_SIZE;
    localparam DEPTH = (1 << ADDR_WIDTH);

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

    integer errors;
    integer i;
    integer cycle_count;

    reg [WORD_WIDTH-1:0] expected_data;
    reg [WORD_WIDTH-1:0] received_data;

    reg [WORD_WIDTH-1:0] memory_model [0:DEPTH-1];
    reg memory_valid [0:DEPTH-1];


    ofm_buffer #(
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


    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    task create_word;

        input integer base;

        begin
            expected_data = {WORD_WIDTH{1'b0}};

            for (i = 0; i < ARRAY_SIZE; i = i + 1) begin
                expected_data[(i*DATA_WIDTH) +: DATA_WIDTH] =
                    base + i;
            end
        end

    endtask


    task create_signed_word;

        begin
            expected_data = {WORD_WIDTH{1'b0}};

            expected_data[0*DATA_WIDTH +: DATA_WIDTH] = -128;
            expected_data[1*DATA_WIDTH +: DATA_WIDTH] = -100;
            expected_data[2*DATA_WIDTH +: DATA_WIDTH] = -64;
            expected_data[3*DATA_WIDTH +: DATA_WIDTH] = -1;
            expected_data[4*DATA_WIDTH +: DATA_WIDTH] = 0;
            expected_data[5*DATA_WIDTH +: DATA_WIDTH] = 1;
            expected_data[6*DATA_WIDTH +: DATA_WIDTH] = 64;
            expected_data[7*DATA_WIDTH +: DATA_WIDTH] = 127;
        end

    endtask


    task write_word;

        input integer address;
        input integer base;

        begin

            create_word(base);

            @(negedge clk);

            if (!wr_ready) begin
                $display(
                    "ERROR: wr_ready LOW before write. Address=%0d",
                    address
                );
                errors = errors + 1;
            end

            wr_addr = address;
            wr_data = expected_data;
            wr_en   = 1'b1;

            @(posedge clk);

            #1;

            wr_en = 1'b0;

            memory_model[address] = expected_data;
            memory_valid[address] = 1'b1;

            $display(
                "WRITE: address=%0d base=%0d PASS",
                address,
                base
            );

        end

    endtask


    task write_signed_word;

        input integer address;

        begin

            create_signed_word;

            @(negedge clk);

            if (!wr_ready) begin
                $display(
                    "ERROR: wr_ready LOW before signed write. Address=%0d",
                    address
                );
                errors = errors + 1;
            end

            wr_addr = address;
            wr_data = expected_data;
            wr_en   = 1'b1;

            @(posedge clk);

            #1;

            wr_en = 1'b0;

            memory_model[address] = expected_data;
            memory_valid[address] = 1'b1;

            $display(
                "SIGNED WRITE: address=%0d PASS",
                address
            );

        end

    endtask


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


    task read_word;

        input integer address;

        begin

            @(negedge clk);

            if (!rd_valid) begin
                $display(
                    "ERROR: rd_valid LOW before read. Address=%0d",
                    address
                );
                errors = errors + 1;
            end

            rd_addr = address;
            rd_en   = 1'b1;

            @(posedge clk);

            #1;

            rd_en = 1'b0;

            received_data = rd_data;

            if (received_data !== memory_model[address]) begin

                $display(
                    "READ: address=%0d FAIL",
                    address
                );

                for (i = 0; i < ARRAY_SIZE; i = i + 1) begin

                    $display(
                        "       Element[%0d]: expected=%0d got=%0d",
                        i,
                        $signed(
                            memory_model[address]
                            [(i*DATA_WIDTH) +: DATA_WIDTH]
                        ),
                        $signed(
                            received_data
                            [(i*DATA_WIDTH) +: DATA_WIDTH]
                        )
                    );

                end

                errors = errors + 1;

            end
            else begin

                $display(
                    "READ: address=%0d PASS",
                    address
                );

            end

        end

    endtask


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


    initial begin

        errors = 0;
        cycle_count = 0;

        rst_n = 1'b0;

        wr_en   = 1'b0;
        wr_addr = 0;
        wr_data = 0;
        wr_done = 1'b0;

        rd_en   = 1'b0;
        rd_addr = 0;
        rd_done = 1'b0;

        expected_data = 0;
        received_data = 0;

        for (i = 0; i < DEPTH; i = i + 1) begin
            memory_model[i] = 0;
            memory_valid[i] = 1'b0;
        end


        $display("");
        $display("==============================================");
        $display("          OFM PING-PONG BUFFER TEST");
        $display("==============================================");
        $display("");
        $display("DATA_WIDTH = %0d", DATA_WIDTH);
        $display("ARRAY_SIZE = %0d", ARRAY_SIZE);
        $display("WORD_WIDTH = %0d", WORD_WIDTH);
        $display("DEPTH      = %0d", DEPTH);
        $display("");


        repeat (3) @(posedge clk);

        rst_n = 1'b1;

        @(posedge clk);

        #1;

        $display("RESET RELEASED");
        $display("wr_ready = %b", wr_ready);
        $display("rd_valid = %b", rd_valid);
        $display("");


        if (wr_ready !== 1'b1) begin
            $display("FAIL: wr_ready should be 1 after reset.");
            errors = errors + 1;
        end

        if (rd_valid !== 1'b0) begin
            $display("FAIL: rd_valid should be 0 after reset.");
            errors = errors + 1;
        end


        $display("----------------------------------------------");
        $display("TEST 1: WRITE BUFFER 1");
        $display("----------------------------------------------");

        write_word(0, 10);
        write_word(1, 20);
        write_word(2, 30);
        write_word(3, 40);


        $display("");
        $display("----------------------------------------------");
        $display("TEST 2: COMPLETE BUFFER 1");
        $display("----------------------------------------------");

        finish_write;

        if (wr_ready !== 1'b1) begin
            $display("FAIL: write side did not switch to buffer 2.");
            errors = errors + 1;
        end
        else begin
            $display("PASS: write side switched to buffer 2.");
        end

        if (rd_valid !== 1'b1) begin
            $display("FAIL: buffer 1 is not available for reading.");
            errors = errors + 1;
        end
        else begin
            $display("PASS: buffer 1 available for reading.");
        end


        $display("");
        $display("----------------------------------------------");
        $display("TEST 3: READ BUFFER 1");
        $display("----------------------------------------------");

        read_word(0);
        read_word(1);
        read_word(2);
        read_word(3);


        $display("");
        $display("----------------------------------------------");
        $display("TEST 4: WRITE BUFFER 2 WHILE BUFFER 1 READ COMPLETE");
        $display("----------------------------------------------");

        write_word(0, 100);
        write_word(1, 110);
        write_word(2, 120);
        write_word(3, 130);


        $display("");
        $display("----------------------------------------------");
        $display("TEST 5: COMPLETE READ OF BUFFER 1");
        $display("----------------------------------------------");

        finish_read;


        if (wr_ready !== 1'b0) begin
            $display(
                "FAIL: expected current write buffer to remain full."
            );
        end
        else begin
            $display(
                "PASS: buffer ownership remains consistent."
            );
        end


        $display("");
        $display("----------------------------------------------");
        $display("TEST 6: COMPLETE BUFFER 2");
        $display("----------------------------------------------");

        finish_write;

        if (rd_valid !== 1'b1) begin
            $display("FAIL: buffer 2 is not available for reading.");
            errors = errors + 1;
        end
        else begin
            $display("PASS: buffer 2 available for reading.");
        end


        $display("");
        $display("----------------------------------------------");
        $display("TEST 7: READ BUFFER 2");
        $display("----------------------------------------------");

        read_word(0);
        read_word(1);
        read_word(2);
        read_word(3);


        $display("");
        $display("----------------------------------------------");
        $display("TEST 8: COMPLETE READ BUFFER 2");
        $display("----------------------------------------------");

        finish_read;

        if (wr_ready !== 1'b1) begin
            $display("FAIL: write side did not become available.");
            errors = errors + 1;
        end
        else begin
            $display("PASS: write side available again.");
        end


        $display("");
        $display("----------------------------------------------");
        $display("TEST 9: SIGNED DATA");
        $display("----------------------------------------------");

        write_signed_word(5);

        finish_write;

        if (rd_valid !== 1'b1) begin
            $display("FAIL: signed-data buffer not readable.");
            errors = errors + 1;
        end
        else begin
            read_word(5);
        end

        finish_read;


        $display("");
        $display("----------------------------------------------");
        $display("TEST 10: OVERWRITE OLD ADDRESS");
        $display("----------------------------------------------");

        write_word(0, 200);
        finish_write;

        if (rd_valid) begin
            read_word(0);
        end
        else begin
            $display("FAIL: overwritten buffer unavailable.");
            errors = errors + 1;
        end

        finish_read;


        $display("");
        $display("----------------------------------------------");
        $display("TEST 11: MULTIPLE PING-PONG CYCLES");
        $display("----------------------------------------------");


        write_word(1, 300);
        write_word(2, 310);
        write_word(3, 320);

        finish_write;

        if (rd_valid) begin
            read_word(1);
            read_word(2);
            read_word(3);
        end
        else begin
            $display("FAIL: cycle 1 read buffer unavailable.");
            errors = errors + 1;
        end

        finish_read;


        write_word(1, 400);
        write_word(2, 410);
        write_word(3, 420);

        finish_write;

        if (rd_valid) begin
            read_word(1);
            read_word(2);
            read_word(3);
        end
        else begin
            $display("FAIL: cycle 2 read buffer unavailable.");
            errors = errors + 1;
        end

        finish_read;


        write_word(1, 500);
        write_word(2, 510);
        write_word(3, 520);

        finish_write;

        if (rd_valid) begin
            read_word(1);
            read_word(2);
            read_word(3);
        end
        else begin
            $display("FAIL: cycle 3 read buffer unavailable.");
            errors = errors + 1;
        end

        finish_read;


        $display("");
        $display("----------------------------------------------");
        $display("TEST 12: SIMULTANEOUS WR_DONE + RD_DONE");
        $display("----------------------------------------------");

        @(negedge clk);

        wr_done = 1'b1;
        rd_done = 1'b1;

        @(posedge clk);

        #1;

        wr_done = 1'b0;
        rd_done = 1'b0;

        $display(
            "wr_ready=%b rd_valid=%b",
            wr_ready,
            rd_valid
        );


        repeat (3) @(posedge clk);


        $display("");
        $display("==============================================");

        if (errors == 0) begin

            $display("          OFM BUFFER : PASS");
            $display("");
            $display("All tests passed successfully.");

        end
        else begin

            $display("          OFM BUFFER : FAIL");
            $display("");
            $display(
                "Total errors = %0d",
                errors
            );

        end

        $display("==============================================");
        $display("");

        $finish;

    end


    initial begin
        $dumpfile("ofm_buffer.vcd");
        $dumpvars(0, tb_ofm_buffer);
    end

endmodule