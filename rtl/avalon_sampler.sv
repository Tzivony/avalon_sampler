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
			$warning("For larger data capacities, it is advised you use a desicated FIFO module.\n
If this is intentional, set parameter SUPPRESS_WARNING to '1'");
		end
	end


endmodule : avalon_sampler