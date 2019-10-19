`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2019 11:55:47 PM
// Design Name: 
// Module Name: Node_tb
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


module Node_tb(

    );
    wire    [51:0]  all_output;
    wire    [21:0]  outgoing_msg_1;
    wire    [21:0]  outgoing_msg_0;
    wire    [3:0]   request_sig_1;
    wire    [3:0]   request_sig_0;
    wire    [49:0]  all_input;
    
    reg     [2:0]   arbiter_control_sig_1;
    reg     [2:0]   arbiter_control_sig_0;
    reg     [21:0]  incoming_msg_1;
    reg     [21:0]  incoming_msg_0;
    reg             clk;
    reg             reset;
    
    assign request_sig_1 = all_output[51:48];
    assign request_sig_0 = all_output[47:44];
    assign outgoing_msg_1 = all_output[43:22];
    assign outgoing_msg_0 = all_output[21:0];
    assign all_input = {arbiter_control_sig_1,arbiter_control_sig_0,incoming_msg_1,incoming_msg_0};
    
    Node #(
    .NODE_NUMBER(4)
    )
    Node_4(
    .input_port(all_input),
    .clk(clk),
    .reset(reset),
    
    .output_port(all_output)
    );
    
    initial begin
        arbiter_control_sig_1 = 0;
        arbiter_control_sig_0 = 0;
        incoming_msg_1 = 0;
        incoming_msg_0 = 0;
        clk = 0;
        reset = 1;
        #20;
        reset = 0;
        #10;                //should be a request coming out, sending to node 6
        $display("send request %b", request_sig_0);
        #10;
        arbiter_control_sig_0 = 3'b100; //grant sending request
        $display("The outgoing message is %h", outgoing_msg_0);
        #10;
        arbiter_control_sig_1 = 3'b010;     //receive message
        arbiter_control_sig_0 = 0;
        incoming_msg_1 = 22'b1000100000111111110000;
        #10;
        arbiter_control_sig_1 = 3'b001;         //bypassing
        incoming_msg_1 = 22'b0010100000111100001111;
        $display("Bypassed message is %h", outgoing_msg_1);
        #10;
        arbiter_control_sig_0 = 3'b010;         //forwarding
        arbiter_control_sig_1 = 0;
        incoming_msg_0 = 22'b1110100000110010001111;
        #10;
        $display("send request %b", request_sig_0);
    end
        
    always
        #5 clk = !clk;
endmodule
