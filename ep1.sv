module ep1
  ( 
    input  logic [31:0] inp,
    output logic [31:0] res);
   
  logic [31:0] temp2;
  logic [31:0] temp3;
  logic [31:0] temp4;
 
  rotright6 rr6(.inp, .res(temp2));
  rotright11 rr11(.inp, .res(temp3));
  rotright25 rr25(.inp, .res(temp4));
  assign res = temp2 ^ temp3 ^ temp4;
 
endmodule
