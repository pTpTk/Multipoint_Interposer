`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2019 09:24:19 PM
// Design Name: 
// Module Name: ArbiterNestLoop
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

/*
 *Logic is as followed:
 *1. if there is no unfinished request, we can grant request
 *2. if there is an unfinished request, check if the inner counter is at destination
        if it is, set node to receive, no more unfinished request
        if not, set node to bypass
 *3. if inner counter is at first grant node, terminate loop
 */
module ArbiterNestLoop#(                        //default logic is to send from 0 to 7
    parameter NODE_COUNT = 8,
    parameter NODE_SIGNAL_IN = 4,				//on/off 1 bit, destination 3 bits
    parameter NODE_SIGNAL_OUT = 3,				//Tx 1 bit, Rx 1 bit, Bp 1 bit
    parameter TOTAL_SIGNAL_IN = NODE_SIGNAL_IN * NODE_COUNT,
    parameter TOTAL_SIGNAL_OUT = NODE_SIGNAL_OUT * NODE_COUNT
    )
    (
    input   wire     [TOTAL_SIGNAL_IN - 1:0]    request_port,       //4 bits per node, on/off 1 bit, destination 3 bits
    input   wire                                clk,
    input   wire                                reset,
    
    output  reg      [TOTAL_SIGNAL_OUT - 1:0]  control_port         //send control, bypassing control and receiving control, 3 bits per node
    );
    
    wire    [NODE_SIGNAL_IN- 1:0]	input_sig[NODE_COUNT - 1:0];	//for easier use of adressing each node
	wire	[3:0]					main_signal;
	wire	[2:0]					loop_signal;					//case used to control whether to loop
    
    reg     [NODE_SIGNAL_IN - 2:0]      destination;                //to store the destination the node wants to send to
    reg                             	unfinish_flag;              //to indicate if there is an unfinished request (send is granted, no receive set yet)
    reg     [NODE_SIGNAL_IN - 2:0]      priority_counter;           //incremented every clk cycle to indicate which node has priority
    reg     [NODE_SIGNAL_IN - 2:0]      inner_counter;              //increment after the corresponding node is dealt with, indicating which bit arbiter is dealing with
    reg     [NODE_COUNT - 1:0]          send_control;               //signal corresponding node to send
    reg     [NODE_COUNT - 1:0]          receive_control;            //signal corresponding node to receive
    reg     [NODE_COUNT - 1:0]          bypass_control;             //signal corresponding node to bypass, exclusive with the two above
    reg     [NODE_COUNT - 1:0]          requests;                   //nodes with request to send
    reg                             	on_off;                     //on off switch for the arbiter logic
    reg     [NODE_SIGNAL_IN - 1:0]      first_grant;                //records first node to send, first bit is valid.
    reg                                 receive_flag;
    
    assign input_sig[0] = request_port[3:0];                        //split input by node
    assign input_sig[1] = request_port[7:4];
    assign input_sig[2] = request_port[11:8];
    assign input_sig[3] = request_port[15:12];
    assign input_sig[4] = request_port[19:16];
    assign input_sig[5] = request_port[23:20];
    assign input_sig[6] = request_port[27:24];
    assign input_sig[7] = request_port[31:28];
	
	assign main_signal = {unfinish_flag, requests[inner_counter], (destination == inner_counter), first_grant[NODE_SIGNAL_IN - 1]};
	assign loop_signal = {first_grant[NODE_SIGNAL_IN - 1] && (inner_counter == first_grant[NODE_SIGNAL_IN - 2:0]), unfinish_flag, |requests};
    
    always @ (posedge on_off) begin
		on_off = 0;
		
		case(main_signal)
			4'b0100, 4'b0110: begin			
				send_control[inner_counter] = 1;						//first grant
				unfinish_flag = 1;
				destination = input_sig[inner_counter][2:0];
				first_grant = {1'b1, inner_counter};
				requests[inner_counter] = 0;
				end
			4'b0101, 4'b0111: begin
				send_control[inner_counter] = 1;						//grant
				unfinish_flag = 1;
				destination = input_sig[inner_counter][2:0];
				requests[inner_counter] = 0;
				end
			4'b1001, 4'b1101: begin
				bypass_control[inner_counter] = 1;						//bypass
			    end
			4'b1011, 4'b1111: begin
				receive_control[inner_counter] = 1;						//receive
				unfinish_flag = 0;
				receive_flag = 1;										//tell the loop case this is receiving
				end
		endcase
		
		inner_counter = (inner_counter == 7) ? 0 : inner_counter + 1;
    end
	
	always @ (inner_counter) begin
		case(loop_signal)
			3'b001, 3'b010, 3'b011: begin
				if(receive_flag) begin
				    inner_counter = (inner_counter == 0) ? 7 : inner_counter - 1;
				    receive_flag = 0;
				end
				on_off = 1;
				end
			3'b110: begin
				receive_control[inner_counter] = 1;	
				unfinish_flag = 0;
				end
		endcase
		
		control_port = {send_control, receive_control, bypass_control};
	end
    
    always @ (posedge clk) begin
        if(!reset) begin
            priority_counter = (priority_counter == 7) ? 0 : priority_counter + 1;   // Rotating the counter, no need to give permission to node 7 since data goes one way
			inner_counter = priority_counter;
            requests = requests | {input_sig[7][3], input_sig[6][3], input_sig[5][3],input_sig[4][3], input_sig[3][3], input_sig[2][3],input_sig[1][3], input_sig[0][3]};   //add new requests to the queue
            unfinish_flag =0;
            destination = 0;
            first_grant = 0;
            send_control = 0;
            receive_control = 0;
            bypass_control = 0;
            on_off = 1;
            receive_flag = 0;
        end
        else begin
            priority_counter = 0;
            inner_counter = 0;
            requests = 8'b00000000;
            on_off = 0;
            unfinish_flag = 0;
            first_grant = 0;
            send_control = 0;
            receive_control = 0;
            bypass_control = 0;
            destination = 0;
            receive_flag = 0;
        end
    end
    
endmodule