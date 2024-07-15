module avalon_sampler #(
	parameter int unsigned CAPACITY = 2,
	parameter bit SUPPRESS_WARNING = 0
) (
	input logic clk,    // Clock
	input logic rst_n,  // Asynchronous reset active low
	
	avalon_st_if.slave  msg_in,
	avalon_st_if.master msg_out,
);
	// Assertions
	initial begin
		if (msg_in.DATA_WIDTH != msg_out.DATA_WIDTH) begin
			$error("interfaces data width mismatch!");
			$fatal();
		end

		if (CAPACITY == 0) begin
			$error("CAPACITY can't be 0!");
			$fatal();
		end

		if (CAPACITY == 1) begin
			$warning("CAPACITY == 1 results in a half-rate sampler, meaning this module can cut down throughput by up to 50\%.\n
If this is intentional, set parameter SUPPRESS_WARNING to '1'");
		end

		if (CAPACITY > 16) begin
			$warning("For larger data capacities, it is advised you use a dedicated FIFO module.\n
If this is intentional, set parameter SUPPRESS_WARNING to '1'");
		end
	end

	// Constants
	localparam int PAYLOAD_WIDTH = msg_in.DATA_WIDTH + msg_in.META_WIDTH;

	// Declerations
	logic [PAYLOAD_WIDTH-1:0] payload_in;
	logic [PAYLOAD_WIDTH-1:0] payload_out;

	logic [CAPACITY:0] one_hot;
	logic              in_tran, out_tran;

	logic [CAPACITY-1:0] load_en;

	// Logic
	begin : conc
		assign payload_in = {msg_in.data, msg_in.empty, msg_in.sop, msg_in.eop};
		assign {msg_out.data, msg_out.empty, msg_out.sop, msg_out.eop} = payload_out;
	end

	begin : onehot_sm
		assign in_tran  = msg_in.vld & msg_in.rdy;
		assign out_tran = msg_out.vld & msg_out.rdy;

		_one_hot #(
			.ONEHOT_WIDTH(CAPACITY + 1),
			.POLARITY    (1'b0        )
		) i_one_hot (
			.clk     (clk     ),
			.rst_n   (rst_n   ),
			.inc     (in_tran ),
			.dec     (out_tran),
			.data_out(one_hot )
		);

		assign msg_in.rdy  = one_hot[CAPACITY];
		assign msg_out.vld = one_hot[0];
	end

	begin : payload_sr		
		assign load_en = {CAPACITY{in_tran}} & (~one_hot >> out_tran); // As we actually want to write into the previous index if reading occours

		generate
			for (int i = 0; i < PAYLOAD_WIDTH; i++) begin
				_shift_reg #(.REG_WIDTH(CAPACITY)) i_shift_reg (
					.clk      (clk           ),
					.rst_n    (rst_n         ),
					.load_data(payload_in[i] ),
					.load_en  (load_en       ),
					.sh       (out_tran      ),
					.data_out (payload_out[i])    // This should take only the LSB bit of the shift-register
				);
			end
		endgenerate
	end

endmodule : avalon_sampler


module _shift_reg #(
	parameter unsigned int REG_WIDTH
) (
	input logic clk,    // Clock
	input logic rst_n,  // Asynchronous reset active low
	
	input logic load_data,
	input logic [REG_WIDTH-1:0] load_en, // One-hot index
	input logic sh,

	output logic [REG_WIDTH:0] data_out  // Extra const-0 bit at the end (can be ignored)
);
	
	always_ff @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			data_out[REG_WIDTH] <= 1'b0;
	end

	generate
		for (int i = 0; i < REG_WIDTH; i++) begin
			always_ff @(posedge clk or negedge rst_n) begin
				if(~rst_n) begin
					data_out[i] <= 1'b0;
				end else begin
					if (load_en[i]) begin
						data_out[i] <= load_data;
					end else if (sh) begin
						data_out[i] <= data_out[i+1];
					end
				end
			end			
		end
	endgenerate

endmodule : _shift_reg


module _one_hot #(
	parameter unsigned int ONEHOT_WIDTH,
	parameter bit POLARITY = 1'b1 // i.e. one-hot shifts around a '1' value by default
) (
	input logic clk,    // Clock
	input logic rst_n,  // Asynchronous reset active low
	
	input logic inc,
	input logic dec,

	output logic [ONEHOT_WIDTH-1:0] data_out
);

	always_ff @(posedge clk or negedge rst_n) begin
		if(~rst_n) begin
			data_out[0] <= POLARITY;
			data_out[ONEHOT_WIDTH-1:1] <= {(ONEHOT_WIDTH-1){~POLARITY}};
		end else begin
			if (inc & ~dec) begin
				data_out <= data_out << 1;
				data_out[0] <= ~POLARITY;
			end

			if (~inc & dec) begin
				data_out <= data_out >> 1;
				data_out[ONEHOT_WIDTH-1] <= ~POLARITY;
			end
		end
	end

endmodule : _one_hot