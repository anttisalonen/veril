module sha256_double
  ( 
    input clk,
    input rst,
    input in_valid,
    /* verilator lint_off UNUSED */
    input  logic [63:0][7:0] in_data,
    input  logic [7:0][31:0] in_state,
    input  logic [31:0] in_nonce_base,
    input  logic [31:0][7:0] in_target,
    input  logic [31:0] in_position,
    /* verilator lint_on UNUSED */

    output              out_valid,
    output logic [31:0][7:0] out_result,
    output logic [31:0] out_nonce_found
  );

  logic [7:0][31:0] working_state;
  logic [63:0][7:0] working_input;
  logic tumble_out_valid_r;
  logic [7:0][31:0] tumble_res_r;
  logic tumble_in_valid;
  logic [31:0][7:0] intermediate_data;
  logic sha_in_valid;
  logic sha_running;
  logic sha_out_valid;
  logic [31:0][7:0] final_result;
  logic [31:0] this_nonce;
  logic nonce_found;

  tumble tumble_p(.clk(clk),
	  .rst(rst),
	  .in_valid(tumble_in_valid),
	  .state0(working_state[0]),
	  .state1(working_state[1]),
	  .state2(working_state[2]),
	  .state3(working_state[3]),
	  .state4(working_state[4]),
	  .state5(working_state[5]),
	  .state6(working_state[6]),
	  .state7(working_state[7]),
	  .in_data(working_input),
	  .out_valid(tumble_out_valid_r),
	  .out_res(tumble_res_r)
  );

  sha256 sha256_p(.clk(clk),
      .rst(rst),
      .in_valid(sha_in_valid),
      .in_data(intermediate_data),
      .out_valid(sha_out_valid),
      .out_res(final_result)
  );

  // Register all inputs
  always_ff @ (posedge clk, posedge rst) begin
      if (rst) begin
		  working_state <= in_state;
		  working_input <= '0;
		  tumble_in_valid <= 0;
          nonce_found <= 0;
          this_nonce <= in_nonce_base;
          sha_in_valid <= 0;
          sha_running <= 0;
      end else if(in_valid) begin
          // start
		  working_input[11:0] <= in_data[11:0];
          working_input[15:12] <= this_nonce;
		  working_input[63:16] <= in_data[63:16];
		  tumble_in_valid <= 1;
          nonce_found <= 0;
          sha_running <= 0;
	  end else if (~nonce_found && tumble_out_valid_r && ~in_valid && ~tumble_in_valid && ~sha_running && ~sha_in_valid) begin
          // move to sha
          sha_in_valid <= 1;
          intermediate_data <= tumble_res_r;
		  tumble_in_valid <= 0;
          sha_running <= 1;
	  end else if(~nonce_found && sha_running && ~sha_out_valid) begin
          // sha running
          sha_in_valid <= 0;
		  tumble_in_valid <= 0;
	  end else if(~nonce_found && sha_out_valid && ~tumble_in_valid && sha_running && ~sha_in_valid) begin
          // sha finished
          sha_running <= 0;
          if(final_result < in_target) begin
              $display("%b", final_result);
              $display("%b", in_target);
              nonce_found <= 1;
          end else begin
              this_nonce <= this_nonce + 1;
              working_input[15:12] <= this_nonce + 1;
              tumble_in_valid <= 1;
              nonce_found <= 0;
          end
          sha_in_valid <= 0;
	  end else begin
          sha_in_valid <= 0;
		  tumble_in_valid <= 0;
	  end
  end

  // Register outputs
  always_ff @ (posedge clk, posedge rst) begin
          if (rst) begin
                  out_valid <= '0;
                  out_result   <= '0;
                  out_nonce_found <= '0;
          end else begin
              if (in_valid) begin
                  out_valid <= '0;
                  out_nonce_found <= '0;
              end else if (nonce_found) begin
                  out_valid <= '1;
                  out_nonce_found <= this_nonce;
                  out_result <= final_result;
                  $display("%b", final_result);
              end else begin
                  out_valid <= '0;
                  out_nonce_found <= '0;
              end
          end
  end

endmodule
