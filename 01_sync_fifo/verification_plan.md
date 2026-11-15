# Sync FIFO: verification plan

Fill in before writing tests. One row per feature; every row needs a check and a way to know it was hit.

| # | Feature / requirement | Stimulus | Check (scoreboard / assertion) | Coverage item | Status |
|---|-----------------------|----------|--------------------------------|---------------|--------|
| 1 | Reset state: empty=1, full=0, count=0 | reset at start and mid-traffic | ___ | ___ | |
| 2 | Data comes out in the order written | ___ | scoreboard queue | ___ | |
| 3 | `full` asserts at DEPTH entries | fill | ___ | full reached | |
| 4 | Write when full is ignored | ___ | ___ | wr_en while full | |
| 5 | `empty` asserts at 0 entries | drain | ___ | empty reached | |
| 6 | Read when empty is ignored | ___ | ___ | rd_en while empty | |
| 7 | Simultaneous read+write (empty / middle / full) | ___ | ___ | cross: state x op | |
| 8 | Pointer wraparound | > DEPTH total ops | ___ | wrap of each pointer | |
| 9 | `count` matches stored entries | random | ___ | count bins | |
| 10 | ___ | | | | |

## Assertions (SVA), to write after the plain testbench passes
- No overflow: never accepted write while full (or: write when full does not change count).
- No underflow: same for read when empty.
- `full` and `empty` never both 1 (for DEPTH > 0).
- `count` changes by +1, -1, or 0 only, matching accepted ops.
- After reset: `empty` and `!full`.

## Exit criteria (how you decide you are done)
- All plan rows have a passing check.
- Functional coverage 100% on the items above, or holes explained in writing.
- Code coverage (statement/branch/toggle) reviewed, with unreachable code explained.
- Random test run with at least 3 different seeds / write-read ratios.
- Each bug found is logged in `progress.md`, with how it was caught.
