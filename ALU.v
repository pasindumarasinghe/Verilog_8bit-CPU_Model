module alu(DATA1,DATA2,RESULT,SELECT,ZERO);

    input  [7:0] DATA1 ;
    input  [7:0] DATA2 ;//defining inputs and outputs all wires exept for the result register
    input  [2:0] SELECT ;
    output reg [7:0] RESULT;//has to be register type, as RESULT is assigned values in an always @ block
    output ZERO;//to check whether both the inputs to the ALU are the same or not.

    wire [7:0] forward_out,add_out,and_out,or_out,ror_out,mul_out,sra_out,shiftl_out;//wires inside the alu

    FORWARD Forward(DATA2,forward_out);//instantiating modules with individual output wires for each
    ADD Add(DATA1,DATA2,add_out);
    AND And(DATA1,DATA2,and_out) ;
    OR Or(DATA1,DATA2,or_out) ;
    // LOGICAL_SHIFT ls(DATA2,DATA1,shiftl_out);

//    ROTATE_RIGHT ROR(DATA2,DATA1,ror_out);
    //MULTIPLY mul(DATA1,DATA2,mul_out);
    //ARITHMATIC_SHIFT_RIGHT sra(DATA2,DATA1,sra_out);
    //LOGICAL_SHIFT sl(DATA2,DATA1,shiftl_out);

   always @ (SELECT,forward_out,add_out,and_out,or_out) begin//run whenever inputs are changed
		case (SELECT)
			3'b000 :  RESULT = forward_out;//assigning the coresponding outputs acording to the SELECT signal
			3'b001 :  RESULT = add_out;
			3'b010 :  RESULT = and_out;
			3'b011 :  RESULT = or_out;
//    3'b100 :  RESULT = ror_out;
    // 3'b101 :  RESULT = mul_out;
    // 3'b110 :  RESULT = sra_out;
    // 3'b111 :  RESULT = shiftl_out;
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

module LOGICAL_SHIFT(DATA1,IMMEDIATE_VALUE,RESULT) ;//module for bitwise or operation

    input [7:0] DATA1 ;
    input signed [7:0] IMMEDIATE_VALUE;
    output reg [7:0] RESULT;
    
    reg [0:7] data;
    integer i;

    reg shift=0;
    reg shift_amount;

    shift_left_logical sll(shift,data,RESULT);
    shift_right_logical srl(shift,data,RESULT);
   
   always @ (DATA1,IMMEDIATE_VALUE) begin
       case(IMMEDIATE_VALUE[7])//check the MSB for sign
           0:begin//if the value is positive
               shift_amount = IMMEDIATE_VALUE;
           end           
           1:begin//if the value is negative
               shift_amount = -IMMEDIATE_VALUE;              
           end
       endcase
   end

   for(i=0;i<shift_amount;i++) begin
       shift=1;
       shift=0;   
       data = RESULT;

   end


// endmodule

// module ROTATE_RIGHT(DATA_IN,IMMEDIATE_VALUE,RESULT);

//     input [7:0] DATA_IN;
//     input [7:0] IMMEDIATE_VALUE;
//     output reg [7:0] RESULT;

//     // integer i = 128*IMMEDIATE_VALUE[7] + 64*IMMEDIATE_VALUE[6] + 32*IMMEDIATE_VALUE[5] + 16*IMMEDIATE_VALUE[4] + 8*IMMEDIATE_VALUE[3] + 4*IMMEDIATE_VALUE[2] + 2*IMMEDIATE_VALUE[1] + IMMEDIATE_VALUE[0];

//     always @ (DATA_IN,IMMEDIATE_VALUE) begin
// 		RESULT =  {DATA_IN[IMMEDIATE_VALUE-1:0],DATA_IN[7:IMMEDIATE_VALUE]};
//     end
// endmodule

// module ARITHMATIC_SHIFT_RIGHT(DATA_IN,IMMEDIATE_VALUE,RESULT);

//     input [7:0] DATA_IN;
//     input [7:0] IMMEDIATE_VALUE;
//     output reg [7:0] RESULT;

