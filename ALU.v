module testbed;//for testing the alu

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

endmodule

module alu(DATA1,DATA2,RESULT,SELECT);

    input  [7:0] DATA1 ;
    input  [7:0] DATA2 ;//defining inputs and outputs all wires exept for the result register
    input  [2:0] SELECT ;
    output reg [7:0] RESULT;//has to be register type, as RESULT is assigned values in an always @ block

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

    assign #2 ESULT = DATA1 + DATA2;//addiing the data and continuesly assigning the wire RESULT with an artifitial delay

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
