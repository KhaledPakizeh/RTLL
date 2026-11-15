// Synchronous FIFO: template. Fill in the TODOs. See ../spec.md and ../diagram/.
// For EDA Playground this file goes in the "design" pane.

module fifo 
    #(
    parameter int DATA_WIDTH =  8,
    parameter int ADDRESS_WIDTH = 8
    ) 
(
    input logic [DATA_WIDTH-1:0] d_in, 
    output logic [DATA_WIDTH-1:0] d_out, 
    input logic clk,rst,read_enable,write_enable 
);
    parameter DEPTH = (1 << ADDRESS_WIDTH); 

    // TODO: write pointer, read pointer (and whatever tells full from empty).
    logic [ADDRESS_WIDTH:0] w_ptr;
    logic [ADDRESS_WIDTH:0] r_ptr;

    // TODO: storage (memory array).
    logic [ADDRESS_WIDTH-1:0] L_fifo [(1<<ADDRESS_WIDTH)]; 

    logic full,empty; 
    
    assign full  =  ((r_ptr[ADDRESS_WIDTH-1:0] == w_ptr[ADDRESS_WIDTH-1:0]) && (w_ptr[ADDRESS_WIDTH] != r_ptr[ADDRESS_WIDTH]));
    assign empty = ((r_ptr[ADDRESS_WIDTH-1:0] == w_ptr[ADDRESS_WIDTH-1:0]) && (w_ptr[ADDRESS_WIDTH] == r_ptr[ADDRESS_WIDTH]));
    
    // TODO: accepted-write and accepted-read conditions (what gates wr_en / rd_en?).
    always_ff @(posedge clk) begin 
        if(rst) begin
            L_fifo <=0; 
            w_ptr  <=0;
            r_ptr  <=0; 
        end

        else begin
            if(rd_enable && !empty) begin 
                d_out <= L_fifo[r_ptr[ADDRESS_WIDTH-1:0]]; 
            end 
            if(wr_enable && !full) begin
                L_fifo[w_ptr[ADDRESS_WIDTH-1:0]] <= d_in; 
            end 

            case ({rd_enable && !empty,wr_enable && !full})
            2'b10: 
            begin 
                r_ptr <= r_ptr +1;  
            end 
            2'b01: 
            begin
                w_ptr <= w_ptr+1; 
            end         
            default: begin
            end 
            
        end
        
    end 
endmodule
