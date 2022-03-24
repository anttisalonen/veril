module tumble
  ( 
    input clk,
    input rst,
    input in_valid,

    input  logic [31:0] state0,
    input  logic [31:0] state1,
    input  logic [31:0] state2,
    input  logic [31:0] state3,
    input  logic [31:0] state4,
    input  logic [31:0] state5,
    input  logic [31:0] state6,
    input  logic [31:0] state7,
    input  logic [63:0][7:0] in_data,
    output              out_valid,
    output logic [7:0][31:0] out_res
  );
   
  logic [31:0] a;
  logic [31:0] b;
  logic [31:0] c;
  logic [31:0] d;
  logic [31:0] e;
  logic [31:0] f;
  logic [31:0] g;
  logic [31:0] h;
  logic [6:0]  cycle;
  logic [31:0] t1;
  logic [31:0] t2;
  logic [31:0] ep0_r;
  logic [31:0] ep1_r;
  logic [31:0] ch_r;
  logic [31:0] maj_r;
  logic [31:0] sig0_r;
  logic [31:0] sig1_r;
  logic [63:0][31:0] m;
  logic stopped;

  ep0 ep0_p(.inp(a), .res(ep0_r));
  ep1 ep1_p(.inp(e), .res(ep1_r));
  ch ch_p(.inp1(e), .inp2(f), .inp3(g), .res(ch_r));
  maj maj_p(.inp1(a), .inp2(b), .inp3(c), .res(maj_r));
  sig0 sig0_p(.inp(m[cycle - 14]), .res(sig0_r));
  sig1 sig1_p(.inp(m[cycle - 1]), .res(sig1_r));

  /* verilator lint_off LITENDIAN */
  localparam logic [0:63][31:0] k = {
	  32'h428a2f98,32'h71374491,32'hb5c0fbcf,32'he9b5dba5,32'h3956c25b,32'h59f111f1,32'h923f82a4,32'hab1c5ed5,
	  32'hd807aa98,32'h12835b01,32'h243185be,32'h550c7dc3,32'h72be5d74,32'h80deb1fe,32'h9bdc06a7,32'hc19bf174,
	  32'he49b69c1,32'hefbe4786,32'h0fc19dc6,32'h240ca1cc,32'h2de92c6f,32'h4a7484aa,32'h5cb0a9dc,32'h76f988da,
	  32'h983e5152,32'ha831c66d,32'hb00327c8,32'hbf597fc7,32'hc6e00bf3,32'hd5a79147,32'h06ca6351,32'h14292967,
	  32'h27b70a85,32'h2e1b2138,32'h4d2c6dfc,32'h53380d13,32'h650a7354,32'h766a0abb,32'h81c2c92e,32'h92722c85,
	  32'ha2bfe8a1,32'ha81a664b,32'hc24b8b70,32'hc76c51a3,32'hd192e819,32'hd6990624,32'hf40e3585,32'h106aa070,
	  32'h19a4c116,32'h1e376c08,32'h2748774c,32'h34b0bcb5,32'h391c0cb3,32'h4ed8aa4a,32'h5b9cca4f,32'h682e6ff3,
	  32'h748f82ee,32'h78a5636f,32'h84c87814,32'h8cc70208,32'h90befffa,32'ha4506ceb,32'hbef9a3f7,32'hc67178f2
  };
  /* verilator lint_on LITENDIAN */

  always_comb begin
	  t1 = h + ep1_r + ch_r + k[cycle] + m[cycle];
	  t2 = ep0_r + maj_r;
  end

  // Register all inputs
  always_ff @ (posedge clk, posedge rst) begin
          if (rst) begin
                  a      <= '0;
                  b      <= '0;
                  c      <= '0;
                  d      <= '0;
                  e      <= '0;
                  f      <= '0;
                  g      <= '0;
                  h      <= '0;
		  cycle  <= '0;
		  stopped <= 1;
          end else if(in_valid) begin
                  a      <= state0;
                  b      <= state1;
                  c      <= state2;
                  d      <= state3;
                  e      <= state4;
                  f      <= state5;
                  g      <= state6;
                  h      <= state7;
		  cycle  <= '0;
		  stopped <= 0;
		  m[15:0] <= in_data;
	  end else begin
		  if(~stopped && cycle < 64) begin
			  if(cycle >= 15 && cycle < 63) begin
				  /*
				  * uint32_t m[64]; <- 64 * 4 = 256 bytes
				  * The first 64 bytes are filled by in_data
				  * Byte 64 is filled with: m[i - 7] = m[9]
				  * m[9] = 9 * 4 = 36 bytes in
				  * (cycle - 7) * 4 = 9 * 4 = 36
				  */
				  m[cycle + 1] <= sig1_r + m[cycle - 6] + sig0_r + m[cycle - 15];
			  end
			  cycle <= cycle + 1;
			  h <= g;
			  g <= f;
			  f <= e;
			  e <= d + t1;
			  d <= c;
			  c <= b;
			  b <= a;
			  a <= t1 + t2;
		  end
	  end
  end

  // Register outputs
  always_ff @ (posedge clk, posedge rst) begin
          if (rst) begin
                  out_res      <= '0;
                  out_valid <= '0;
		  stopped <= 1;
          end else begin
		  if (cycle == 64 && ~in_valid) begin
		      out_res[0] <= state0 + a;
		      out_res[1] <= state1 + b;
		      out_res[2] <= state2 + c;
		      out_res[3] <= state3 + d;
		      out_res[4] <= state4 + e;
		      out_res[5] <= state5 + f;
		      out_res[6] <= state6 + g;
		      out_res[7] <= state7 + h;
                      out_valid <= '1;
		      stopped <= 1;
		  end else begin
                      out_valid <= '0;
	          end
          end
  end

endmodule
