module alu(DATA1,DATA2,RESULT,SELECT,ZERO);

    input  [7:0] DATA1 ;
    input  [7:0] DATA2 ;//defining inputs and outputs all wires exept for the result register
    input  [2:0] SELECT ;
    output reg [7:0] RESULT;//has to be register type, as RESULT is assigned values in an always @ block
    output ZERO;//to check whether both the inputs to the ALU are the same or not.

    wire [7:0] forward_out,add_out,and_out,or_out;//wires inside the alu

    FORWARD Forward(DATA2,forward_out);//instantiating modules with individual output wires for each
    ADD Add(DATA1,DATA2,add_out);
    AND And(DATA1,DATA2,and_out) ;
    OR Or(DATA1,DATA2,or_out) ;

   always @ (SELECT,forward_out,add_out,and_out,or_out) begin//run whenever inputs are changed
		case (SELECT)
			3'b000 :  RESULT = forward_out;//assigning the coresponding outputs acording to the SELECT signal
			3'b001 :  RESULT = add_out;
			3'b010 :  RESULT = and_out;
			3'b011 :  RESULT = or_out;
			default :  RESULT =forward_out;
		endcase
   end
   
   assign ZERO = (add_out)?0:1;

endmodule
    
module FORWARD(DATA2,RESULT);//module for forwarding the data from port two to RESULT

    input [7:0] DATA2 ;
    output [7:0] RESULT;

    assign #1 RESULT = DATA2;//continuous assigning of valules to the wire RESULT with an artifitial delay

endmodule

module ADD(DATA1,DATA2,RESULT);//module to add two 8bit data values

    input [7:0] DATA1 ;
    input [7:0] DATA2 ;
    output [7:0] RESULT;

    assign #2 RESULT = DATA1 + DATA2;//addiing the data and continuesly assigning the wire RESULT with an artifitial delay

endmodule

module AND(DATA1,DATA2,RESULT) ;//module for bitwise and operation

    input [7:0] DATA1 ;
    input [7:0] DATA2 ;
    output [7:0] RESULT;

    assign #1 RESULT = DATA1 & DATA2;//ANDing the data and continuesly assigning the wire RESULT with an artifitial delay

endmodule

module OR(DATA1,DATA2,RESULT) ;//module for bitwise or operation

    input [7:0] DATA1 ;
    input [7:0] DATA2 ;
    output [7:0] RESULT;

    assign #1 RESULT = DATA1 | DATA2;//ORing the data and continuesly assigning the wire RESULT with an artifitial delay

endmodule
