# RTL Verification Prep: working rules

Goal: prepare for a NAND RTL verification role by designing, verifying, synthesizing and timing real
blocks, hands-on. Kalil writes the RTL. Claude provides templates, reviews, and explains. Phases:
1 sync FIFO (`01_sync_fifo/`), 2 MIPS pipeline (on hold), 3 resume tools, 4 VLSI topics.

## Roles
- Kalil writes the RTL and the test bodies. Claude does NOT hand over finished RTL. Claude gives
  templates (ports, parameters, TODOs), hints, and review comments.
- Templates are minimal: an empty module shell and TODO comments only. Do NOT list parameters, ports,
  signals or widths in a template. Kalil decides them in the spec and diagram. Once he has written the
  ports, Claude adapts the testbench scaffolding to match.
- Testbench scaffolding (clock, reset, scoreboard, monitor) is provided by Claude. Kalil writes the tests.
- Keep explanations short. Ask Kalil to explain a step back before moving on.
- Do not point Kalil at the reference FIFO in `sv-tutorial/testbenches/*/fifo.sv` until his own version
  passes. Compare against it afterwards.

## The loop for every design (do the steps in order; do not skip ahead)
1. **Spec**: fill in `spec.md` (ports, parameters, behavior, corner cases, open decisions).
2. **Diagram**: draw the block diagram into `diagram/` BEFORE any code. Claude reads the image, checks
   it against the spec, asks questions. Code starts only after the diagram is agreed.
3. **RTL**: Kalil fills in `rtl/design.sv` from the template. Claude reviews: lint-style issues, latches,
   reset, blocking vs nonblocking, width mismatches. No simulation yet.
4. **Verification plan**: fill in `verification_plan.md` (features, checks, stimulus, coverage) before
   writing tests.
5. **Testbench**: fill in tests in `tb/testbench.sv`. Directed first, then constrained-random with the
   scoreboard.
6. **Simulate**: EDA Playground first (quick, VCS or Questa), then local (`sim/run.do`) if needed.
   Look at waveforms, not just PASS/FAIL. Record bugs found in `progress.md`.
7. **Assertions + coverage**: add SVA and functional coverage; check coverage holes against the plan.
8. **UVM** (when the plain testbench is solid): rebuild the same checks as a UVM env.
9. **Synthesize**: Quartus (`synth/quartus.tcl`). Open the RTL Viewer and compare it with the hand
   diagram. Read the warnings (inferred latches, RAM vs registers, unused logic).
10. **Timing**: add `synth/fifo.sdc`, read the critical path, setup slack, Fmax, area. Try one
    optimization and compare before/after numbers. Note the numbers in `progress.md`.
11. **Interview recap**: Kalil explains the design out loud: diagram, one bug found, one timing number,
    one trade-off. Claude asks 3 follow-up questions.

## Session habits
- Start by reading `progress.md` and resume at the first unchecked step.
- End by updating `progress.md` (what is done, bugs found, numbers, next step).
- Never mark a step done until the artifact exists in the folder (diagram image, passing log, report).

## Tools
- EDA Playground: paste `rtl/design.sv` as design and `tb/testbench.sv` as testbench. Pick a SystemVerilog
  simulator (Synopsys VCS or Aldec/Questa). Tick "Open EPWave after run".
- Local: ModelSim/Questa from Intel FPGA is installed (`vsim` is on PATH). UVM and coverage need
  Questa FSE; ASE may not support them.
- Quartus Prime (Intel FPGA install) for synthesis, RTL Viewer, TimeQuest.
