`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/18/2019 12:59:39 AM
// Design Name: 
// Module Name: NodeIO_tb
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


module NodeIO_tb(

    );
    wire [3:0] request_sig;
    wire [21:0] outgoing_msg;
    wire [19:0] received_msg;
    
    reg [2:0] control_sig;
    reg [21:0] incoming_msg;
    reg [21:0] random_msg;
    reg clk;
    reg reset;
    
    NodeIO haha(
    .msg_in(incoming_msg),
    .msg_rand(random_msg),
    .control_in(control_sig),
    .clk(clk),
    .reset(reset),
    
    .msg_out(outgoing_msg),
    .msg_received(received_msg),
    .request_out(request_sig)
    );
    
    initial begin
        control_sig = 0;
        incoming_msg = 0;
        random_msg = 22'b1101001010101010101010;
        clk = 0;
        reset = 1;
        #20;
        reset = 0;
        #10;                //should be a request coming out, sending to node 6
        $display("send request %b", request_sig);
        #10;
        control_sig = 3'b100; //grant sending request
        $display("The outgoing message is %h", outgoing_msg);
        #10;
        control_sig = 3'b010;     //receive message
        incoming_msg = 22'b1000100000111111110000;
        #10;
        control_sig = 3'b001;         //bypassing
        incoming_msg = 22'b0010100000111100001111;
        $display("Bypassed message is %h", outgoing_msg);
        #10;
        control_sig = 3'b010;         //forwarding
        incoming_msg = 22'b1110100000110010001111;
        #10;
        $display("send request %b", request_sig);
    end
        
    always
        #5 clk = !clk;
endmodule
