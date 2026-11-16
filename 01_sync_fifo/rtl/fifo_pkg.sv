// Shared FIFO constants. Compile this file BEFORE anything that imports it.
package fifo_pkg;
    parameter int DATA_WIDTH    = 8;                 // data is [7:0]
    parameter int ADDRESS_WIDTH = 4;                 // 16 entries
    localparam int DEPTH        = 1 << ADDRESS_WIDTH;

    typedef logic [DATA_WIDTH-1:0]    data_t;        // [7:0]
    typedef logic [ADDRESS_WIDTH-1:0] addr_t;
    typedef logic [ADDRESS_WIDTH:0]   ptr_t;         // pointer with the extra wrap bit
endpackage
