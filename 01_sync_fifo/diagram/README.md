# Block diagram

Put your drawing here (`fifo_block_diagram.png`, `.jpg`, `.pdf` or `.drawio`). Claude can read PNG/JPG/PDF
and `.drawio` (it is XML), so any of these works:

- Pen and paper or tablet: take a photo or screenshot, save it here. Fastest, and fine.
- draw.io (diagrams.net): install the "Draw.io Integration" VS Code extension and save as
  `fifo_block_diagram.drawio.png`. The image shows the drawing and also carries the editable source.
- Excalidraw (excalidraw.com): export PNG.

The diagram should show: every port with direction and width, the memory, write and read pointers,
the full/empty/count logic, what feeds what, and where the registers are (clock edge boundaries).
Also draw a small timing sketch: one write, one read, and what `rd_data` does the cycle after.
