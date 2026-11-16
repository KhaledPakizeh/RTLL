// Synchronous FIFO: UVM testbench.
// Compile order:  fifo_pkg.sv  ->  design.sv  ->  this file.
// EDA Playground: pick a UVM-capable simulator, tick "UVM / OVM" = UVM 1.2.
//
// ============================== HOW EVERYTHING CONNECTS ==============================
//
//   fifo_test                      (creates env, starts the sequence)
//     |
//     +-- fifo_env                 (creates agent + scoreboard, wires them)
//           |
//           +-- fifo_agent         (creates sequencer, driver, monitor, wires driver<->sequencer)
//           |     |
//           |     +-- sqr (sequencer) <----- fifo_seq.start(sqr)  [test starts the sequence on it]
//           |     |        ^
//           |     |        | seq_item_port.connect(seq_item_export)   (agent.connect_phase)
//           |     +-- drv (driver) --- drives ---> vif ---> DUT pins
//           |     +-- mon (monitor) <-- samples -- vif <--- DUT pins
//           |              |
//           |              | ap.write(item)  (analysis port)
//           |              v
//           +-- scb (scoreboard)   mon.ap.connect(scb.imp)   (env.connect_phase)
//
//   Top module: creates the clock/reset, the interface "vif" and the DUT, then hands vif to
//   the driver and monitor through uvm_config_db (set in top, get in driver and monitor).
//
//   Data flow for one transaction:
//     sequence randomizes an item -> sequencer -> driver drives the pins for 1 clock
//     -> DUT reacts -> monitor samples the pins every clock -> scoreboard compares with its model
// ======================================================================================

`timescale 1ns/1ps
`include "uvm_macros.svh"      // the `uvm_* macros (utils, info, error, fatal)
import uvm_pkg::*;             // UVM base classes
import fifo_pkg::*;            // DATA_WIDTH, ADDRESS_WIDTH, DEPTH, data_t


// ============================ Interface ============================
// Bundle of wires between the testbench classes and the DUT. Classes cannot touch module
// ports directly, so they reach the pins through a "virtual interface" handle (vif).
interface fifo_if (input logic clk);        // clk comes from the top module
    logic  rst;                             // driven by the top module (reset sequence)
    logic  read_enable, write_enable;       // driven by the driver, read by DUT + monitor
    data_t d_in;                            // driven by the driver
    data_t d_out;                           // driven by the DUT, read by the monitor
    logic  full, empty;                     // driven by the DUT, read by the monitor
endinterface


// ============================ Sequence item ============================
// One transaction = what happens in ONE clock cycle (idle, read, write or both).
class fifo_item extends uvm_sequence_item;

    // Names for the 2-bit {write_enable, read_enable} combinations (used in the constraint).
    localparam bit [1:0] OP_IDLE  = 2'b00;
    localparam bit [1:0] OP_READ  = 2'b01;
    localparam bit [1:0] OP_WRITE = 2'b10;
    localparam bit [1:0] OP_BOTH  = 2'b11;

    // Stimulus fields: randomized by the sequence, driven by the driver.
    rand data_t d_in;
    rand bit    read_enable, write_enable;

    // Observed fields: filled in by the MONITOR (not rand, they are DUT outputs).
    data_t d_out;
    bit    full, empty;

    // Weighted mix of operations. More writes than reads so the FIFO reaches full;
    // some idle cycles are allowed (weight 10).
    constraint enable_mix {
        {write_enable, read_enable} dist {
            OP_BOTH  := 20,
            OP_WRITE := 50,
            OP_READ  := 20,
            OP_IDLE  := 10
        };
    }

    `uvm_object_utils(fifo_item)            // registers the class with the UVM factory
    function new(string name = "fifo_item");
        super.new(name);
    endfunction
endclass


// ============================ Sequence ============================
// A sequence generates items. The test decides when to start it and on which sequencer.
class fifo_seq extends uvm_sequence #(fifo_item);
    `uvm_object_utils(fifo_seq)

    int num_items = 500;                    // the test can change this before start()

    function new(string name = "fifo_seq");
        super.new(name);
    endfunction

    task body();
        fifo_item item;

        repeat (num_items) begin
            item = fifo_item::type_id::create("item");   // 1. create through the factory
            start_item(item);                            // 2. ask the sequencer for a slot
            if (!item.randomize())                       // 3. fill in random values
                `uvm_error("SEQ", "randomize failed")
            finish_item(item);                           // 4. hand to the driver; wait until driven
        end

        // Final idle item: the driver keeps driving the LAST item's values until a new item
        // arrives, so without this the FIFO would keep reading/writing after the test.
        item = fifo_item::type_id::create("idle_item");
        start_item(item);
        if (!item.randomize() with { read_enable == 0; write_enable == 0; })
            `uvm_error("SEQ", "randomize (idle) failed")
        finish_item(item);
    endtask
endclass


