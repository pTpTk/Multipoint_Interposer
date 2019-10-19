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
	parameter TOTAL_OUT = (MSG_SIZE + ARBITER_SIGNAL_OUT) * 2
)
(
	input	wire	[MSG_SIZE - 1:0]					msg_in,
	input	wire	[MSG_SIZE - 1:0]					msg_rand,
	input	wire	[ARBITER_SIGNAL_IN - 1:0]			control_in,
	input	wire										clk,
	input	wire										reset,
	
	output	reg		[MSG_SIZE - 1:0]					msg_out,
	output	reg		[MSG_SIZE - NODE_COUNT_DIGIT:0]		msg_received,				//msg intended for this node, first bit valid bit, filtered out the header
	output	reg		[ARBITER_SIGNAL_OUT - 1:0]			request_out
);


	wire	[NODE_COUNT_DIGIT - 1:0]	msg_in_addr;						//destination of the incoming message
	wire	[NODE_COUNT_DIGIT - 1:0]	msg_rand_addr;						//destination of the random message
	wire								msg_rand_valid;						//for flow control, only let 1/8 random message get send
	wire								msg_rand_send;						//control signal for whether to send the random message or not
	wire	[2:0]						stack_sig;							//control signal for filling the stack
	wire								stack_requests;						//indicating whether there are any more requests left in the stack
	
	reg		[MSG_SIZE:0]				output_stack[NODE_COUNT - 1:0];		//output stack, node count entries to hold data to send, the first bit is valid bit
	reg		[NODE_COUNT_DIGIT - 1:0]	head;								//head of the stack, pointing at the newest entry
	reg		[NODE_COUNT_DIGIT - 1:0]	tail;								//tail of the stack
	reg									forward_flag;						//indicating whether to forward the message
	reg									pending_request;					//indicating whether there is a outgoing request to send
	reg                                 k;                                  //used for initialization
	
	assign msg_in_addr    = msg_in[MSG_SIZE - 1:MSG_SIZE - NODE_COUNT_DIGIT];
	assign msg_rand_addr  = msg_rand[MSG_SIZE - 1:MSG_SIZE - NODE_COUNT_DIGIT];
	assign msg_rand_valid = & msg_rand[2:0];								//only put the random value to stack if the last three digits are 111, so only 1/8 messages get sent
	assign msg_rand_send  = (NODE_IO_NUMBER) ? (msg_rand_valid && (NODE_NUMBER > msg_rand_addr)) : (msg_rand_valid && (NODE_NUMBER < msg_rand_addr));		//make sure this is the right IO to use for the message
	assign stack_sig      = {forward_flag, msg_rand_send};
	assign stack_requests = output_stack[head][MSG_SIZE] & output_stack[tail][MSG_SIZE];
	
	
	always @ (posedge clk) begin
		if(!reset) begin
			case(control_in)
				3'b100: begin															//Tx
					msg_out = output_stack[tail][MSG_SIZE - 1:0];
					output_stack[tail][MSG_SIZE] = 0;
					tail = (tail == NODE_COUNT - 1) ? 0 : tail + 1;
					pending_request = 0;
					end
				3'b010: begin														//Rx
					if (msg_in_addr == NODE_NUMBER)								//if this is not forwarding
						msg_received = {1'b1, msg_in[MSG_SIZE - NODE_COUNT_DIGIT:0]};
					else
						forward_flag = 1;
					end
				3'b001:															//bypassing
					msg_out = msg_in;
			endcase
			
			case(stack_sig)
				2'b11: begin															//both data need to be sent out
					head = (head == NODE_COUNT - 1) ? 0 : head + 1;
					output_stack[head] = {1'b1, msg_in};
					head = (head == NODE_COUNT - 1) ? 0 : head + 1;
					output_stack[head] = {1'b1, msg_rand};
					forward_flag = 0;
					end
				2'b10: begin															//only forwarding
					head = (head == NODE_COUNT - 1) ? 0 : head + 1;
					output_stack[head] = {1'b1, msg_in};
					forward_flag = 0;
					end
				2'b01: begin															//only send generated
					head = (head == NODE_COUNT - 1) ? 0 : head + 1;
					output_stack[head] = {1'b1, msg_rand};
					end
			endcase
			
			request_out = (pending_request) ? request_out : {stack_requests, output_stack[tail][MSG_SIZE - 1:MSG_SIZE - NODE_COUNT_DIGIT]};
		end
		else begin
			msg_out = 0;
			msg_received = 0;
			request_out = 0;
			head = 0;
			tail = 0;
			forward_flag = 0;
			pending_request = 0;
			output_stack[0] = 0;
			output_stack[1] = 0;
			output_stack[2] = 0;
			output_stack[3] = 0;
			output_stack[4] = 0;
			output_stack[5] = 0;
			output_stack[6] = 0;
			output_stack[7] = 0;
		end
	end



endmodule
