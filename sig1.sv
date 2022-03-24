module sig1
  ( 
    input  logic [31:0] inp,
    output logic [31:0] res);
   
  logic [31:0] temp2;
  logic [31:0] temp3;
 
  rotright17 rr17(.inp, .res(temp2));
  rotright19 rr19(.inp, .res(temp3));
  assign res = temp2 ^ temp3 ^ (inp >> 10);
 
endmodule
