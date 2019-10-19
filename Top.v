module Top #(
	parameter NODE_COUNT = 8;
	parameter NODE_COUNT_DIGIT = 3,
	parameter ACTUAL_MESSAGE_SIZE = 16,
	parameter MSG_SIZE = ACTUAL_MESSAGE_SIZE + NODE_COUNT_DIGIT * 2,
	parameter ARBITER_TO_NODE_SIG = 3,
	parameter NODE_TO_ARBITER_SIG = NODE_COUNT_DIGIT + 1,
	parameter TOTAL_NODE_IN = (MSG_SIZE + ARBITER_TO_NODE_SIG) * 2,
	parameter TOTAL_NODE_OUT = (MSG_SIZE + NODE_TO_ARBITER_SIG) * 2,
	parameter TOTAL_ARBITER_IN = NODE_COUNT * NODE_TO_ARBITER_SIG,
	parameter TOTAL_ARBITER_OUT = NODE_COUNT * ARBITER_TO_NODE_SIG
	
)
(
	input	wire	clk;
	input	wire	reset;
)

	wire	[ARBITER_TO_NODE_SIG - 1:0]		arbiter_to_node_1[NODE_COUNT - 1:0];
	wire    [ARBITER_TO_NODE_SIG - 1:0]		arbiter_to_node_0[NODE_COUNT - 1:0];
	wire	[NODE_TO_ARBITER_SIG - 1:0]		node_to_arbiter_1[NODE_COUNT - 1:0];
	wire    [NODE_TO_ARBITER_SIG - 1:0]		node_to_arbiter_0[NODE_COUNT - 1:0]
	wire    [MSG_SIZE - 1:0]				node_msg_1[NODE_COUNT - 2:0];
	wire	[MSG_SIZE - 1:0]				node_msg_0[NODE_COUNT - 2:0];
	wire	[TOTAL_NODE_IN - 1:0]			node_in[NODE_COUNT - 1:0];
	wire	[TOTAL_NODE_OUT - 1:0]			node_out[NODE_COUNT - 1:0];
	wire	[TOTAL_ARBITER_IN - 1:0]		arbiter_in_1[NODE_COUNT - 1:0];
	wire    [TOTAL_ARBITER_IN - 1:0]		arbiter_in_0[NODE_COUNT - 1:0];
	wire	[TOTAL_ARBITER_OUT - 1:0]		arbiter_out_1[NODE_COUNT - 1:0];
	wire    [TOTAL_ARBITER_OUT - 1:0]       arbiter_out_0[NODE_COUNT - 1:0];
	wire	[NODE_COUNT - 1:0]				control_sig_1[2:0];	//2 is send, 1 is receive, 0 is bypass
	wire    [NODE_COUNT - 1:0]				control_sig_0[2:0];
	
	assign control_sig_1[2] = arbiter_out_1[TOTAL_ARBITER_OUT - 1:NODE_COUNT * 2];
	assign control_sig_1[1] = arbiter_out_1[NODE_COUNT * 2 -1:NODE_COUNT];
	assign control_sig_1[0] = arbiter_out_1[NODE_COUNT - 1:0];

	assign control_sig_0[2] = arbiter_out_0[TOTAL_ARBITER_OUT - 1:NODE_COUNT * 2];
	assign control_sig_0[1] = arbiter_out_0[NODE_COUNT * 2 -1:NODE_COUNT];
	assign control_sig_0[0] = arbiter_out_0[NODE_COUNT - 1:0];

	integer a;
	for (a = 0; a < NODE_COUNT - 1:0) begin
		assign arbiter_in_1[NODE_TO_ARBITER * (NODE_COUNT - a) - 1:NODE_TO_ARBITER * (NODE_COUNT - a - 1)] = node_to_arbiter_1[a];
		assign arbiter_in_0[NODE_TO_ARBITER * (a + 1) - 1:NODE_TO_ARBITER * a] = node_to_arbiter_0[a];
		assign arbiter_to_node_1[a] = {control_sig_1[2][NODE_COUNT - a - 1], control_sig_1[1][NODE_COUNT - a - 1], control_sig_1[0][NODE_COUNT - a - 1]};
		assign arbiter_to_node_0[a] = {control_sig_0[2][a], control_sig_0[1][a], control_sig_0[0][a]};
		assign node_in[a] = {arbiter_to_node_1[a], arbiter_to_node_0[a], node_msg_1, node_msg_0};
		assign node_to_arbiter_1[a] = node_out[a][TOTAL_NODE_OUT - 1:TOTAL_NODE_OUT - NODE_TO_ARBITER_SIG];
		assign node_to_arbiter_0[a] = node_out[a][TOTAL_NODE_OUT - NODE_TO_ARBITER_SIG - 1:MSG_SIZE * 2];
		assign node_msg_1[NODE_COUNT - a - 2] = node_out[a + 1][MSG_SIZE * 2 - 1:MSG_SIZE];
		assign node_msg_0[a] = node_out[a][MSG_SIZE - 1:0];
	end

	genvar i;
	generate
		for (i = 0; i < NODE_COUNT; i = i + 1) begin : NODE
			Node #(
			.NODE_NUMBER(i),
			.NODE_COUNT(NODE_COUNT),
			.NODE_COUNT_DIGIT(NODE_COUNT_DIGIT),
			.ACTUAL_MESSAGE_SIZE(ACTUAL_MESSAGE_SIZE),
			.ARBITER_SIGNAL_IN(ARBITER_TO_NODE_SIG),
			.ARBITER_SIGNAL_OUT(NODE_TO_ARBITER_SIG)
			)
			Interposer_Node(
			.input_port(node_in[i]),
			.clk(clk),
			.reset(reset),

			.output_port(node_out[i])
			);
		end
	endgenerate
	
	Arbiter Arbiter_1(			//the high to low arbiter
	.request_port(arbiter_in_1),
	.clk(clk),
	.reset(reset),

	.control_port(arbiter_out_1)
	);

	Arbiter Arbiter_0(
	.request_port(arbiter_in_0),
        .clk(clk),
        .reset(reset),

        .control_port(arbiter_out_0)
	);