// ============================ Driver ============================
// Takes items from the sequencer and wiggles the DUT pins through the vif.
class fifo_driver extends uvm_driver #(fifo_item);
    `uvm_component_utils(fifo_driver)       // components use _component_utils

    virtual fifo_if vif;                    // handle to the real interface (set in top)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Fetch the vif that the top module stored with uvm_config_db::set (same key "vif").
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("DRV", "no vif found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        // Safe values before any item arrives.
        vif.read_enable  <= 0;
        vif.write_enable <= 0;
        vif.d_in         <= '0;

        // Wait for reset to be asserted and then released before driving traffic.
        wait (vif.rst === 1'b1);
        wait (vif.rst === 1'b0);

        forever begin
            seq_item_port.get_next_item(req);   // blocks until the sequence has an item (req)
            @(posedge vif.clk);                 // 1 item = 1 clock cycle
            vif.d_in         <= req.d_in;       // nonblocking: no race with the DUT
            vif.read_enable  <= req.read_enable;
            vif.write_enable <= req.write_enable;
            seq_item_port.item_done();          // tell the sequencer this item is finished
        end
    endtask
endclass


// ============================ Monitor ============================
// Passively watches the pins every clock and broadcasts what it sees.
class fifo_monitor extends uvm_monitor;
    `uvm_component_utils(fifo_monitor)

    virtual fifo_if vif;
    uvm_analysis_port #(fifo_item) ap;      // broadcast channel to the scoreboard

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);               // ports are created with new, not the factory
        if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
            `uvm_fatal("MON", "no vif found in config_db")
    endfunction

    task run_phase(uvm_phase phase);
        fifo_item item;
        forever begin
            @(posedge vif.clk);             // samples values from just BEFORE this edge
            if (vif.rst) continue;          // ignore cycles during reset
            item = fifo_item::type_id::create("item");   // a new item every cycle
            item.d_in         = vif.d_in;
            item.read_enable  = vif.read_enable;
            item.write_enable = vif.write_enable;
            item.d_out        = vif.d_out;
            item.full         = vif.full;
            item.empty        = vif.empty;
            ap.write(item);                 // sends a copy to everything connected
        end
    endtask
endclass


// ============================ Scoreboard ============================
// Reference model (a queue) + checks. write() is called by the monitor's analysis port.
class fifo_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fifo_scoreboard)

    uvm_analysis_imp #(fifo_item, fifo_scoreboard) imp;   // receiving end of the monitor's port

    data_t data_queue[$];                   // what the FIFO should be holding
    data_t data_expected;                   // value the last accepted read should return
    bit    check_pending;                   // 1 = compare d_out on the NEXT cycle (registered read)
    int    errors, checks;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        imp = new("imp", this);
    endfunction

    // Called once per clock cycle with the item the monitor built.
    function void write(fifo_item item);
        int size_before;

        // 1. Compare data from the read accepted on the previous cycle.
        if (check_pending) begin
            checks++;
            if (item.d_out !== data_expected) begin
                errors++;
                `uvm_error("SCB", $sformatf("d_out=%0h expected %0h", item.d_out, data_expected))
            end
        end
        check_pending = 0;

        // 2. Check the flags against the model (state before this cycle's update).
        size_before = data_queue.size();
        checks++;
        if (item.full !== (size_before == DEPTH)) begin
            errors++;
            `uvm_error("SCB", $sformatf("full=%b, model size=%0d", item.full, size_before))
        end
        if (item.empty !== (size_before == 0)) begin
            errors++;
            `uvm_error("SCB", $sformatf("empty=%b, model size=%0d", item.empty, size_before))
        end

        // 3. Update the model. Both decisions use size_before, like the DUT's full/empty gating:
        //    read when empty is ignored, write when full is ignored.
        if (item.read_enable && size_before > 0) begin
            data_expected = data_queue.pop_front();
            check_pending = 1;
        end
        if (item.write_enable && size_before < DEPTH)
            data_queue.push_back(item.d_in);
    endfunction

    // Runs at the end of the simulation: print the verdict.
    function void report_phase(uvm_phase phase);
        if (errors == 0) `uvm_info("SCB", $sformatf("PASS: %0d checks, 0 errors", checks), UVM_LOW)
        else             `uvm_error("SCB", $sformatf("FAIL: %0d errors in %0d checks", errors, checks))
    endfunction
endclass


