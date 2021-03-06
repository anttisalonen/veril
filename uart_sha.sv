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

  localparam NUM_SHA_UNITS = 12;
  logic [$clog2(NUM_SHA_UNITS):0] unit_found_nonce;

  /* verilator lint_off UNUSED */
  logic sha_in_valid;
  logic [11:0][7:0] sha_in_data;
  logic [7:0][31:0] sha_in_state;
  logic [31:0][7:0] sha_in_target;
  logic [NUM_SHA_UNITS-1:0][31:0] sha_in_nonce_bases;
  logic [31:0] sha_in_position;

  logic [NUM_SHA_UNITS-1:0] sha_out_valids;
  logic [NUM_SHA_UNITS-1:0] sha_out_exhausteds;
  logic [NUM_SHA_UNITS-1:0][31:0] sha_out_nonce_founds;
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

  sha256_double sha256_double_p[NUM_SHA_UNITS-1:0](.clk(clk),
      .rst(sha_rst),
      .in_valid(sha_in_valid),
      .in_data(sha_in_data),
      .in_state(sha_in_state),
      .in_nonce_base(sha_in_nonce_bases),
      .in_target(sha_in_target),
      .in_position(sha_in_position),
      .out_valid(sha_out_valids),
      .out_nonce_found(sha_out_nonce_founds),
      .out_exhausted(sha_out_exhausteds)
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
  
  always_comb begin
      unit_found_nonce = 0;
      for(int i = 0; i < NUM_SHA_UNITS; i++) begin
          if(sha_out_valids[i]) begin
              unit_found_nonce = i[$clog2(NUM_SHA_UNITS):0];
          end
      end
  end

  always_ff @ (posedge clk) begin
      if (in_rst) begin
          state <= STT_WAIT_HANDSHAKE;
          rxif.ready <= 1;
          txif.valid <= 0;
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
                      sha_rst <= 1;
                      txif.data  <= "E";
                      txif.valid <= 1;
                      rxif.ready <= 1;
                  end

                  STT_RECEIVE_DATA: begin
                      sha_rst <= 0;
                      txif.valid <= 0;
                      receive_cnt <= receive_cnt + 1;
                      if(receive_cnt < 12) begin
                          sha_in_data[receive_cnt] <= rxif.data;
                      end else if(receive_cnt < 44) begin
                          receive_buf[receive_cnt - 12] <= rxif.data;
                      end else if(receive_cnt < 76) begin
                          if(receive_cnt == 44) begin
                              sha_in_state <= {>>{receive_buf}};
                          end
                          sha_in_target[receive_cnt - 44] <= rxif.data;
                      end else if(receive_cnt < 80) begin
                          receive_buf[receive_cnt - 76] <= rxif.data;
                      end else if(receive_cnt < 84) begin
                          if(receive_cnt == 80) begin
                              for(int i = 0; i < NUM_SHA_UNITS; i++) begin
                                  sha_in_nonce_bases[i] <= {>>{receive_buf[3:0]}};
                              end
                          end
                          receive_buf[receive_cnt - 80] <= rxif.data;
                      end
                  end

                  default: begin
                      txif.data <= "e";
                      txif.valid <= 1;
                      rxif.ready <= 1;
                      state <= STT_WAIT_HANDSHAKE;
                      sha_rst <= 1;
                  end
              endcase
          end
      end else if (state == STT_RECEIVE_DATA && receive_cnt == 84) begin
          for(int i = 0; i < NUM_SHA_UNITS; i++) begin
              // at 100 MHz, about 1.4s until units start
              // to overlap
              sha_in_nonce_bases[i] <= sha_in_nonce_bases[i] + i * 32'h200000;
          end
          sha_in_position <= {>>{receive_buf[3:0]}};
          txif.data <= "S";
          txif.valid <= 1;
          rxif.ready <= 0;
          state <= STT_HASHING;
          sha_in_valid <= 1;
      end else if (state == STT_HASHING && (|sha_out_valids || |sha_out_exhausteds)) begin
          send_cnt <= 0;
          rxif.ready <= 0;
          state <= STT_SEND_RESULT;
          txif.data <= |sha_out_valids ? "Y" : "N";
          txif.valid <= 1;
      end else if(state == STT_SEND_RESULT) begin
          if(txif.ready) begin
              txif.data <= sha_out_nonce_founds[unit_found_nonce][8 * send_cnt +: 8];
              if(send_cnt < 4 && |sha_out_valids) begin
                  send_cnt <= send_cnt + 1;
              end else begin
                  txif.valid <= 0;
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
          sha_rst <= 0;
      end
  end

endmodule
