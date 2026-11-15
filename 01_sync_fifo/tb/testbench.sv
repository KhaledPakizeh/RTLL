// Synchronous FIFO: testbench template. Clock, reset, driver helpers, monitor and scoreboard are done.
// Fill in the tests (marked TODO). For EDA Playground this file goes in the "testbench" pane.
//
// Conventions (avoid races):
//  - Drive DUT inputs only with nonblocking assignments right after @(posedge clk).
//  - The monitor samples at posedge, so it sees the values from just before the edge.
//  - Scoreboard assumes: registered read, rd_data valid the cycle AFTER an accepted read (see ../spec.md).

`timescale 1ns/1ps

module fifo_tb;

    localparam int WIDTH = 8;
    localparam int DEPTH = 16;
    localparam int CW    = $clog2(DEPTH) + 1;

    logic             clk = 0;
    logic             rst;
    logic             wr_en, rd_en;
    logic [WIDTH-1:0] wr_data, rd_data;
    logic             full, empty;
    logic [CW-1:0]    count;

    fifo #(.WIDTH(WIDTH), .DEPTH(DEPTH)) dut (.*);

    always #5 clk = ~clk;

    int errors = 0;
    int checks = 0;

    // ---------------- Scoreboard / reference model ----------------
    logic [WIDTH-1:0] model_q[$];
    logic [WIDTH-1:0] exp_data;
    bit               exp_valid = 0;

    always @(posedge clk) begin
        if (rst) begin
            model_q.delete();
            exp_valid <= 0;
        end else begin
            // 1. Check data of the read accepted on the previous edge.
            if (exp_valid) begin
                checks++;
                if (rd_data !== exp_data) begin
                    errors++;
                    $error("[%0t] rd_data=%0h expected %0h", $time, rd_data, exp_data);
                end
            end
            exp_valid <= 0;

            // 2. Check flags and count against the model (state before this edge's update).
            checks++;
            if (full  !== (model_q.size() == DEPTH)) begin errors++; $error("[%0t] full=%b, model size=%0d",  $time, full,  model_q.size()); end
            if (empty !== (model_q.size() == 0))     begin errors++; $error("[%0t] empty=%b, model size=%0d", $time, empty, model_q.size()); end
            if (count !== model_q.size())            begin errors++; $error("[%0t] count=%0d, model size=%0d", $time, count, model_q.size()); end

            // 3. Apply this edge's accepted operations to the model.
            //    A read of the head happens before a same-cycle write is stored.
            if (rd_en && model_q.size() > 0) begin
                exp_data  <= model_q.pop_front();
                exp_valid <= 1;
            end
            if (wr_en && model_q.size() < DEPTH)
                model_q.push_back(wr_data);
            // TODO (spec question): read+write when full. Does your design accept the write? Adjust the
            // model to match the spec you wrote, not the other way round.
        end
    end

    // ---------------- Driver helpers ----------------
    task automatic do_reset(int cycles = 3);
        rst <= 1; wr_en <= 0; rd_en <= 0; wr_data <= '0;
        repeat (cycles) @(posedge clk);
        rst <= 0;
        @(posedge clk);
    endtask

    task automatic push(input logic [WIDTH-1:0] d);
        wr_en <= 1; wr_data <= d;
        @(posedge clk);
        wr_en <= 0;
    endtask

    task automatic pop();
        rd_en <= 1;
        @(posedge clk);
        rd_en <= 0;
    endtask

    task automatic idle(int n = 1);
        repeat (n) @(posedge clk);
    endtask

    // ---------------- Tests ----------------
    task automatic test_reset();
        // TODO: after reset: empty=1, full=0, count=0.
    endtask

    task automatic test_fill_drain();
        // TODO: push DEPTH items, check full, try one more write, then pop everything, check empty.
    endtask

    task automatic test_simultaneous();
        // TODO: read+write in the same cycle: empty, in the middle, and full.
    endtask

    task automatic test_wraparound();
        // TODO: push/pop more than DEPTH items total so both pointers wrap.
    endtask

    task automatic test_random(int n_cycles = 2000);
        // TODO: each cycle randomize wr_en, rd_en, wr_data. Try different write/read probabilities
        //       (mostly writes, mostly reads, balanced) so the FIFO hits both full and empty.
        // Hint: $urandom_range(0,99) < p_write
    endtask

    // ---------------- Main ----------------
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, fifo_tb);

        do_reset();
        test_reset();
        test_fill_drain();
        test_simultaneous();
        test_wraparound();
        test_random();

        idle(5);
        if (errors == 0) $display("PASS: %0d checks, 0 errors", checks);
        else             $display("FAIL: %0d errors in %0d checks", errors, checks);
        $finish;
    end

    // Safety net: never hang the simulator.
    initial begin
        #1_000_000;
        $error("Timeout");
        $finish;
    end

endmodule
