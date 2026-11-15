# Synchronous FIFO: spec

Fill in the blanks (`___`) and decide the open questions BEFORE drawing the diagram.

## Parameters
| Name | Meaning | Default | Constraint |
|------|---------|---------|------------|
|      |         |         |            |

## Ports
| Port | Dir | Width | Meaning |
|------|-----|-------|---------|
|      |     |       |         |

## Behavior
- Write accepted when `wr_en && !full`. Write when full: ___ (ignored? error?)
- Read accepted when `rd_en && !empty`. Read when empty: ___
- Simultaneous read and write: ___ (when empty? when full? in between?)
- `rd_data` timing: **default = registered, valid the cycle AFTER an accepted read.** (The alternative is
  first-word-fall-through, where `rd_data` shows the head entry without a read.) Your choice: ___
  The testbench template assumes the default. If you change it, change the scoreboard check.
- Reset: pointers and count to ___, `empty`=___, `full`=___. Memory contents are not cleared. Why?
- `full`/`empty`/`count`: registered or derived from pointers? ___

## Open design questions (answer in the diagram)
1. How do you tell full from empty when read and write pointers are equal? (extra bit, count, flag)
2. Memory: array of registers or inferred block RAM? What does that change for reset and read timing?
3. Where is the critical path likely to be?

## Corner cases to cover (feeds the verification plan)
Reset mid-operation, fill to full, drain to empty, write when full, read when empty, read+write at
full, read+write at empty, pointer wraparound, back-to-back accesses, DEPTH=1 or 2 if allowed.
