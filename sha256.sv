module sha256
  ( 
    input clk,
    input rst,
    input in_valid,
    input  logic [31:0][7:0] in_data,

    output reg             out_valid,
    output reg [31:0][7:0] out_res
  );

  logic [63:0][7:0] data;
  logic tumble_out_valid_r;
  logic [7:0][31:0] tumble_res_r;
  logic tumble_in_valid;

  /* verilator lint_off LITENDIAN */
  localparam logic [0:7][31:0] state = {
	  32'h6a09e667,
	  32'hbb67ae85,
	  32'h3c6ef372,
	  32'ha54ff53a,
	  32'h510e527f,
	  32'h9b05688c,
	  32'h1f83d9ab,
	  32'h5be0cd19
  };
  /* verilator lint_on LITENDIAN */

  tumble tumble_p(.clk(clk),
	  .rst(rst),
	  .in_valid(tumble_in_valid),
	  .state0(state[0]),
	  .state1(state[1]),
	  .state2(state[2]),
	  .state3(state[3]),
	  .state4(state[4]),
	  .state5(state[5]),
	  .state6(state[6]),
	  .state7(state[7]),
	  .in_data(data),
	  .out_valid(tumble_out_valid_r),
	  .out_res(tumble_res_r)
  );

  // Register all inputs
  always_ff @ (posedge clk) begin
          if (rst) begin
		  data <= '0;
		  tumble_in_valid <= 0;
          end else if(in_valid) begin
		  data[31:0] <= in_data;
		  data[32]   <= '0;
		  data[33]   <= '0;
		  data[34]   <= '0;
		  data[35]   <= 8'h80;
		  for(int i = 36; i < 60; i++) begin
			  data[i] <= '0;
		  end
		  data[60]   <= 8'h00;  // bitlen = 256 = 0x0100
		  data[61]   <= 8'h01;
		  data[62]   <= 8'h00;
		  data[63]   <= 8'h00;
		  tumble_in_valid <= 1;
	  end else begin
		  tumble_in_valid <= 0;
	  end
  end

  // Register outputs
  always_ff @ (posedge clk) begin
          if (rst) begin
                  out_valid <= '0;
                  out_res   <= '0;
          end else begin
		  if (in_valid) begin
                      out_valid <= '0;
	          end else if (tumble_out_valid_r && ~in_valid && ~tumble_in_valid) begin
		      out_res <= tumble_res_r;
                      out_valid <= '1;
		  end else begin
                      out_valid <= '0;
	          end
          end
  end

endmodule
