/* verilator lint_off MODDUP */
`include "SystemVerilog-UART/rtl/uart_rx.sv"
/* verilator lint_on MODDUP */

module uart_sha
  /* verilator lint_off UNDRIVEN */
  ( 
    input clk,
    input in_rst,
    input in_uart_rxd,
    output out_uart_txd
  );

  /* verilator lint_off UNUSED */
  logic sha_in_valid;
  logic [63:0][7:0] sha_in_data;
  logic [7:0][31:0] sha_in_state;
  logic [31:0][7:0] sha_in_target;
  logic [31:0] sha_in_nonce_base;
  logic [31:0] sha_in_position;

  logic sha_out_valid;
  logic [31:0][7:0] sha_out_result;
  logic [31:0] sha_out_nonce_found;
  /* verilator lint_off UNDRIVEN */

  logic rstn;
  logic sha_rst;
  logic [7:0] uart_rx_data;

  logic [7:0] receive_cnt;
  logic [31:0][7:0] receive_buf;
  logic [7:0] send_cnt;

  typedef enum logic [1:0] {STT_WAIT_HANDSHAKE,
                            STT_RECEIVE_DATA,
                            STT_HASHING,
                            STT_SEND_RESULT
                            } statetype;

   statetype                 state;

  sha256_double sha256_double_p(.clk(clk),
      .rst(sha_rst),
      .in_valid(sha_in_valid),
      .in_data(sha_in_data),
      .in_state(sha_in_state),
      .in_nonce_base(sha_in_nonce_base),
      .in_target(sha_in_target),
      .in_position(sha_in_position),
      .out_valid(sha_out_valid),
      .out_result(sha_out_result),
      .out_nonce_found(sha_out_nonce_found)
  );
  /* verilator lint_on UNUSED */

   localparam DATA_WIDTH = 8;
   localparam BAUD_RATE  = 115200;
   localparam CLK_FREQ   = 100_000_000;

   uart_if #(DATA_WIDTH) rxif();
   uart_rx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ) urx(.rxif(rxif),
                                                  .clk(clk),
                                                  .rstn(rstn));

   uart_if #(DATA_WIDTH) txif();
   uart_tx #(DATA_WIDTH, BAUD_RATE, CLK_FREQ) utx(.txif(txif),
                                                  .clk(clk),
                                                  .rstn(rstn));
  assign rxif.sig = in_uart_rxd;
  assign rstn = ~in_rst;
  assign out_uart_txd = txif.sig;

  assign uart_rx_data = rxif.data;

  always_ff @ (posedge clk) begin
      if (in_rst) begin
          state <= STT_WAIT_HANDSHAKE;
          rxif.ready <= 1;
          receive_cnt <= 0;
          sha_rst <= 1;
      end
      if (rxif.valid) begin
          if(rxif.data == "R") begin // reset
              sha_rst <= 1;
              txif.data  <= "O";
              txif.valid <= 1;
              rxif.ready <= 0;
              receive_cnt <= 0;
              state <= STT_WAIT_HANDSHAKE;
          end else if(rxif.data == "H") begin // hello
              sha_rst <= 0;
              txif.data  <= "1";
              txif.valid <= 1;
              rxif.ready <= 0;
              receive_cnt <= 0;
              state <= STT_RECEIVE_DATA;
          end else begin
              case(state)
                  STT_WAIT_HANDSHAKE: begin
                      txif.data  <= "E";
                      txif.valid <= 1;
                      rxif.ready <= 0;
                  end

                  STT_RECEIVE_DATA: begin
                      sha_rst <= 0;
                      txif.valid <= 0;
                      receive_cnt <= receive_cnt + 1;
                      if(receive_cnt < 64) begin
                          sha_in_data[receive_cnt] <= rxif.data;
                      end else if(receive_cnt < 96) begin
                          receive_buf[receive_cnt - 64] <= rxif.data;
                      end else if(receive_cnt < 128) begin
                          if(receive_cnt == 96) begin
                              sha_in_state <= {>>{receive_buf}};
                          end
                          sha_in_target[receive_cnt - 96] <= rxif.data;
                      end else if(receive_cnt < 132) begin
                          receive_buf[receive_cnt - 128] <= rxif.data;
                      end else if(receive_cnt < 136) begin
                          if(receive_cnt == 132) begin
                              sha_in_nonce_base <= {>>{receive_buf[3:0]}};
                          end
                          receive_buf[receive_cnt - 132] <= rxif.data;
                      end
                  end

                  default: begin
                      txif.data <= "e";
                      txif.valid <= 1;
                      rxif.ready <= 0;
                      state <= STT_WAIT_HANDSHAKE;
                  end
              endcase
          end
      end else if (state == STT_RECEIVE_DATA && receive_cnt == 136) begin
          sha_in_position <= {>>{receive_buf[3:0]}};
          txif.data <= "S";
          txif.valid <= 1;
          rxif.ready <= 0;
          state <= STT_HASHING;
          sha_in_valid <= 1;
      end else if (state == STT_HASHING && sha_out_valid) begin
          send_cnt <= 0;
          rxif.ready <= 0;
          state <= STT_SEND_RESULT;
          txif.data <= "Y";
          txif.valid <= 1;
      end else if(state == STT_SEND_RESULT) begin
          if(txif.ready) begin
              txif.data <= sha_out_nonce_found[8 * send_cnt +: 8];
              if(send_cnt < 4) begin
                  send_cnt <= send_cnt + 1;
              end else begin
                  rxif.ready <= 1;
                  receive_cnt <= 0;
                  state <= STT_WAIT_HANDSHAKE;
                  sha_rst <= 1;
              end
          end
      end else begin
          txif.valid <= 0;
          rxif.ready <= 1;
          sha_in_valid <= 0;
      end
  end

endmodule
