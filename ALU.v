/*module testbed;//for testing the alu

    reg [7:0] DATA1,DATA2;
    reg [2:0] SELECT; //creating registers and wires
    wire [7:0] RESULT;

    initial begin
        $monitor($time,"select = %b data1 = %b data2 = %b result : %b",SELECT,DATA1,DATA2,RESULT);//monitering the changes in result
        $dumpfile("alu_wavedata.vcd");//wavedata dumpfile to be examined with GTKwave
        $dumpvars(0,testbed);//dumpng all the variables in the testbed 
    end

    alu myALU(DATA1,DATA2,RESULT,SELECT);//instanciating the alu module

    initial begin
        DATA1 = 8'b1000_0001;
        DATA2 = 8'b0100_1110;
    end

    initial begin
        #10
        SELECT = 3'b001;//add signal
        DATA1 = 8'b0000_0001;
        DATA2 = 8'b0000_0011;
    end

    initial begin
        #15
        SELECT = 3'b010;//and signal
        DATA1 = 8'b1101_0101;
        DATA2 = 8'b1110_1010;
    end

    initial begin
        #20
        SELECT = 3'b011;//or signal
        DATA1 = 8'b0000_0001;
        DATA2 = 8'b0000_0010;
    end
    
    initial begin
        #25
        SELECT = 3'b000;
        DATA1 = 8'b1000_0001;
        DATA2 = 8'b0111_1110;
    end

    initial begin//finishing the simulation
        #100 $finish;
    end

endmodule*/

module alu(DATA1,DATA2,RESULT,SELECT,ZERO);

    input  [7:0] DATA1 ;
    input  [7:0] DATA2 ;//defining inputs and outputs all wires exept for the result register
    input  [2:0] SELECT ;
    output reg [7:0] RESULT;//has to be register type, as RESULT is assigned values in an always @ block
    output reg ZERO;//for outputting whether inputs are equal or not

    wire [7:0] forward_out,add_out,and_out,or_out,ror_out,mul_out,sra_out,shiftl_out;//wires inside the alu

    FORWARD Forward(DATA2,forward_out);//instantiating modules with individual output wires for each
    ADD Add(DATA1,DATA2,add_out);
    AND And(DATA1,DATA2,and_out);
    OR Or(DATA1,DATA2,or_out);
    ROTATE_RIGHT ROR(DATA1,DATA2,ror_out);
    MULTIPLY mul(DATA1,DATA2,mul_out);
    ARITHMATIC_SHIFT_RIGHT sra(DATA1,DATA2,sra_out);
    LOGICAL_SHIFT sl(DATA1,DATA2,shiftl_out);
    
    always @ (add_out) begin //setting out for beq and bne instructions
        if ( add_out == 0 )
            ZERO = 1 ;     
        else
            ZERO = 0 ;
    end

   always @ (SELECT,forward_out,add_out,and_out,or_out,ror_out,sra_out,shiftl_out) begin//run whenever inputs are changed

    case (SELECT)

    3'b000 :  RESULT = forward_out;//assigning the coresponding outputs acording to the SELECT signal
    3'b001 :  RESULT = add_out;
    3'b010 :  RESULT = and_out;
    3'b011 :  RESULT = or_out;
    3'b100 :  RESULT = ror_out;
    3'b101 :  RESULT = mul_out;
    3'b110 :  RESULT = sra_out;
    3'b111 :  RESULT = shiftl_out;

    default :  RESULT =8'bz;
    
    endcase

    end

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

    reg [7:0] shift_amount = 1'd0;
   
   always @ (DATA1,IMMEDIATE_VALUE) begin
       case(IMMEDIATE_VALUE[7])//check the MSB for sign
           0:begin//if the value is positive
               shift_amount = IMMEDIATE_VALUE;
               RESULT = {{shift_amount*{DATA1[7]}},DATA1[7:IMMEDIATE_VALUE]};
           end           
           1:begin//if the value is negative
               shift_amount = -IMMEDIATE_VALUE;
               RESULT = {DATA1[7-shift_amount:0],{shift_amount*{1'0}}};               
           end
       endcase
   end
endmodule

module ROTATE_RIGHT(DATA_IN,IMMEDIATE_VALUE,RESULT);

    input [7:0] DATA_IN;
    input [7:0] IMMEDIATE_VALUE;
    output reg [7:0] RESULT;

    always @ (DATA_IN,IMMEDIATE_VALUE) begin
        RESULT =  {DATA_IN[IMMEDIATE_VALUE-1'b1:0],DATA_IN[7:IMMEDIATE_VALUE]};        
    end
endmodule

module ARITHMATIC_SHIFT_RIGHT(DATA_IN,IMMEDIATE_VALUE,RESULT);

    input [7:0] DATA_IN;
    input [7:0] IMMEDIATE_VALUE;
    output reg [7:0] RESULT;

    always @ (IMMEDIATE_VALUE,DATA_IN) begin
        RESULT = {{IMMEDIATE_VALUE*{1'b0}},DATA_IN[7:IMMEDIATE_VALUE]};
    end

endmodule

module MULTIPLY(DATA_IN,IMMEDIATE_VALUE,RESULT);

    input [0:7] DATA_IN;
    input [7:0] IMMEDIATE_VALUE;
    output reg [7:0] RESULT;

    reg [7:0] PRODUCT0,PRODUCT1,PRODUCT2,PRODUCT3,PRODUCT4,PRODUCT5,PRODUCT6,PRODUCT7;//intermediate wires
    wire [7:0] intermediate1,intermediate2;

    //multiplying one value with each bit of the other, sperately
    PRODUCT0[3:0] = {4{DATA_IN[0]}} ;
    PRODUCT1[3:0] = {4{DATA_IN[1]}} ;
    PRODUCT2[3:0] = {4{DATA_IN[2]}} ;
    PRODUCT3[3:0] = {4{DATA_IN[3]}} ;

    PRODUCT0[3:0] = PRODUCT0[3:0] & IMMEDIATE_VALUE[3:0]
    PRODUCT1[3:0] = PRODUCT1[3:0] & IMMEDIATE_VALUE[3:0]
    PRODUCT2[3:0] = PRODUCT2[3:0] & IMMEDIATE_VALUE[3:0]
    PRODUCT3[3:0] = PRODUCT3[3:0] & IMMEDIATE_VALUE[3:0]

    //sign extending and shifting
    PRODUCT0[7:0] = {4{PRODUCT0[3]},PRODUCT0[3:0]};           
    PRODUCT1[7:0] = {3{PRODUCT1[3]},PRODUCT1[3:0],1'b0};  
    PRODUCT2[7:0] = {2{PRODUCT2[3]},PRODUCT2[3:0],2'b00}; 
    PRODUCT3[7:0] = {1{PRODUCT3[3]},PRODUCT3[3:0],3'b000};

    intermediate1 #1 = PRODUCT0 + PRODUCT1 ;
    intermediate2 #1 = PRODUCT2 + PRODUCT3 ;

    RESULT #1 = intermediate1 + intermediate2;

endmodule