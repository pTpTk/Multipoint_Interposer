`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/04/2019 10:02:44 PM
// Design Name: 
// Module Name: Arbiter_tb
// Project Name: 
// Target Devices: 
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


module Arbiter_tb(
    );
    reg     [31:0]      request;
    reg                 clk;
    reg                 reset;
    
    wire    [23:0]      control_sig;
    
    
    
    ArbiterNestLoop lala(
    .request_port(request),
    .clk(clk),
    .reset(reset),
    
    .control_port(control_sig)
    );
    
    initial begin
        clk = 0;
        reset = 1;
        #20;
        reset = 0;
        request[3:0]   = 4'b1100;
        request[7:4]   = 4'b0000;
        request[11:8]  = 4'b0000;
        request[15:12] = 4'b0000;
        request[19:16] = 4'b0000;
        request[23:20] = 4'b0000;
        request[27:24] = 4'b0000;
        request[31:28] = 4'b0000;
        #10;
        request[3:0]   = 4'b1100;
        request[7:4]   = 4'b0000;
        request[11:8]  = 4'b0000;
        request[15:12] = 4'b0000;
        request[19:16] = 4'b0000;
        request[23:20] = 4'b1111;
        request[27:24] = 4'b0000;
        request[31:28] = 4'b0000;
        #10;
        request[3:0]   = 4'b1110;
        request[7:4]   = 4'b0000;
        request[11:8]  = 4'b1101;
        request[15:12] = 4'b0000;
        request[19:16] = 4'b1111;
        request[23:20] = 4'b0000;
        request[27:24] = 4'b1111;
        request[31:28] = 4'b0000;
        #10;
    end
    
    always 
        #5  clk =  ! clk;
endmodule