// ============================ Coverage ============================
// Functional coverage: answers "did the stimulus reach the interesting situations?".
// A uvm_subscriber is a component with a built-in analysis export, so it hooks to the
// monitor's port exactly like the scoreboard does (see fifo_env.connect_phase).
class fifo_coverage extends uvm_subscriber #(fifo_item);
    `uvm_component_utils(fifo_coverage)

    fifo_item item;                         // the covergroup samples the fields of this handle

    // Wraparound tracking: count ACCEPTED operations (the DUT ignores read-when-empty and
    // write-when-full) and flag the cycle in which a pointer rolls over from DEPTH-1 to 0.
    int unsigned wr_count, rd_count;
    bit          wr_wrap, rd_wrap;
    bit [1:0]    state;                     // 0 = empty, 1 = in between, 2 = full

    covergroup cg;
        option.per_instance = 1;

        // What the testbench asked for in this cycle.
        cp_op: coverpoint {item.write_enable, item.read_enable} {
            bins idle  = {2'b00};
            bins read  = {2'b01};
            bins write = {2'b10};
            bins both  = {2'b11};
        }

        // Where the FIFO is (from the DUT flags).
        cp_state: coverpoint state {
            bins empty = {0};
            bins mid   = {1};
            bins full  = {2};
        }

        // Every operation in every state, including read-when-empty and write-when-full.
        x_op_state: cross cp_op, cp_state;

        // Write pointer / read pointer rolled over at least once.
        cp_wr_wrap: coverpoint wr_wrap { bins wrapped = {1}; }
        cp_rd_wrap: coverpoint rd_wrap { bins wrapped = {1}; }

        // Data values written (corners and ranges).
        cp_wdata: coverpoint item.d_in iff (item.write_enable) {
            bins zero = {0};
            bins low  = {[1 : 'h7F]};
            bins high = {['h80 : 'hFE]};
            bins max  = {'hFF};
        }
    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg = new();                         // a covergroup inside a class is built in the constructor
    endfunction

    // Called once per clock cycle by the monitor (through the analysis export).
    function void write(fifo_item t);
        item = t;
        state = t.full ? 2 : (t.empty ? 0 : 1);

        wr_wrap = 0;
        rd_wrap = 0;
        if (t.write_enable && !t.full) begin
            wr_wrap = (wr_count % DEPTH) == DEPTH - 1;   // this write lands on the last slot
            wr_count++;
        end
        if (t.read_enable && !t.empty) begin
            rd_wrap = (rd_count % DEPTH) == DEPTH - 1;
            rd_count++;
        end

        cg.sample();
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("COV", $sformatf("functional coverage = %0.2f%%", cg.get_inst_coverage()), UVM_LOW)
    endfunction
endclass


// ============================ Agent ============================
// Groups the driver, monitor and sequencer for one interface.
class fifo_agent extends uvm_agent;
    `uvm_component_utils(fifo_agent)

    uvm_sequencer #(fifo_item) sqr;         // standard sequencer, no custom class needed
    fifo_driver                drv;
    fifo_monitor               mon;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Components are always created with the factory (type_id::create), "this" = parent.
        sqr = uvm_sequencer#(fifo_item)::type_id::create("sqr", this);
        drv = fifo_driver::type_id::create("drv", this);
        mon = fifo_monitor::type_id::create("mon", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        // Items flow sequence -> sequencer -> driver through this port/export pair.
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass


// ============================ Env ============================
// Holds everything needed to test the DUT: the agent and the scoreboard.
class fifo_env extends uvm_env;
    `uvm_component_utils(fifo_env)

    fifo_agent      agent;
    fifo_scoreboard scb;
    fifo_coverage   cov;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = fifo_agent::type_id::create("agent", this);
        scb   = fifo_scoreboard::type_id::create("scb", this);
        cov   = fifo_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        // Monitor broadcasts -> scoreboard receives (port "ap" to export "imp").
        agent.mon.ap.connect(scb.imp);
        // The same port also feeds coverage: one sender, several listeners.
        agent.mon.ap.connect(cov.analysis_export);
    endfunction
endclass


// ============================ Test ============================
// Top of the UVM hierarchy: builds the env and decides which sequence(s) to run.
class fifo_test extends uvm_test;
    `uvm_component_utils(fifo_test)

    fifo_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fifo_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_seq seq = fifo_seq::type_id::create("seq");

        phase.raise_objection(this);        // "I am still running": keeps the simulation alive
        seq.start(env.agent.sqr);           // runs seq.body() on the agent's sequencer
        #200;                               // drain: let the last items reach monitor and scoreboard
        phase.drop_objection(this);         // "I am done": UVM ends the run phase
    endtask
endclass


// ============================ Top ============================
// The only module: clock, reset, interface, DUT, and the hand-off to UVM.
module fifo_tb_top;

    logic clk = 0;
    always #5 clk = ~clk;                   // 10 ns period

    fifo_if vif (clk);                      // the interface instance (gets the clock)

    // DUT: parameters come from fifo_pkg so the model and the DUT agree on DEPTH.
    // Every port is wired to a wire inside the interface.
    fifo #(.DATA_WIDTH(DATA_WIDTH), .ADDRESS_WIDTH(ADDRESS_WIDTH)) dut (
        .clk          (clk),
        .rst          (vif.rst),
        .read_enable  (vif.read_enable),
        .write_enable (vif.write_enable),
        .d_in         (vif.d_in),
        .d_out        (vif.d_out),
        .full         (vif.full),
        .empty        (vif.empty)
    );

    // Reset: high for 3 clock edges, then released. The driver waits for this to finish.
    initial begin
        vif.rst = 1;
        repeat (3) @(posedge clk);
        vif.rst <= 0;
    end

    initial begin
        // Hand the interface to the UVM world. Key "vif" must match the driver/monitor get().
        uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", vif);
        run_test("fifo_test");              // creates fifo_test and runs the UVM phases
    end

    // Waveform dump (optional, for EDA Playground / viewers).
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, fifo_tb_top);
    end
endmodule
