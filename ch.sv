module ch
  ( 
    input  logic [31:0] inp1,
    input  logic [31:0] inp2,
    input  logic [31:0] inp3,
    output logic [31:0] res);
   
  assign res = (inp1 & inp2) ^ (~(inp1) & inp3);
 
endmodule
