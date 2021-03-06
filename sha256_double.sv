module sha256_double
  ( 
    input clk,
    input rst,
    input in_valid,
    input  logic [11:0][7:0] in_data,
    input  logic [7:0][31:0] in_state,
    input  logic [31:0] in_nonce_base,
    input  logic [31:0][7:0] in_target,
    /* verilator lint_off UNUSED */
    input  logic [31:0] in_position,
    /* verilator lint_on UNUSED */

    output reg             out_valid,
    output reg [31:0] out_nonce_found,
    output reg        out_exhausted
  );

  localparam NUM_SHA_UNITS = 12;
  localparam MAX_NONCE_CNT = 32'hfffffffe / NUM_SHA_UNITS;
  
  logic [7:0][31:0] working_state;
  logic [63:0][7:0] working_input;
  logic tumble_out_valid_r;
  logic [7:0][31:0] tumble_res_r;
  logic tumble_in_valid;
  logic [31:0][7:0] sha_in_data;
  logic sha_in_valid;
  logic sha_out_valid;
  logic [31:0][7:0] final_result;
  logic [31:0][7:0] byte_reversed_final_result;
  logic [31:0] tumble_nonce;
  logic [31:0] sha_nonce;
  logic nonce_found;
  logic [31:0] nonce_cnt;

  // states:
  // idle (reset)
  // just tumble running
  // tumbla+sha running
  // just sha running
  // transitions:
  // idle -> tumble when in_valid
  // tumble -> both when tumble finishes (tumble_out_valid_r)
  // both -> tumble when sha finishes (sha_out_valid)
  // both -> sha when tumble finishes (tumble_out_valid_r)
  // sha -> both when sha finishes (sha_out_valid)
  // any -> idle when hash found or exhausted
  typedef enum logic [1:0] {STT_IDLE,
                            STT_TUMBLE,
                            STT_BOTH,
                            STT_SHA
                            } statetype;

   statetype                 state;


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
      .in_data(sha_in_data),
      .out_valid(sha_out_valid),
      .out_res(final_result)
  );
  
  always_comb begin
        byte_reversed_final_result = {<<8{ {<<32{final_result}} }};
  end

  // Register all inputs
  always_ff @ (posedge clk) begin
      if (rst) begin
          state <= STT_IDLE;
          working_state <= '0;
          working_input <= '0;
          nonce_found <= 0;
          tumble_nonce <= '0;
          nonce_cnt <= '0;
          sha_nonce <= '0;
      end else if(in_valid) begin
          // start
          state <= STT_TUMBLE;
          working_state <= in_state;
          tumble_nonce <= in_nonce_base;
          nonce_cnt <= '0;
          working_input[11:0] <= in_data[11:0];
          working_input[15:12] <= in_nonce_base;
          working_input[63:16] <= 384'h000002800000000000000000000000000000000000000000000000000000000000000000000000000000000080000000;
          tumble_in_valid <= 1;
          nonce_found <= 0;
      end else begin
          case(state)
              STT_IDLE: begin
                  tumble_in_valid <= 0;
                  sha_in_valid <= 0;
              end

              STT_TUMBLE: begin
                  if (tumble_out_valid_r) begin
                      // move to both
                      state <= nonce_cnt > MAX_NONCE_CNT ? STT_IDLE : STT_BOTH;
                      sha_in_valid <= 1;
                      sha_nonce <= tumble_nonce;
                      sha_in_data <= tumble_res_r;
                      tumble_nonce <= tumble_nonce + 1;
                      working_input[15:12] <= tumble_nonce + 1;
                      nonce_cnt <= nonce_cnt + 1;
                      tumble_in_valid <= 1;
                  end else begin
                       tumble_in_valid <= 0;
                  end
              end

              STT_BOTH: begin
                  if (~nonce_found && tumble_out_valid_r && ~in_valid && ~tumble_in_valid) begin
                      // tumble finished
                      state <= STT_SHA;
                  end else if(~nonce_found && ~sha_out_valid) begin
                      // sha running
                      sha_in_valid <= 0;
                      tumble_in_valid <= 0;
                  end else if(~nonce_found && sha_out_valid && ~tumble_in_valid && ~sha_in_valid) begin
                      // sha finished
                      if(final_result < in_target) begin
                          nonce_found <= 1;
                          state <= STT_IDLE;
                      end else begin
                          state <= STT_TUMBLE;
                      end
                  end
              end

              STT_SHA: begin
                  if(sha_out_valid) begin
                      if(byte_reversed_final_result < in_target) begin
                          nonce_found <= 1;
                          state <= STT_IDLE;
                      end else begin
                          // sha finished, restart tumble and sha
                          tumble_nonce <= tumble_nonce + 1;
                          nonce_cnt <= nonce_cnt + 1;
                          working_input[15:12] <= tumble_nonce + 1;
                          tumble_in_valid <= 1;
                          sha_in_data <= tumble_res_r;
                          sha_in_valid <= 1;
                          sha_nonce <= tumble_nonce;
                          state <= nonce_cnt > MAX_NONCE_CNT ? STT_IDLE : STT_BOTH;
                      end
                  end
              end
          endcase
      end
  end

  // Register outputs
  always_ff @ (posedge clk) begin
          if (rst) begin
                  out_valid <= '0;
                  out_nonce_found <= '0;
                  out_exhausted <= 0;
          end else begin
              if (in_valid) begin
                  out_valid <= '0;
                  out_nonce_found <= '0;
                  out_exhausted <= 0;
              end else if (nonce_found) begin
                  out_valid <= '1;
                  out_nonce_found <= sha_nonce;
              end else begin
                  out_valid <= '0;
                  out_nonce_found <= '0;
                  if(nonce_cnt > MAX_NONCE_CNT) begin
                      out_exhausted <= 1;
                  end
              end
          end
  end

endmodule
