module testbed;

    reg [7:0] DATA1,DATA2;
    reg [2:0] SELECT;
    wire [7:0] RESULT;

    initial begin
        //$monitor($time," result : %b",RESULT);
        $dumpfile("alu_wavedata.vcd");
        $dumpvars(0,testbed);
    end

    alu myALU(DATA1,DATA2,RESULT,SELECT);
    
    initial begin
		
		$monitor($time," result : %b",RESULT);
		DATA1 = 8'b0000_0001;
		DATA2 = 8'b0000_0001;
		SELECT = 3'b001;
		
		#1
		$monitor($time," result : %b",RESULT);
		
		#1
		$monitor($time," result : %b",RESULT);
		
		DATA1 = 8'b0000_0000;
		/*whenever a value changes, it takes the existing values and do the calculations.In order to see a result, we need to
		change one of DATA1,DATA2 and RESULT.
		
		Considering this case:-
			*t = 0 - DATA1 = 1,DATA2 = 1,SELECT = ADD. There exists undefined values in DATA1,DATA2 and RESULT. Since ADD has a
					 delay of 2 units, the ALU outputs/monitors the value in the RESULT(which is not defined)
					 
			*t = 1 - still the RESULT is undefined because ADD has a delay of 2 time units.
					(result1 = 1,result2=x,result3=1,result4=1)
			
			*t = 2 - RESULT is still Undefined(result1 = 1,result2=2,result3=1,result4=1).To assign the new value to Result
					 one of DATA1,DATA2,SELECT should change.If the RESULT changes the testbench outputs the new value.
					 Here, the RESULT is 2.
		
		*/
		#1
		$monitor($time," result : %b",RESULT);
		
		#1
		$monitor($time," result : %b",RESULT);
		
		#1
		$monitor($time," result : %b",RESULT);
		
		#1
		$monitor($time," result : %b",RESULT);
		
		#1
		$monitor($time," result : %b",RESULT);
		
    end

    

  

endmodule

module alu(DATA1,DATA2,RESULT,SELECT);

    input  [7:0] DATA1;
    input  [7:0] DATA2;
    input  [2:0] SELECT;
    output reg [7:0] RESULT;

    wire [7:0] result1,result2,result3,result4;

    FORWARD Forward(DATA2,result1);
    ADD Add(DATA1,DATA2,result2);
    AND And(DATA1,DATA2,result3);
    OR Or(DATA1,DATA2,result4);

   always @ (DATA1,DATA2,SELECT) begin
		case (SELECT)
			3'b000 : RESULT = result1;
			3'b001 : RESULT = result2;
			3'b010 : RESULT = result3;
			3'b011 : RESULT = result4;
			default : RESULT = result1; 
		endcase
    end

endmodule

    
module FORWARD(data,result);
	input [7:0] data;
	output [7:0] result;
	
	assign #1 result=data;
endmodule


module ADD(data1,data2,result);
	input [7:0] data1,data2;
	output [7:0] result;
	
	assign #2 result = data1+data2;
endmodule


module AND(data1,data2,result);
	input [7:0] data1,data2;
	output [7:0] result;
	
	assign #1 result = data1&data2;
endmodule


module OR(data1,data2,result);
	input [7:0] data1,data2;
	output [7:0] result;
	
	assign #1 result = data1|data2;
endmodule
