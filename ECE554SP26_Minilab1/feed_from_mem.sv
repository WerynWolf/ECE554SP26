
//

module fill_from_mem
#(
  parameter NUM_FIFOS=9,
  parameter DEPTH=8,
  parameter DATA_WIDTH=8
)
(
    // System Controls
    input wire clk,
    input wire rst_n,

    // User Controls to MEM
    input wire [31:0] addr,    // Address to fill FIFO from

    // User Controls to FIFO
    input wire fill,           // Initiate filling of FIFOs

    // Interface to FIFO
    output logic [DATA_WIDTH-1:0] dataByte,   // Data written to selected FIFO
    output logic [NUM_FIFOS-1:0] fifoEnable,  // Write-Enable to FIFOs (1-hot)

    // Done Signal
    output reg done
);



// State Machine Parameters
reg [1:0] state;
localparam IDLE = 2'b00,
           LOAD = 2'b01,
           FILL = 2'b10,
           EVAL = 2'b11;
reg [31:0] curAddr;
reg memRead, memDone, memInUse;

reg [63:0] memData, data;
// Output only sees FIFO-Width bits at a time
assign dataByte = data[DATA_WIDTH-1:0];

reg [NUM_FIFOS-1:0] fifoCTR;  // Which FIFO is in use (1-hot)
reg writeEn;                 // Write current Byte to current FIFO
// Output only sees 1-Hot Write-Enable
assign fifoEnable = writeEn ? fifoCTR : '0;

reg [DEPTH-1:0] byteCTR;  // Which FIFO index is being filled



// Instantiate Memory Interface
mem_wrapper MEM
(
    // Link System Controls
    .clk(clk), .reset_n(rst_n),

    //
    .address(curAddr), .read(memRead),
    .readdata(memData), .readdatavalid(memDone),
    .waitrequest(memInUse)
);



// Define Sequential Logic
always @(posedge clk or negedge rst_n) begin

    // Reset Behavior
    if (~rst_n) begin
        curAddr <= '0;
        memRead <= 1'b0;
        data <= '0;
        fifoCTR <= '0;
        writeEn <= 1'b0;
        byteCTR <= '0;
        done <= 1'b0;
        state <= IDLE;

    // State Machine Behavior
    end else begin case(state)
        
        // IDLE state awaits instruction to begin Fill-From-Mem op
        IDLE: begin
            if (fill) begin
                done <= 1'b0;  // De-assert Completion Status
                fifoCTR <= '0 | 1'b1;  // First line copied to first FIFO
                curAddr <= addr;      // Snapshot of Memory Address
                memRead <= 1'b1;      // Read from Memory
                state <= LOAD;        // Advance to next State
        end end
        
        // LOAD state delays until Memory returns
        LOAD: begin
            if(~memInUse) memRead <= 1'b0;  // Read signal PULSED
            if(memDone) begin
                data <= memData   // Snapshot of Memory Data
                byteCTR <= '0 | 1'b1;  // Start counting Bytes
                state <= FILL     // Advance to next State
        end end
        
        // FILL state fills current FIFO with data
        FILL: begin
            writeEn <= 1'b0;
            // Current FIFO full
            if (~&byteCTR) state <= EVAL;   // TODO - Addressing issues
            // Room remains; Feed next Byte
            else begin
                byteCTR <= byteCTR<<1;
                data <= data>>DATA_WIDTH;
                writeEn <= 1'b1;
        end end
        
        // EVAL state rotates through FIFOs
        EVAL: begin
            
            // Next FIFO exists
            if (fifoCTR<<1) begin
                curAddr <= curAddr + 1;   // TODO - Addressing issues
                fifoCTR <= fifoCTR<<1;
                memRead <= 1'b1;
                state <= LOAD;
            
            // All FIFOs filled
            end else begin
                // TODO - Reset actions?
                done <= 1'b1;
                state <= IDLE;
        end end
    
    // End of Case Statement
    endcase end

end // End of ALWAYS BLOCK

// End of feed_from_mem
endmodule