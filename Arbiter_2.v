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
	wire	[5:0]					main_signal;
	wire	[2:0]					loop_signal;					//case used to control whether to loop
    
    reg     [NODE_SIGNAL_IN - 2:0]      destination;                //to store the destination the node wants to send to
    reg                             	unfinish_flag;              //to indicate if there is an unfinished request (send is granted, no receive set yet)
    reg     [NODE_SIGNAL_IN - 2:0]      priority_counter;           //incremented every clk cycle to indicate which node has priority
    reg     [NODE_SIGNAL_IN - 2:0]      inner_counter;              //increment after the corresponding node is dealt with, indicating which bit arbiter is dealing with
    reg     [NODE_SIGNAL_IN - 2:0]      send_control;               //signal corresponding node to send
    reg     [NODE_SIGNAL_IN - 2:0]      receive_control;            //signal corresponding node to receive
    reg     [NODE_SIGNAL_IN - 2:0]      bypass_control;             //signal corresponding node to bypass, exclusive with the two above
    reg     [NODE_SIGNAL_IN - 2:0]      requests;                   //nodes with request to send
    reg                             	on_off;                     //on off switch for the arbiter logic
    reg     [NODE_SIGNAL_IN - 1:0]      first_grant;                //records first node to send, first bit is valid.
    
    assign input_sig[0] = request_port[3:0];                        //split input by node
    assign input_sig[1] = request_port[7:4];
    assign input_sig[2] = request_port[11:8];
    assign input_sig[3] = request_port[15:12];
    assign input_sig[4] = request_port[19:16];
    assign input_sig[5] = request_port[23:20];
    assign input_sig[6] = request_port[27:24];
    assign input_sig[7] = request_port[31:28];
	
	assign main_signal = {unfinish_flag, requests[inner_counter], destination == inner_counter, first_grant[NODE_SIGNAL_IN - 1], inner_counter == first_grant[NODE_SIGNAL_IN - 2:0], | requests};
	assign loop_signal = {first_grant[NODE_SIGNAL_IN - 1] && (inner_counter == first_grant[NODE_SIGNAL_IN - 2:0]), unfinish_flag, |requests};
    
    always @ (posedge on_off) begin
        // inner_counter = priority_counter;
        // while(on_off && (requests || unfinish_flag)) begin
            // if (unfinish_flag) begin                                 //if there is an unfinished request
                // if(inner_counter == destination) begin
                    // receive_control = receive_control | inner_counter;
                    // unfinish_flag = 0;
                    // end
                // else
                    // bypass_control = bypass_control | inner_counter;
            // end
            // if((inner_counter & requests) && !unfinish_flag) begin   //if there is a request on the corresponding node
                // send_control = send_control | inner_counter;        //grant the request to send
                // unfinish_flag = 1;                                  //raise the unfinished flag
                // requests = requests ^ inner_counter;                //clear the request
                // destination = (inner_counter[0]) ? input_sig[0][7:0] : ((inner_counter[1]) ? input_sig[1][7:0] : ((inner_counter[2]) ? input_sig[2][7:0] : ((inner_counter[3]) ? input_sig[3][7:0] : ((inner_counter[4]) ? input_sig[4][7:0] : ((inner_counter[5]) ? input_sig[5][7:0] : ((inner_counter[6]) ? input_sig[6][7:0] : input_sig[7][7:0]))))));
                // first_grant = (first_grant[NODE_COUNT]) ? first_grant : {1'b1, inner_counter};
            // end
            // inner_counter = {inner_counter[6:0],inner_counter[7]};  //rotate the inner counter
            // if (inner_counter == first_grant[NODE_COUNT - 1:0]) begin                 //if the loop has finished
                // on_off = 0;
                // if (unfinish_flag) begin
                    // receive_control = receive_control | inner_counter;
                    // unfinish_flag = 0;
                // end
            // end
        // end
        // control_port = {send_control, receive_control, bypass_control};
        // first_grant[NODE_COUNT] = 0;
        // on_off = 0;
		on_off = 0;
		
		case(main_signal)
			4'b0100: 			
				send_control[inner_counter] = 1;						//first grant
				unfinish_flag = 1;
				destination = input_sig[inner_counter][2:0];
				first_grant = {1'b1, inner_counter}
				requests[inner_counter] = 0;
				inner_counter = (inner_counter == 7) ? 0 : inner_counter + 1;
								
			4'b0101:
				send_control[inner_counter] = 1;						//grant
				unfinish_flag = 1;
				destination = input_sig[inner_counter][2:0];
				requests[inner_counter] = 0;
				inner_counter = (inner_counter == 7) ? 0 : inner_counter + 1;
								
			4'b1001, 4'b1101:
				bypass_control[inner_counter] = 1;						//bypass
				inner_counter = (inner_counter == 7) ? 0 : inner_counter + 1;
			
			4'b1011, 4'b1111:
				receive_control[inner_counter] = 1;						//receive
				unfinish_flag = 0;
				on_off = 1;										//start the process again after receiving to grant potential send requests
		endcase
		
    end
	
	always @ (inner_counter) begin
		case(loop_signal)
			3'b001, 3'b010, 3'b011:
				on_off = 1;
				
			3'b110:
				receive_control[inner_counter] = 1;	
				unfinish_flag = 0;
		endcase
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
        end
        else begin
            priority_counter = 0;
            requests = 8'b00000000;
            on_off = 0;
            unfinish_flag = 0;
            first_grant = 0;
            send_control = 0;
            receive_control = 0;
            bypass_control = 0;
            destination = 0;
        end
    end
    
endmodule