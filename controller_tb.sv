module controller_tb();

    // Signals changed in the testbench
    reg clk;
    reg enable;
    reg [7:0] addr; // Should be one-hot encoded values (8'b0000_0001, 8'b000_0010, etc.)

    // This corresponds to the values in memory (see rom_ctrl.sv)
    reg [7:0] expectedValues [7:0] = {8'hB3, 8'h76, 8'h39, 8'h72, 
                                        8'h33, 8'h32, 8'h23, 8'h22};

    // Will be initialized to 1 since everything "passes", once something fails a
    reg passed;
    wire [7:0] out;
    reg [7:0] oneHot [7:0] = {8'b0000_0001, 8'b0000_0010, 8'b0000_0100, 8'b0000_1000, 
                              8'b0001_0000, 8'b0010_0000, 8'b0100_0000, 8'b1000_0000};
    
    rom_ctrl iDUT(.clk(clk), .enable(enable), .address(addr), .data(out));

    initial begin
        clk = 0;
        enable = 0;
        addr = 8'h00;
        passed = 1; // Changes to 0 if any test fails
        repeat (5) @(posedge clk);
        
        // TEST 1: Output should be all 0s when addr is not set
        if (out !== 8'h00) begin
            $display("ERR: output wasn't all 0s when addr was 0 (was %h)", out);
            passed = 0;
        end

        // TEST 2: 0th index
        for (integer i = 0; i < 8; i = i + 1) begin
            @(negedge clk);
            addr = oneHot[i];
            enable = 1;
            @(posedge clk);
            if (out !== expectedValues[i]) begin
                $display("ERR: output wasn't correct at index %0d, expected %h but was %h", i, expectedValues[i], out);
                passed = 0;
            end
        end

        if (passed === 1'b1) $display("ALL CASES PASSED!");
        else $display("Some test failed, see output");

    end

    always #5 clk = ~clk;
endmodule