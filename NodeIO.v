`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2019 09:15:45 PM
// Design Name: 
// Module Name: NodeIO
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


module NodeIO #(
	parameter NODE_IO_NUMBER = 0,					//0 means low to high, 1 means high to low
	parameter NODE_NUMBER = 0,
	parameter NODE_COUNT = 8,
	parameter NODE_COUNT_DIGIT = 3,
	parameter RADOM_SEED = 10'b1001111000,
	parameter ACTUAL_MESSAGE_SIZE = 16,
	parameter MSG_SIZE = ACTUAL_MESSAGE_SIZE + NODE_COUNT_DIGIT * 2,
	parameter ARBITER_SIGNAL_IN = 3,
	parameter ARBITER_SIGNAL_OUT = NODE_COUNT_DIGIT + 1,
	parameter TOTAL_IN = (MSG_SIZE + ARBITER_SIGNAL_IN) * 2,
	parameter TOTAL_OUT = (MSG_SIZE + ARBITER_SIGNAL_OUT) * 2,
	parameter FIFO_DEPTH = 8
)
(
	input	wire	[MSG_SIZE - 1:0]					msg_in,
	input	wire	[MSG_SIZE - 1:0]					msg_rand,
	input	wire	[ARBITER_SIGNAL_IN - 1:0]			control_in,
	input	wire										clk,
	input	wire										reset,
	
	output	wire 	[MSG_SIZE - 1:0]					msg_out,
	output	reg		[MSG_SIZE - NODE_COUNT_DIGIT:0]		msg_received,				//msg intended for this node, first bit valid bit, filtered out the header
	output	reg		[ARBITER_SIGNAL_OUT - 1:0]			request_out
);


	wire   	[NODE_COUNT_DIGIT - 1:0]	msg_in_addr;						//destination of the incoming message
	wire	[NODE_COUNT_DIGIT - 1:0]	msg_rand_addr;						//destination of the random message
	wire								msg_rand_valid;						//for flow control, only let 1/8 random message get send
	wire								msg_rand_send;						//control signal for whether to send the random message or not
	
	reg     [MSG_SIZE:0]                msg_in_reg;
	reg		[MSG_SIZE:0]				output_stack[FIFO_DEPTH - 1:0];		//output stack, node count entries to hold data to send, the first bit is valid bit
	reg		[NODE_COUNT_DIGIT - 1:0]	head_out;								//head of the output stack, pointing at the newest entry
	reg		[NODE_COUNT_DIGIT - 1:0]	tail_out;								//tail of the output stack
	reg									forward_flag;						//indicating whether to forward the message
	
	integer                             k;                                  //used for initialization
	
	assign msg_in_addr    = msg_in_reg[MSG_SIZE - 1:MSG_SIZE - NODE_COUNT_DIGIT];
	assign msg_rand_addr  = msg_rand[MSG_SIZE - 1:MSG_SIZE - NODE_COUNT_DIGIT];
	assign msg_rand_valid = & msg_rand[2:0];								//only put the random value to stack if the last three digits are 111, so only 1/8 messages get sent
	assign msg_rand_send  = (NODE_IO_NUMBER) ? (msg_rand_valid && (NODE_NUMBER > msg_rand_addr)) : (msg_rand_valid && (NODE_NUMBER < msg_rand_addr));		//make sure this is the right IO to use for the message
	assign msg_out = (control_in[2]) ? output_stack[tail_out][MSG_SIZE - 1:0] : (control_in[0]) ? msg_in_reg : 0;	//make sure to send and bypass as soon as the control signal is here
	
	always @ (msg_in) begin
	    msg_in_reg <= msg_in;
	end
	always @ (negedge clk) begin
	    msg_received[MSG_SIZE - NODE_COUNT_DIGIT] = 0;
		if(!reset) begin
		
			if(control_in[2]) begin															//Tx
				output_stack[tail_out][MSG_SIZE] = 0;
				tail_out = (tail_out == FIFO_DEPTH - 1) ? 0 : tail_out + 1;
				request_out[ARBITER_SIGNAL_OUT - 1] = 0;
			end
			
			if(control_in[1]) begin														//Rx
				if (msg_in_addr == NODE_NUMBER)								//if this is not forwarding
					msg_received = {1'b1, msg_in_reg[MSG_SIZE - NODE_COUNT_DIGIT - 1:0]};
				else
					forward_flag = 1;
			end
			
			if(forward_flag) begin											//forwarding msg add to output FIFO
			    output_stack[head_out] = {1'b1, msg_in_reg};
				head_out = (head_out == FIFO_DEPTH - 1) ? 0 : head_out + 1;
				forward_flag = 0;
			end
			
			if(msg_rand_send) begin											//random msg add to output FIFO
			    output_stack[head_out] = {1'b1, msg_rand};
				head_out = (head_out == FIFO_DEPTH - 1) ? 0 : head_out + 1;
			end
			
			request_out = (request_out[ARBITER_SIGNAL_OUT - 1])? request_out : {output_stack[tail_out][MSG_SIZE], output_stack[tail_out][MSG_SIZE - 1:MSG_SIZE - NODE_COUNT_DIGIT]};
			
		end
		else begin

			msg_received <= 0;
			request_out <= 0;
			head_out <= 0;
			tail_out <= 0;
			forward_flag <= 0;
			for(k = 0; k < NODE_COUNT; k = k + 1) begin
			    output_stack[k] <= 0;
            end
			
		end
	end

endmodule
