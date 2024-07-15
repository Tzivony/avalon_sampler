module avalon_sampler_tb ();
	// Constants
	localparam int unsigned CAPACITY = 2;
	localparam int unsigned DATA_WIDTH_IN_BYTES = 1;

	// Declerations
	logic clk   = 1'b1;
	logic rst_n = 1'b1;	
	avalon_st_if #(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) msg_in ();
	avalon_st_if #(.DATA_WIDTH_IN_BYTES(DATA_WIDTH_IN_BYTES)) msg_out();

	// DUT
	avalon_sampler #(.CAPACITY(CAPACITY)) i_avalon_sampler (
		.clk    (clk    ),
		.rst_n  (rst_n  ),
		.msg_in (msg_in ),
		.msg_out(msg_out)
	);


	// Stimulus
	initial begin
		msg_in.data = '{default:0};
		msg_in.vld = 1'b0;
		msg_in.sop = 1'b0;
		msg_in.eop = 1'b0;
		msg_in.empty = '{default:0};

		@(negedge rst_n);
		@(posedge clk);

		msg_in.data = 'hAA;
		msg_in.vld = 1'b1;
		@(posedge clk);

		msg_in.data = 'hBB;
		@(posedge clk);

		msg_in.data = 'hCC;
		@(posedge clk);

		msg_in.data = 'hDD;
		@(posedge clk);

		msg_in.data = 'hEE;
		@(posedge clk);

		msg_in.data = 'hFF;
		@(posedge clk);

		msg_in.vld = 1'b0;
		@(posedge clk);
		@(posedge clk);

		msg_in.vld = 1'b1;
		msg_in.data = 'h11;
		@(posedge clk);

		msg_in.data = 'h22;
		@(posedge clk);

		msg_in.data = 'h33;
		@(posedge clk);

		msg_in.data = 'h44;
		@(posedge clk);

		msg_in.vld = 1'b0;

		#10000;
	end

	initial begin
		msg_out.rdy = 1'b0;

		@(negedge rst_n);
		@(posedge clk);

		repeat (9) begin
			msg_out.rdy <= ~msg_out.rdy;
			@(posedge clk);
		end

		msg_out.rdy <= 1'b1;
	end

	// Clock
	always #0.5 clk = ~clk;

	// Reset
	initial begin
		@(posedge clk);
		rst_n <= 1'b0;
		@(posedge clk);
		rst_n <= 1'b1;
	end

endmodule : avalon_sampler_tb