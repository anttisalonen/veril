module rotright25
  ( 
    input  logic [31:0] inp,
    output logic [31:0] res);
   
  logic [31:0] temp;
 
  always_comb begin
          assign temp[0] = inp[25];
          assign temp[1] = inp[26];
          assign temp[2] = inp[27];
          assign temp[3] = inp[28];
          assign temp[4] = inp[29];
          assign temp[5] = inp[30];
          assign temp[6] = inp[31];
          assign temp[7] = inp[0];
          assign temp[8] = inp[1];
          assign temp[9] = inp[2];
          assign temp[10] = inp[3];
          assign temp[11] = inp[4];
          assign temp[12] = inp[5];
          assign temp[13] = inp[6];
          assign temp[14] = inp[7];
          assign temp[15] = inp[8];
          assign temp[16] = inp[9];
          assign temp[17] = inp[10];
          assign temp[18] = inp[11];
          assign temp[19] = inp[12];
          assign temp[20] = inp[13];
          assign temp[21] = inp[14];
          assign temp[22] = inp[15];
          assign temp[23] = inp[16];
          assign temp[24] = inp[17];
          assign temp[25] = inp[18];
          assign temp[26] = inp[19];
          assign temp[27] = inp[20];
          assign temp[28] = inp[21];
          assign temp[29] = inp[22];
          assign temp[30] = inp[23];
          assign temp[31] = inp[24];

          res = temp;
  end
 
endmodule
