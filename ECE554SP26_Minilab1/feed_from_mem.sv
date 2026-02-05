
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

reg [63:0] memData;
reg [63+DATA_WIDTH:0] data;
// Output only sees FIFO-Width bits at a time
assign dataByte = data[DATA_WIDTH-1:0];

reg [NUM_FIFOS:0] fifoCTR;  // Which FIFO is in use (1-hot)
reg writeEn;                 // Write current Byte to current FIFO
// Output only sees 1-Hot Write-Enable
assign fifoEnable = writeEn ? fifoCTR[NUM_FIFOS-1:0] : '0;

reg [DEPTH:0] byteCTR;  // Which FIFO index is being filled



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
                done <= 1'b0;          // De-assert Completion Status
                fifoCTR <= '0 | 1'b1;  // Start counting FIFOs
                curAddr <= addr;       // Snapshot of Memory Address
                memRead <= 1'b1;       // Read from Memory
                state <= LOAD;         // Advance to next State
        end end
        
        // LOAD state delays until Memory returns
        LOAD: begin
            if(~memInUse) memRead <= 1'b0;  // Hold Read signal until recieved
            if(memDone) begin
                byteCTR <= '0 | 1'b1;                  // Start counting Bytes
                data <= {memData,{DATA_WIDTH{1'b0}}};  // Snapshot of Memory Data
                state <= FILL;                         // Advance to next State
        end end
        
        // FILL state fills current FIFO with data
        FILL: begin
            writeEn <= 1'b0;
            // Current FIFO full
            if (byteCTR[DEPTH]) state <= EVAL;
            // Room remains; Feed next Byte
            else begin
                data <= data>>DATA_WIDTH;  // Prepare next Byte
                writeEn <= 1'b1;           // Write Byte to FIFO
                byteCTR <= byteCTR<<1;     // Increment Byte count
        end end
        
        // EVAL state rotates through FIFOs
        EVAL: begin
            
            // All FIFOs filled
            if (fifoCTR[NUM_FIFOS]) begin
                done <= 1'b1;
                state <= IDLE;
            
            // Next FIFO exists
            end else begin
                curAddr <= curAddr + 1;  // TODO - Addressing issues
                fifoCTR <= fifoCTR<<1;   // Advance to next FIFO
                memRead <= 1'b1;         // Read from Memory
                state <= LOAD;           // Advance to next State
        end end
    
    // End of Case Statement
    endcase end

end // End of ALWAYS BLOCK

// End of feed_from_mem
endmodule