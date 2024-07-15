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