module rotright17
  ( 
    input  wire logic [31:0] inp,
    output logic [31:0] res);
   
 
  always_comb begin
          res[0] = inp[17];
          res[1] = inp[18];
          res[2] = inp[19];
          res[3] = inp[20];
          res[4] = inp[21];
          res[5] = inp[22];
          res[6] = inp[23];
          res[7] = inp[24];
          res[8] = inp[25];
          res[9] = inp[26];
          res[10] = inp[27];
          res[11] = inp[28];
          res[12] = inp[29];
          res[13] = inp[30];
          res[14] = inp[31];
          res[15] = inp[0];
          res[16] = inp[1];
          res[17] = inp[2];
          res[18] = inp[3];
          res[19] = inp[4];
          res[20] = inp[5];
          res[21] = inp[6];
          res[22] = inp[7];
          res[23] = inp[8];
          res[24] = inp[9];
          res[25] = inp[10];
          res[26] = inp[11];
          res[27] = inp[12];
          res[28] = inp[13];
          res[29] = inp[14];
          res[30] = inp[15];
          res[31] = inp[16];

  end
 
endmodule
