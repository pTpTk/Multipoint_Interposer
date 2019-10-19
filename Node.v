`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/11/2019 08:51:59 PM
// Design Name: 
// Module Name: Node
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


module Node #(
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
	input	wire	[TOTAL_IN - 1:0]	input_port,			//control signal from arbiter 6 bit, 22 bits received message from nodes above it, 22 bits received message from the nodes below it
	input	wire						clk,
	input	wire						reset,
	
	output	reg		[TOTAL_OUT - 1:0]	output_port		//request signal to arbiter 4 * 2 bits, message send to larger nodes 19 bits, message send to smaller nodes 19 bits
);


	wire	[ARBITER_SIGNAL_IN - 1:0]		arbiter_signal[1:0];			//control signal from the arbiters, 5:3 arbiter going from high to low, 2:0 arbiter going from low to high
	wire	[NODE_COUNT_DIGIT - 1:0]		random_address;					//who the randomly generated message is for
	wire	[MSG_SIZE - 1:0]				random_msg;								//destination 3 bits, origin 3 bits message 16 bits, the last bit is also for whether to send or not
	wire	[MSG_SIZE - 1:0]				incoming_data[1:0];						//the message received
	wire	[MSG_SIZE:0]					IO_msg_received[1:0];					//interface to msg_received
	wire	[MSG_SIZE - 1:0]				IO_msg_out[1:0];						//interface to msg_out
	wire	[ARBITER_SIGNAL_OUT - 1:0]		IO_request_out[1:0];					//interfact to request_out
	wire    [NODE_COUNT_DIGIT - 1:0]        node_number;                       //node number of this node
	
	reg		[9:0]							feedback_shift_reg;									//used to generate random messages

	
	assign node_number       = NODE_NUMBER;
	assign arbiter_signal[1] = input_port[TOTAL_IN - 1:TOTAL_IN - ARBITER_SIGNAL_IN];
	assign arbiter_signal[0] = input_port[TOTAL_IN - ARBITER_SIGNAL_IN - 1:TOTAL_IN - ARBITER_SIGNAL_IN * 2];
//	assign random_msg        = {feedback_shift_reg[0],feedback_shift_reg[3],feedback_shift_reg[1], node_number, feedback_shift_reg[2] ,feedback_shift_reg[8],feedback_shift_reg[4],feedback_shift_reg[6],feedback_shift_reg[7], feedback_shift_reg};	//19 bit random message
    assign random_msg        = 22'b1101001010101010101010;
	assign incoming_data[1]  = input_port[MSG_SIZE * 2 - 1:MSG_SIZE];
	assign incoming_data[0]  = input_port[MSG_SIZE - 1:0];
	
	
	NodeIO #(
	.NODE_IO_NUMBER(1),
	.NODE_NUMBER(NODE_NUMBER)
	)
	Node_IO_1(
	.msg_in(incoming_data[1]),
	.msg_rand(random_msg),
	.control_in(arbiter_signal[1]),
	.clk(clk),
	.reset(reset),
	
	.msg_out(IO_msg_out[1]),
	.msg_received(IO_msg_received[1]),
	.request_out(IO_request_out[1])
	);
	
	NodeIO #(
	.NODE_IO_NUMBER(0),
	.NODE_NUMBER(NODE_NUMBER)
	)
	NodeIO_0(
	.msg_in(incoming_data[0]),
	.msg_rand(random_msg),
	.control_in(arbiter_signal[0]),
	.clk(clk),
	.reset(reset),
	
	.msg_out(IO_msg_out[0]),
	.msg_received(IO_msg_received[0]),
	.request_out(IO_request_out[0])
	);
	
	
	always @ (*) begin			//to update output
		output_port = {IO_request_out[1], IO_request_out[0], IO_msg_out[1], IO_msg_out[0]};
		if(IO_msg_received[1][MSG_SIZE])
			$display("Node %d received data %h from node %d on lane 1.", NODE_NUMBER, IO_msg_received[1][ACTUAL_MESSAGE_SIZE - 1:0], IO_msg_received[1][MSG_SIZE - 1:ACTUAL_MESSAGE_SIZE]);
		if(IO_msg_received[0][MSG_SIZE])
			$display("Node %d received data %h from node %d on lane 0.", NODE_NUMBER, IO_msg_received[0][ACTUAL_MESSAGE_SIZE - 1:0], IO_msg_received[0][MSG_SIZE - 1:ACTUAL_MESSAGE_SIZE]);
	end
	
	always @ (posedge clk) begin
		if(!reset) begin
			feedback_shift_reg[9] = feedback_shift_reg[0];
			feedback_shift_reg[8] = feedback_shift_reg[9];
			feedback_shift_reg[7] = feedback_shift_reg[8];
			feedback_shift_reg[6] = feedback_shift_reg[7];
			feedback_shift_reg[5] = feedback_shift_reg[6] ^ feedback_shift_reg[0];
			feedback_shift_reg[4] = feedback_shift_reg[5] ^ feedback_shift_reg[0];
			feedback_shift_reg[3] = feedback_shift_reg[4] ^ feedback_shift_reg[0];
			feedback_shift_reg[2] = feedback_shift_reg[3] ^ feedback_shift_reg[0];
			feedback_shift_reg[1] = feedback_shift_reg[2] ^ feedback_shift_reg[0];
			feedback_shift_reg[0] = feedback_shift_reg[1];
		end
		else begin
			output_port = 0;
			feedback_shift_reg = RADOM_SEED;
		end
	end

endmodule