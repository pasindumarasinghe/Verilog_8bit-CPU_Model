/*
CO224 - Computer Architecture
Lab 4 - Part 1 - ALU

Group 12
*E/17/134 - Jayasooriya JAKD
*E/17/207 - Marasinghe MAPG
*/

//This is the testbench that tests the ALU

module testbed;

    reg [7:0] DATA1,DATA2;
    reg [2:0] SELECT;
    wire [7:0] RESULT;

    initial begin
        $monitor($time," result : %b",RESULT);
        $dumpfile("alu_wavedata.vcd");
        $dumpvars(0,testbed);
    end

    alu myALU(DATA1,DATA2,RESULT,SELECT);

    initial begin
        DATA1 = 8'b10000001;
        DATA2 = 8'b01001110;
    end

    initial begin
        #10
        SELECT = 3'b001;
        DATA1 = 8'b00000001;
        DATA2 = 8'b00000011;
    end

    initial begin
        #15
        SELECT = 3'b010;
        DATA1 = 8'b11010101;
        DATA2 = 8'b11101010;
    end

    initial begin
        #20
        SELECT = 3'b011;
        DATA1 = 8'b00000001;
        DATA2 = 8'b00000010;
    end
    
    initial begin
        #25
        SELECT = 3'b000;
        DATA1 = 8'b10000001;
        DATA2 = 8'b01111110;
    end

    initial begin
        #500 $finish;
    end

endmodule

module alu(DATA1,DATA2,RESULT,SELECT);
	input [7:0] DATA1,DATA2; //declare 8-bit operands
	input [2:0] SELECT; //declare the 3 bit select input
	output reg [7:0] RESULT; //declare the 3 bit output
	
	//The mux will output the required result according to the select input
	always @(DATA1,DATA2,SELECT) begin
		case(SELECT)
			3'b000 : #1 RESULT = DATA2;
			3'b001 : #2 RESULT = DATA1 + DATA2;
			3'b010 : #1 RESULT = DATA1 & DATA2;
			3'b011 : #1 RESULT = DATA1 | DATA2;
			default : #2 RESULT = DATA1 + DATA2;
		endcase				
	end	
endmodule
