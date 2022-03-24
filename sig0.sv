module sig0
  ( 
    input  logic [31:0] inp,
    output logic [31:0] res);
   
  logic [31:0] temp2;
  logic [31:0] temp3;
 
  rotright7 rr7(.inp, .res(temp2));
  rotright18 rr18(.inp, .res(temp3));
  assign res = temp2 ^ temp3 ^ (inp >> 3);
 
endmodule