//     always @ (IMMEDIATE_VALUE,DATA_IN) begin
//         RESULT = {{IMMEDIATE_VALUE*{1'b0}},DATA_IN[7:IMMEDIATE_VALUE]};
//     end

// endmodule

module MULTIPLY(DATA_IN,IMMEDIATE_VALUE,RESULT);

    input [0:7] DATA_IN;
    input [7:0] IMMEDIATE_VALUE;
    output reg [7:0] RESULT;

    reg [7:0] PRODUCT0,PRODUCT1,PRODUCT2,PRODUCT3,PRODUCT4,PRODUCT5,PRODUCT6,PRODUCT7;//intermediate wires
    wire [7:0] intermediate1,intermediate2;

    //multiplying one value with each bit of the other, sperately
    PRODUCT0[3:0] = {4{DATA_IN[0]}} & IMMEDIATE_VALUE[3:0];
    PRODUCT1[3:0] = {4{DATA_IN[1]}} & IMMEDIATE_VALUE[3:0];
    PRODUCT2[3:0] = {4{DATA_IN[2]}} & IMMEDIATE_VALUE[3:0];
    PRODUCT3[3:0] = {4{DATA_IN[3]}} & IMMEDIATE_VALUE[3:0];

    //sign extending and shifting
    PRODUCT0[7:0] = {4{PRODUCT0[3]},PRODUCT0[3:0]};           
    PRODUCT1[7:0] = {3{PRODUCT1[3]},PRODUCT1[3:0],1'b0};  
    PRODUCT2[7:0] = {2{PRODUCT2[3]},PRODUCT2[3:0],2'b00}; 
    PRODUCT3[7:0] = {1{PRODUCT3[3]},PRODUCT3[3:0],3'b000};

    intermediate1 #1 = PRODUCT0 + PRODUCT1 ;
    intermediate2 #1 = PRODUCT2 + PRODUCT3 ;

    RESULT #1 = intermediate1 + intermediate2;

endmodule

// module shift_left_logical(shift,DATA,out) ;

//     input shift;
//     input [7:0] DATA;
//     output  [7:0] out;

//     out[0] = DATA[0] & !shift  ;
//     out[1] = DATA[1] & !shift  + shift & DATA[0];
//     out[2] = DATA[2] & !shift  + shift & DATA[1];
//     out[3] = DATA[3] & !shift  + shift & DATA[2];
 
//     out[4] = DATA[4] & !shift  + shift & DATA[3];
//     out[5] = DATA[5] & !shift  + shift & DATA[4];
//     out[6] = DATA[6] & !shift  + shift & DATA[5];
//     out[7] = DATA[7] & !shift  + shift & DATA[6];

// endmodule


// module shift_right_logical(shift,DATA,out) ;

//     input shift;
//     input [7:0] DATA;
//     output  [7:0] out;

//     out[7] = DATA[7] & !shift ;
//     out[6] = DATA[6] & !shift  + shift & DATA[0];
//     out[5] = DATA[5] & !shift  + shift & DATA[1];
//     out[4] = DATA[4] & !shift  + shift & DATA[2];
 
//     out[3] = DATA[3] & !shift  + shift & DATA[3];
//     out[2] = DATA[2] & !shift  + shift & DATA[4];
//     out[1] = DATA[1] & !shift  + shift & DATA[5];
//     out[0] = DATA[0] & !shift  + shift & DATA[6];

// endmodule


// module shift_right_arithmatic(shift,DATA,out) ;

//     input shift;
//     input [7:0] DATA;
//     output  [7:0] out;

//     out[7] = DATA[7] & !shift + shift & DATA[7];
//     out[6] = DATA[6] & !shift + shift & DATA[7];
//     out[5] = DATA[5] & !shift + shift & DATA[6];
//     out[4] = DATA[4] & !shift + shift & DATA[5];
 
//     out[3] = DATA[3] & !shift + shift & DATA[4];
//     out[2] = DATA[2] & !shift + shift & DATA[3];
//     out[1] = DATA[1] & !shift + shift & DATA[2];
//     out[0] = DATA[0] & !shift + shift & DATA[1];

// endmodule

