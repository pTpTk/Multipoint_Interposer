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
    wire [3:0] request_sig_4;
    wire [3:0] request_sig_5;
    wire [21:0] outgoing_msg;
    wire [19:0] received_msg_4;
    wire [19:0] received_msg_5;
    
    reg [2:0] control_sig_4;
    reg [2:0] control_sig_5;
    reg [21:0] incoming_msg_4;
    reg [21:0] random_msg;
    reg clk;
    reg reset;
    
    NodeIO #(
    .NODE_NUMBER(4)
    )
    haha (
    .msg_in(incoming_msg_4),
    .msg_rand(random_msg),
    .control_in(control_sig_4),
    .clk(clk),
    .reset(reset),
    
    .msg_out(outgoing_msg),
    .msg_received(received_msg_4),
    .request_out(request_sig_4)
    );
    
    NodeIO #(
    .NODE_NUMBER(5)
    )
    hahaHA (
    .msg_in(outgoing_msg),
    .msg_rand(random_msg),
    .control_in(control_sig_5),
    .clk(clk),
    .reset(reset),
    
    .msg_out(outgoing_msg),
    .msg_received(received_msg_5),
    .request_out(request_sig_5)
    );
    
    initial begin
        control_sig_4 = 0;
        control_sig_5 = 0;
        incoming_msg_4 = 0;
        clk = 0;
        #5;
        reset = 1;
        clk = 1;
        #5;
        reset = 0;
        clk = 0;
        #5
        random_msg = 22'b1011001010101010101111;
        clk = 1;
        #5
        clk = 0;
        #5
        control_sig_4 = 3'b100;//send
        control_sig_5 = 3'b010;//receive
        clk = 1;
        #5;
        clk = 0;
        #5;
        random_msg = 22'b1101001010101010101111;    //receive & forward request
        control_sig_4 = 3'b100;//send
        control_sig_5 = 3'b010;//receive
        clk = 1;
        #5;
        clk = 0;
        #5;
        incoming_msg_4 = 22'b1011001010101010110011;
        control_sig_4 = 3'b001;//bypass
        control_sig_5 = 3'b010;//receive
        clk = 1;
        #5;
        clk = 0;
        #5;
/*        random_msg = 22'b1101001010101010101111;
        #10;                //should be a request coming out, sending to node 6
        random_msg = 22'b1101001010101010101100;
//        #10;
//        $display("send request %b", request_sig);
        #10;
        control_sig = 3'b100; //grant sending request
//        $display("The outgoing message is %h", outgoing_msg);
        #10;
        control_sig = 3'b010;     //receive message
        incoming_msg = 22'b1000100000111111110000;
        #10;

        #10;
        control_sig = 3'b001;         //bypassing
        incoming_msg = 22'b0010100000111100001111;
//        $display("Bypassed message is %h", outgoing_msg);
//        #10;
//        control_sig = 3'b010;         //forwarding
//        incoming_msg = 22'b1110100000110010001111;
//        #10;
//        $display("send request %b", request_sig);
//        control_sig = 3'b100;
//        #50;
*/
    end
        
//    always
//        #5 clk = !clk;
endmodule
