module ep0
  ( 
    input  logic [31:0] inp,
    output logic [31:0] res);
   
  logic [31:0] temp2;
  logic [31:0] temp3;
  logic [31:0] temp4;
 
  rotright2 rr2(.inp, .res(temp2));
  rotright13 rr13(.inp, .res(temp3));
  rotright22 rr22(.inp, .res(temp4));
  assign res = temp2 ^ temp3 ^ temp4;
 
endmodule
