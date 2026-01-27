`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/22/2026 04:13:27 PM
// Design Name: 
// Module Name: rom_ctrl
// Project Name: minilab0
// Target Devices: FPGA
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module rom_ctrl(clk, enable, address, data);
    input  logic       clk;
    input  logic       enable;
    input  logic [7:0] address;
    output logic [7:0] data;
    
    //initalize and assign 8 random 8-bit numbers
    logic [7:0] memory [7:0];
    
    assign memory[0] = 8'b0010_0010; //8'h22
    assign memory[1] = 8'b0010_0011; //8'h23
    assign memory[2] = 8'b0011_0010; //8'h32
    assign memory[3] = 8'b0011_0011; //8'h33
    assign memory[4] = 8'b0111_0010; //8'h72
    assign memory[5] = 8'b0011_1001; //8'h39
    assign memory[6] = 8'b0111_0110; //8'h76
    assign memory[7] = 8'b1011_0011; //8'hB3
    
    //when enable is high retrieve data from address otherwise data is all 0's
    always_ff @ (posedge clk) begin
        if (enable) begin
            case(address) 
                8'b0000_0001 : data <= memory[0];
                8'b0000_0010 : data <= memory[1];
                8'b0000_0100 : data <= memory[2];
                8'b0000_1000 : data <= memory[3];
                8'b0001_0000 : data <= memory[4];
                8'b0010_0000 : data <= memory[5];
                8'b0100_0000 : data <= memory[6];
                default      : data <= memory[7];
            endcase
        end else begin
            data <= 8'd0;
        end
    end
    
endmodule
