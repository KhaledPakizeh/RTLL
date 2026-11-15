# Course material map (high level, from folder listing and READMEs only)

Not yet read in depth. Mapped to the prep phases. Update as we go through each item.

| Where | What it is | Phase |
|-------|-----------|-------|
| `sv-tutorial/combinational`, `sequential`, `fsm`, `fsmd`, `structural`, `gotchas` | SystemVerilog design tutorial: muxes, registers, FSMs, FSMD, common mistakes | 1 (RTL coding) |
| `sv-tutorial/testbenches/basic` | first testbenches, race conditions, reset races | 1 (testbench) |
| `sv-tutorial/testbenches/assertions` | SVA examples, including a FIFO with assertions | 1 (SVA). Reference FIFO: look only after yours passes |
| `sv-tutorial/testbenches/coverage` | functional coverage examples, including a FIFO | 1 (coverage) |
| `sv-tutorial/testbenches/crv` | constrained-random verification | 1 (random tests) |
| `sv-tutorial/testbenches/uvm` | UVM section (empty folder) | 1 (UVM) |
| `intel-training-modules/RTL`, `timing` | Intel FPGA RTL exercises (pipelines, fan-out, adder tree, timers) | 2, 4 (timing) |
| `lab5/` (`timing_background`, `timing_opt`, `analyzer_tutorial`, `fsmd_tips`, `adder_3input`) | timing analysis and optimization slides plus lab | 1 step 10, 4 |
| `lab1`..`lab4-solo`, `lab3-sim` | course labs, including your MIPS and convolution work | 2 |
| `lab4-solo/interview_prep` | interview crib sheet and shadowing notes | 2, interview |
| `VLSI-II/VCS`, `TCL`, `ICC2`, `TetraMax`, `Videos` | VCS manual, TCL, IC Compiler II tutorial, test | 3 |
| `Lectures/Lectures` | recorded lectures (Lecture1..31, CoverGroup) | all, reference |
| `RTL Design and Verification Interview Questions.pdf` | interview question list | all |
| `SoC_Course_Tutorials-main` | SoC course tutorials | later |
| `*.zip` files | archives of the folders above (Lectures.zip is ~10 GB) | ignore |

Suggested parallel reading while doing the FIFO: `sv-tutorial/sequential`, then `testbenches/basic`, then
`lab5/timing_background.pptx` before the timing step.
